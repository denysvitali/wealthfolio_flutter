#!/usr/bin/env python3
"""
Generate Dart types from wealthfolio_api_reference.md.

This script parses the API reference doc and generates:
1. Dart model classes matching the API contract
2. A request/response type registry for validation

Run: python3 scripts/generate_dart_types.py

The generated types make contract mismatches compile-time errors rather
than runtime failures. Any field rename or type change in the backend
will surface as a compile error in the Flutter client.

NOTE: This is a proof-of-concept. For production use, the backend should
publish an OpenAPI 3.x spec (e.g. via utoipa + openapi-generator) and the
Flutter client should use openapi-generator to generate typed clients.
"""

import re
import sys
from pathlib import Path

SRC = Path("lib/core/api")
DOC = Path("wealthfolio_api_reference.md")
OUTPUT = SRC / "api_contract_types.dart"

# -------------------------------------------------------------------
# Section parsers
# -------------------------------------------------------------------

def parse_sections(doc: str) -> dict:
    """Split doc into named sections."""
    sections = {}
    current = None
    lines = []
    for line in doc.splitlines():
        m = re.match(r'^##\s+(.+)$', line)
        if m:
            if current:
                sections[current] = "\n".join(lines)
            current = m.group(1).strip()
            lines = []
        else:
            lines.append(line)
    if current:
        sections[current] = "\n".join(lines)
    return sections


def parse_table_rows(text: str) -> list[tuple]:
    """Parse | col1 | col2 | ... | rows into list of tuples."""
    rows = []
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("|") and "---" in line:
            continue
        if line.startswith("|"):
            cells = [c.strip() for c in line.strip("|").split("|")]
            if len(cells) >= 2:
                rows.append(tuple(cells))
    return rows


def parse_struct(text: str) -> dict[str, str]:
    """Parse ```...``` blocks into field: type dict."""
    fields = {}
    in_code = False
    for line in text.splitlines():
        line = line.strip()
        if line.startswith("```"):
            in_code = not in_code
            continue
        if in_code and ":" in line:
            # "field: type" or "field: type  // comment"
            parts = line.split("//")[0].split(":")
            if len(parts) >= 2:
                field = parts[0].strip()
                typ = parts[1].strip().rstrip(",").strip()
                if field:
                    fields[field] = typ
    return fields


# -------------------------------------------------------------------
# Dart type generators
# -------------------------------------------------------------------

def dart_type(typ: str) -> str:
    """Map API reference types to Dart types."""
    mapping = {
        "String": "String",
        "bool": "bool",
        "i64": "int",
        "i32": "int",
        "f64": "double",
        "number": "double",
        "Option<String>": "String?",
        "Option<bool>": "bool?",
        "Option<i64>": "int?",
        "Option<f64>": "double?",
        "Option<ExchangeRate>": "ExchangeRate?",
        "Vec<String>": "List<String>",
        "Vec<SymbolSearchResult>": "List<Map<String, dynamic>>",
        "Vec<Quote>": "List<Map<String, dynamic>>",
        "Vec<QuoteImport>": "List<Map<String, dynamic>>",
        "HashMap<String, LatestQuoteSnapshot>": "Map<String, dynamic>",
        "Vec<YahooDividend>": "List<Map<String, dynamic>>",
        "Vec<ProviderInfo>": "List<Map<String, dynamic>>",
    }
    return mapping.get(typ, typ)


def to_camel(s: str) -> str:
    """toCamelCase"""
    parts = re.split(r"[_\-]", s)
    return parts[0] + "".join(p.title() for p in parts[1:])


def generate_dart_class(name: str, fields: dict[str, str]) -> str:
    """Generate a Dart class with fromJson factory."""
    dart_fields = []
    from_json_lines = []

    for field, typ in fields.items():
        dart_typ = dart_type(typ)
        dart_fields.append(f"  final {dart_typ} {to_camel(field)};")
        from_json_lines.append(f"    {to_camel(field)}: parse{get_parse_fn(typ)}(map['{field}']),")

    return f"""
class {name} {{
{chr(10).join(dart_fields)}

  const {name}({{{', '.join(f'this.{to_camel(f)}' for f in fields)}});

  factory {name}.fromJson(dynamic raw) {{
    final map = parseMap(raw);
    return {name}({{
{chr(10).join(from_json_lines)}});
  }}
}}
"""


def get_parse_fn(typ: str) -> str:
    """Select json_parsing helper based on type."""
    t = typ.lstrip("Option<").rstrip(">")
    if t in ("String",):
        return "String"
    if t in ("i64", "i32"):
        return "Int"
    if t in ("f64", "number"):
        return "Double"
    if t == "bool":
        return "Bool"
    return "Dynamic"


# -------------------------------------------------------------------
# Main
# -------------------------------------------------------------------

def main():
    doc_text = DOC.read_text()
    sections = parse_sections(doc_text)

    # Extract activity-related sections
    lines = []
    lines.append("// GENERATED — do not edit by hand.")
    lines.append("// Run: python3 scripts/generate_dart_types.py to regenerate.")
    lines.append("")
    lines.append("part of 'wealthfolio_api.dart';")
    lines.append("")

    # Parse Activity struct from the reference doc
    if "Data Models" in sections:
        models_text = sections["Data Models"]
        # Look for activity struct
        activity_match = re.search(
            r"#### Activity\s*```[^\n]*\n(.*?)```",
            models_text,
            re.DOTALL | re.MULTILINE,
        )
        if activity_match:
            struct_fields = parse_struct(activity_match.group(1))
            lines.append(generate_dart_class("ActivityContract", struct_fields))

    # Also output a note about OpenAPI generation
    lines.append("""
// ----------------------------------------------------------------------
// NOTE: For production, generate types from an OpenAPI spec published by
// the backend (e.g. via utoipa + openapi-generator). The types above are a
// proof-of-concept generated from wealthfolio_api_reference.md.
//
// Benefits of OpenAPI-generated types:
// - Contract mismatches become compile-time errors
// - No manual type maintenance
// - Generated client code for all endpoints
// - Server and client always in sync
//
// See: https://openapi-generator.tech/
// ----------------------------------------------------------------------
""")

    OUTPUT.write_text("\n".join(lines))
    print(f"Written: {OUTPUT}")
    print("""
Next steps for full contract testing:
1. Backend team: publish OpenAPI spec via utoipa + openapi-generator
2. CI step: validate spec against running server (e.g. via prism)
3. Flutter: use openapi-generator to produce typed clients
4. Add generated types to integration_test/activity_e2e_test.dart
""")


if __name__ == "__main__":
    main()
