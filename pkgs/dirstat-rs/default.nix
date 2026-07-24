{
  rustPlatform,
  lib,
  sources,
}:
let
  p = sources.dirstat-rs;
in
rustPlatform.buildRustPackage {
  inherit (p) pname src;
  version = lib.removePrefix "v" p.version;

  cargoLock.lockFile = "${p.src}/Cargo.lock";

  meta = {
    description = "Command-line tool to manipulate impermanence old roots in btrfs";
    homepage = "https://github.com/js0ny/oroot";
    license = lib.licenses.mit;
    mainProgram = "ds";
    platforms = lib.platforms.linux;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
}
