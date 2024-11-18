{
  lib,
  stdenv,
  pkgs,
  buildPackages,
  fetchurl,
  installShellFiles,
  testers,
}:
let
  releases = {
    k0s_1_30 = import ./1_30.nix;
  };
in
builtins.mapAttrs (
  name: release:
  stdenv.mkDerivation rec {
    pname = "k0s";
    inherit (release) version;

    src = fetchurl {
      inherit
        (release.srcs."${stdenv.hostPlatform.system}"
          or (throw "Missing source for host system: ${stdenv.hostPlatform.system}")
        )
        url
        hash
        ;
    };

    nativeBuildInputs = [ installShellFiles ];

    phases = [ "installPhase" ];

    installPhase =
      let
        k0s =
          if stdenv.buildPlatform.canExecute stdenv.hostPlatform then
            placeholder "out"
          else
            buildPackages."${name}";
      in
      ''
        install -m 755 -D -- "$src" "$out"/bin/k0s

        # Generate shell completions
        installShellCompletion --cmd k0s \
          --bash <(${k0s}/bin/k0s completion bash) \
          --fish <(${k0s}/bin/k0s completion fish) \
          --zsh <(${k0s}/bin/k0s completion zsh)
      '';

    passthru.tests.version = testers.testVersion {
      package = pkgs."${name}";
      command = "k0s version";
      version = "v${version}";
    };

    passthru.updateScript = ./update-script.bash;

    meta = {
      description = "The Zero Friction Kubernetes";
      homepage = "https://k0sproject.io";
      license = lib.licenses.asl20;
      sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
      mainProgram = "k0s";
      maintainers = with lib.maintainers; [ twz123 ];
      platforms = builtins.attrNames release.srcs;
    };
  }
) releases
