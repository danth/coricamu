{ coricamuLib, pkgsLib, ... }:

with coricamuLib;
with pkgsLib;

let
  formatVerbatim = text:
    if hasInfix "\n" text
    then "<programlisting>${escapeXML text}</programlisting>"
    else "<literal>${escapeXML text}</literal>";

  formatValue = value: formatVerbatim (showVal value);

  formatParagraph = text:
    if builtins.match ".*</[a-z]+>.*" text != null
    then "<para>${text}</para>"
    else
      let splitText = replaceStrings [ "\n\n" ] [ "</para><para>" ] text;
      in "<para>${splitText}</para>";

  formatAnything = fallback: value:
    if value?_type
    then
      if value._type == "literalDocBook"
      then formatParagraph value.text
      else
        if value._type == "literalExpression"
        then formatVerbatim value.text
        else
          warn "Text type `${value._type}` is not implemented"
          (formatVerbatim value.text)
    else fallback value;

  formatValue' = formatAnything formatValue;
  formatParagraph' = formatAnything formatParagraph;

in {
  makeOptionsDocBook = {
    options,
    showInvisible ? false,
    showInternal ? false,
    customFilter ? (option: true)
  }:
  let
    makeOptionDocBook =
      option:
      let
        subOptions = option.type.getSubOptions option.loc;
      in ''
        <section xmlns:xlink="http://www.w3.org/1999/xlink">
          <title>${escapeXML (showOption option.loc)}</title>

          <table><tgroup><tbody>
            <row>
              <entry>Type:</entry>
              <entry>${option.type.description or "unspecified"}</entry>
            </row>
            ${optionalString (option?defaultText || option?default) ''
              <row>
                <entry>Default:</entry>
                <entry>${formatValue' (option.defaultText or option.default)}</entry>
              </row>
            ''}
            ${optionalString (option?example) ''
              <row>
                <entry>Example:</entry>
                <entry>${formatValue' option.example}</entry>
              </row>
            ''}
          </tbody></tgroup></table>

          ${optionalString (option.description != null) ''
            ${formatParagraph' option.description}
          ''}

          ${
            optionalString (subOptions != {})
            (concatStringsSep "\n" (makeOptionsDocBooks subOptions))
          }
        </section>
      '';

    makeOptionsDocBooks = options: pipe options [
      attrValues
      (map (option: 
        if isOption option
        then
          if (customFilter option) &&
            ((option.visible or true) || showInvisible) &&
            (!(option.internal or false) || showInternal)
          then [ (makeOptionDocBook option) ]
          else []
        else makeOptionsDocBooks option
      ))
      concatLists
    ];

  in ''
    <section>
      ${concatStringsSep "\n" (makeOptionsDocBooks options)}
    </section>
  '';
}
