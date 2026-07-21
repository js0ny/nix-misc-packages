# /var/lib/jellyfin/plugins/SSO Authentication_${version}
{
  stdenvNoCC,
  sources,
  lib,
  buildDotnetModule,
  dotnetCorePackages,
}:
let
  bin = sources.jellyfin-plugin-sso;
  src = sources.jellyfin-plugin-sso-src;

in
{
  jellyfin-plugin-sso-bin = stdenvNoCC.mkDerivation {
    inherit (bin) version src;
    pname = "jellyfin-plugin-sso";

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      cp -R . $out/

      runHook postInstall
    '';

    meta = {
      homepage = "https://github.com/Buco7854/jellyfin-plugin-sso";
      license = lib.licenses.gpl3Only;
      platform = lib.platforms.linux;
      sourceProvenance = [ lib.sourceTypes.binaryBytecode ];
    };
  };
  jellyfin-plugin-sso-src = buildDotnetModule {
    inherit (src) src;
    pname = "jellyfin-plugin-sso";
    version = lib.removePrefix "v" src.version;

    projectFile = "SSO-Auth.sln";

    dotnet-sdk = dotnetCorePackages.sdk_9_0;

    nugetDeps = ./deps.json;

    meta = {
      homepage = "https://github.com/Buco7854/jellyfin-plugin-sso";
      license = lib.licenses.gpl3Only;
      platform = lib.platforms.linux;
      sourceProvenance = [ lib.sourceTypes.fromSource ];
    };
  };
}
