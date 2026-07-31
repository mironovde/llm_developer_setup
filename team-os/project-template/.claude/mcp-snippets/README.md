# MCP snippets

Optional MCP server configs, kept out of `.mcp.json` until actually needed.
To enable one: merge its `mcpServers` entry into the project `.mcp.json`,
or run `claude mcp add-json <name> '<json>'`.
Note: an unset `${VAR}` does NOT disable a server — the server still starts.
Keep unused servers out of `.mcp.json` entirely.
