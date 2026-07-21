{ fetchzip, lib, ... }:
fetchzip {
  url = "https://github.com/skywind3000/ECDICT/releases/download/1.0.28/ecdict-stardict-28.zip";
  hash = "sha256-G/zY8U0I14MmsRYL7uPEBWnM3QnO5ZW6OSLju9fluY0=";
  stripRoot = false;

  meta = {
    description = "Free English to Chinese Dictionary Database";
    homepage = "https://github.com/skywind3000/ECDICT";
    license = lib.licenses.mit;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
}
