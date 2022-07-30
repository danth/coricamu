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

      formatValue = value:
        if value?_type
        then
          if value._type == "literalDocBook"
          then value.text
          else
            if value._type == "literalExpression"
            then formatVerbatim value.text
            else throw "Text type `${value._type}` is not implemented"
        else formatVerbatim (showVal value);

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
              <entry>${formatValue option.default}</entry>
            </row>
          ''}
          ${optionalString (option?example) ''
            <row>
              <entry>Example:</entry>
              <entry>${formatValue option.example}</entry>
            </row>
          ''}
        </tbody></tgroup></table>

        ${optionalString (option.description != null) ''
          <para>${option.description}</para>
        ''}
      </section>
    '';

  makeOptionsDocBook = {
    options,
    showInvisible ? false,
    showInternal ? false
  }: ''
    <section xmlns:xlink="http://www.w3.org/1999/xlink">
      ${pipe options [
        optionAttrSetToDocList
        (filter (option:
          (option.visible || showInvisible) &&
          (!option.internal || showInternal)
        ))
        (map makeOptionDocBook)
        (concatStringsSep "\n")
      ]}
    </section>
  '';

  makeModulesDocBook =
    { modules, ... }@args:
    let
      newArgs = removeAttrs args [ "modules" ];
      evaluated = evalModules { inherit modules; };
    in
      makeOptionsDocBook (newArgs // {
        inherit (evaluated) options;
      });
}
