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
        pageContains "fa-" args &&
        pageContains "<i " args;
      defaultText = ''
        <literal>true</literal> if <literal>fa-</literal> and
        <literal>&lt;i </literal> are found anywhere in the generated
        HTML for the body (indicating that a Font Awesome icon might
        be used), otherwise <literal>false</literal>.
      '';
      type = bool;
    };
  };

  config = mkIf config.installFontAwesome {
    styles = [{
      path = "fontawesome/all.css";
      cssFile = "${fontAwesome}/css/all.css";
    }];

    files = {
      "fontawesome/webfonts" = "${fontAwesome}/webfonts";
    };
  };
}
