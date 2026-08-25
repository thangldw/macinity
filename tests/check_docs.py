#!/usr/bin/env python3
"""Validate the trilingual Markdown and repository-local link contract."""

import argparse
from html.parser import HTMLParser
from pathlib import Path
import re
import sys
import unicodedata
import urllib.parse


LANGUAGE_HEADINGS = ("## English", "## Tiếng Việt", "## 日本語")
EXTERNAL_SCHEMES = ("http://", "https://", "mailto:")
LINK_RE = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")
HEADING_RE = re.compile(r"^(#{1,6})[ \t]+(.+?)[ \t]*#*[ \t]*$", re.MULTILINE)
LIST_ITEM_RE = re.compile(r"^[ \t]*(?:[-*+]|[0-9]+[.)])[ \t]+", re.MULTILINE)
SUBHEADING_RE = re.compile(r"^#{3,6}[ \t]+", re.MULTILINE)
TABLE_ROW_RE = re.compile(r"^[ \t]*\|.*\|[ \t]*$", re.MULTILINE)
FENCE_RE = re.compile(r"^[ \t]*(?:```|~~~)", re.MULTILINE)
MIN_PARITY_PERCENT = 60


class IDParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.identifiers: set[str] = set()

    def handle_starttag(self, _tag: str, attrs: list[tuple[str, str | None]]) -> None:
        attributes = {name: value or "" for name, value in attrs}
        for attribute in ("id", "name"):
            if attributes.get(attribute):
                self.identifiers.add(attributes[attribute])


def report(path: Path, message: str) -> None:
    print(f"{path}: {message}")


def is_within(path: Path, root: Path) -> bool:
    try:
        path.relative_to(root)
    except ValueError:
        return False
    return True


def meaningful_lines(section: str) -> int:
    return sum(bool(line.strip()) for line in section.splitlines())


def structural_signature(section: str) -> tuple[int, int, int, int]:
    return (
        len(SUBHEADING_RE.findall(section)),
        len(LIST_ITEM_RE.findall(section)),
        len(TABLE_ROW_RE.findall(section)),
        len(FENCE_RE.findall(section)),
    )


def check_languages(_path: Path, text: str) -> list[str]:
    errors: list[str] = []
    matches_by_heading: list[re.Match[str] | None] = []
    for heading in LANGUAGE_HEADINGS:
        matches = list(re.finditer(rf"^{re.escape(heading)}\s*$", text, re.MULTILINE))
        if len(matches) != 1:
            errors.append(f"must contain exactly one {heading!r} heading")
            matches_by_heading.append(None)
            continue
        matches_by_heading.append(matches[0])

    if any(match is None for match in matches_by_heading):
        return errors

    language_matches = [match for match in matches_by_heading if match is not None]
    positions = [match.start() for match in language_matches]
    if positions != sorted(positions):
        errors.append("language headings must appear in English, Vietnamese, Japanese order")
        return errors

    sections = [
        text[language_matches[index].end() : language_matches[index + 1].start()]
        if index + 1 < len(language_matches)
        else text[language_matches[index].end() :]
        for index in range(len(language_matches))
    ]
    names = ("English", "Tiếng Việt", "日本語")
    line_counts = [meaningful_lines(section) for section in sections]
    for name, count in zip(names, line_counts):
        if count == 0:
            errors.append(f"{name} section must not be empty")

    english_lines = line_counts[0]
    english_structure = structural_signature(sections[0])
    if english_lines:
        for name, section, count in zip(names[1:], sections[1:], line_counts[1:]):
            if count * 100 < english_lines * MIN_PARITY_PERCENT:
                errors.append(
                    f"{name} section is grossly condensed relative to English "
                    f"({count} vs {english_lines} meaningful lines; minimum {MIN_PARITY_PERCENT}%)"
                )
            if structural_signature(section) != english_structure:
                errors.append(
                    f"{name} section lacks structural parity with English "
                    "(headings, list items, table rows, or code fences differ); "
                    "translation quality still requires human review"
                )
    return errors


def markdown_slug(label: str) -> str:
    label = re.sub(r"<[^>]+>", "", label)
    label = re.sub(r"!?\[([^\]]+)\]\([^)]+\)", r"\1", label)
    label = re.sub(r"[`*_~]", "", label).strip().casefold()
    characters = [
        character
        for character in label
        if character in {"-", "_", " "}
        or unicodedata.category(character)[0] in {"L", "M", "N"}
    ]
    return re.sub(r"\s+", "-", "".join(characters))


def markdown_anchors(text: str) -> set[str]:
    anchors: set[str] = set()
    counts: dict[str, int] = {}
    for match in HEADING_RE.finditer(text):
        base = markdown_slug(match.group(2))
        if not base:
            continue
        duplicate = counts.get(base, 0)
        anchors.add(base if duplicate == 0 else f"{base}-{duplicate}")
        counts[base] = duplicate + 1

    parser = IDParser()
    parser.feed(text)
    parser.close()
    anchors.update(parser.identifiers)
    return anchors


def html_anchors(text: str) -> set[str]:
    parser = IDParser()
    parser.feed(text)
    parser.close()
    return parser.identifiers


def check_fragment(destination: Path, fragment: str, raw_target: str) -> list[str]:
    decoded = urllib.parse.unquote(fragment)
    suffix = destination.suffix.casefold()
    source = destination.read_text(encoding="utf-8")
    if suffix in {".md", ".markdown"}:
        if decoded not in markdown_anchors(source):
            return [f"local Markdown fragment does not resolve: {raw_target}"]
    elif suffix in {".html", ".htm"}:
        if decoded not in html_anchors(source):
            return [f"local HTML fragment does not resolve: {raw_target}"]
    return []


def check_link(path: Path, raw_target: str, root: Path) -> list[str]:
    target = raw_target.strip()
    if target.startswith(EXTERNAL_SCHEMES):
        return []

    parsed = urllib.parse.urlsplit(target.strip("<>"))
    if parsed.scheme in {"http", "https", "mailto"}:
        return []

    link_path = urllib.parse.unquote(parsed.path)
    if Path(link_path).is_absolute() or parsed.scheme == "file":
        return [f"absolute local link is not allowed: {raw_target}"]

    destination = path if not link_path else (path.parent / link_path).resolve()
    if not is_within(destination, root):
        return [f"link escapes repository: {raw_target}"]
    if not destination.exists():
        return [f"local link target does not exist: {raw_target}"]
    if parsed.fragment:
        return check_fragment(destination, parsed.fragment, raw_target)
    return []


def check_file(path_argument: str, root: Path) -> int:
    path = Path(path_argument)
    if not path.is_absolute():
        path = root / path
    path = path.resolve()
    display_path = path.relative_to(root) if is_within(path, root) else path
    if not path.is_file():
        report(display_path, "Markdown file does not exist")
        return 1

    text = path.read_text(encoding="utf-8")
    failures = check_languages(path, text)
    for match in LINK_RE.finditer(text):
        failures.extend(check_link(path, match.group(1), root))

    for failure in failures:
        report(display_path, failure)
    return int(bool(failures))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("markdown", nargs="+", help="repository-relative Markdown paths")
    arguments = parser.parse_args()
    root = Path.cwd().resolve()
    failed = False
    for path in arguments.markdown:
        failed = bool(check_file(path, root)) or failed
    return int(failed)


if __name__ == "__main__":
    sys.exit(main())
