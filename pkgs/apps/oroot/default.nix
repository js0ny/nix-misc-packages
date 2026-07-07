{
  rustPlatform,
  lib,
  sources,
  ...
}:
let
  p = sources.oroot;
in
rustPlatform.buildRustPackage {
  inherit (p) pname version src;

  cargoLock.lockFile = "${p.src}/Cargo.lock";

  meta = {
    description = "Command-line tool to manipulate impermanence old roots in btrfs";
    homepage = "https://github.com/js0ny/oroot";
    license = lib.licenses.mit;
    mainProgram = "oroot";
    platforms = lib.platforms.linux;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
}
