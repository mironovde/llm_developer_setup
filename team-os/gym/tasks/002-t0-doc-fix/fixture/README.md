# gym-fixture-slug

Tiny URL-slug utility. Turns titles into URL-safe slugs. Zero dependencies.

## Quick Start

Verify your setup by running the test suite:

```sh
npm run tst
```

## CLI

Convert a title to a slug:

```sh
node src/slug.js "Hello World"
# hello-world
```

### Options

| Flag | Description |
|------|-------------|
| `--verbose` | Print the raw input to stderr before slugifying |
