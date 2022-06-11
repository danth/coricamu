{ coricamuLib, pkgsLib, pkgs, ... }:

with pkgsLib;
with coricamuLib;

let
  argumentPattern = ''([^[:space:]/>"'=]+)="(([^"\\]|\\.])*)"'';

  # This function takes a HTML argument list of the string form:
  # argument1="value1" argument2="value2"
  # And converts it into an attribute set of the form:
  # { argument1 = "value1"; argument2 = "value2"; }
  matchArguments = input:
    let
      matches = builtins.split argumentPattern input;
      foldMatch =
        accumulator: match:
        if isString match
        then accumulator
        else accumulator // { "${elemAt match 0}" = elemAt match 1; };
    in
      foldl foldMatch {} matches;

  templateSelfClosingPattern = name:
    "<[[:space:]]*templates-${escapeRegex name}(([[:space:]]*${argumentPattern})*)[[:space:]]*(/)>";

  templateStartPattern = name:
    "<[[:space:]]*templates-${escapeRegex name}(([[:space:]]*${argumentPattern})*)[[:space:]]*>";

  templateEndPattern = name:
    "</[[:space:]]*templates-${escapeRegex name}[[:space:]]*>";

  templatePattern = name:
    "(${templateStartPattern name}|${templateSelfClosingPattern name}|${templateEndPattern name})";

  # This rather complex function uses regular expressions to parse template
  # tags into a list of:
  # - Strings representing content which is not related to any template
  # - Attribute sets representing a template which should be filled
  # This is implemented by first creating a list of:
  # - Strings representing content which is not related to any template
  # - Lists representing start tags
  # - Lists representing end tags
  matchTemplate = name: input:
    let
      splitted = builtins.split (templatePattern name) input;
      isStartTag = match: isList match && elemAt match 1 != null;
      isSelfClosingTag = match: isList match && elemAt match 11 == "/";
      isEndTag = match: isList match && elemAt match 1 == null;
      collate = collated: item:
        let
          # Operations on the output value.
          # We can either add a new match object, or update the latest one.
          append = value: collated ++ [value];
          updateLast = attrs: init collated ++ [(last collated // attrs)];

          # If true, we have not reached a closing tag for the current call yet.
          lastIsOpen =
            (length collated > 0) &&
            isAttrs (last collated) &&
            (last collated).open > 0;
        in
          if isStartTag item
          then
            if lastIsOpen
            # There is already a template open, so we convert another opening
            # tag back to a string. This string will be passed to the already
            # open template as its contents, and possibly returned to us later,
            # when it will be parsed as a template again. This process allows
            # template calls to be nested.
            then updateLast {
              contents = (last collated).contents + (elemAt item 0);
              # We must count how many times we have seen a nested opening tag
              # so that the corresponding number of closing tags can be processed.
              open = (last collated).open + 1;
            }
            # There is no template open, so we open a new one.
            else append {
              open = 1;
              contents = "";
              arguments = matchArguments (elemAt item 1);
            }
          else
            if isSelfClosingTag item
            then
              if lastIsOpen
              # This self-closing tag is nested, so convert it to a string
              # as per the comment above.
              then updateLast {
                contents = (last collated).contents + (elemAt item 0);
              }
              # There is no template open, so we can create an already-closed
              # template with the arguments from this self-closing tag.
              else append {
                open = 0;
                contents = "";
                arguments = matchArguments (elemAt item 6);
              }
            else
              if isEndTag item
              then
                if isAttrs (last collated)
                then
                  if (last collated).open > 1
                  # This closing tag corresponds to an opening tag which was nested,
                  # therefore is is converted to a string as per the comment above.
                  then updateLast {
                    contents = (last collated).contents + (elemAt item 0);
                    # Count how many times we have seen a nested closing tag so that
                    # we know when the template should be finished.
                    open = (last collated).open - 1;
                  }
                  # This is a normal closing tag.
                  else updateLast {
                    # We know that open <= 1, so we can skip decrementing and simply
                    # set it to zero.
                    open = 0;
                  }
                else
                  throw "Unexpected closing template tag: ${elemAt item 0}"
              else
                # This is a string of content, not a relevant template tag.
                if !lastIsOpen
                # Between calls, we just insert content to the output list directly.
                then append item
                # Within a template call, we must add to the content of the template.
                else updateLast {
                  contents = (last collated).contents + item;
                };
    in
      foldl collate [] splitted;

  # matchTemplate returns template matches in the form:
  # { arguments = {...}; contents = "..."; }
  # But the template functions we are given expect the contents
  # to be combined into the arguments to make:
  # { argument1 = "..."; argument2 = "..."; contents = "..."; }
  # Unless the template doesn't contain anything, in which case
  # the contents argument is omitted.
  # This function does the required conversion between forms.
  matchToArguments = match:
    match.arguments //
    (optionalAttrs (match.contents != "") {
      inherit (match) contents;
    });

  # Used when we have filled one template, and then we fill another template
  # into the body returned from the first filling. In this case, the newer body
  # should replace the old one, but we have still used all of the templates.
  updateFillResult = left: right: {
    body = right.body;
    usedTemplates = left.usedTemplates ++ right.usedTemplates;
  };

  # Used when we have filled a template into part of a body, and then we fill
  # it into the next part. In this case the parts are combined to build up a new
  # complete body into which the template has been filled.
  mergeFillResults = left: right: {
    body = left.body + right.body;
    usedTemplates = left.usedTemplates ++ right.usedTemplates;
  };

  concatFillResults = foldl mergeFillResults { body = ""; usedTemplates = []; };

  # This function takes a template match and replaces it with the output
  # of the corresponding template function.
  expandTemplate = templates: template: match:
    updateFillResult
      # The return value of fillTemplates will not include the current template,
      # because fillTemplates does not know that's where the body came from.
      { usedTemplates = [ template ]; }
      # We must repeat the template filling in case there are any template tags 
      # within the output of the template we are about to call.
      (fillTemplates {
        body = template.function (matchToArguments match);
        inherit templates;
      });

  # Here, the effects of matchTemplate and expandTemplate are combined to create a
  # function which performs the entire filling for a single template definition.
  fillTemplate = templates: name: template: body:
    let
      matches = matchTemplate name body;
      fill = match:
        if isString match
        then { body = match; usedTemplates = []; }
        else expandTemplate templates template match;
    in
      concatFillResults (map fill matches);

  # Finally: we repeat fillTemplate over all of the defined templates.
  # This is done by fully filling the first template as if it was the only one which
  # existed, then going back to the start and filling the second template, and so on
  # until everything is done.
  fillTemplates = { body, templates }:
    pipe {
      inherit body;
      usedTemplates = [];
    }
    (mapAttrsToList (
      name: template: result:
      updateFillResult result
      (fillTemplate templates name template result.body)
    ) templates);

in { inherit fillTemplates; }
