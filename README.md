# Nix Misc Packages 

Miscellaneous packages for my Nix Setup

## Usage

### Proton 

```nix
# Bottles
xdg.dataFile."bottles/runners/dwproton-${dwproton.version}".source = dwproton;
```

### TI CC Studio

```nix
# nixos
let 
  ccstudio = pkgs.js0ny.ccstudio;
in 
{
  environment.systemPackages = [ ccstudio ];
  services.udev.packages = [ ccstudio ];
}
```

---

The bundled TI rules cover selected FTDI-based debug probes, but not the common FT232R ID `0403:6001`. Add the following rule when using such a device and CCS fails to enumerate it with error `-151`:

```nix
# Allow the active local session to use D2XX with FTDI raw USB devices.
services.udev.extraRules = ''
  SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="0403", TAG+="uaccess"
'';
```
This error can occur even when `/dev/ttyUSB*` works because D2XX opens the raw USB node under `/dev/bus/usb`. Reconnect the device and restart CCS after applying the rule.
