{
  unzip,
  lib,
  sources,
  stdenvNoCC,
}:
let
  flypy = sources.rime-wanxiang-flypy;
  zrm = sources.rime-wanxiang-zrm;
  makeWanxiang =
    {
      lib,
      pname,
      src,
      version,
      keepDefault ? false,
    }:
    stdenvNoCC.mkDerivation {
      inherit
        pname
        version
        src
        ;

      outputs = [
        "out"
        "raw"
      ];

      postPatch = lib.optionalString (!keepDefault) /* bash */ ''
        rm -f README.md
        mv default.yaml .wanxiang-default.yaml
        mv weasel.yaml .wanxiang-weasel.yaml
      '';

      nativeBuildInputs = [ unzip ];

      sourceRoot = "source";

      unpackPhase = ''
        unzip $src -d source
      '';

      installPhase = ''
        mkdir -p $raw $out/share/rime-data
        cp -r * $raw/
        cp -r * $out/share/rime-data/
      '';

      meta = {
        description = "Rime Wanxiang input schema | 万象输入方案";
        homepage = "https://amzxyz.github.io/";
        license = lib.licenses.cc-by-40;
        platforms = lib.platforms.all;
        sourceProvenance = [ lib.sourceTypes.fromSource ];
      };
    };
in
{
  rime-wanxiang-flypy = makeWanxiang {
    inherit lib;
    inherit (flypy) pname version src;
  };

  rime-wanxiang-zrm = makeWanxiang {
    inherit lib;
    inherit (zrm) pname version src;
  };
}
