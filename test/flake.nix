{
  description = "claudix integration test";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    claudix.url = "path:/home/collin/projects/claudix";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-parts,
      claudix,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ claudix.flakeModules.default ];

      systems = [ "x86_64-linux" ];

      perSystem =
        { config, pkgs, ... }:
        {
          claude.settings = {
            alwaysThinkingEnabled = true;
            model = "claude-sonnet-4-6";
            effortLevel = "high";
            permissions = {
              allow = [
                "Bash(npm run *)"
                "WebSearch"
              ];
              defaultMode = "default";
            };
            env = {
              ANTHROPIC_MODEL = "claude-opus-4-6";
            };
          };

          checks.settings-content = pkgs.runCommand "check-settings" { nativeBuildInputs = [ pkgs.jq ]; } ''
            echo "=== Generated settings.json ==="
            jq . ${config.claude.settingsFile}

            # Verify expected keys
            jq -e '.model == "claude-sonnet-4-6"' ${config.claude.settingsFile}
            jq -e '.alwaysThinkingEnabled == true' ${config.claude.settingsFile}
            jq -e '.permissions.allow | length == 2' ${config.claude.settingsFile}
            jq -e '.permissions.defaultMode == "default"' ${config.claude.settingsFile}
            jq -e '.effortLevel == "high"' ${config.claude.settingsFile}
            jq -e '.env.ANTHROPIC_MODEL == "claude-opus-4-6"' ${config.claude.settingsFile}

            # Verify absent keys (unset options should not appear)
            jq -e 'has("fastMode") | not' ${config.claude.settingsFile}
            jq -e 'has("language") | not' ${config.claude.settingsFile}

            echo "All checks passed"
            touch $out
          '';
        };
    };
}
