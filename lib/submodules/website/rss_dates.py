import sys
from bs4 import BeautifulSoup
from dateutil.parser import isoparse


# argument 1: input XML file
input_file_path = sys.argv[1]
# argument 2: output XML file
output_file_path = sys.argv[2]


def reformat_date(tag):
    """Change the date within the given tag from ISO format to RFC-822 format."""

    date = isoparse(tag.string)

    # RFC-822 requires that day and month names are in the US locale.
    # This is the Python default and cannot change due to Nix's sandboxing.
    tag.string = date.strftime(f"%a, %d %b %Y %H:%M:%S %z")


with open(input_file_path, "r") as input_file:
    soup = BeautifulSoup(input_file, "xml")

for tag in soup.find_all("pubDate"):
    reformat_date(tag)

with open(output_file_path, "w") as output_file:
    output_file.write(str(soup))
