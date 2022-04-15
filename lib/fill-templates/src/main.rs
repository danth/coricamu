extern crate kuchiki;

use kuchiki::{parse_html, NodeRef};
use kuchiki::traits::*;
use std::io;

fn escape_nix_string(content: &str) -> String {
    // A multiline string is used as it only has two things to escape.
    let content = content.replace("''", "'''");
    let content = content.replace("${", "''${");
    return content;
}

fn call_template(
    template_calls: &mut Vec<String>,
    template_name: &str,
    template_arguments: &str
) -> String {
    let template_number = template_calls.len();
    let template_call = format!("templates.{} {}", template_name, template_arguments);
    template_calls.push(template_call);
    format!("${{template{}}}", template_number)
}

fn serialize_template_calls(template_calls: &[String]) -> String {
    template_calls.iter().enumerate()
        .map(|(i, c)| format!("template{} = {};", i, c))
        .fold(String::new(), |a, b| a + &b + "\n")
}

fn process_node(template_calls: &mut Vec<String>, node: &NodeRef) {
    if let Some(element) = node.as_element() {
        let name = element.name.local.to_string();
        if let Some(template_name) = name.strip_prefix("templates-") {
            let mut template_arguments = String::from("{");

            // Add content to the template arguments
            let mut content_string = "".to_string();

            for child in node.children() {
                content_string.push_str(&child.to_string());
            }
            if !content_string.trim().is_empty() {
                let content_string = escape_nix_string(&content_string);
                let content_argument = format!("contents = ''{}'';", content_string);
                template_arguments.push_str(&content_argument);
            }

            // Add attributes to the template arguments
            for (attribute_name, attribute)
            in &element.attributes.borrow().map {
                let attribute_name = attribute_name.local.to_string();
                let attribute_value = escape_nix_string(&attribute.value);
                let argument = format!("{} = ''{}'';", attribute_name, attribute_value);
                template_arguments.push_str(&argument);
            }

            template_arguments.push('}');

            let splice = call_template(
                template_calls, template_name, &template_arguments
            );
            let splice = NodeRef::new_text(splice);
            node.insert_after(splice);
            node.detach();
            return;
        }
    }

    if let Some(text) = node.as_text() {
        let escaped_text = escape_nix_string(&text.take());
        let escaped_node = NodeRef::new_text(escaped_text);
        node.insert_after(escaped_node);
        node.detach();
        return;
    }

    for child in node.children() {
        process_node(template_calls, &child);
    }
}

fn main() {
    // Read and parse HTML from stdin
    let document = parse_html()
        .from_utf8()
        .read_from(&mut io::stdin().lock())
        .expect("Parsing input");

    // Fill templates
    let mut template_calls = Vec::new();
    process_node(&mut template_calls, &document);

    // Write Nix code to stdout
    println!("templates:");
    if !template_calls.is_empty() {
        println!("let {} in", serialize_template_calls(&template_calls));
    }
    println!("''{}''", &document.to_string());
}
