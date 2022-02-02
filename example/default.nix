{ config, ... }:

{
  baseUrl = "https://coricamu.example.com/";

  header = ''
    <h1>Coricamu Example Site</h1>

    <templates-note title="Example">
      This is an example website for
      <a href="https://github.com/danth/coricamu">Coricamu</a>.
    </templates-note>
  '';

  # Discourage search engines from indexing this site
  meta.robots = "noindex";

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
      sitemap = {
        lastModified = "2022-01-30";
        # Encourage search engines to check the homepage before other pages
        priority = "1.0";
      };
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

    contact = {
      path = "contact.html";
      title = "Contact";

      markdownBody = ''
        <templates-note title="Office hours">
          We will only reply between 9AM and 4PM on weekdays.
        </templates-note>

        You can contact us on:

        - Email A
        - Email B
        - Email C

        <templates-note title="Spam">
          1. Don't send us spam emails
          2. We'll delete them
        </templates-note>

        <templates-note title="Phishing">
          Don't send us phishing emails
        </templates-note>
      '';
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
