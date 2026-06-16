{
  lib,
  stdenvNoCC,
  sources,
  ...
}:
let
  p = sources.sts2-Quick-Restart;
in
stdenvNoCC.mkDerivation {
  inherit (p) pname src;
  version = lib.removePrefix "v" p.version;

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -R . $out/

    runHook postInstall
  '';

  meta = {
    homepage = "https://github.com/erasels/StS2-Quick-Restart";
    license = lib.licenses.gpl3Only;
    sourceProvenance = [ lib.sourceTypes.binaryBytecode ];
  };
}
