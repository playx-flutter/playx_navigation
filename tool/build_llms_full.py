#!/usr/bin/env python3
"""Builds docs/llms-full.txt: the whole documentation as one plain-text file.

Run it before `mkdocs build` (the docs workflow does). Usage:

    python3 tool/build_llms_full.py
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DOCS = ROOT / "docs"

# Reading order for the combined file.
PAGES = [
    "index.md",
    "getting-started.md",
    "choosing-an-approach.md",
    "routes.md",
    "bindings.md",
    "page-configuration.md",
    "guards-and-redirects.md",
    "error-handling.md",
    "scopes.md",
    "controllers-and-views.md",
    "state-management-interop.md",
    "navigation-api.md",
    "web.md",
    "breadcrumbs.md",
    "testing.md",
    "migration.md",
    "troubleshooting.md",
]


def _block(lines, i, indent):
    """Collects the indented body that follows a block opener at index i - 1."""
    body = []
    while i < len(lines) and (lines[i].startswith(indent + "    ") or not lines[i].strip()):
        body.append(lines[i][len(indent) + 4:] if lines[i].strip() else "")
        i += 1
    while body and not body[-1]:
        body.pop()
    return body, i


def clean(text: str) -> str:
    """Turns MkDocs-specific syntax (admonitions, content tabs) into plain markdown."""
    out, lines, i = [], text.split("\n"), 0
    while i < len(lines):
        admonition = re.match(r'^(\s*)(!!!|\?\?\?)\s+(\w+)(?:\s+"([^"]*)")?\s*$', lines[i])
        tab = re.match(r'^(\s*)=== "([^"]+)"\s*$', lines[i])
        if admonition:
            indent, label = admonition.group(1), admonition.group(4) or admonition.group(3).capitalize()
            body, i = _block(lines, i + 1, indent)
            out.append(f"> **{label}:** " + (body[0] if body else ""))
            out.extend("> " + line if line else ">" for line in body[1:])
            out.append("")
        elif tab:
            indent, name = tab.group(1), tab.group(2)
            body, i = _block(lines, i + 1, indent)
            out.append(f"**{name}**")
            out.append("")
            out.extend(body)
            out.append("")
        else:
            out.append(lines[i])
            i += 1
    return "\n".join(out)


def main() -> None:
    header = (DOCS / "llms.txt").read_text().split("## Documentation")[0].rstrip()
    parts = [header, "\n---\n\nThe full documentation follows.\n"]
    for name in PAGES:
        text = clean((DOCS / name).read_text())
        parts.append(f"\n---\n\n<!-- {name} -->\n\n{text.strip()}\n")
    target = DOCS / "llms-full.txt"
    target.write_text("\n".join(parts))
    print(f"Wrote {target.relative_to(ROOT)} ({target.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    main()
