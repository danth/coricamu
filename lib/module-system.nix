{ coricamuLib, pkgsLib, ... }:

with coricamuLib;
with pkgsLib;

{
  makeOptionSection = option: ''
    <section>
      <title>${escapeXML option.name}</title>

      ${optionalString (option.description != null) ''
        <para>${option.description}</para>
      ''}

      <para>Type: ${option.type}</para>

      <para>Default: ${
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
              else option.defaultText
        else
          if option?default
          then "<literal>${escapeXML (showVal option.default)}</literal>"
          else "undefined"
      }</para>
    </section>
  '';

  makeOptionsPage = {
    options,
    showInvisible ? false,
    showInternal ? false
  }: ''
    <section>
      ${pipe options [
        optionAttrSetToDocList
        (filter (option:
          (option.visible || showInvisible) &&
          (!option.internal || showInternal)
        ))
        (map makeOptionSection)
        (concatStringsSep "\n")
      ]}
    </section>
  '';
}
