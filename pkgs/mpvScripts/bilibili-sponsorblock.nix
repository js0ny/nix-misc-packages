{
  sources,
  stdenv,
  rustPlatform,
  mpv,
  pkg-config,
  lib,
  ...
}:

let
  p = sources.mpv-bilibili-sponsorblock;
in

rustPlatform.buildRustPackage rec {
  inherit (p) src;
  pname = "bilibili-sponsorblock";
  version = lib.removePrefix "v" p.version;

  cargoHash = "sha256-SRFJum9+yDKxphOnzGCQ9vS5y7dZKY0CE7Scn8MmF8I=";

  nativeBuildInputs = [
    pkg-config
    rustPlatform.bindgenHook
  ];

  buildInputs = [ mpv ];

  doCheck = false;

  passthru.scriptName = "${pname}/bilibili_sponsorblock.so";

  installPhase = ''
    runHook preInstall

    install -Dm755 target/${stdenv.hostPlatform.rust.cargoShortTarget}/release/libmpv_bilibili_sponsorblock.so \
      $out/share/mpv/scripts/${pname}/bilibili_sponsorblock.so
    install -Dm644 bilibili-sponsorblock.toml \
      $out/share/mpv/scripts/${pname}/bilibili-sponsorblock.toml

    runHook postInstall
  '';

  meta = {
    description = "MPV plugin that allows skipping sponsor segments while watching Bilibili videos";
    homepage = "https://github.com/test482/mpv-bilibili-sponsorblock";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    sourceProvenance = [ lib.sourceProvenance.fromSource ];
  };
}
