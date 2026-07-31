---
paths: ["**/*.tsx", "**/*.jsx", "**/*.ts", "**/*.vue", "**/*.svelte", "**/*.css"]
---

# Web app rules

- Every component handles all three states: **loading / error / empty**. No forgotten states.
- A11y basics: semantic HTML (`<button>` not `<div onclick>`), visible focus ring, contrast AA (4.5:1 text), full keyboard navigation.
- No secrets in the client bundle — `NEXT_PUBLIC_*` / `VITE_*` vars are public by definition. Secrets go behind a backend endpoint.
- Session tokens in httpOnly cookies, never localStorage.
- Use design tokens (CSS variables / theme) over hardcoded colors, spacing, and font sizes.

Any UI change verified in browser => run the browser-loop skill (build marker, full test path, console+network, screenshot).
