{
  stdenv,
  lib,
  cmake,
  sources,
}:
let
  p = sources.msd_lite;
in
stdenv.mkDerivation {
  inherit (p) pname src;
  version = "1.11.0-unstable-${p.date}";

  nativeBuildInputs = [ cmake ];

  cmakeBuildType = "Release";

  postInstall = ''
    install -Dm644 $src/conf/msd_lite.conf $out/etc/msd_lite/msd_lite.conf.sample
  '';

  meta = with lib; {
    description = "Multi stream daemon lite for IPTV streaming over HTTP";
    homepage = "https://github.com/rozhuk-im/msd_lite";
    license = licenses.bsd2;
    mainProgram = "msd_lite";
    platforms = platforms.linux;
  };
}
