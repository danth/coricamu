extern crate kuchiki;
extern crate url;

use kuchiki::{parse_html, ElementData, NodeRef};
use kuchiki::traits::*;
use std::env;
use std::io;
use url::Url;

fn process_attribute(
    base_url: &Url,
    attribute_name: &str,
    element: &ElementData
) {
    let mut attrs = element.attributes.borrow_mut();
    if let Some(relative_url) = attrs.get_mut(attribute_name) {
        let absolute_url = base_url.join(relative_url)
            .expect("Parsing relative URL");

        eprintln!("{} + {} → {}", base_url, relative_url, absolute_url);

        relative_url.clear();
        relative_url.push_str(&absolute_url.to_string());
    }
}

fn process_node(base_url: &Url, node: &NodeRef) {
    if let Some(element) = node.as_element() {
        process_attribute(base_url, "src", element);
        process_attribute(base_url, "href", element);
    }

    for child in node.children() {
        process_node(base_url, &child);
    }
}

fn main() {
    // Get base URL from command line arguments
    let args: Vec<String> = env::args().collect();
    let base_url = Url::parse(&args[1]).expect("Parsing base URL");

    // Read and parse HTML from stdin
    let document = parse_html()
        .from_utf8()
        .read_from(&mut io::stdin().lock())
        .expect("Parsing input");

    // Absolutify URLs
    process_node(&base_url, &document);

    // Write modified HTML to stdout
    println!("{}", &document.to_string());
}
