{
  lib,
  stdenvNoCC,
  sources,
  pkgs,
  ...
}:
let
  p = sources.SlayTheSpire2-LAN-Multiplayer;
in
stdenvNoCC.mkDerivation {
  inherit (p) pname src version;

  nativeBuildInputs = [ pkgs.p7zip ];

  buildPhase = ''
    runHook preBuild
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -R ./SlayTheSpire2.LAN.Multiplayer/* $out/

    runHook postInstall
  '';

  meta = {
    homepage = "https://github.com/erasels/StS2-Quick-Restart";
    license = lib.licenses.gpl3Only;
    sourceProvenance = [ lib.sourceTypes.binaryBytecode ];
  };
}
