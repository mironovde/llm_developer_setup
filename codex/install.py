#!/usr/bin/env python3
"""Install the reviewed Astra files; dry-run by default. Python 3.11+."""

import argparse
import copy
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import tempfile
import tomllib
import uuid

ROOT = Path(__file__).resolve().parent


def digest(data):
    return hashlib.sha256(data).hexdigest() if data is not None else None


def read(path):
    if path.is_symlink():
        raise ValueError(f"Refusing to replace a symlink: {path}")
    return path.read_bytes() if path.exists() else None


def merge_config(current, portable):
    """Edit only managed root scalars; verify all other TOML values survive."""
    old = tomllib.loads(current)
    settings = tomllib.loads(portable)
    if set(settings) != {"model", "model_reasoning_effort", "personality"}:
        raise ValueError("Unexpected managed config keys")
    expected = copy.deepcopy(old)
    expected.pop("model_context_window", None)
    expected.update(settings)
    # This intentionally supports simple root scalar assignments only. Semantic
    # equality below rejects unusual TOML safely before any live file is written.
    table = re.search(r"(?m)^\s*\[", current)
    head, tail = (current[:table.start()], current[table.start():]) if table else (current, "")
    for key in (*settings, "model_context_window"):
        head = re.sub(rf"(?m)^[ \t]*{key}[ \t]*=[^\n]*(?:\n|$)", "", head)
    managed = "".join(f"{key} = {json.dumps(value)}\n" for key, value in settings.items())
    result = managed + head + tail
    if tomllib.loads(result) != expected:
        raise ValueError("Config has nonstandard root assignments; merge manually without overwriting other settings")
    return result.encode()


def atomic_write(path, data, mode):
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix=".astra-", dir=path.parent)
    try:
        with os.fdopen(fd, "wb") as stream:
            os.fchmod(stream.fileno(), mode)
            stream.write(data)
        os.replace(temporary, path)
    finally:
        Path(temporary).unlink(missing_ok=True)


def plan_install(codex_home, home_guide, projects):
    sources = [(ROOT / "home/AGENTS.md", codex_home / "AGENTS.md"),
               (ROOT / "home/astra-deep.config.toml", codex_home / "astra-deep.config.toml")]
    if home_guide:
        sources.append((ROOT / "home-directory/AGENTS.md", home_guide))
    for item in projects:
        name, separator, destination = item.partition("=")
        if not separator or not re.fullmatch(r"[a-zA-Z0-9_-]+", name):
            raise ValueError("Project syntax: --project template-name=/absolute/project/path")
        source = ROOT / "projects" / name / "AGENTS.md"
        directory = Path(destination).expanduser().absolute()
        if not source.is_file() or not directory.is_dir():
            raise ValueError(f"Missing project template or destination: {name}")
        sources.append((source, directory / "AGENTS.md"))
    override_paths = [codex_home / "AGENTS.override.md"]
    override_paths.extend(dst.parent / "AGENTS.override.md" for _, dst in sources)
    for override in set(override_paths):
        if override.exists() and override.read_text().strip():
            raise ValueError(f"Active override would mask this installation: {override}")
    config = codex_home / "config.toml"
    old_config = read(config)
    plan = [(config, old_config, merge_config(
        (old_config or b"").decode(), (ROOT / "home/config.toml").read_text()))]
    plan.extend((dst, read(dst), src.read_bytes()) for src, dst in sources)
    if len({path for path, _, _ in plan}) != len(plan):
        raise ValueError("Duplicate installation destination")
    return [(path, old, new) for path, old, new in plan if old != new]


def apply_plan(plan, codex_home):
    if not plan:
        return None
    for path, old, _ in plan:
        if read(path) != old:
            raise ValueError(f"File changed after planning: {path}")
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    backup = codex_home / "backups" / "gpt-6-astra" / f"{stamp}-{uuid.uuid4().hex[:8]}"
    backup.mkdir(parents=True, mode=0o700)
    records = []
    for index, (path, old, new) in enumerate(plan):
        mode = stat.S_IMODE(path.stat().st_mode) if old is not None else 0o600
        filename = f"{index:03}.original" if old is not None else None
        if old is not None:
            atomic_write(backup / filename, old, 0o600)
        records.append({"path": str(path), "backup": filename, "mode": mode,
                        "before": digest(old), "after": digest(new)})
    # Write the recovery manifest before mutations, including for interrupted runs.
    atomic_write(backup / "manifest.json", json.dumps({"files": records}, indent=2).encode(), 0o600)
    for path, old, new in plan:
        if read(path) != old:
            raise ValueError(f"Concurrent change; recovery manifest: {backup}")
        mode = stat.S_IMODE(path.stat().st_mode) if old is not None else 0o600
        atomic_write(path, new, mode)
    return backup


def restore(backup, apply):
    records = json.loads((backup / "manifest.json").read_text())["files"]
    pending = []
    for record in records:
        path = Path(record["path"])
        current = digest(read(path))
        if current == record["before"]:
            continue
        if current != record["after"]:
            raise ValueError(f"Refusing to overwrite edits made after installation: {path}")
        original = (backup / record["backup"]).read_bytes() if record["backup"] else None
        if digest(original) != record["before"]:
            raise ValueError(f"Backup checksum mismatch: {path}")
        pending.append((path, original, record["mode"]))
    for path, original, mode in pending:
        print(f"{'RESTORE' if apply else 'WOULD RESTORE'} {path}")
        if apply:
            # Recheck immediately before writing; never clobber a later user edit.
            record = next(r for r in records if r["path"] == str(path))
            if digest(read(path)) != record["after"]:
                raise ValueError(f"Concurrent change during restore: {path}")
            if original is None:
                path.unlink()
            else:
                atomic_write(path, original, mode)
    return len(pending)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true", help="Write reviewed changes (default: dry-run)")
    parser.add_argument("--codex-home", type=Path,
                        default=Path(os.environ.get("CODEX_HOME", str(Path.home() / ".codex"))))
    parser.add_argument("--home-guide", type=Path, help="Explicit destination for the legacy home AGENTS.md")
    parser.add_argument("--project", action="append", default=[], metavar="NAME=PATH")
    parser.add_argument("--restore", type=Path, help="Restore a private backup; requires --apply to write")
    args = parser.parse_args()
    try:
        if args.restore:
            if args.home_guide or args.project:
                raise ValueError("Do not combine restore with project installation")
            count = restore(args.restore.expanduser().absolute(), args.apply)
        else:
            codex_home = args.codex_home.expanduser().absolute()
            home_guide = args.home_guide.expanduser().absolute() if args.home_guide else None
            plan = plan_install(codex_home, home_guide, args.project)
            for path, old, new in plan:
                print(f"{'UPDATE' if args.apply else 'WOULD UPDATE'} {path} ({len(old or b'')} → {len(new)} bytes)")
            backup = apply_plan(plan, codex_home) if args.apply else None
            if backup:
                print(f"Private backup: {backup}")
            count = len(plan)
        print(f"{count} file(s) {'processed' if args.apply else 'planned'}.")
    except (ValueError, OSError) as error:
        parser.exit(1, f"Error: {error}\n")


if __name__ == "__main__":
    main()
