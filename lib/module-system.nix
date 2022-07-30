{ coricamuLib, pkgsLib, ... }:

with coricamuLib;
with pkgsLib;

{
  makeOptionDocBook =
    option:
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

    in ''
      <section>
        <title>${escapeXML option.name}</title>

        <table><tgroup><tbody>
          <row>
            <entry>Type:</entry>
            <entry>${option.type}</entry>
          </row>
          ${optionalString (option?default) ''
            <row>
              <entry>Default:</entry>
              <entry>${formatValue' option.default}</entry>
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
      </section>
    '';

  makeOptionsDocBook = {
    options,
    showInvisible ? false,
    showInternal ? false,
    customFilter ? (option: true)
  }: ''
    <section xmlns:xlink="http://www.w3.org/1999/xlink">
      ${pipe options [
        optionAttrSetToDocList
        (filter (option:
          (customFilter option) &&
          (option.visible || showInvisible) &&
          (!option.internal || showInternal)
        ))
        (map makeOptionDocBook)
        (concatStringsSep "\n")
      ]}
    </section>
  '';
}
