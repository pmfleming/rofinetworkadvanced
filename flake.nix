{
  description = "NetworkManager JSON/JSONL API adapter";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (system: pkgs: {
        default = pkgs.rustPlatform.buildRustPackage {
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
      });

      apps = forAllSystems (system: pkgs: {
        default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/nm-api";
          meta.description = "Run the nm-api NetworkManager adapter";
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
