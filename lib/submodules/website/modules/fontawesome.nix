{ pkgs, ... }:

let
  fontAwesome = pkgs.fetchzip {
    url = "https://use.fontawesome.com/releases/v6.2.0/fontawesome-free-6.2.0-web.zip";
    sha256 = "p1J/g7NvXTKAgBK8OTCPOmJIHuU9q0huVm9MzoRLbhk=";
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
