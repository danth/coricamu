{ coricamuLib, pkgsLib, pkgs, ... }:

with pkgsLib;
with coricamuLib;

let
  argumentPattern = ''([^[:space:]/>"'=]+)="(([^"\\]|\\.])*)"'';

  matchArguments =
    input:
    let
      matches = builtins.split argumentPattern input;
      foldMatch =
        accumulator: match:
        if isString match
        then accumulator
        else accumulator // { "${elemAt match 0}" = elemAt match 1; };
    in
      foldl foldMatch {} matches;

  templateStartPattern = name:
    "<[[:space:]]*templates-${escapeRegex name}(([[:space:]]*${argumentPattern})*)[[:space:]]*>";

  templateEndPattern = name:
    "</[[:space:]]*templates-${escapeRegex name}[[:space:]]*>";

  matchTemplate =
    name: input:
    let
      splitted = builtins.split "(${templateStartPattern name}|${templateEndPattern name})" input;
      isStartTag = match: isList match && elemAt match 2 != null;
      isEndTag = match: isList match && elemAt match 2 == null;
      collate =
        collated: item:
        if isStartTag item
        then collated ++ [{
          arguments = matchArguments (elemAt item 1);
        }]
        else
          if isEndTag item
          then collated
          else
            if (length collated == 0) || (last collated)?contents
            then collated ++ [item]
            else init collated ++ [(last collated // {
              contents = item;
            })];
    in
      foldl collate [] splitted;

  mergeFillResults = left: right: {
    body = left.body + right.body;
    usedTemplates = left.usedTemplates ++ right.usedTemplates;
  };

  concatFillResults = foldl mergeFillResults {
    body = "";
    usedTemplates = [];
  };

  expandTemplate =
    templates: template: arguments:
    let
      # We must repeat fillTemplates in case any templates were used
      # within the output of the template.
      filledTemplate = fillTemplates {
        body = template.function arguments;
        inherit templates;
      };
    in
      {
        body = filledTemplate.body;
        usedTemplates = [ template ] ++ filledTemplate.usedTemplates;
      };

  fillTemplate =
    templates: name: template: body:
    concatFillResults (
      map
      (item:
        if isString item
        then {
          body = item;
          usedTemplates = [];
        }
        else
          expandTemplate templates template
          (item.arguments // (optionalAttrs (item.contents != "") { inherit (item) contents; }))
      )
      (matchTemplate name body)
    );

  fillTemplates =
    { body, templates }:
    let
      fillers = mapAttrsToList (
        name: template: result:
        let newResult = fillTemplate templates name template result.body;
        in {
          body = newResult.body;
          usedTemplates = result.usedTemplates ++ newResult.usedTemplates;
        }
      ) templates;
    in
      pipe {
        inherit body;
        usedTemplates = [];
      } fillers;

in { inherit fillTemplates; }
