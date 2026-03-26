{
  crane,
  fenix,
  ...
}:
{
  perSystem =
    {
      pkgs,
      lib,
      system,
      ...
    }:
    let
      toolchain = fenix.packages.${system}.stable.toolchain;
      craneLib = (crane.mkLib pkgs).overrideToolchain toolchain;
      root = ../.;

      args = {
        src = lib.fileset.toSource {
          inherit root;
          fileset = lib.fileset.unions [
            (craneLib.fileset.commonCargoSources root)
            (lib.fileset.fileFilter (file: file.hasExt "plist") root)
          ];
        };
        strictDeps = true;
        doCheck = false;

        nativeBuildInputs = [ ];
        buildInputs = [ ];
      };

      build = craneLib.buildPackage (
        args
        // {
          cargoArtifacts = craneLib.buildDepsOnly args;
        }
      );
      version = "0.4.0";

      rift-bin = pkgs.stdenv.mkDerivation {
        pname = "rift-bin";
        version = version;
        src = builtins.fetchTarball {
          url = "https://github.com/acsandmann/rift/releases/download/v${version}/rift-universal-macos-${version}.tar.gz";
          sha256 = "063wmi5xyid0pp5s6pdvigvqqj5di4mnq0x44m3rbh5sy90km6lb";
        };
        phases = [ "installPhase" ];
        installPhase = ''
          mkdir -p $out/bin
          cp -r $src/* $out/bin
          chmod +x $out/bin/*
        '';
      };
    in
    {
      checks.rift = build;

      packages.rift = build;
      packages.rift-bin = rift-bin;
      packages.default = rift-bin;

      devshells.default = {
        packages = [
          toolchain
        ];
        commands = [
          {
            help = "";
            name = "hot";
            command = "${pkgs.watchexec}/bin/watchexec -e rs -w src -w Cargo.toml -w Cargo.lock -r ${toolchain}/bin/cargo run -- $@";
          }
        ];
      };
    };
}
