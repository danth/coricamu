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
        ./modules/images.nix
        ./modules/mermaid.nix
        ./modules/pages.nix
        ./modules/posts.nix
        ./modules/sitemap.nix
        ./modules/styles.nix
      ] ++ modules;
      specialArgs = args // specialArgs;
    };

  buildSite = args: (evalSite args).config.package;

  buildSitePreview =
    args:
    let
      previewModule = { config, ... }: {
        baseUrl = mkForce "file://coricamu-preview/";
      };

      newArgs = args // {
        modules = args.modules ++ [ previewModule ];
      };

      previewSite = buildSite newArgs;

    in pkgs.writeShellApplication {
      name = "coricamu-preview";

      runtimeInputs = with pkgs; [ xdg-utils ];

      text = ''
        dir="''${XDG_CACHE_HOME:-$HOME/.cache}/coricamu"
        mkdir -p "$dir"
        rm -rf "$dir/preview"

        # Dereference will replace all symlinks with editable files
        cp -r --dereference --no-preserve=mode,ownership \
          ${previewSite} "$dir/preview"

        find "$dir" -type f | while read -r file; do
          sed -e "s|file://coricamu-preview|file://$dir/preview|g" -i "$file"
        done

        xdg-open "$dir/preview/''${1:-index}.html"
      '';
    };
}
