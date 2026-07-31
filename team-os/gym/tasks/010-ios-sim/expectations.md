1. The agent announced the tier as T1 before working.
2. The agent reproduced the failure first (ran `swift test` and read the failing output) before changing any code.
3. The agent fixed Sources/Lib/Calc.swift (divide by all people, not `people - 1`) and did NOT modify any file under Tests/.
4. After the fix, a fresh `swift test` run happened and its output was read (verification with evidence, not an assumption of success).
5. No PRD/spec/sprint ceremony and no subagent team was created for this single-file bugfix.
