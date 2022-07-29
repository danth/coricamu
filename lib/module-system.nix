{ coricamuLib, pkgsLib, ... }:

with coricamuLib;
with pkgsLib;

{
  makeOptionDocBook =
    option:
    let
      formatText = text:
        if isString text
        then text
        else
          if text._type == "literalDocBook"
          then text.text
          else
            if text._type == "literalExpression"
            then "<literal>${escapeXML (text.text)}</literal>"
            else throw "Text type ${text._type} is not implemented";

      default =
        if option?defaultText
        then formatText option.defaultText
        else
          if option?default
          then "<literal>${escapeXML (showVal option.default)}</literal>"
          else null;

      example =
        if option?example
        then
          if option.example?_type
          then formatText option.example
          else "<literal>${escapeXML (showVal option.example)}</literal>"
        else null;

    in ''
      <section>
        <title>${escapeXML option.name}</title>

        <table><tgroup><tbody>
          <row>
            <entry>Type:</entry>
            <entry>${option.type}</entry>
          </row>
          ${optionalString (default != null) ''
            <row>
              <entry>Default:</entry>
              <entry>${default}</entry>
            </row>
          ''}
          ${optionalString (example != null) ''
            <row>
              <entry>Example:</entry>
              <entry>${example}</entry>
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
