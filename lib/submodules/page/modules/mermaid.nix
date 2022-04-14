{ coricamuLib, pkgsLib, config, ... }@args:

with pkgsLib;
with pkgsLib.types;
with coricamuLib;

{
  options = {
    installMermaid = mkOption {
      description = ''
        Whether to install the JavaScript for rendering Mermaid diagrams on
        this page.
      '';
      default =
        # TODO: Scan body after templates have been resolved
        pageContains "class=\"mermaid\"" args ||
        pageContains "templates-mermaid" args;
      defaultText = ''
        <literal>true</literal> if <literal>class="mermaid"</literal> is
        found anywhere in the generated HTML for the body, otherwise
        <literal>false</literal>.
      '';
      type = bool;
    };
  };

  config = mkIf config.installMermaid {
    head = ''
      <script
        src="https://cdn.jsdelivr.net/npm/mermaid@8.14.0/dist/mermaid.min.js"
        integrity="sha256-7wT34TI0pEBeEFoi4z+vhuSddGh6vUTMWdqJ2SDe2jg="
        crossorigin="anonymous"
      ></script>
      <script>
        mermaid.initialize({ startOnLoad: true });
      </script>
    '';
  };
}
