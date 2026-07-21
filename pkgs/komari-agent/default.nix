{
  buildGoModule,
  lib,
  sources,
}:
let
  p = sources.komari-agent;
in
buildGoModule (finalAttrs: {
  inherit (p) pname version src;

  vendorHash = "sha256-teKx9u7M2ZQdd7G3xSCqhwjcHRzBzKeBViSl62TRg+g=";

  # These integration tests require network access and raw socket permissions.
  # which is not available in Nix Build Sandbox
  checkFlags = [ "-skip=Test(ICMP|TCP|HTTP)Ping" ];

  meta = {
    description = "komari agent";
    homepage = "https://github.com/komari-monitor/komari-agent";
    license = lib.licenses.mit;
    mainProgram = "komari-agent";
    platforms = lib.platforms.freebsd ++ lib.platforms.linux ++ lib.platforms.darwin;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
})
