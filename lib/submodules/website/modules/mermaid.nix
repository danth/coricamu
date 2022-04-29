{
  templates.mermaid = {
    function =
      { contents }:
      "<pre class=\"mermaid\">${contents}</pre>";

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
