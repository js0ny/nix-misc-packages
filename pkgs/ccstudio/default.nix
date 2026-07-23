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
  # 从完整版本号派生 TI 下载地址所需的发行版本，以及桌面名称所需的主版本号。
  pname = "ccstudio";
  version = "21.0.0.00014";
  versionParts = lib.splitString "." version;
  releaseVersion = lib.concatStringsSep "." (lib.take 3 versionParts);
  majorVersion = lib.head versionParts;

  # CCStudio 是预编译的通用 Linux 程序，运行时假定存在传统 FHS 目录和这些动态库。
  # buildFHSEnv 会将依赖集中映射到 /usr，而不会修改上游二进制文件。
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

  # TI 安装器会尝试调用 service，但构建沙箱中既没有也不应启动系统服务。
  serviceShim = writeShellScriptBin "service" ''
    exit 0
  '';

  # 不使用安装器生成的桌面文件，避免其中包含安装时的绝对路径。
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

  # 安装器要求以 root 身份写入 /etc/udev，同时还依赖 binutils。
  # 这里使用隔离的 FHS 环境模拟该条件，所有写入都限制在构建沙箱中。
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

  # 运行 TI 官方安装器，产出未经二次打包的完整 CCStudio 安装目录。
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

      # ZIP 内安装器的文件名包含版本号，因此通过固定前缀查找实际文件名。
      for installer in ccs_setup_*.run; do
        break
      done
      if [ ! -f "$installer" ]; then
        echo "CCStudio installer not found" >&2
        exit 1
      fi

      # 安装器会修改自身目录和 HOME，复制到临时目录以保持源码只读。
      installerDir="$TMPDIR/ccstudio-installer"
      installerHome="$TMPDIR/ccstudio-home"
      rm -rf "$installerDir" "$installerHome"
      mkdir -p "$installerDir" "$installerHome"
      cp -r . "$installerDir"
      chmod +x "$installerDir/$installer"

      # 仅安装 C2000 组件；失败时输出安装日志，便于定位静默安装错误。
      if ! ${installerEnv}/bin/ccstudio-installer-env -c \
        "HOME=$installerHome $installerDir/$installer --mode unattended --prefix $out --enable-components PF_C28"; then
        find "$out" -type f -path '*/install_logs/*' -print -exec cat {} \; || true
        exit 1
      fi

      # 删除卸载器、安装日志和安装器生成的桌面文件，避免无用文件及构建路径泄漏。
      rm -rf \
        "$out/CCS ${releaseVersion}.desktop" \
        "$out/ccs/install_info" \
        "$out/ccs/install_logs" \
        "$out/ccs/uninstall_ccs.dat" \
        "$out/ccs/uninstall_ccs.run" \
        "$out/ccs/uninstallers" \
        "$out/ccs/ccs_base/emulation/Blackhawk/Install/bh_emulation_install.log"

      # 上游缓存包含构建期间的日志路径和耗时。将其归一化以保证构建结果可复现。
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

    # CCStudio 自带配套的二进制和运行时目录，不执行可能破坏该布局的通用 fixup。
    dontFixup = true;
  };

  # 启动器负责首次运行首选项、Chromium 沙箱以及桌面协议选择。
  launcher = writeShellScript "ccstudio-launcher" ''
    settingsFile="''${XDG_CONFIG_HOME:-$HOME/.config}/Texas Instruments/CCS/${baseNameOf ccstudio-unwrapped}/0/theia/settings.json"
    electronArgs=()
    preferenceArgs=()

    # Electron 37 默认使用 XWayland；它与 Fcitx XIM 组合时会吞掉键盘事件。
    # Wayland 会话中强制使用原生后端，并启用 Chromium 的 Wayland 输入法支持。
    if [[ -n "''${WAYLAND_DISPLAY:-}" ]]; then
      electronArgs+=(--ozone-platform=wayland --enable-wayland-ime)
    fi

    # 只在用户尚未保存该配置时注入参数，避免每次启动覆盖用户设置。
    if [[ ! -f "$settingsFile" ]] || \
      ! ${lib.getExe gnugrep} -q '"CCS.update.autoCheckUpdate"[[:space:]]*:' "$settingsFile"; then
      preferenceArgs+=(--set-preference=CCS.update.autoCheckUpdate=false)
    fi

    # 优先使用 NixOS 提供的 SUID Chromium 沙箱；不存在时交由 Electron 自行处理。
    if [[ -x /run/wrappers/bin/chromium-sandbox ]]; then
      export CHROME_DEVEL_SANDBOX=/run/wrappers/bin/chromium-sandbox
    fi
    exec ${ccstudio-unwrapped}/ccs/theia/ccstudio \
      "''${electronArgs[@]}" "''${preferenceArgs[@]}" "$@"
  '';
in
# 最终用户包提供 FHS 运行环境、启动命令、桌面入口及调试器所需的 udev 规则。
buildFHSEnv {
  inherit pname version;

  targetPkgs = runtimePkgs;

  runScript = launcher;

  extraInstallCommands = /* bash */ ''
    # 安装由 Nix 生成的桌面入口，并复用官方应用图标。
    install -Dm644 ${desktopItem}/share/applications/ccstudio.desktop \
      $out/share/applications/ccstudio.desktop
    install -Dm644 ${ccstudio-unwrapped}/ccs/doc/ccs.png \
      $out/share/icons/hicolor/256x256/apps/ccstudio.png

    # 收集 TI、Blackhawk 和 J-Link 调试器规则，使模块可通过 services.udev.packages 启用。
    install -Dm644 ${ccstudio-unwrapped}/ccs/install_scripts/71-ti-permissions.rules \
      $out/lib/udev/rules.d/71-ti-permissions.rules
    install -Dm644 ${ccstudio-unwrapped}/ccs/ccs_base/emulation/Blackhawk/Install/71-bh-permissions.rules \
      $out/lib/udev/rules.d/71-bh-permissions.rules
    install -Dm644 ${ccstudio-unwrapped}/ccs/ccs_base/cloudagent/install_scripts/70-mm-no-ti-emulators.rules \
      $out/lib/udev/rules.d/70-mm-no-ti-emulators.rules
    install -Dm644 ${ccstudio-unwrapped}/ccs/install_scripts/99-jlink.rules \
      $out/lib/udev/rules.d/71-jlink.rules

    # 上游规则将设备设为全局可读写；改用 logind 的 uaccess，仅授权当前本地会话用户。
    # ttyACM 规则额外限制为 TI 和 MSP430 常见的 USB 厂商 ID，避免放宽无关串口权限。
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

  # 包元数据用于搜索、许可证检查以及 lib.getExe 解析主程序。
  meta = {
    description = "Integrated development environment for TI embedded processors; add it to services.udev.packages to enable its udev rules";
    homepage = "https://www.ti.com/tool/CCSTUDIO";
    license = lib.licenses.unfree;
    mainProgram = "ccstudio";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
