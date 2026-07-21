{
  lib,
  stdenvNoCC,
  buildFHSEnv,
  fetchurl,
  gnugrep,
  makeDesktopItem,
  unzip,
  writeShellScript,
  writeShellScriptBin,
  ...
}:
let
  pname = "ccstudio";
  version = "21.0.0.00014";
  versionParts = lib.splitString "." version;
  releaseVersion = lib.concatStringsSep "." (lib.take 3 versionParts);
  majorVersion = lib.head versionParts;

  runtimePkgs =
    pkgs: with pkgs; [
      alsa-lib
      at-spi2-atk
      at-spi2-core
      cairo
      cups
      dbus
      expat
      fontconfig
      freetype
      glib
      gtk3
      libdrm
      libgbm
      libGL
      libnotify
      libsecret
      libusb-compat-0_1
      libusb1
      libx11
      libxcomposite
      libxcursor
      libxdamage
      libxext
      libxfixes
      libxi
      libxkbcommon
      libxkbfile
      libxrandr
      libxrender
      libxscrnsaver
      libxtst
      libxcb
      nspr
      nss
      pango
      stdenv.cc.cc.lib
      systemd
      udev
      zlib
    ];

  serviceShim = writeShellScriptBin "service" ''
    exit 0
  '';

  desktopItem = makeDesktopItem {
    name = "ccstudio";
    desktopName = "TI Code Composer Studio ${majorVersion}";
    comment = "Develop and debug applications for TI embedded processors";
    exec = "ccstudio %F";
    icon = "ccstudio";
    categories = [
      "Development"
      "IDE"
    ];
  };

  installerEnv = buildFHSEnv {
    name = "ccstudio-installer-env";
    targetPkgs = pkgs: [
      pkgs.binutils
      serviceShim
    ];
    unshareUser = true;
    extraBwrapArgs = [
      "--dir /etc/udev"
      "--dir /etc/udev/rules.d"
      "--uid 0"
      "--gid 0"
    ];
  };

  ccstudio-unwrapped = stdenvNoCC.mkDerivation {
    pname = "ccstudio-unwrapped";
    inherit version;

    src = fetchurl {
      url = "https://dr-download.ti.com/software-development/ide-configuration-compiler-or-debugger/MD-J1VdearkvK/${releaseVersion}/CCS_${version}_linux.zip";
      hash = "sha256-mqAfANWabU7pl9e4TmyYGrKU4soq5Ib048ygNmAREls=";
    };

    nativeBuildInputs = [ unzip ];

    installPhase = ''
      runHook preInstall

      for installer in ccs_setup_*.run; do
        break
      done
      if [ ! -f "$installer" ]; then
        echo "CCStudio installer not found" >&2
        exit 1
      fi

      installerDir="$TMPDIR/ccstudio-installer"
      installerHome="$TMPDIR/ccstudio-home"
      rm -rf "$installerDir" "$installerHome"
      mkdir -p "$installerDir" "$installerHome"
      cp -r . "$installerDir"
      chmod +x "$installerDir/$installer"

      if ! ${installerEnv}/bin/ccstudio-installer-env -c \
        "HOME=$installerHome $installerDir/$installer --mode unattended --prefix $out --enable-components PF_C28"; then
        find "$out" -type f -path '*/install_logs/*' -print -exec cat {} \; || true
        exit 1
      fi

      rm -rf \
        "$out/CCS ${releaseVersion}.desktop" \
        "$out/ccs/install_info" \
        "$out/ccs/install_logs" \
        "$out/ccs/uninstall_ccs.dat" \
        "$out/ccs/uninstall_ccs.run" \
        "$out/ccs/uninstallers" \
        "$out/ccs/ccs_base/emulation/Blackhawk/Install/bh_emulation_install.log"

      ibLogfile=$(grep -m1 '^ib_logfile=' "$out/ccs/eclipse/ccs.properties")
      substituteInPlace "$out/ccs/eclipse/ccs.properties" \
        --replace-fail "$ibLogfile" 'ib_logfile='

      discoveryTime=$(grep -m1 '^Total tool discovery time:' \
        "$out/ccs/eclipse/configuration/com.ti.ccs.project/compilerProperties.cache.log")
      substituteInPlace "$out/ccs/eclipse/configuration/com.ti.ccs.project/compilerProperties.cache.log" \
        --replace-fail "$discoveryTime" 'Total tool discovery time: 0 ms'

      productDiscoveryTime=$(grep -m1 '^Total tool discovery time:' \
        "$out/ccs/eclipse/configuration/com.ti.ccs.project/productDescriptor.cache.log")
      substituteInPlace "$out/ccs/eclipse/configuration/com.ti.ccs.project/productDescriptor.cache.log" \
        --replace-fail "$productDiscoveryTime" 'Total tool discovery time: 0 ms'

      runHook postInstall
    '';

    dontFixup = true;
  };

  launcher = writeShellScript "ccstudio-launcher" ''
    settingsFile="''${XDG_CONFIG_HOME:-$HOME/.config}/Texas Instruments/CCS/${baseNameOf ccstudio-unwrapped}/0/theia/settings.json"
    preferenceArgs=()

    if [[ ! -f "$settingsFile" ]] || \
      ! ${lib.getExe gnugrep} -q '"CCS.update.autoCheckUpdate"[[:space:]]*:' "$settingsFile"; then
      preferenceArgs+=(--set-preference=CCS.update.autoCheckUpdate=false)
    fi

    if [[ -x /run/wrappers/bin/chromium-sandbox ]]; then
      export CHROME_DEVEL_SANDBOX=/run/wrappers/bin/chromium-sandbox
    fi
    exec ${ccstudio-unwrapped}/ccs/theia/ccstudio "''${preferenceArgs[@]}" "$@"
  '';
