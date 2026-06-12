{
  stdenvNoCC,
  fd,
  sources,
}:
let
  p = sources.rime-cantonese;
in
stdenvNoCC.mkDerivation {
  inherit (p) pname version src;

  nativeBuildInputs = [ fd ];

  postPatch = ''
    find . -name '*.md' -delete
    rm -rf .ci .github demo
  '';

  installPhase = ''
    mkdir -p $out
    cp -r . $out
  '';
}
