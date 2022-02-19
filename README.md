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

  outputs = { coricamu, ... }:
    coricamu.lib.generateFlakeOutputs {
      outputName = "my-website";
      modules = [ ./website.nix ];
    };
}
```

Where `website.nix` is a configuration module, as documented below.

This will add two things to your flake outputs:
- `my-website`, a package containing the built HTML and other files, ready to
  be published by a HTTP server such as Nginx
- `my-website-preview`, an app which allows you to open `my-website` locally

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

For lots of file types, there are smarter options, for example:

### Images

There is a separate option for image files which will perform some compression
to improve website loading speed, with minimal quality reduction. Currently,
[`image_optim`](https://github.com/toy/image_optim) is used behind the scenes.

```nix
{
  images = [
    {
      path = "clouds.png";
      file = ./clouds.png;
    }
  ];
}
```

### Pages

Rather than writing out entire HTML documents by hand and adding them to files,
Coricamu includes a layer of abstraction which can generate a lot of
boilerplate for you:

```nix
{
  pages = {
    index = {
      path = "index.html";
      title = "Home";

      # Currently supports either HTML or Markdown input
      body.markdown = ''
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do
        eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad
        minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip
        ex ea commodo consequat. Duis aute irure dolor in reprehenderit in
        voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur
        sint occaecat cupidatat non proident, sunt in culpa qui officia
        deserunt mollit anim id est laborum.
      '';
    };

    about = {
      path = "about.html";
      title = "About Us";
      # File only needs to contain the insides of <body>, not an entire page
      body.html = builtins.readFile ./about.html;
    };
  };
}
```

This is all validated by the Nix module system, so you will be warned if any
information is missing or improperly formatted.

### Header / Footer

You can define a header and footer which will be repeated on every page of
your site.

```nix
{
  header.html = ''
    <h1>My Website</h1>
  '';

  footer.markdown = ''
    Content on this site is available under the *Lorem Ipsum License* unless
    otherwise stated.
  '';
}
```

### Posts

If you are building a blog-style site, you should use the post option.
Posts can be defined in a list:

```nix
{
  posts = [
    {
      title = "Lorem Ipsum";
      datetime = "2022-01-31 20:10:05Z";
      authors = [ "John Doe" "Jane Doe" ];
      body.markdown = builtins.readFile ./lorem_ipsum.md;
    }
    {
      title = "Ut Enim Ad Minim";
      datetime = "2022-01-31 20:10:05Z";
      authors = [ "Jane Doe" ];
      body.html = builtins.readFile ./ut_enim_ad_minim.html;
    }
  ];
}
```

Posts include rich metadata in the generated page, which allows search engines
to present your content in the most appropriate manner.

#### Indices

If at least one post is present, the page `posts/index.html` will be enabled;
this is an automatically generated, chronological list of all your posts, with
a link to each post's individual page.

If you have more than one author on your site, or have added lists of
`keywords` to your posts, the page `posts/pills.html` will be enabled; this is
an automatically generated tool which allows visitors to filter posts by author
or keyword.

Coricamu asks search engines not to index `posts/index.html`,
`posts/pills.html` and any filtered post lists which they link to; this allows
them to spend more time indexing your actual content instead. Search engines
don't need these pages to discover your posts because `sitemap.xml` is
generated for that.

#### Lists

Coricamu pre-defines two templates related to posts:

- `all-posts` inserts a chronological list of all posts, as is found on
  `posts/index.html`.
- `recent-posts` inserts a chronological list of the newest `count` posts.

You will learn more about how to use templates later in this document.

### Styles

Coricamu comes with a bare-bones CSS file which is imported by default. This
style sheet aims to make small improvements to most web browsers' defaults,
while not introducing any outstanding design elements.

If you define any style-sheets of your own...

```nix
{
  styles.custom = {
    path = "style.css";
    file = ./style.css;
  };
}
```

...then the default styling will be removed. If you would like to build on top
of Coricamu's CSS rather than replacing it, you can re-insert the default like
this:

```nix
{ options, ... }:

{
  styles = options.styles.default // {
    custom = {
      path = "style.css";
      file = ./style.css;
    };
  };
}
```

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
  pages.example.body.html = ''
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
  pages.example.body.html = builtins.readFile ./example.html;
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
<templates-note title="An important note">
  Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi
  ut aliquip ex ea commodo consequat.
</templates-note>
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
text inside the `<templates-note>` tag has become the `contents` argument; this
is a special argument intended for templates which fit around other content.
Text, HTML and even other template tags can be placed inside a template like
this.

*Note:* because HTML tags are case-insensitive, template names will also be
case-insensitive when used via template tags.

*Note:* There is nothing to prevent you from using template tags even when Nix
splices are available; just be aware that they can require a little extra
computation when the site is built. Use whichever style you prefer.

## Credits

Coricamu was heavily inspired by [Styx](https://github.com/styx-static/styx).
Many thanks to the authors of that project!
