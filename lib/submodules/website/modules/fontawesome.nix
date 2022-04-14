{
  templates.font-awesome =
    { style ? "regular", icon }:
    "<svg class=\"font-awesome\"><use href=\"/fontawesome/${style}.svg#${icon}\"></use></svg>";
}
