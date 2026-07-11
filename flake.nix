{
  description = "Miscellaneous packages for my Nix Setup";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpak = {
      url = "github:nixpak/nixpak";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
  };
  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      imports = [
        ./nixpaks
      ];
      perSystem =
        { pkgs, ... }:
        {
          packages =
            let
              packageTree = import ./pkgs {
                inherit pkgs;
                lib = pkgs.lib;
              };

              flattenPackages =
                prefix: attrs:
                pkgs.lib.concatMapAttrs (
                  name: value:
                  let
                    packageName = if prefix == "" then name else "${prefix}-${name}";
                  in
                  if pkgs.lib.isDerivation value then
                    { ${packageName} = value; }
                  else if pkgs.lib.isAttrs value then
                    flattenPackages packageName value
                  else
                    { }
                ) attrs;
            in
            flattenPackages "" packageTree
            // {
              bbdown = packageTree.apps.bbdown;
              limes = packageTree.apps.limes;
              oroot = packageTree.apps.oroot;
              ratune = packageTree.apps.ratune;
              danmaku2ass = packageTree.apps.danmaku2ass;
              clrmamepro = packageTree.apps.wine.clrmamepro;
              ecdict = packageTree.data.stardict.ecdict;
              clair-obscur-fix = packageTree.mods.clair-obscur-fix;
              jellyfin-plugin-sso = packageTree.services.jellyfin.plugins.sso;
              jellyfin-plugin-sso-src = packageTree.services.jellyfin.plugins.sso-src;
            };
        };
      flake = {
        overlays.default = final: prev: {
          misc = import ./pkgs {
            pkgs = final;
            inherit (final) lib;
          };
        };
      };
    };
}
