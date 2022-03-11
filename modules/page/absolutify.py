import sys
from bs4 import BeautifulSoup
from urllib.parse import urljoin


# argument 1: input HTML file
input_file_path = sys.argv[1]
# argument 2: output Nix file
output_file_path = sys.argv[2]
# argument 3: base URL for relative links
current_url = sys.argv[3]


def set_base_url(tag, attribute):
    """
    If the attribute value is absolute (https://example.com/), it is not changed
    Otherwise, the base URL is prepended to create an absolute path
    """

    original_url = tag.attrs[attribute]
    new_url = urljoin(current_url, original_url)
    tag.attrs[attribute] = new_url

    print(current_url, "+", original_url, "→", new_url)


with open(input_file_path, "r") as input_file:
    soup = BeautifulSoup(input_file, "html.parser")

for attribute in [ "src", "href" ]:
    for tag in soup.find_all(attrs={ attribute: True }):
        set_base_url(tag, attribute)

with open(output_file_path, "w") as output_file:
    output_file.write(str(soup))
