{
  sources,
  stdenvNoCC,
  lib,
  ...
}:
let
  p = sources.firefox-csshacks;
in
stdenvNoCC.mkDerivation {
  inherit (p) version src;
  pname = "firefox-csshacks";

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -R . $out/

    runHook postInstall
  '';

  meta = {
    description = "Collection of userstyles affecting the browser";
    homepage = "https://github.com/MrOtherGuy/firefox-csshacks";
    license = lib.licenses.mpl20;
    sourceProvenance = [ lib.sourceProvenance.fromSource ];
  };
}
