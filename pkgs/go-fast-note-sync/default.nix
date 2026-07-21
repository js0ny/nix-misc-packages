{
  buildGoModule,
  lib,
  sources,
  ...
}:
let
  p = sources.go-fast-note-sync;
in
buildGoModule (finalAttrs: {
  inherit (p) pname version src;
  vendorHash = "sha256-RprORNk78eVi5I2tpZ7P4uy9QDWbnpkbY8R6NopLXcM=";
  postInstall = ''
    mv $out/bin/cmd $out/bin/go-fast-note-sync
  '';

  meta = {
    description = "A Linux/headless Go CLI daemon that syncs a local Obsidian vault with a self-hosted fast-note-sync-service instance over WebSocket — no desktop, no GUI required.";
    homepage = "https://github.com/erichll/go-fast-note-sync";
    license = lib.licenses.asl20;
    platforms = lib.platforms.unix;
    mainProgram = "go-fast-note-sync";
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
})
