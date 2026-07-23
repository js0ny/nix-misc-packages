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
