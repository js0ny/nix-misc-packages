{
  stdenvNoCC,
  fetchzip,
  upx,
  autoPatchelfHook,
  lib,
  ...
}:
stdenvNoCC.mkDerivation rec {
  pname = "snell-server";
  version = "5.0.1";

  src = fetchzip {
    url = "https://dl.nssurge.com/snell/snell-server-v${version}-linux-amd64.zip";
    hash = "sha256-J2kRVJRC0GhxLMarg7Ucdk8uvzTsKbFHePEflPjwsHU=";
  };

  dontUnpack = false;

  nativeBuildInputs = [
    upx
    autoPatchelfHook
  ];

  installPhase = ''
    mkdir -p $out/bin

    upx -d snell-server
    cp snell-server $out/bin/${pname}
    chmod +x $out/bin/${pname}
  '';
  meta = {
    description = "An encrypted proxy service program";
    homepage = "https://kb.nssurge.com/surge-knowledge-base/release-notes/snell";
    license = lib.licenses.unfree;
    mainProgram = "snell-server";
    platforms = lib.platforms.linux;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
