# Coricamu

Coricamu allows you to generate a static site using [the Nix package manager](https://nixos.org/).

A static site is one which does not run any code on the server side. It can still use
JavaScript on the client side to provide some level of interactivity.

The following documentation assumes that you have some prior experience with the Nix
language and website development.

## Usage and features

Coricamu uses the module system for website configuration. This is the same way that
NixOS machines are configured, but with different options to choose from. You can use
imports, define your own options, and use the `mkIf`, `mkMerge` and `mkForce` functions,
just as you would in NixOS.

### Creating a flake

Coricamu expects you to use [Flakes](https://www.tweag.io/blog/2020-05-25-flakes/)
for dependency management.

Before writing a module, you need to create `flake.nix` as follows. Alternatively, this
can be combined with an existing `flake.nix` as part of a larger project.

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

- `website.nix` will be your main module.
- `my-website` is the name of the flake output containing the site.

### Basic information

Within the main module, you must define the following options:

`baseUrl`
: The root URL where your site will be served.

`siteTitle`
: A human-readable title for the site. If it's not given, this will use your domain name.

`language`
: Representation of the spoken language used on your website, for example
  `EN-US` for English, or `DE` for German.

Here's an example:

```nix
{
  baseUrl = "https://coricamu.example.com/";
  siteTitle = "Coricamu Example Site";
  language = "en-gb";
}
```

### Files

You can add any file directly to your site by putting it in the `files` attribute set:

```nix
{
  files."favicon.ico" = ./favicon.ico;
}
```

This is versatile, but does not have any smart features. For many file types you should use
a more specific option as described below.

### Images

The `images` option will automatically convert many bitmap file types to the modern
`webp` format. This is a recommended action on [PageSpeed Insights](https://pagespeed.web.dev/).

`svg` images don't need this conversion: they should be added directly to `files`.

```nix
{
  images = [
    {
      path = "clouds.webp";
      file = ./clouds.png;
    }
  ];
}
```

- The `path` option defines where the file will appear in your website. Note how it
  ends with `webp` but the file ends with `png`.
- The `file` option defines where the file is in your repository.

`path` and `file` can look totally different: there is no need to lay out your source
files in the same way that they will appear in the finished website.

Specifying both a path and a file in this way is a common pattern throughout Coricamu.

### Pages

Rather than writing out entire documents by hand and adding them to files,
Coricamu can generate a lot of the boilerplate for you.

The `pages` option is what you should use for most pages, unless you have a
finished HTML file already.

```nix
{
  pages = [
    {
      path = "index.html";
      title = "Home";

      # Currently supports HTML, Markdown or DocBook input
      body.markdown = ''
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do
        eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad
        minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip
        ex ea commodo consequat. Duis aute irure dolor in reprehenderit in
        voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur
        sint occaecat cupidatat non proident, sunt in culpa qui officia
        deserunt mollit anim id est laborum.
      '';
    }

    {
      path = "about.html";
      title = "About Us";
      # File only needs to contain the insides of <body>, not an entire page
      body.htmlFile = ./about.html;
    }
  ];
}
```

Coricamu supports three formats for the `body`:

- HTML
- Markdown
- DocBook

All of which can either be given as a string within your Nix file, or a path to
a separate file.

You can also give `images` and `files` within an individual page. The path of each
image or file is still relative to the root of the website - so a path of `clouds.png`
will appear at `https://example.com/clouds.png`, even if the page is in a subdirectory
at `https://example.com/subdirectory/page.html`.

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

The supported content types for the header and footer are the same as those for the
body of each page.

### Posts

If you are building a blog, consider using `posts` instead of `pages`. You can of course
choose to build your own blog by using the `pages` option instead.

The `posts` option requires some extra information about each post, in return for which
you get an automatically generated index page and RSS feed, which are linked at the bottom
of each post. The extra information is also embedded into the page, using
[Microdata](https://danth.me/posts/post/microdata.html), so that search engines can
understand it.

```nix
{
  posts = [
    {
      title = "Lorem Ipsum";
      datetime = "2022-01-31 20:10:05Z";
      authors = [ "John Doe" "Jane Doe" ];
      body.markdownFile = ./lorem_ipsum.md;
    }
    {
      title = "Ut Enim Ad Minim";
      datetime = "2022-01-31 20:10:05Z";
      edited = "2022-03-10 07:55:00Z";
      authors = [ "Jane Doe" ];
      body.htmlFile = ./ut_enim_ad_minim.html;
    }
  ];
}
```

Posts can be categorised by adding one or more `sections`:

```nix
{
  title = "Lorem Ipsum Dolor";
  datetime = "2022-02-26 11:29:26Z";
  authors = [ "John Doe" ];
  sections = [ "lorem" "ipsum" "dolor" "sit amet" ];
  body.markdownFile = ./lorem_ipsum_dolor.md;
}
```

#### Generated pages

The generated index page is at `posts/index.html`, and the RSS feed is at
`posts/rss/index.xml`.

If you have more than one author, or have used sections, `posts/pills.html`
will also be generated. This allows visitors to filter posts by author or section.

Coricamu asks search engines not to index `posts/index.html`, `posts/pills.html`
or any other lists. This allows them to spend more time indexing your actual content
instead. Search engines don't need to read these pages to discover your posts because
[`sitemap.xml`](https://developers.google.com/search/docs/crawling-indexing/sitemaps/overview)
is provided.

#### Templates related to posts

Coricamu includes two templates related to posts:

`all-posts`
: A chronological list of all posts, as found on `posts/index.html`.

`recent-posts`
: A chronological list of the newest `count` posts.

You will learn more about how to use templates later in this document.

### Styles

Coricamu comes with a basic style sheet which is imported by default. This makes some
of the generated elements look better, without introducing any outstanding design.

If you define any style sheets of your own...

```nix
{
  styles = [{
    path = "style.css";
    cssFile = ./style.css;
  }];
}
```

...then the default one will be removed. If you would like to build on top of Coricamu's
style sheet rather than replacing it, you can insert the default manually like this:

```nix
{ options, ... }:

{
  styles = options.styles.default ++ [{
    custom = {
      path = "style.css";
      cssFile = ./style.css;
    };
  }];
}
```

[Sass / SCSS](https://sass-lang.com/guide) style sheets are also supported:

```nix
{
  styles = [{
    # This is the path of the output file, so it is still .css
    path = "style.css";

    # This is the input file
    scssFile = ./style.scss;
  }];
}
```

Styles can be added within an individual page too. If you use the same `path` for
style sheets on multiple pages, it will cause an error unless those style sheets
are exactly the same.

### Templates

Templates can be used to avoid HTML boilerplate even more, or to standardise the
presentation of a particular design element.

#### Defining templates

A template is just a Nix function which takes an arbitrary set of parameters
(in this case `title` and `contents`), and returns some HTML. Templates can rely on
other templates; they can even call themselves, if you are careful to avoid infinite
recursion.

Custom templates are added to the `templates` attribute set:

```nix
{
  templates.info.function =
    { title, contents }: ''
      <div class="info">
        <h2>${title}</h2>
        <p>${contents}</p>
      </div>
    '';
}
```

Most page settings can be specified within templates too. Those settings will be added
to any page where that template is used. This can be used to install extra files to make
the template work, for example a style sheet:

```nix
{
  templates.info = {
    function =
      { title, contents }: ''
        <div class="info">
          <h2>${title}</h2>
          <p>${contents}</p>
        </div>
      '';

    styles = [{
      path = "info.css";
      css = ''
        .info {
          border: 3px solid black;
          padding: 5px;
        }
      '';
    }];
  };
}
```

#### Template tags

Templates are inserted using "template tag" syntax. This looks similar to a HTML
tag, but its name must match up with one of the templates you have defined for your
website.

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

Coricamu will parse the tag and call the corresponding template function.

- Attributes on the tag are converted to corresponding function arguments.
- Text inside the template tag is given as the `contents` argument.

This is all handled within Nix.

Note that template tags also work in Markdown, but not DocBook.

### Icons

Icons from [Font Awesome 6](https://fontawesome.com/search?m=free) can be
inserted using the built-in `font-awesome` template:

```html
<templates-font-awesome icon="book" />
```

For logos, you need to add `style="brands"`:

```html
<templates-font-awesome style="brands" icon="github" />
```

The `style` attribute can also used to switch between `regular` and `solid`
for the non-branded icons.

You can add content to the template to have it written alongside the icon:

```html
<templates-font-awesome icon="book">
  <p>These are some notes next to a book icon.</p>
</templates-font-awesome>
```

Icons and styles from Font Awesome Pro are not yet supported.

### Diagrams

[Mermaid diagrams](https://mermaid-js.github.io/) can be inserted using the
built-in `mermaid` template.

```html
<templates-mermaid>
flowchart TD
insert template ---> get diagram
</templates-mermaid>
```

Using a `mermaid` code block in Markdown may have same visual output, however
this could break in future updates. You should prefer using the template.

## Compilation

There are two commands which will be most important to you during development:

`nix build .#my-website`
: This will compile your website and place its files into `result`. These can be
  inspected, or deployed to a web server by hand.

`nix run .#my-website-preview`
: This will compile the website as above, but launch a local web server so that you
  can test the site in a browser. Further instructions on how to do this will be printed
  after running the command.

## Deployment

The commands above are useful while writing a website, but you will want to use a more
automated setup when you publish it. Coricamu works with multiple web servers and hosts,
some of which are documented below.

### GitHub Pages

There is a reusable GitHub Actions workflow for deploying to GitHub Pages. To use it, copy
the following text to `.github/workflows/docs.yml` in your repository:

```yaml
name: Deploy

on:
  push:
    branches:
      - master

jobs:
  pages:
    name: Pages
    uses: danth/coricamu/.github/workflows/pages.yml@cd253a6940853ffc3da7c14c9311940f1d70e222
    with:
      output_name: my-website
```

The text after `output_name` must correspond to the `outputName` you provided
to `coricamu.lib.generateFlakeOutputs` in `flake.nix`. In the example earler on
this page, we used `my-website`.

## Credits

Coricamu was heavily inspired by [Styx](https://github.com/styx-static/styx).
Many thanks to the authors of that project!
