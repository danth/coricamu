extern crate kuchiki;

use kuchiki::{parse_html, NodeRef};
use kuchiki::traits::*;
use std::collections::HashSet;
use std::io;

fn escape_nix_string(content: &str) -> String {
    // A multiline string is used as it only has two things to escape.
    content.replace("''", "'''").replace("${", "''${")
}

fn call_template(
    template_calls: &mut Vec<String>,
    template_name: &str,
    template_arguments: &str
) -> String {
    let template_number = template_calls.len();
    let template_call = format!(
        "templates.{}.function {}",
        template_name, template_arguments
    );
    template_calls.push(template_call);
    format!("${{template{}}}", template_number)
}

fn process_node(
    used_templates: &mut HashSet<String>,
    template_calls: &mut Vec<String>,
    node: &NodeRef
) {
    if let Some(element) = node.as_element() {
        let name = element.name.local.to_string();
        if let Some(template_name) = name.strip_prefix("templates-") {
            used_templates.insert(template_name.to_string());

            let mut template_arguments = String::from("{\n");

            // Add content to the template arguments
            let mut content_string = "".to_string();

            for child in node.children() {
                content_string.push_str(&child.to_string());
            }
            if !content_string.trim().is_empty() {
                let content_string = escape_nix_string(&content_string);
                let content_argument = format!("contents = ''{}'';\n", content_string);
                template_arguments.push_str(&content_argument);
            }

            // Add attributes to the template arguments
            for (attribute_name, attribute)
            in &element.attributes.borrow().map {
                let attribute_name = attribute_name.local.to_string();
                let attribute_value = escape_nix_string(&attribute.value);
                let argument = format!("{} = ''{}'';\n", attribute_name, attribute_value);
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

        for attribute in element.attributes.borrow_mut().map.values_mut() {
            let escaped_value = escape_nix_string(&attribute.value);
            attribute.value.clear();
            attribute.value.push_str(&escaped_value);
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
        process_node(used_templates, template_calls, &child);
    }
}

fn main() {
    // Read and parse HTML from stdin
    let document = parse_html()
        .from_utf8()
        .read_from(&mut io::stdin().lock())
        .expect("Parsing input")
        // The input is automatically wrapped in <html>, which we don't want
        .children()
        .next()
        .expect("Selecting document body");

    // Fill templates
    let mut used_templates = HashSet::new();
    let mut template_calls = Vec::new();
    process_node(&mut used_templates, &mut template_calls, &document);

    // Write Nix code to stdout
    println!("templates:");
    if !template_calls.is_empty() {
        println!("let");
        for (template_number, template_call) in template_calls.iter().enumerate() {
            println!("template{} = {};", &template_number, &template_call);
        }
        println!("in {{");
    } else {
        println!("{{");
    }
    print!("usedTemplates = [");
    for template_name in &used_templates {
        print!("templates.{} ", &template_name);
    }
    println!("];");
    println!("body = ''{}'';", &document.to_string());
    println!("}}");
}
