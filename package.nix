{ lib
, buildNpmPackage
, nodejs_22
, makeWrapper
}:

let
  version = "0.29.3";
in buildNpmPackage {
  pname = "gemini-cli";
  inherit version;

  src = ./wrapper;

  npmDepsHash = "sha256-eO5MP6GpE7aEOD63uiW8Ta7FaaZp/DR/wUEhDnA/41k=";

  nodejs = nodejs_22;

  dontNpmBuild = true;

  # Skip native module compilation (keytar) - gemini-cli works without it
  # by falling back to file-based credential storage.
  # npmFlags applies to all npm commands (ci, rebuild, prune), not just install.
  npmFlags = [ "--ignore-scripts" ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/gemini-cli $out/bin
    cp -r node_modules $out/lib/gemini-cli/

    makeWrapper ${nodejs_22}/bin/node $out/bin/gemini \
      --add-flags "$out/lib/gemini-cli/node_modules/@google/gemini-cli/dist/index.js"

    runHook postInstall
  '';

  nativeBuildInputs = [ makeWrapper ];

  meta = with lib; {
    description = "Gemini CLI - an open-source AI agent that brings Gemini to your terminal";
    homepage = "https://github.com/google-gemini/gemini-cli";
    license = licenses.asl20;
    platforms = platforms.unix;
    mainProgram = "gemini";
  };
}
