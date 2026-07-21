{
  alsa-lib,
  dbus,
  lib,
  openssl,
  pkg-config,
  rustPlatform,
  sources,
  stdenv,
  ...
}:
let
  p = sources.ratune;
in
rustPlatform.buildRustPackage {
  inherit (p) pname src;
  version = lib.removePrefix "v" p.version;

  cargoLock.lockFile = "${p.src}/Cargo.lock";

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ pkg-config ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    alsa-lib
    dbus
    openssl
  ];

  meta = {
    description = "Terminal music player for Subsonic-compatible servers";
    homepage = "https://github.com/acmagn/ratune";
    license = lib.licenses.mit;
    mainProgram = "ratune";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
}
