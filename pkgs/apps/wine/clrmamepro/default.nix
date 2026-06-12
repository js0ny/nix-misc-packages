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
  };
  nativeBuildInputs = [
    pkgs.makeWrapper
    pkgs.copyDesktopItems
  ];

  buildInputs = [ winepkg ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt/clrmamepro
    cp -r * $out/opt/clrmamepro/

    mkdir -p $out/bin

    makeWrapper ${lib.getExe winepkg} $out/bin/clrmameUI \
      --add-flags "$out/opt/clrmamepro/clrmameUI.exe"

    makeWrapper ${lib.getExe winepkg} $out/bin/clrmame \
      --add-flags "$out/opt/clrmamepro/clrmame.exe"

    runHook postInstall
  '';

  desktopItems = [
    (pkgs.makeDesktopItem {
      name = "clrmamepro";
      exec = "clrmameUI %u";
      icon = "clrmamepro";
      desktopName = "clrmamepro.desktop";
      genericName = "ROM Manager";
      comment = description;
      categories = [
        "Utilities"
        "Game"
      ];
      startupWMClass = "clrmamepro";
    })
  ];

  meta = {
    inherit description;
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
  };
}
