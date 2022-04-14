{ coricamuLib, pkgsLib, pkgs, ... }@args:

with coricamuLib;
with pkgsLib;

{
  evalSite =
    { modules, specialArgs ? {} }:
    evalModules {
      modules = [
        ./modules/default.nix
        ./modules/files.nix
        ./modules/fontawesome.nix
        ./modules/mermaid.nix
        ./modules/pages.nix
        ./modules/posts.nix
        ./modules/sitemap.nix
        ../image/option.nix
        (import ../style/option.nix {
          insertDefault = true;
        })
      ] ++ modules;
      specialArgs = args // specialArgs;
    };

  buildSite = args: (evalSite args).config.package;

  buildSitePreview =
    args:
    let
      previewModule = { config, ... }: {
        baseUrl = mkForce "http://localhost:8000/";
      };

      newArgs = args // {
        modules = args.modules ++ [ previewModule ];
      };

      previewSite = buildSite newArgs;

    in pkgs.writeShellApplication {
      name = "coricamu-preview";
      runtimeInputs = with pkgs; [ simple-http-server ];
      text = ''
        cat <<EOF

        The preview server is starting now. Press Ctrl+C to stop it.
        Open http://localhost:8000 in your browser to view the website!

        The preview files can also be inspected here:
        ${previewSite}

        EOF

        simple-http-server \
          --silent \
          --nocache \
          --port 8000 \
          --index \
          ${previewSite}
      '';
    };
}
