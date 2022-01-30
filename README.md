# Coricamu

*Note:* This documentation assumes that you have some pre-existing knowledge of:
- Nix Flakes
- The Nix expression language
- The Nix module system

## Building a site

Coricamu can be added to `flake.nix` like this:

```nix
{
  inputs.coricamu.url = "github:danth/coricamu";

  outputs = { coricamu, ... }: {
    packages."x86_64-linux".website =
      coricamu.lib.buildSite {
        system = "x86_64-linux";
        modules = [ ./website.nix ];
      };
  };
}
```

Where `website.nix` is a configuration module, as documented below.

This will produce a single package output (`website`) containing the built HTML
and other files, ready to be published by a HTTP server such as Nginx.

## Configuring a site

Coricamu uses the Nix module system for website configuration. This is similar
to how NixOS machines are configured, except obviously the set of options
available is different. You can use imports, create custom options, use `mkIf`,
`mkMerge`, `mkForce`, in fact pretty much anything you can do in a NixOS module
can also be done in a Coricamu module.

### Files

You can directly add a file to your site by putting it in the `files` attribute
set:

```nix
{
  files."favicon.ico" = ./favicon.ico;
}
```

### Pages

However, rather than writing out entire HTML documents by hand and adding them
to files, Coricamu includes a layer of abstraction which can generate a lot of
boilerplate for you:

```nix
{
  pages = {
    index = {
      path = "index.html";
      title = "Home";
      body = ''
        <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do
        eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad
        minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip
        ex ea commodo consequat. Duis aute irure dolor in reprehenderit in
        voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur
        sint occaecat cupidatat non proident, sunt in culpa qui officia
        deserunt mollit anim id est laborum.</p>
      '';
    };

    about = {
      path = "about.html";
      title = "About Us";
      # File only needs to contain the insides of <body>, not an entire page
      body = builtins.readFile ./about.html;
    };
  };
}
```

This is all validated by the Nix module system, so you will be warned if any
information is missing or improperly formatted.

### Templates

Templates can be used to avoid HTML boilerplate even more, and standardise the
presentation of a particular design element.

#### Defining templates

Custom templates can be added to the `templates` attribute set:

```nix
{
  templates.info = { title, contents }: ''
    <div class="info">
      <h2>${title}</h2>
      <p>${contents}</p>
    </div>
  '';
}
```

A template is just a Nix function which takes an arbitrary set of parameters
(in this case `title` and `contents`), and returns a string containing HTML.
Templates can rely on other templates; they can even call themselves, if you
are careful to avoid infinite recursion.

#### Nix splices

The most basic way to use a template is by calling its function, and splicing
the return value into your HTML:

```nix
{ config, ... }:

{
  pages.example.body = ''
    <p>
      Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod
      tempor incididunt ut labore et dolore magna aliqua.
    </p>
    ${config.templates.note {
      title = "An important note";
      contents = ''
        Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi
        ut aliquip ex ea commodo consequat.
      '';
    }}
    <p>
      Duis aute irure dolor in reprehenderit in voluptate velit esse cillum
      dolore eu fugiat nulla pariatur.
    </p>
  '';
}
```

This relies on a Nix feature, so you can no longer import the body from a
separate HTML file:

```nix
{
  pages.example.body = builtins.readFile ./example.html;
}
```

#### Template tags

This is where template tags come in. Rather than directly calling the template
function, you can format the arguments as pseudo-HTML:

```html
<p>
  Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod
  tempor incididunt ut labore et dolore magna aliqua.
</p>
<templates.note title="An important note">
  Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi
  ut aliquip ex ea commodo consequat.
</templates.note>
<p>
  Duis aute irure dolor in reprehenderit in voluptate velit esse cillum
  dolore eu fugiat nulla pariatur.
</p>
```

This doesn't directly rely on Nix, so it will work when the body is loaded from
a file.

Coricamu will detect that a template tag was used, and enable some
import-from-derivation magic which automatically reformats the above HTML to
behave as if you wrote:

```nix
''
<p>
  Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod
  tempor incididunt ut labore et dolore magna aliqua.
</p>
${config.templates.note {
  title = "An important note";
  contents = ''
    Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi
    ut aliquip ex ea commodo consequat.
  '';
}}
<p>
  Duis aute irure dolor in reprehenderit in voluptate velit esse cillum
  dolore eu fugiat nulla pariatur.
</p>
''
```

Any attributes on the tag are converted to function arguments. Notice how the
text inside the `<templates.note>` tag has become the `contents` argument; this
is a special argument intended for templates which fit around other content.
Text, HTML and even other template tags can be placed inside a template like
this.

*Note:* There is nothing to prevent you from using template tags even when Nix
splices are available; just be aware that they can require a little extra
computation when the site is built. Use whichever style you prefer.

## Credits

Coricamu was heavily inspired by [Styx](https://github.com/styx-static/styx).
Many thanks to the authors of that project!
