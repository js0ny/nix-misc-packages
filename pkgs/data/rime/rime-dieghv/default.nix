{
  sources,
  stdenvNoCC,
  lib,
}:
let
  p = sources.rime-dieghv;
in
stdenvNoCC.mkDerivation {
  inherit (p)
    pname
    version
    src
    date
    ;

  outputs = [
    "out"
    "raw"
  ];

  postPatch = ''
    find . -name '*.md' -delete
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $raw $out/share/rime-data
    cp -r . $raw
    cp -r . $out/share/rime-data

    runHook postInstall
  '';

  meta = {
    license = lib.licenses.gpl3Only;
    homepage = "https://github.com/kahaani/dieghv";
    description = "潮语拼音输入法 (Rime schema for Teochew dialect)";
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
}
