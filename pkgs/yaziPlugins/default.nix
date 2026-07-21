{
  lib,
  pkgs,
  sources,
}:
lib.recurseIntoAttrs {
  dump-tabs = pkgs.callPackage ./dump-tabs.nix {
    inherit sources;
  };
}
