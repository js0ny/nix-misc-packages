{
  stdenvNoCC,
  lib,
  fetchurl,
  unzip,
  sources,
  pkgs,
  ...
}:
let
  versions = with builtins; fromJSON (readFile ./sts2-pp-mod-release.json);
  makePPMods =
    {
      pKey,
      p,
      meta,
    }:
    stdenvNoCC.mkDerivation {
      pname = pKey;
      version = p.latest;
      src = fetchurl {
        url = p.download_intl;
        sha256 = p.sha256;
      };

      nativeBuildInputs = [ unzip ];

      buildPhase = ''
        runHook preBuild
        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall

        mkdir -p $out
        cp -R . $out/

        runHook postInstall
      '';
      meta = {
        platform = lib.platforms.linux ++ lib.platforms.darwin;
        license = lib.licenses.unfree;
        sourceProvenance = [ lib.sourceTypes.binaryBytecode ];
      }
      // meta;
    };
in
{
  damagemeter = makePPMods {
    pKey = "DamageMeter";
    p = versions.mods.DamageMeter;
    meta = {
      homepage = "https://www.nexusmods.com/slaythespire2/mods/33";
      license = lib.licenses.unfree;
    };
  };
  modconfig = makePPMods {
    pKey = "ModConfig";
    p = versions.mods.ModConfig;
    meta = {
      homepage = "https://github.com/xhyrzldf/ModConfig-STS2";
      license = lib.licenses.mit;
    };
  };
  speedx = makePPMods {
    pKey = "SpeedX";
    p = versions.mods.SpeedX;
    meta = {
      homepage = "https://www.nexusmods.com/slaythespire2/mods/91";
      license = lib.licenses.unfree;
    };
  };
  rewind = makePPMods {
    pKey = "Rewind";
    p = versions.mods.Rewind;
    meta = {
      homepage = "https://www.nexusmods.com/slaythespire2/mods/211";
      license = lib.licenses.unfree;
    };
  };
  quicklink = makePPMods {
    pKey = "QuickLink";
    p = versions.mods.QuickLink;
    meta = {
      homepage = "https://www.nexusmods.com/slaythespire2/mods/280";
      license = lib.licenses.unfree;
    };
  };
  quick-restart = import ./quick-restart.nix { inherit lib stdenvNoCC sources; };
  lan-multiplayer = import ./lan-multiplayer.nix {
    inherit
      lib
      stdenvNoCC
      sources
      pkgs
      ;
  };
}
