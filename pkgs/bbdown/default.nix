# BBDown/Directory.Build.props: NativeAOT
{
  lib,
  sources,
  buildDotnetModule,
  clang,
  dotnetCorePackages,
  zlib,
}:
let
  p = sources.bbdown;
in
buildDotnetModule {
  inherit (p) pname version src;
  nugetDeps = ./deps.json;

  # Use objcopy provided by llvm
  postPatch = ''
    substituteInPlace BBDown/Directory.Build.props \
      --replace-fail aarch64-linux-gnu-objcopy objcopy
  '';

  nativeBuildInputs = [ clang ];
  buildInputs = [ zlib ];

  projectFile = "BBDown/BBDown.csproj";

  dotnet-sdk = dotnetCorePackages.sdk_9_0;
  dotnet-runtime = dotnetCorePackages.runtime_9_0;
  selfContainedBuild = true;

  executables = [ "BBDown" ];

  meta = {
    description = "Bilibili Downloader. 一个命令行式哔哩哔哩下载器.";
    homepage = "https://github.com/nilaoda/BBDown";
    license = lib.licenses.mit;
    platforms = with lib.platforms; linux ++ darwin;
    mainProgram = "BBDown";
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
}
