{
  pkgs,
  lib,
  package ? pkgs.firefox,
  mkNixPak,
  buildEnv,
  makeDesktopItem,
  ...
}:

let
  appId = "org.mozilla.firefox";
  wrapped = mkNixPak {
    config =
      {
        config,
        sloth,
        ...
      }:
      {
        app = {
          package = package;
          binPath = "bin/firefox";
        };
        flatpak.appId = appId;

        imports = [
          ./modules/gui-base.nix
          ./modules/network.nix
          ./modules/common.nix
        ];

        bubblewrap = {
          bind.rw = [
            (sloth.mkdir (sloth.concat' sloth.homeDir "/.mozilla"))
            (sloth.mkdir (sloth.concat' sloth.xdgConfigHome "/mozilla"))
            sloth.xdgDownloadDir
          ];
          bind.ro = [
            "/etc/firefox"
            "/sys/bus/pci"
            [
              "${config.app.package}/lib/firefox"
              "/app/etc/firefox"
            ]

            # ================ for browserpass extension ===============================
            "/etc/gnupg"
            (sloth.concat' sloth.homeDir "/.gnupg") # gpg's config
            (sloth.concat' sloth.homeDir "/.local/share/password-store") # my secrets
            (sloth.concat' sloth.runtimeDir "/gnupg") # for access gpg-agent socket

            # Unsure
            (sloth.concat' sloth.xdgConfigHome "/dconf")
          ];

          sockets = {
            x11 = false;
            wayland = true;
            pipewire = true;
          };
        };
      };
  };
  exePath = lib.getExe wrapped.config.script;
in
buildEnv {
  inherit (wrapped.config.script) name meta passthru;
  paths = [
    wrapped.config.script
    (makeDesktopItem {
      name = appId;
      desktopName = "Firefox";
      genericName = "Firefox Boxed";
      comment = "Firefox Browser";
      exec = "${exePath} %U";
      terminal = false;
      icon = "firefox";
      startupNotify = true;
      startupWMClass = "firefox";
      type = "Application";
      categories = [
        "Network"
        "WebBrowser"
      ];
      mimeTypes = [
        "text/html"
        "text/xml"
        "application/xhtml+xml"
        "application/vnd.mozilla.xul+xml"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
      ];

      actions = {
        new-private-window = {
          name = "New Private Window";
          exec = "${exePath} --private-window %U";
        };
        new-window = {
          name = "New Window";
          exec = "${exePath} --new-window %U";
        };
        profile-manager-window = {
          name = "Profile Manager";
          exec = "${exePath} --ProfileManager";
        };
      };

      extraConfig = {
        X-Flatpak = appId;
      };
    })
  ];
}
