{ coricamuLib, pkgsLib, ... }:

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

  # Operations on the output value of matchTemplate.
  # We can either add a new match object, or update the latest one.
  append = collated: value: collated ++ [value];
  updateLast = collated: attrs: init collated ++ [(last collated // attrs)];

  # If true, we have not reached a closing tag for the current call yet.
  lastIsOpen = collated:
    (length collated > 0) &&
    isAttrs (last collated) &&
    (last collated).open > 0;

  # Start tags and self-closing tags are matched by the same pattern.
  # If a "/" is captured by the last group, then we know it's self-closing.
  startTagPattern = name:
    "<[[:space:]]*templates-${escapeRegex name}(([[:space:]]*${argumentPattern})*)[[:space:]]*(/)?>";

  isStartOrSelfClosingTag = match: elemAt match 1 != null;
  isSelfClosingTag = match: elemAt match 6 == "/";

  collateStartOrSelfClosingTag = collated: match:
    let
      # Self-closing tags create a template call but never open it,
      # so no content will be picked up and a closing tag is not required.
      open = if isSelfClosingTag match then 0 else 1;
    in
      if lastIsOpen collated
      # This tag is nested, so convert it to a string. The string will be passed
      # to the already open template as part of its contents, and possibly returned
      # to us later, when it will be parsed as a template again. This process allows
      # template calls to be nested without causing problems.
      then updateLast collated {
        # The first capturing group is the entire tag as a string.
        contents = (last collated).contents + (elemAt match 0);
        # We must count how many times we have seen a nested opening tag
        # so that the corresponding number of closing tags can be processed.
        open = (last collated).open + open;
      }
      # There is no template open, so we can start a new one.
      else append collated {
        inherit open;
        contents = "";
        arguments = matchArguments (elemAt match 1);
      };

  endTagPattern = name:
    "</[[:space:]]*templates-${escapeRegex name}[[:space:]]*>";

  collateEndTag = collated: match:
    if isAttrs (last collated)
    then
      if (last collated).open > 1
      # This closing tag corresponds to an opening tag which was nested,
      # therefore is is converted to a string as per the comment in
      # collateStartTag.
      then updateLast collated {
        contents = (last collated).contents + (elemAt match 0);
        # Count how many times we have seen a nested closing tag so that
        # we know when the template should be finished.
        open = (last collated).open - 1;
      }
      # This is a normal closing tag.
      else updateLast collated {
        # We know that open <= 1, so we can skip decrementing and simply
        # set it to zero.
        open = 0;
      }
    else
      throw "Unexpected closing template tag: ${elemAt match 0}";

  templatePattern = name:
    "(${startTagPattern name}|${endTagPattern name})";

  collateContent = collated: match:
    # This is a string of content, not a relevant template tag.
    if !(lastIsOpen collated)
    # Between calls, we just insert content to the output list directly.
    then append collated match
    # Within a template call, we must add to the content of the template.
    else updateLast collated {
      contents = (last collated).contents + match;
    };

  collateMatches = collated: match:
    if isString match then
      collateContent collated match
    else if isStartOrSelfClosingTag match then
      collateStartOrSelfClosingTag collated match
    else
      collateEndTag collated match;

  # This function uses regular expressions to parse template
  # tags into a list of:
  # - Strings representing content which is not related to any template
  # - Attribute sets representing a template which should be filled
  # This is implemented by first creating a list of:
  # - Strings representing content which is not related to any template
  # - Lists representing start tags
  # - Lists representing end tags
  matchTemplate = name: input:
    let splitted = builtins.split (templatePattern name) input;
    in foldl collateMatches [] splitted;

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
    inherit (right) body;
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
