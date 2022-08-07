{ pkgs, ... }:

let
  fontAwesome = pkgs.fetchzip {
    url = "https://use.fontawesome.com/releases/v6.1.2/fontawesome-free-6.1.2-web.zip";
    sha256 = "qplVyWQTIe8ZG2IGWvmM+7ipzv7rnj9BBjTxoZ7DZOM=";
  };

in {
  templates.font-awesome = {
    function =
      { style ? "regular", icon, contents ? null }:
      if contents == null
      then ''
        <svg class="font-awesome">
          <use href="fontawesome/${style}.svg#${icon}"></use>
        </svg>
      ''
      else ''
        <div class="font-awesome-box">
          <svg class="font-awesome">
            <use href="fontawesome/${style}.svg#${icon}"></use>
          </svg>
          <div>${contents}</div>
        </div>
      '';

    files."fontawesome" = "${fontAwesome}/sprites";
  };
}
