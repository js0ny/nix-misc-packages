{
  lib,
  pkgs,
  sources,
}:
lib.recurseIntoAttrs {
  bilibili-sponsorblock = pkgs.callPackage ./bilibili-sponsorblock.nix {
    inherit sources;
  };
}
