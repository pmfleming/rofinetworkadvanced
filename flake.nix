{
  description = "NetworkManager JSON/JSONL API adapter";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (system: pkgs:
        let
          nmApi = pkgs.rustPlatform.buildRustPackage {
            pname = "nm-api";
            version = "0.1.0";
            src = ./.;
            cargoLock.lockFile = ./Cargo.lock;
            nativeBuildInputs = with pkgs; [ makeWrapper pkg-config ];
            postInstall = ''
              wrapProgram $out/bin/nm-api --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.iw ]}
            '';
            meta = {
              description = "NetworkManager JSON/JSONL API adapter";
              mainProgram = "nm-api";
              platforms = pkgs.lib.platforms.linux;
            };
          };
        in
        {
          default = nmApi;
          connectParityProbe = pkgs.writeShellApplication {
            name = "nm-api-connect-parity-probe";
            runtimeInputs = [
              pkgs.coreutils
              pkgs.jq
              pkgs.networkmanager
              nmApi
            ];
            checkPhase = ''
              runHook preCheck
              ${pkgs.stdenv.shellDryRun} "$target"
              ${pkgs.shellcheck}/bin/shellcheck --exclude=SC2016 "$target"
              runHook postCheck
            '';
            text = builtins.readFile ./tools/connect-parity-probe.sh;
            meta = {
              description = "Compare nm-api and nmcli Wi-Fi connection behavior for visible networks";
              mainProgram = "nm-api-connect-parity-probe";
              platforms = pkgs.lib.platforms.linux;
            };
          };
        });

      apps = forAllSystems (system: pkgs: {
        default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/nm-api";
          meta.description = "Run the nm-api NetworkManager adapter";
        };
        connectParityProbe = {
          type = "app";
          program = "${self.packages.${system}.connectParityProbe}/bin/nm-api-connect-parity-probe";
          meta.description = "Compare nm-api and nmcli Wi-Fi connection behavior";
        };
      });

      devShells = forAllSystems (system: pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            cargo
            clippy
            gcc
            iw
            just
            pkg-config
            rust-analyzer
            rustc
            rustfmt
          ];

          RUST_BACKTRACE = "1";
        };
      });

      formatter = forAllSystems (system: pkgs: pkgs.nixpkgs-fmt);
    };
}
