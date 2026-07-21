{
  pkgs,
  winepkg ? pkgs.wine64,
  lib,
  stdenvNoCC,
  ...
}:
let
  version = "0.7.1";
  dlVersion = builtins.replaceStrings [ "." ] [ "" ] version;
  description = "clrmamepro is a software that allows you to check and rebuild your arcade romsets according to an information file in xml or dat format.";
in
stdenvNoCC.mkDerivation {
  pname = "clrmamepro";
  inherit version;

  src = pkgs.fetchzip {
    url = "https://mamedev.emulab.it/clrmamepro/binaries/clrmame_v${dlVersion}.zip";
    hash = "sha256-/smkK8n+gY/df4Ry3OmyYw9OupcbtczN69QiUwvB43g=";
    stripRoot = false;
  };
  nativeBuildInputs = [
    pkgs.makeWrapper
    pkgs.copyDesktopItems
    pkgs.icoutils
  ];

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild

    wrestool --extract --type=14 clrmameUI.exe > app.ico
    icotool --extract --width=48 --height=48 --bit-depth=32 --output=clrmamepro.png app.ico

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -m755 -d $out/libexec/clrmamepro
    install -m755 clrmame.exe clrmameUI.exe wrapper.sh $out/libexec/clrmamepro
    install -m644 7z.dll readme.md $out/libexec/clrmamepro
    install -Dm644 clrmamepro.png $out/share/icons/hicolor/48x48/apps/clrmamepro.png

    mkdir -p $out/bin

    makeWrapper ${lib.getExe winepkg} $out/bin/clrmameUI \
      --add-flags "$out/libexec/clrmamepro/clrmameUI.exe"

    makeWrapper ${lib.getExe winepkg} $out/bin/clrmame \
      --add-flags "$out/libexec/clrmamepro/clrmame.exe"

    runHook postInstall
  '';

  desktopItems = [
    (pkgs.makeDesktopItem {
      name = "clrmamepro";
      exec = "clrmameUI %u";
      icon = "clrmamepro";
      desktopName = "clrmamepro";
      genericName = "ROM Manager";
      comment = description;
      categories = [
        "Utility"
        "Game"
      ];
      startupWMClass = "clrmamepro";
    })
  ];

  meta = {
    inherit description;
    license = lib.licenses.unfree;
    mainProgram = "clrmameUI";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
