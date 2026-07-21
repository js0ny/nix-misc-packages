{
  stdenv,
  lib,
  sources,
}:
let
  p = sources.udpxy;
in
stdenv.mkDerivation {
  inherit (p) pname version src;

  sourceRoot = "${p.src.name}/chipmunk";

  enableParallelBuilding = true;

  buildFlags = [ "release" ];
  makeFlags = [ "CFLAGS=-Wno-error" ];

  installPhase = ''
    runHook preInstall

    install -Dm755 udpxy $out/bin/udpxy
    ln -s udpxy $out/bin/udpxrec
    install -Dm644 doc/en/udpxy.1 $out/share/man/man1/udpxy.1
    install -Dm644 doc/en/udpxrec.1 $out/share/man/man1/udpxrec.1

    runHook postInstall
  '';

  meta = {
    description = " lightweight network-traffic relay daemon";
    homepage = "https://github.com/pcherenkov/udpxy";
    license = lib.licenses.gpl3Plus;
    mainProgram = "udpxy";
    platforms = lib.platforms.linux;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
}
