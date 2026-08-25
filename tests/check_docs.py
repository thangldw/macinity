#!/usr/bin/env python3
"""Validate the trilingual Markdown and repository-local link contract."""

import argparse
from pathlib import Path
import re
import sys
import urllib.parse


LANGUAGE_HEADINGS = ("## English", "## Tiếng Việt", "## 日本語")
EXTERNAL_SCHEMES = ("http://", "https://", "mailto:")
LINK_RE = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")


def report(path: Path, message: str) -> None:
    print(f"{path}: {message}")


def is_within(path: Path, root: Path) -> bool:
    try:
        path.relative_to(root)
    except ValueError:
        return False
    return True


def check_languages(path: Path, text: str) -> list[str]:
    errors: list[str] = []
    positions: list[int] = []
    for heading in LANGUAGE_HEADINGS:
        matches = list(re.finditer(rf"^{re.escape(heading)}\s*$", text, re.MULTILINE))
        if len(matches) != 1:
            errors.append(f"must contain exactly one {heading!r} heading")
            continue
        positions.append(matches[0].start())

    if len(positions) == len(LANGUAGE_HEADINGS) and positions != sorted(positions):
        errors.append("language headings must appear in English, Vietnamese, Japanese order")
    return errors


def check_link(path: Path, raw_target: str, root: Path) -> list[str]:
    target = raw_target.strip()
    if target.startswith(EXTERNAL_SCHEMES):
        return []

    parsed = urllib.parse.urlsplit(target.strip("<>"))
    if parsed.scheme in {"http", "https", "mailto"}:
        return []

    link_path = urllib.parse.unquote(parsed.path)
    if not link_path:
        return []
    if Path(link_path).is_absolute() or parsed.scheme == "file":
        return [f"absolute local link is not allowed: {raw_target}"]

    destination = (path.parent / link_path).resolve()
    if not is_within(destination, root):
        return [f"link escapes repository: {raw_target}"]
    if not destination.exists():
        return [f"local link target does not exist: {raw_target}"]
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
