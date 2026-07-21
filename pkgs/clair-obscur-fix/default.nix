{
  sources,
  stdenvNoCC,
  lib,
  ...
}:
let
  p = sources.clair-obscur-fix;
in
stdenvNoCC.mkDerivation {
  inherit (p) version src;
  pname = "clair-obscur-fix";

  installPhase = ''
    runHook preInstall

    mv ClairObscurFix.ini ClairObscurFix.ini.example

    mkdir -p $out
    cp -R . $out/

    runHook postInstall
  '';

  meta = {
    homepage = "https://codeberg.org/Lyall/ClairObscurFix";
    description = "An ASI plugin for Clair Obscur: Expedition 33 that removes the 30fps cap in cutscenes, disables sharpening and more.";
    license = lib.licenses.mit;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
