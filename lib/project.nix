{ coricamuLib, pkgsLib, ... }:

with coricamuLib;
with pkgsLib;

{
  makeProjectPage = name: file:
    let
      text = builtins.readFile file;
      lines = splitString "\n" text;

      titleLine = findFirst (hasPrefix "# ") null lines;
      title =
        if titleLine != null
        then removePrefix "# " titleLine
        else name;

      path =
        if name == "README"
        then "index.html"
        else "${makeSlug title}.html";

      content = pipe lines [
        (filter (line: line != titleLine))
        (concatStringsSep "\n")
      ];

    in {
      inherit title path;
      body.markdown = content;
    };

  makeProjectPages = projectRoot: pipe projectRoot [
    builtins.readDir
    attrNames
    (map (builtins.match "([A-Z_]+)\.md"))
    (filter (m: m != null))
    (map (m: elemAt m 0))
    (names: genAttrs names (name: "${projectRoot}/${name}.md"))
    (mapAttrsToList makeProjectPage)
  ];

  makeProjectHeader =
    { title, pages, repository ? null }:
    let
      makeLink = href: text: "<a href=\"${href}\">${text}</a>";

      getTitle = page:
        if page.path == "index.html"
        then "Home"
        else page.title;

      pageLinks = map (page: makeLink page.path (getTitle page)) pages;

      repositoryLinks = optional
        (repository != null)
        (makeLink repository "Repository");

      links = concatStringsSep " "
        (pageLinks ++ repositoryLinks);

    in {
      html = ''
        <h1>${title}</h1>
        <nav>${links}</nav>
      '';
    };
}
