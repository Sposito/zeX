{
  description = "zeX: the zig comptime scheme ";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.zig
            pkgs.zls
            pkgs.chez
            pkgs.gambit
            pkgs.nixpkgs-fmt
            pkgs.vscode
            pkgs.vscode-extensions.bbenoist.nix
            pkgs.vscode-extensions.ziglang.vscode-zig
            pkgs.vscode-extensions.justusadam.language-haskell
          ];

          shellHook = ''
            echo "Zig + Scheme Dev Env Loaded"
          '';
        };
      }
    );
}

