{
  pkgs,
  lib,
  ...
}:
let
  sources = pkgs.callPackage ../_sources/generated.nix { };

  scanPackages =
    path:
    let
      content = builtins.readDir path;
      dirs = lib.filterAttrs (name: type: type == "directory") content;
    in
    lib.mapAttrs (
      name: _:
      let
        subdir = path + "/${name}";
      in
      if builtins.pathExists (subdir + "/default.nix") then
        pkgs.callPackage subdir { inherit sources; }
      else
        scanPackages subdir
    ) dirs;

  collectPackages =
    attrs:
    lib.concatMap (
      name:
      let
        value = attrs.${name};
      in
      if lib.isDerivation value || (lib.isAttrs value && (value.recurseForDerivations or false)) then
        [
          {
            inherit name value;
          }
        ]
      else if lib.isAttrs value then
        collectPackages value
      else
        [ ]
    ) (builtins.attrNames attrs);

  packageEntries = collectPackages (scanPackages ./.);
  packageNames = map (package: package.name) packageEntries;
  duplicateNames = lib.unique (
    lib.filter (name: builtins.length (lib.filter (other: other == name) packageNames) > 1) packageNames
  );
  packageSet = builtins.listToAttrs packageEntries;
in
assert lib.assertMsg (
  duplicateNames == [ ]
) "duplicate package names: ${lib.concatStringsSep ", " duplicateNames}";
{
  flatPackages = lib.filterAttrs (_: lib.isDerivation) packageSet;
  inherit packageSet;
}
