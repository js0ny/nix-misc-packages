{
  lib,
  stdenvNoCC,
  buildFHSEnv,
  dpkg,
  makeDesktopItem,
  writeShellScript,
  fetchurl,
  ...
}:
let
  pname = "FTNN";
  version = "16.24.16908";

  futubull-unwrapped = stdenvNoCC.mkDerivation {
    pname = "${pname}-unwrapped";
    inherit version;

    src = fetchurl {
      url = "https://softwaredownload.futunn.com/FTNN_desktop_${version}_amd64.deb";
      hash = "sha256-PWSK0yL+AkVaKXCPdzs+zJCalf9Zi0oiTFDQokm9hkk=";
    };
    nativeBuildInputs = [ dpkg ];

    unpackPhase = ''
      runHook preUnpack
      dpkg-deb -x "$src" .
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/opt"
      cp -a opt/FTNN "$out/opt/FTNN"
      runHook postInstall
    '';

    dontFixup = true;
  };

  launcher = writeShellScript "futubull-desktop-launcher" ''
    appDir=${futubull-unwrapped}/opt/FTNN
    export FTNN_HOME="$appDir"
    export LD_LIBRARY_PATH="$appDir:$appDir/lib:$appDir/plugins/platforms''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    export QT_PLUGIN_PATH="$appDir/plugins:$appDir/plugins/platforms''${QT_PLUGIN_PATH:+:$QT_PLUGIN_PATH}"
    cd "$appDir"
    exec ./FTNN "$@"
  '';

  desktopItem = makeDesktopItem {
    name = pname;
    desktopName = "Futubull Desktop";
    comment = "Trade stocks and manage investments";
    exec = "${pname} %U";
    icon = pname;
    categories = [
      "Office"
      "Finance"
    ];
  };
in
buildFHSEnv {
  inherit pname version;

  targetPkgs =
    pkgs: with pkgs; [
      alsa-lib
      at-spi2-atk
      at-spi2-core
      bzip2
      cairo
      cups
      db5
      dbus
      expat
      fontconfig
      freetype
      glib
      gst_all_1.gst-plugins-base
      gst_all_1.gstreamer
      gtk3
      libdrm
      libgbm
      libGL
      libice
      libmng
      libnotify
      libsm
      libx11
      libxcb
      libxcomposite
      libxcursor
      libxcrypt-legacy
      libxdamage
      libxext
      libxfixes
      libxi
      libxkbcommon
      libxrandr
      libxrender
      libxscrnsaver
      libxtst
      ncurses5
      nspr
      nss
      pango
      pulseaudio
      readline70
      sqlite
      systemd
      tcl
      tk
      xcbutilimage
      xcbutilkeysyms
      xcbutilrenderutil
      xcbutilwm
      xz
      zlib
      zstd
    ];

  runScript = launcher;

  extraInstallCommands = /* bash */ ''
    install -Dm644 ${desktopItem}/share/applications/${pname}.desktop \
      $out/share/applications/${pname}.desktop
    install -Dm644 ${futubull-unwrapped}/opt/FTNN/app.png \
      $out/share/icons/hicolor/256x256/apps/${pname}.png
  '';

  passthru.unwrapped = futubull-unwrapped;

  meta = {
    description = "Desktop trading platform from Futu";
    homepage = "https://www.futunn.com/";
    license = lib.licenses.unfree;
    mainProgram = pname;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
