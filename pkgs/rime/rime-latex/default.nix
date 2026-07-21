{
  lib,
  stdenvNoCC,
  sources,
}:
let
  p = sources.rime-latex;
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
    rm -rf .scripts
    rm -f LICENSE
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $raw $out/share/rime-data
    cp -r . $raw
    cp -r . $out/share/rime-data

    runHook postInstall
  '';

  meta = with lib; {
    description = "Rime input method schema for LaTeX";
    homepage = "https://github.com/shenlebantongying/rime_latex";
    license = licenses.gpl3Only;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
}
