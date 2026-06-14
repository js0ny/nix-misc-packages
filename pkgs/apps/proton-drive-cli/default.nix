{
  stdenv,
  fetchurl,
  libsecret,
  glib,
  lib,
  ...
}:
stdenv.mkDerivation rec {
  pname = "proton-drive-cli";
  version = "0.4.4";
  src = fetchurl {
    url = "https://proton.me/download/drive/cli/${version}/linux-x64/proton-drive";
    hash = "sha256-raEm89uUW8WmLZcAGU/C4RJISeNL15+31+o9kCQv/zI=";
  };
  dontUnpack = true;
  # when stripping, bun executable payload is after the ELF header
  dontStrip = true;

  runtimeDeps = [
    libsecret
    glib
  ];

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/proton-drive-cli
    runHook postInstall
  '';
  meta = with lib; {
    description = "Proton Drive CLI";
    homepage = "https://proton.me/drive/download";
    license = licenses.mit;
    mainProgram = "proton-drive-cli";
    platforms = [ "x86_64-linux" ];
  };
}
