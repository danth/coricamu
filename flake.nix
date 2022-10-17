{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { nixpkgs, utils, self, ... }:
    let
      makeFlakeOutputs =
        { name, entrypoint }:
        utils.lib.eachDefaultSystem (
          system:
          let
            pkgs = import "${nixpkgs}" {
              inherit system;
              overlays = [(self: super: {
                inherit coricamu;
              })];
            };
            coricamu = pkgs.callPackage ./lib/default.nix {};
          in rec {
            packages.${name} = pkgs.callPackage entrypoint {};

            apps."${name}-preview" = utils.lib.mkApp {
              name = "${name}-preview";
              drv = pkgs.writeShellApplication {
                name = "${name}-preview";
                runtimeInputs = [ pkgs.simple-http-server ];
                text = ''
                  cat <<EOF
                  The preview server is starting now. Press Ctrl+C to stop it.

                  Open http://localhost:8000 in your browser to view the website!

                  The preview files can also be inspected here:
                  ${packages.${name}}
                  EOF

                  simple-http-server \
                    --silent \
                    --nocache \
                    --port 8000 \
                    --index \
                    ${packages.${name}}
                '';
              };
            };
          }
        );
    in {
      lib = { inherit makeFlakeOutputs; };
    } //
    makeFlakeOutputs {
      name = "docs";
      entrypoint = ./docs/default.nix;
    };
}
