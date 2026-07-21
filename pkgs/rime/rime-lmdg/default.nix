{
  lib,
  stdenvNoCC,
  sources,
}:
let
  hans = sources.rime-lmdg-zh-hans;
  hant = sources.rime-lmdg-zh-hant;
  makeLMDG =
    p:
    stdenvNoCC.mkDerivation {
      inherit (p) pname version src;
      dontUnpack = true;
      installPhase = ''
        runHook preInstall

        install -Dm444 "$src" "$raw/wanxiang.gram"

        install -Dm444 "$src" \
          "$out/share/rime-data/wanxiang.gram"

        runHook postInstall
      '';

      outputs = [
        "out"
        "raw"
      ];

      meta = {
        description = ''
          简繁扩展词库/声调编码/最全声调标注工具链/万象更新工具链/Rime语法模型：LMDG - Language, Model, Dictionary, Grammar。没错这里是万象拼音的“罗马帝国”!
        '';
        homepage = "https://github.com/amzxyz/RIME-LMDG";
        license = lib.licenses.cc-by-40;
        platforms = lib.platforms.all;
        sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
      };
    };
in
{
  rime-lmdg-zh-hans = makeLMDG hans;
  rime-lmdg-zh-hant = makeLMDG hant;
}
