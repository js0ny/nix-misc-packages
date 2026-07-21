{
  stdenvNoCC,
  lib,
  sources,
}:
let
  p = sources.dwproton;
  makeDWProton =
    {
      pname,
      version,
      src,
    }:
    stdenvNoCC.mkDerivation {
      inherit pname version src;

      installPhase = ''
        runHook preInstall

        mkdir -p $out
        cp -r * $out/
        find $out -xtype l -delete

        runHook postInstall
      '';

      meta = with lib; {
        description = "Proton builds with the latest Dawn Winery fixes.";
        homepage = "https://dawn.wine/dawn-winery/dwproton";
        license = licenses.bsd3;
        platforms = [ "x86_64-linux" ];
        sourceProvenance = [ sourceTypes.binaryBytecode ];
      };
    };
in
rec {

  dwproton = makeDWProton {
    inherit (p) pname src;
    version = lib.removePrefix "dwproton-" p.version;
  };
  dwproton-11 = makeDWProton rec {
    pname = "dwproton";
    version = "11.0-4";
    src = fetchTarball {
      url = "https://dawn.wine/dawn-winery/dwproton/releases/download/dwproton-${version}/dwproton-${version}-x86_64.tar.xz";
      sha256 = "sha256-t5dLTIN+KSCQIG8spzN6soOhfCnnc+OgBoQWBdtJQFM=";
    };
  };
  dwproton-pin = dwproton-11;
}
