{
  templates.font-awesome =
    { style ? "regular", icon, contents ? null }:
    if contents == null
    then ''
      <svg class="font-awesome">
        <use href="/fontawesome/${style}.svg#${icon}"></use>
      </svg>
    ''
    else ''
      <div class="font-awesome-box">
        <svg class="font-awesome">
          <use href="/fontawesome/${style}.svg#${icon}"></use>
        </svg>
        <div>${contents}</div>
      </div>
    '';
}
