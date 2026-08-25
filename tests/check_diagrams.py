#!/usr/bin/env python3
"""Validate self-contained accessible Toolbox documentation diagrams."""

import argparse
from html.parser import HTMLParser
from pathlib import Path
import re
import sys


class DiagramParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.errors: list[str] = []
        self.svg_count = 0
        self.svg_depth = 0
        self.first_svg_child: str | None = None
        self.svg_attributes: dict[str, str] = {}
        self.ids: list[str] = []
        self.title_text: list[str] = []
        self.desc_text: list[str] = []
        self.in_title = 0
        self.in_desc = 0

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        attributes = {name: value or "" for name, value in attrs}
        if tag == "script":
            self.errors.append("script elements are not allowed")
        if tag.startswith("animate") or tag == "set":
            self.errors.append(f"animation element is not allowed: {tag}")
        if tag in {"img", "image"}:
            for attribute in ("src", "href", "xlink:href"):
                source = attributes.get(attribute, "")
                if source.startswith(("http://", "https://", "//")):
                    self.errors.append(f"external {tag} source is not allowed: {source}")

        if tag == "svg":
            self.svg_count += 1
            self.svg_depth += 1
            if self.svg_depth == 1:
                self.svg_attributes = attributes
                identifier = attributes.get("id")
                if identifier:
                    self.ids.append(identifier)
            return

        if self.svg_depth:
            if self.svg_depth == 1 and self.first_svg_child is None:
                self.first_svg_child = tag
            identifier = attributes.get("id")
            if identifier:
                self.ids.append(identifier)
            if tag == "title":
                self.in_title += 1
            elif tag == "desc":
                self.in_desc += 1

    def handle_endtag(self, tag: str) -> None:
        if tag == "title" and self.in_title:
            self.in_title -= 1
        elif tag == "desc" and self.in_desc:
            self.in_desc -= 1
        elif tag == "svg" and self.svg_depth:
            self.svg_depth -= 1

    def handle_data(self, data: str) -> None:
        if self.in_title:
            self.title_text.append(data)
        if self.in_desc:
            self.desc_text.append(data)


def check_file(path: Path) -> int:
    if not path.is_file():
        print(f"{path}: HTML file does not exist")
        return 1

    source = path.read_text(encoding="utf-8")
    parser = DiagramParser()
    parser.feed(source)
    parser.close()
    errors = parser.errors.copy()

    if "writing-mode" in source.lower():
        errors.append("writing-mode is not allowed")
    if "jetbrains mono" in source.lower():
        errors.append("JetBrains Mono is not allowed")
    if re.search(r"@(?:-[\w]+-)?keyframes\b|\banimation(?:-[\w-]+)?\s*:", source, re.IGNORECASE):
        errors.append("CSS animation is not allowed")
    if parser.svg_count != 1:
        errors.append("document must contain exactly one SVG")
    if parser.svg_attributes.get("role") != "img":
        errors.append("SVG must have role=img")
    if parser.svg_attributes.get("viewbox") != "0 0 1280 720":
        errors.append("SVG must have viewBox '0 0 1280 720'")
    if parser.first_svg_child != "title":
        errors.append("the first SVG child must be title")
    if not "".join(parser.title_text).strip():
        errors.append("SVG title must not be empty")
    if not "".join(parser.desc_text).strip():
        errors.append("SVG desc must not be empty")

    prefix = f"{path.stem}-"
    if len(parser.ids) != len(set(parser.ids)):
        errors.append("SVG IDs must be unique")
    invalid_ids = [identifier for identifier in parser.ids if not identifier.startswith(prefix)]
    if invalid_ids:
        errors.append(f"SVG IDs must start with {prefix!r}: {', '.join(invalid_ids)}")
    aria_ids = parser.svg_attributes.get("aria-labelledby", "").split()
    if not aria_ids:
        errors.append("SVG must define aria-labelledby")
    else:
        unresolved = [identifier for identifier in aria_ids if identifier not in parser.ids]
        if unresolved:
            errors.append(f"aria-labelledby IDs do not resolve: {', '.join(unresolved)}")

    for error in errors:
        print(f"{path}: {error}")
    return int(bool(errors))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("html", nargs="+", help="HTML diagram paths")
    arguments = parser.parse_args()
    failed = False
    for path in arguments.html:
        failed = bool(check_file(Path(path))) or failed
    return int(failed)


if __name__ == "__main__":
    sys.exit(main())
