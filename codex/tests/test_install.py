"""File-safety tests: no model calls, global writes or network access."""

import importlib.util
import json
from pathlib import Path
import tempfile
import tomllib
import unittest

MODULE = Path(__file__).resolve().parents[1] / "install.py"
spec = importlib.util.spec_from_file_location("astra_install", MODULE)
installer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(installer)


class InstallationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name) / "codex"
        self.home.mkdir()
        self.config = self.home / "config.toml"
        self.original = b'''model = "old-model"
model_context_window = 1050000
model_reasoning_effort = "xhigh"
approval_policy = "on-request"
notify = ["local-notifier"]
# Preserve this comment.
[mcp_servers.example.env]
TEST_ONLY_TOKEN = "not-a-real-credential"
[plugins."example@local"]
enabled = true
[projects."/tmp/example"]
trust_level = "trusted"
[desktop]
conversationDetailMode = "STEPS_COMMANDS"
'''
        self.config.write_bytes(self.original)

    def plan(self, **kwargs):
        return installer.plan_install(self.home, kwargs.get("home_guide"), kwargs.get("projects", []))

    def test_preservation_idempotence_and_full_restore(self):
        plan = self.plan()
        self.assertEqual(self.config.read_bytes(), self.original)  # dry-run
        backup = installer.apply_plan(plan, self.home)
        result = tomllib.loads(self.config.read_text())
        old = tomllib.loads(self.original.decode())
        for key in ("mcp_servers", "plugins", "projects", "desktop", "approval_policy", "notify"):
            self.assertEqual(result[key], old[key])
        self.assertNotIn("model_context_window", result)
        self.assertIn("# Preserve this comment.", self.config.read_text())
        self.assertEqual(result["model"], "gpt-6-astra")
        self.assertEqual(self.plan(), [])
        self.assertEqual(backup.stat().st_mode & 0o777, 0o700)
        for path in backup.iterdir():
            self.assertEqual(path.stat().st_mode & 0o777, 0o600)
        self.assertEqual(installer.restore(backup, False), len(plan))
        self.assertEqual(installer.restore(backup, True), len(plan))
        self.assertEqual(self.config.read_bytes(), self.original)
        self.assertFalse((self.home / "AGENTS.md").exists())
        self.assertEqual(installer.restore(backup, True), 0)

    def test_restore_rejects_later_edits_before_any_write(self):
        backup = installer.apply_plan(self.plan(), self.home)
        guide = self.home / "AGENTS.md"
        guide.write_text("User changed instructions")
        config_before = self.config.read_bytes()
        with self.assertRaisesRegex(ValueError, "after installation"):
            installer.restore(backup, True)
        self.assertEqual(self.config.read_bytes(), config_before)
        self.assertEqual(guide.read_text(), "User changed instructions")

    def test_install_rejects_concurrent_change(self):
        plan = self.plan()
        self.config.write_text('model = "user-choice"\n')
        with self.assertRaisesRegex(ValueError, "changed after planning"):
            installer.apply_plan(plan, self.home)
        self.assertFalse((self.home / "AGENTS.md").exists())

    def test_project_install_and_rollback_preserve_unrelated_work(self):
        project = Path(self.temp.name) / "project"
        project.mkdir()
        (project / "AGENTS.md").write_text("Existing project instructions")
        (project / "unfinished.py").write_text("user work")
        plan = self.plan(projects=[f"crm_npf={project}"])
        backup = installer.apply_plan(plan, self.home)
        self.assertEqual((project / "unfinished.py").read_text(), "user work")
        installer.restore(backup, True)
        self.assertEqual((project / "AGENTS.md").read_text(), "Existing project instructions")

    def test_override_and_symlink_are_not_silently_replaced(self):
        override = self.home / "AGENTS.override.md"
        override.write_text("Higher-priority instructions")
        with self.assertRaisesRegex(ValueError, "override"):
            self.plan()
        override.unlink()
        (self.home / "AGENTS.md").symlink_to(self.config)
        with self.assertRaisesRegex(ValueError, "symlink"):
            self.plan()

    def test_unusual_toml_is_rejected_without_changes(self):
        self.config.write_text('"model" = "old-model"\n')
        before = self.config.read_bytes()
        with self.assertRaises(ValueError):
            self.plan()
        self.assertEqual(self.config.read_bytes(), before)

    def test_fresh_install_and_duplicate_destination(self):
        self.config.unlink()
        plan = self.plan()
        backup = installer.apply_plan(plan, self.home)
        self.assertEqual(tomllib.loads(self.config.read_text())["model_reasoning_effort"], "medium")
        installer.restore(backup, True)
        self.assertFalse(self.config.exists())
        with self.assertRaisesRegex(ValueError, "Duplicate"):
            self.plan(home_guide=self.home / "AGENTS.md")


if __name__ == "__main__":
    unittest.main()
