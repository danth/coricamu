{ config, ... }:

{
  baseUrl = "https://coricamu.example.com/";

  header.html = ''
    <h1>Coricamu Example Site</h1>

    <templates-note title="Example">
      This is an example website for
      <a href="https://github.com/danth/coricamu">Coricamu</a>.
    </templates-note>
  '';

  pages = {
    index = {
      path = "index.html";
      title = "Home";
      body.html = ''
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
      body.html = builtins.readFile ./about.html;
    };

    contact = {
      path = "contact.html";
      title = "Contact";
      body.markdown = ''
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

  posts = [
    {
      title = "Lorem Ipsum";
      datetime = "2022-01-31 20:10:05Z";
      authors = [ "John Doe" "Jane Doe" ];
      body.markdown = ''
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod
        tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim
        veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea
        commodo consequat. Duis aute irure dolor in reprehenderit in voluptate
        velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint
        occaecat cupidatat non proident, sunt in culpa qui officia deserunt
        mollit anim id est laborum.
      '';
    }
    {
      title = "Lorem Ipsum 2.0";
      datetime = "2022-01-31 22:50:33Z";
      authors = [ "John Doe" ];
      body.markdown = ''
        <p>In volutpat dapibus augue et suscipit. Donec sollicitudin sapien non
        leo interdum, eget porttitor mi convallis. Ut eu mauris et magna
        vulputate aliquet. Vivamus commodo imperdiet diam, eget commodo elit
        dignissim a. Proin vulputate metus diam, et molestie turpis pharetra
        ac. Nunc elementum mattis iaculis. Phasellus suscipit mattis tortor, at
        ultricies orci placerat ac. Quisque quis tristique lorem.</p>

        <templates-note title="Lipsum">
          <p>This was generated using
          <a href="https://lipsum.com">lipsum.com</a>.</p>
        </templates-note>
      '';
    }
  ];

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
