{ config, ... }:

{
  pages = {
    index = {
      path = "index.html";
      title = "Home";
      body = ''
        <h1>Home</h1>

        ${config.templates.note {
          title="Clouds";
          contents = ''
            <img src="clouds.png" alt="A cloudy sky.">
          '';
        }}
      '';
    };

    about = {
      path = "about.html";
      title = "About";
      meta = {
        author = "Jane Doe";
        description = "An example page for Coricamu";
      };
      body = builtins.readFile ./about.html;
    };
  };

  files."clouds.png" = ./clouds.png;

  styles.note = {
    path = "note.css";
    css = ''
      .note {
        border: 2px solid black;
      }
    '';
  };

  templates.note = { title, contents }: ''
    <div class="note">
      <h3>${title}</h3>
      ${contents}
    </div>
  '';
}
