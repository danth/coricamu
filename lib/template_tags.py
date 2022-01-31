import re
import sys
from bs4 import BeautifulSoup
from bs4.element import PreformattedString


# argument 1: input HTML file
input_file_path = sys.argv[1]
# argument 2: output Nix file
output_file_path = sys.argv[2]


# Prevents Nix substitution code from being HTML-escaped
class NixSubstitution(PreformattedString):
    PREFIX = "${"
    SUFFIX = "}"


def string_to_nix(string):
    python_escaped_string = string.__repr__()[1:-1]
    nix_escaped_string = python_escaped_string.replace('"', '\\"')
    return '"' + nix_escaped_string + '"'


def dict_to_nix(dictionary):
    nix_string = "{ "

    for key, value in dictionary.items():
        nix_string += string_to_nix(key) + " = " + string_to_nix(value) + "; "

    nix_string += "}"
    return nix_string


with open(input_file_path, "r") as input_file:
    soup = BeautifulSoup(input_file, "html.parser")

for template_tag in soup.find_all(re.compile(r"^templates-\S+$")):
    template_name = template_tag.name.split("-")[1]

    template_args = template_tag.attrs.copy()

    if template_tag.contents:
        template_args["contents"] = "".join(map(str, template_tag.contents))

    template_tag.replace_with(NixSubstitution(
        "templates." + template_name + " " + dict_to_nix(template_args)
    ))

with open(output_file_path, "w") as output_file:
    output_file.write("templates: ''\n")
    output_file.write(str(soup).replace("''", "'''"))
    output_file.write("''\n")
