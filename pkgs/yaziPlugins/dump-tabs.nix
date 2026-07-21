{
  pkgs,
  lib,
  sources,
  ...
}:
let
  p = sources.dump-tabs;
in
pkgs.stdenvNoCC.mkDerivation {
  inherit (p) pname version src;
  installPhase = ''
    runHook preInstall
    cp -r . $out
    runHook postInstall
  '';
  meta = {
    license = lib.licenses.mit;
    platform = lib.platforms.all;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
}
