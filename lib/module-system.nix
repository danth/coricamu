{ coricamuLib, pkgsLib, ... }:

with coricamuLib;
with pkgsLib;

{
  makeOptionDocBook =
    option:
    let
      default =
        if option?defaultText
        then
          if isString option.defaultText
          then option.defaultText
          else
            if option.defaultText._type == "literalDocBook"
            then option.defaultText.text
            else
              if option.defaultText._type == "literalExpression"
              then "<literal>${escapeXML (option.defaultText.text)}</literal>"
              else throw "Text type ${option.defaultText._type} is not implemented"
        else
          if option?default
          then "<literal>${escapeXML (showVal option.default)}</literal>"
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
