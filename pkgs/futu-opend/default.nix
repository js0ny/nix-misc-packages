{
  lib,
  stdenv,
  fetchurl,
  appimageTools,
  makeWrapper,
  patchelf,
  alsa-lib,
  e2fsprogs,
  expat,
  fontconfig,
  freetype,
  gmp,
  libdrm,
  libgbm,
  libGL,
  libgpg-error,
  libice,
  libsm,
  libx11,
  libxcb,
  sqlite,
  util-linux,
  zlib,
  ...
}:
let
  pname = "futu-opend";
  version = "10.9.6918";

  runtimeLibraries = [
    alsa-lib
    e2fsprogs
    expat
    fontconfig
    freetype
    gmp
    libdrm
    libgbm
    libGL
    libgpg-error
    libice
    libsm
    libx11
    libxcb
    sqlite
    stdenv.cc.cc.lib
    util-linux
    zlib
  ];
  runtimeLibraryPath = lib.makeLibraryPath runtimeLibraries;
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://softwaredownload.futunn.com/Futu_OpenD_${version}_Ubuntu18.04.tar.gz";
    hash = "sha256-N9laKzArUBieXrRkhp07w2TS9di0ZhRPANalYNJmwLM=";
  };

  nativeBuildInputs = [
    appimageTools.appimage-exec
    makeWrapper
    patchelf
  ];

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    releaseDir=Futu_OpenD_${version}_Ubuntu18.04
    appImage=$releaseDir/Futu_OpenD-GUI_${version}_Ubuntu18.04/Futu_OpenD-GUI_${version}_Ubuntu18.04.AppImage
    guiDir=$out/libexec/futu-opend-gui
    cliDir=$out/libexec/futu-opend-cli

    mkdir -p "$out/libexec"
    appimage-exec.sh -x "$guiDir" "$appImage"
    mkdir -p "$cliDir" "$out/bin"
    cp -a "$releaseDir/Futu_OpenD_${version}_Ubuntu18.04/." "$cliDir/"

    for executable in $(find "$guiDir" "$cliDir" -type f -perm -0100); do
      if patchelf --print-interpreter "$executable" >/dev/null 2>&1; then
        patchelf --set-interpreter ${stdenv.cc.bintools.dynamicLinker} "$executable"
      fi
    done

    guiLibraryPath="$guiDir/usr/bin:$guiDir/usr/lib:$guiDir/usr/lib/x86_64-linux-gnu:$guiDir/usr/lib/x86_64-linux-gnu/nss:$guiDir/lib:$guiDir/lib/x86_64-linux-gnu:${runtimeLibraryPath}"

    makeWrapper "$guiDir/usr/bin/Futu_OpenD" "$out/bin/Futu_OpenD" \
      --prefix PATH : "$guiDir/usr/bin" \
      --prefix LD_LIBRARY_PATH : "$guiLibraryPath" \
      --set QT_PLUGIN_PATH "$guiDir/usr/plugins" \
      --set QT_QPA_PLATFORM_PLUGIN_PATH "$guiDir/usr/plugins/platforms" \
      --unset XDG_DATA_DIRS

    makeWrapper "$cliDir/FutuOpenD" "$out/bin/FutuOpenD" \
      --prefix PATH : "$cliDir" \
      --prefix LD_LIBRARY_PATH : "$cliDir:${runtimeLibraryPath}"

    install -Dm644 "$guiDir/Futu_OpenD.desktop" \
      "$out/share/applications/Futu_OpenD.desktop"
    install -Dm644 "$guiDir/Futu_OpenD.png" \
      "$out/share/icons/hicolor/256x256/apps/Futu_OpenD.png"

    runHook postInstall
  '';

  dontStrip = true;

  meta = {
    description = "Gateway for the Futu OpenAPI";
    homepage = "https://openapi.futunn.com/";
    license = lib.licenses.unfree;
    mainProgram = "Futu_OpenD";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
