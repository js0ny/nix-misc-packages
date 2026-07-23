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

  # CCStudio is a prebuilt generic Linux application that expects these libraries in an FHS layout.
  # buildFHSEnv maps the dependencies into /usr without modifying the upstream binaries.
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

  # The TI installer invokes service, but system services should not run in the build sandbox.
  serviceShim = writeShellScriptBin "service" ''
    exit 0
  '';

  # Avoid the installer-generated desktop file because it contains build-time absolute paths.
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

  # The installer requires root access to /etc/udev and depends on binutils.
  # Use an isolated FHS environment so all writes remain inside the build sandbox.
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

  # Run the official TI installer to produce the complete CCStudio installation.
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

      # The installer filename includes its version, so locate it by its stable prefix.
      for installer in ccs_setup_*.run; do
        break
      done
      if [ ! -f "$installer" ]; then
        echo "CCStudio installer not found" >&2
        exit 1
      fi

      # The installer modifies its directory and HOME, so copy it to keep the source read-only.
      installerDir="$TMPDIR/ccstudio-installer"
      installerHome="$TMPDIR/ccstudio-home"
      rm -rf "$installerDir" "$installerHome"
      mkdir -p "$installerDir" "$installerHome"
      cp -r . "$installerDir"
      chmod +x "$installerDir/$installer"

      # Install only the C2000 component and print logs if unattended installation fails.
      if ! ${installerEnv}/bin/ccstudio-installer-env -c \
        "HOME=$installerHome $installerDir/$installer --mode unattended --prefix $out --enable-components PF_C28"; then
        find "$out" -type f -path '*/install_logs/*' -print -exec cat {} \; || true
        exit 1
      fi

      # Remove uninstallers, logs, and generated desktop files that may expose build paths.
      rm -rf \
        "$out/CCS ${releaseVersion}.desktop" \
        "$out/ccs/install_info" \
        "$out/ccs/install_logs" \
        "$out/ccs/uninstall_ccs.dat" \
        "$out/ccs/uninstall_ccs.run" \
        "$out/ccs/uninstallers" \
        "$out/ccs/ccs_base/emulation/Blackhawk/Install/bh_emulation_install.log"

      # Normalize build-time log paths and timings in upstream caches for reproducibility.
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

    # CCStudio bundles binaries and runtime directories whose layout generic fixups may break.
    dontFixup = true;
  };

  # Configure first-run preferences, the Chromium sandbox, and the display protocol.
  launcher = writeShellScript "ccstudio-launcher" ''
    settingsFile="''${XDG_CONFIG_HOME:-$HOME/.config}/Texas Instruments/CCS/${baseNameOf ccstudio-unwrapped}/0/theia/settings.json"
    electronArgs=()
    preferenceArgs=()

    # Electron 37 defaults to XWayland, which can swallow keyboard events when used with Fcitx XIM.
    # Use the native backend and Chromium's Wayland IME support in Wayland sessions.
    if [[ -n "''${WAYLAND_DISPLAY:-}" ]]; then
      electronArgs+=(--ozone-platform=wayland --enable-wayland-ime)
    fi

    # Set the preference only when the user has not already saved it.
    if [[ ! -f "$settingsFile" ]] || \
      ! ${lib.getExe gnugrep} -q '"CCS.update.autoCheckUpdate"[[:space:]]*:' "$settingsFile"; then
      preferenceArgs+=(--set-preference=CCS.update.autoCheckUpdate=false)
    fi

    # Prefer the NixOS SUID Chromium sandbox and otherwise let Electron handle sandboxing.
    if [[ -x /run/wrappers/bin/chromium-sandbox ]]; then
      export CHROME_DEVEL_SANDBOX=/run/wrappers/bin/chromium-sandbox
    fi
    exec ${ccstudio-unwrapped}/ccs/theia/ccstudio \
      "''${electronArgs[@]}" "''${preferenceArgs[@]}" "$@"
  '';
in
# Provide the FHS runtime, launcher, desktop entry, and debugger udev rules.
buildFHSEnv {
  inherit pname version;

  targetPkgs = runtimePkgs;

  runScript = launcher;

  extraInstallCommands = /* bash */ ''
    # Install the generated desktop entry with the official application icon.
    install -Dm644 ${desktopItem}/share/applications/ccstudio.desktop \
      $out/share/applications/ccstudio.desktop
    install -Dm644 ${ccstudio-unwrapped}/ccs/doc/ccs.png \
      $out/share/icons/hicolor/256x256/apps/ccstudio.png

    # Collect TI, Blackhawk, and J-Link debugger rules for use with services.udev.packages.
    install -Dm644 ${ccstudio-unwrapped}/ccs/install_scripts/71-ti-permissions.rules \
      $out/lib/udev/rules.d/71-ti-permissions.rules
    install -Dm644 ${ccstudio-unwrapped}/ccs/ccs_base/emulation/Blackhawk/Install/71-bh-permissions.rules \
      $out/lib/udev/rules.d/71-bh-permissions.rules
    install -Dm644 ${ccstudio-unwrapped}/ccs/ccs_base/cloudagent/install_scripts/70-mm-no-ti-emulators.rules \
      $out/lib/udev/rules.d/70-mm-no-ti-emulators.rules
    install -Dm644 ${ccstudio-unwrapped}/ccs/install_scripts/99-jlink.rules \
      $out/lib/udev/rules.d/71-jlink.rules

    # Replace world-writable permissions with logind uaccess for the active local session.
    # Restrict ttyACM rules to the USB vendor IDs commonly used by TI and MSP430 devices.
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
