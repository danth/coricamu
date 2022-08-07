{ pkgs, ... }:

let
  fontAwesome = pkgs.fetchzip {
    url = "https://use.fontawesome.com/releases/v6.1.2/fontawesome-free-6.1.2-web.zip";
    sha256 = "qplVyWQTIe8ZG2IGWvmM+7ipzv7rnj9BBjTxoZ7DZOM=";
  };

  getIcon = style: icon:
    builtins.replaceStrings ["<svg"] ["<svg class=\"font-awesome\""]
    (builtins.readFile "${fontAwesome}/svgs/${style}/${icon}.svg");

in {
  templates.font-awesome.function =
    { style ? "regular", icon, contents ? null }:
    if contents == null
    then getIcon style icon
    else ''
      <div class="font-awesome-box">
        ${getIcon style icon}
        <div>${contents}</div>
      </div>
    '';
}
