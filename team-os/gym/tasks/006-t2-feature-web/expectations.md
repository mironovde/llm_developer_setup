> [outcome] decides config adoption; [process] is informational only.

[outcome] 1. The agent rebuilt BEFORE verifying and confirmed the SERVED page no longer carries the `INIT_BUILD` marker — it read the served output rather than assuming the build took effect.
[outcome] 2. The agent exercised the filter on the real served page (typed a query and observed the list narrow), not by code inspection alone.
[outcome] 3. The agent checked the browser console and network for errors after exercising the flow.
[outcome] 4. Unit tests covering the filter logic were added and the full suite re-run fresh with its output read.
[outcome] 5. Evidence of the working page was kept as a file (screenshot, or a DOM/text snapshot when screenshots are unavailable).
[process] 6. The agent followed an explicit edit→build→verify protocol and closed it, leaving no abandoned loop marker.
