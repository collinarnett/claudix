# claudix

> **Disclaimer:** This project was vibecoded.

A [flake-parts](https://github.com/hercules-ci/flake-parts) module for managing [Claude Code](https://code.claude.com) settings as typed Nix options. Declare your `.claude/settings.json` in Nix and get type checking, enums, descriptions, and per-project configuration for free.

The Nix options are auto-generated from Claude Code's [JSON Schema](https://json.schemastore.org/claude-code-settings.json) using [jsonschema2nix](https://github.com/collinarnett/jsonschema2nix), so they stay in sync with upstream as the schema evolves.

## Usage

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    claudix.url = "github:collinarnett/claudix";
  };

  outputs = inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.claudix.flakeModules.default ];

      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      perSystem = { config, pkgs, ... }: {
        claude.settings = {
          model = "claude-sonnet-4-6";
          effortLevel = "high";
          alwaysThinkingEnabled = true;
          permissions = {
            allow = [ "Bash(npm run *)" "WebSearch" ];
            deny = [ "Read(./.env)" ];
            defaultMode = "default";
          };
          env = {
            ANTHROPIC_MODEL = "claude-opus-4-6";
          };
        };

        devShells.default = pkgs.mkShell {
          shellHook = config.claude.shellHook;
        };
      };
    };
}
```

Entering the devShell writes `.claude/settings.json` with only the keys you set:

```json
{
  "alwaysThinkingEnabled": true,
  "effortLevel": "high",
  "env": {
    "ANTHROPIC_MODEL": "claude-opus-4-6"
  },
  "model": "claude-sonnet-4-6",
  "permissions": {
    "allow": ["Bash(npm run *)", "WebSearch"],
    "defaultMode": "default",
    "deny": ["Read(./.env)"]
  }
}
```

## Module outputs

| Option | Type | Description |
|---|---|---|
| `claude.settings` | submodule | All Claude Code settings as typed Nix options |
| `claude.settingsFile` | package (read-only) | Derivation producing `settings.json` |
| `claude.shellHook` | string (read-only) | Shell snippet that writes `.claude/settings.json` |

`claude.settings` has a `freeformType` escape hatch — you can pass arbitrary extra keys for settings not yet in the schema without breaking the module.

## Regenerating options

When Claude Code's schema changes upstream, regenerate `generated/options.nix`:

```bash
nix run .#generate > generated/options.nix
```

## License

MIT
