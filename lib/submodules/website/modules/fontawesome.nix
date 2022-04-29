{ pkgs, ... }:

let
  fontAwesome = pkgs.fetchzip {
    url = "https://use.fontawesome.com/releases/v6.1.1/fontawesome-free-6.1.1-web.zip";
    sha256 = "Jve63A5XpdBe+q9L2DhEU0zSnGj7LEHc24ouwe2KkMk=";
  };

in {
  templates.font-awesome = {
    function =
      { style ? "regular", icon, contents ? null }:
      if contents == null
      then ''
        <svg class="font-awesome">
          <use href="/fontawesome/${style}.svg#${icon}"></use>
        </svg>
      ''
      else ''
        <div class="font-awesome-box">
          <svg class="font-awesome">
            <use href="/fontawesome/${style}.svg#${icon}"></use>
          </svg>
          <div>${contents}</div>
        </div>
      '';

    files."fontawesome" = "${fontAwesome}/sprites";
  };
}
