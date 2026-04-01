{
  lib,
  flake-parts-lib,
  ...
}:
let
  inherit (lib) mkOption types;
  inherit (flake-parts-lib) mkPerSystemOption;

  generatedOptions = import ../generated/options.nix { inherit lib; };

  # Recursively strip null leaves and collapse empty attrsets to null.
  # Skips derivations (which are attrsets with a _type field).
  removeNulls =
    val:
    if builtins.isAttrs val && !(val ? _type) then
      let
        cleaned = builtins.mapAttrs (_: removeNulls) val;
        filtered = lib.filterAttrs (_: v: v != null) cleaned;
      in
      if filtered == { } then null else filtered
    else if builtins.isList val then
      map removeNulls val
    else
      val;
in
{
  options = {
    perSystem = mkPerSystemOption (
      { config, pkgs, ... }:
      let
        cfg = config.claude;
        cleaned = removeNulls cfg.settings;
        cleanSettings = if cleaned == null then { } else cleaned;
        settingsJson = builtins.toJSON cleanSettings;
      in
      {
        options.claude = {
          settings = mkOption {
            type = types.submodule {
              freeformType = types.attrsOf types.anything;
              options = generatedOptions;
            };
            default = { };
            description = "Claude Code settings. Values are rendered to .claude/settings.json";
          };

          settingsFile = mkOption {
            type = types.package;
            readOnly = true;
            description = "Derivation producing the claude settings.json file.";
          };

          shellHook = mkOption {
            type = types.str;
            readOnly = true;
            description = "Shell hook that writes .claude/settings.json into the project root.";
          };
        };

        config.claude = {
          settingsFile = pkgs.writeTextFile {
            name = "claude-settings.json";
            text = settingsJson;
          };

          shellHook = ''
            mkdir -p .claude
            if ! diff -q <(cat .claude/settings.json 2>/dev/null) ${cfg.settingsFile} &>/dev/null; then
              cp ${cfg.settingsFile} .claude/settings.json
              echo "claudix: updated .claude/settings.json"
            fi
          '';
        };
      }
    );
  };
}
