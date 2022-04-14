{ coricamuLib, pkgsLib, pkgs, config, ... }@args:

with pkgsLib;
with pkgsLib.types;
with coricamuLib;

let
  fontAwesome = pkgs.fetchzip {
    url = "https://use.fontawesome.com/releases/v6.1.1/fontawesome-free-6.1.1-web.zip";
    sha256 = "Jve63A5XpdBe+q9L2DhEU0zSnGj7LEHc24ouwe2KkMk=";
  };

in {
  options = {
    installFontAwesome = mkOption {
      description = ''
        Whether to support Font Awesome 6 icons on this page.
      '';
      default =
        pageContains "templates-font-awesome" args ||
        pageContains "xlink:href=\"/fontawesome/fa-" args;
      defaultText = ''
        <literal>true</literal> if
        <literal>templates-font-awesome</literal> or
        <literal>href="/fontawesome/fa-</literal>
        is found anywhere in the generated HTML for the
        body, otherwise <literal>false</literal>.
      '';
      type = bool;
    };
  };

  config = mkIf config.installFontAwesome {
    files = {
      "fontawesome" = "${fontAwesome}/sprites";
    };
  };
}
