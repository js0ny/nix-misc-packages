{
  lib,
  libxkbcommon,
  wayland,
  pkg-config,
  rustPlatform,
  sources,
  stdenv,
}:
let
  p = sources.wdotool;
in
rustPlatform.buildRustPackage {
  inherit (p) pname src version;

  cargoLock.lockFile = "${p.src}/Cargo.lock";

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ pkg-config ];

  buildInputs = [
    libxkbcommon
    wayland
  ];

  doCheck = true;

  meta = {
    description = "wdotool — xdotool-compatible input automation for Wayland";
    homepage = "https://github.com/cushycush/wdotool";
    license = with lib.licenses; [
      mit
      asl20
    ];
    mainProgram = "wdotool";
    platforms = lib.platforms.linux;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
}