in
buildFHSEnv {
  inherit pname version;

  targetPkgs = runtimePkgs;

  runScript = launcher;

  extraInstallCommands = /* bash */ ''
    install -Dm644 ${desktopItem}/share/applications/ccstudio.desktop \
      $out/share/applications/ccstudio.desktop
    install -Dm644 ${ccstudio-unwrapped}/ccs/doc/ccs.png \
      $out/share/icons/hicolor/256x256/apps/ccstudio.png

    install -Dm644 ${ccstudio-unwrapped}/ccs/install_scripts/71-ti-permissions.rules \
      $out/lib/udev/rules.d/71-ti-permissions.rules
    install -Dm644 ${ccstudio-unwrapped}/ccs/ccs_base/emulation/Blackhawk/Install/71-bh-permissions.rules \
      $out/lib/udev/rules.d/71-bh-permissions.rules
    install -Dm644 ${ccstudio-unwrapped}/ccs/ccs_base/cloudagent/install_scripts/70-mm-no-ti-emulators.rules \
      $out/lib/udev/rules.d/70-mm-no-ti-emulators.rules
    install -Dm644 ${ccstudio-unwrapped}/ccs/install_scripts/99-jlink.rules \
      $out/lib/udev/rules.d/71-jlink.rules

    substituteInPlace $out/lib/udev/rules.d/71-ti-permissions.rules \
      --replace-fail 'KERNEL=="ttyACM[0-9]*",MODE:="0666"' $'KERNEL=="ttyACM[0-9]*", ATTRS{idVendor}=="0451", TAG+="uaccess"\nKERNEL=="ttyACM[0-9]*", ATTRS{idVendor}=="2047", TAG+="uaccess"' \
      --replace-fail 'MODE:="0666"' 'TAG+="uaccess"' \
      --replace-fail 'MODE="0666"' 'TAG+="uaccess"'
    substituteInPlace $out/lib/udev/rules.d/71-bh-permissions.rules \
      --replace-fail 'MODE:="0666"' 'TAG+="uaccess"'
    substituteInPlace $out/lib/udev/rules.d/71-jlink.rules \
      --replace-fail 'MODE="666"' 'TAG+="uaccess"'
  '';

  passthru.unwrapped = ccstudio-unwrapped;

  meta = {
    description = "Integrated development environment for TI embedded processors; add it to services.udev.packages to enable its udev rules";
    homepage = "https://www.ti.com/tool/CCSTUDIO";
    license = lib.licenses.unfree;
    mainProgram = "ccstudio";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
