{
  stdenvNoCC,
  fd,
  sources,
  lib,
}:
let
  p = sources.rime-cantonese;
in
stdenvNoCC.mkDerivation {
  inherit (p) pname version src;

  outputs = [
    "out"
    "raw"
  ];

  postPatch = ''
    find . -name '*.md' -delete
    rm -rf .ci .github demo
  '';

  installPhase = ''
    mkdir -p $raw $out/share/rime-data
    cp -r . $raw
    cp -r . $out/share/rime-data
  '';

  meta = {
    description = "Rime Cantonese input schema | 中州韻粵語拼音輸入方案";
    homepage = "https://github.com/rime/rime-cantonese";
    license = with lib.licenses; [
      cc-by-40
      odbl
    ];
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
}
