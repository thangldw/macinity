#!/usr/bin/env python3
"""Exercise documentation checkers against controlled regression fixtures."""

from pathlib import Path
import shutil
import subprocess
import sys
import tempfile


REPO_ROOT = Path(__file__).resolve().parents[1]
FIXTURE_ROOT = REPO_ROOT / "tests" / "fixtures"
CHECK_DOCS = REPO_ROOT / "tests" / "check_docs.py"
CHECK_DIAGRAMS = REPO_ROOT / "tests" / "check_diagrams.py"
DOCUMENTATION_CONTRACT = REPO_ROOT / "tests" / "documentation_contract.sh"


def run(command: list[str], cwd: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(command, cwd=cwd, text=True, capture_output=True, check=False)


def output_of(result: subprocess.CompletedProcess[str]) -> str:
    return result.stdout + result.stderr


def expect(
    name: str,
    result: subprocess.CompletedProcess[str],
    *,
    accepted: bool,
    diagnostic: str | None = None,
) -> bool:
    output = output_of(result)
    if accepted and result.returncode != 0:
        print(f"FAIL {name}: valid fixture was rejected\n{output}", end="")
        return False
    if not accepted and result.returncode == 0:
        print(f"BYPASS {name}: invalid fixture was accepted")
        return False
    if diagnostic is not None and diagnostic not in output:
        print(f"FAIL {name}: missing diagnostic {diagnostic!r}\n{output}", end="")
        return False
    print(f"PASS {name}")
    return True


def materialize_fixture(source: Path, destination: Path) -> None:
    for fixture in source.rglob("*.fixture"):
        relative = fixture.relative_to(source)
        target = destination / relative.with_suffix("")
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(fixture, target)


def check_docs_cases() -> list[bool]:
    cases = [
        ("valid-unicode-anchors", True, None),
        ("empty-english", False, "English section must not be empty"),
        ("empty-vietnamese", False, "Tiếng Việt section must not be empty"),
        ("empty-japanese", False, "日本語 section must not be empty"),
        ("missing-markdown-fragment", False, "Markdown fragment does not resolve"),
        ("missing-html-fragment", False, "HTML fragment does not resolve"),
        ("condensed-vietnamese", False, "Tiếng Việt section is grossly condensed"),
        ("condensed-japanese", False, "日本語 section is grossly condensed"),
    ]
    outcomes: list[bool] = []
    for name, accepted, diagnostic in cases:
        with tempfile.TemporaryDirectory(prefix=f"toolbox-check-docs-{name}-") as temporary:
            root = Path(temporary)
            materialize_fixture(FIXTURE_ROOT / "check_docs" / name, root)
            result = run([sys.executable, str(CHECK_DOCS), "document.md"], root)
            outcomes.append(
                expect(
                    f"check_docs/{name}", result, accepted=accepted, diagnostic=diagnostic
                )
            )
    return outcomes


def replace_once(source: str, old: str, new: str) -> str:
    if source.count(old) != 1:
        raise AssertionError(f"fixture mutation target must occur once: {old!r}")
    return source.replace(old, new, 1)


def check_diagram_cases() -> list[bool]:
    base = (FIXTURE_ROOT / "check_diagrams" / "valid.html.fixture").read_text(encoding="utf-8")
    mutations = [
        ("valid", None, True, None),
        ("missing-profile", ("profile: thangldw", "profile: default"), False, "profile: thangldw"),
        (
            "missing-interpretation-container",
            ('class="interpretation"', 'class="summary"'),
            False,
            "trilingual interpretation container",
        ),
        ("missing-english", ("<h2>English</h2>", "<h2>Overview</h2>"), False, "English"),
        (
            "missing-vietnamese",
            ("<h2>Tiếng Việt</h2>", "<h2>Vietnamese</h2>"),
            False,
            "Tiếng Việt",
        ),
        ("missing-japanese", ("<h2>日本語</h2>", "<h2>Japanese</h2>"), False, "日本語"),
        (
            "missing-english-content",
            ("<dd>English content meaning.</dd>", "<dd> </dd>"),
            False,
            "English interpretation must include non-empty Content meaning",
        ),
        (
            "missing-vietnamese-exclusions",
            ("<dd>Nội dung loại trừ.</dd>", "<dd> </dd>"),
            False,
            "Tiếng Việt interpretation must include non-empty Exclusions meaning",
        ),
        (
            "missing-japanese-safety",
            ("<dd>安全境界の意味。</dd>", "<dd> </dd>"),
            False,
            "日本語 interpretation must include non-empty Safety boundary meaning",
        ),
    ]
    outcomes: list[bool] = []
    for name, mutation, accepted, diagnostic in mutations:
        source = base if mutation is None else replace_once(base, *mutation)
        with tempfile.TemporaryDirectory(prefix=f"toolbox-check-diagram-{name}-") as temporary:
            root = Path(temporary)
            diagram = root / "diagram.html"
            diagram.write_text(source, encoding="utf-8")
            result = run([sys.executable, str(CHECK_DIAGRAMS), str(diagram)], root)
            outcomes.append(
                expect(
                    f"check_diagrams/{name}", result, accepted=accepted, diagnostic=diagnostic
                )
            )
    return outcomes


def copy_tracked_markdown(destination: Path) -> None:
    files = run(
        ["git", "ls-files", "*.md", "LICENSE", "docs/diagrams/*.html"], REPO_ROOT
    )
    if files.returncode != 0:
        raise RuntimeError(output_of(files))
    for relative_text in files.stdout.splitlines():
        relative = Path(relative_text)
        target = destination / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(REPO_ROOT / relative, target)
    run(["git", "init", "-q"], destination)
    add = run(["git", "add", "."], destination)
    if add.returncode != 0:
        raise RuntimeError(output_of(add))


def inject_preamble(path: Path, fixture_name: str) -> None:
    snippet = (FIXTURE_ROOT / "documentation_contract" / fixture_name).read_text(
        encoding="utf-8"
    ).strip()
    source = path.read_text(encoding="utf-8")
    first_break = source.find("\n")
    if first_break < 0:
        raise AssertionError(f"fixture target has no title line: {path}")
    path.write_text(source[:first_break] + f"\n\n{snippet}" + source[first_break:], encoding="utf-8")


def contract_case(
    name: str,
    *,
    target: str | None = None,
    fixture: str | None = None,
    accepted: bool,
    diagnostic: str | None = None,
) -> bool:
    with tempfile.TemporaryDirectory(prefix=f"toolbox-doc-contract-{name}-") as temporary:
        root = Path(temporary)
        copy_tracked_markdown(root)
        if target is not None and fixture is not None:
            inject_preamble(root / target, fixture)
            add = run(["git", "add", target], root)
            if add.returncode != 0:
                raise RuntimeError(output_of(add))
        result = run(["bash", str(DOCUMENTATION_CONTRACT), str(root)], REPO_ROOT)
        return expect(
            f"documentation_contract/{name}",
            result,
            accepted=accepted,
            diagnostic=diagnostic,
        )


def documentation_contract_cases() -> list[bool]:
    return [
        contract_case(name="valid-repository", accepted=True),
        contract_case(name="allows-documented-plan-rename", accepted=True),
        contract_case(
            name="allows-explicitly-historical-launch-claim",
            target="docs/launch/toolbox-2.0.0-beta.1.md",
            fixture="stale-current-launch.fixture",
            accepted=True,
        ),
        contract_case(
            name="rejects-unchecked-ordered-item",
            target="docs/superpowers/plans/2026-08-25-toolbox-foundation-plan.md",
            fixture="unchecked-ordered.fixture",
            accepted=False,
            diagnostic="unchecked checklist item",
        ),
        contract_case(
            name="rejects-stale-current-launch",
            target="README.md",
            fixture="stale-current-launch.fixture",
            accepted=False,
            diagnostic="stale authoritative current claim",
        ),
        contract_case(
            name="rejects-stale-current-release",
            target="README.md",
            fixture="stale-current-release.fixture",
            accepted=False,
            diagnostic="stale authoritative current claim",
        ),
        contract_case(
            name="rejects-stale-current-trust",
            target="README.md",
            fixture="stale-current-trust.fixture",
            accepted=False,
            diagnostic="stale authoritative current claim",
        ),
        contract_case(
            name="rejects-stale-plan-prose",
            target="docs/superpowers/plans/2026-08-26-toolbox-documentation-redesign-plan.md",
            fixture="stale-current-launch.fixture",
            accepted=False,
            diagnostic="stale authoritative current claim",
        ),
        contract_case(
            name="rejects-removed-beta-evidence-path",
            target="README.md",
            fixture="removed-beta-path.fixture",
            accepted=False,
            diagnostic="removed beta evidence path",
        ),
        contract_case(
            name="rejects-plan-beta-path-outside-rename",
            target="docs/superpowers/plans/2026-08-26-toolbox-documentation-redesign-plan.md",
            fixture="removed-beta-path.fixture",
            accepted=False,
            diagnostic="allowed only in the documented rename instruction",
        ),
    ]


def main() -> int:
    outcomes = check_docs_cases() + check_diagram_cases() + documentation_contract_cases()
    if all(outcomes):
        print("PASS: checker regression fixtures")
        return 0
    print(f"FAIL: {sum(not outcome for outcome in outcomes)} checker regression fixture(s)")
    return 1


if __name__ == "__main__":
    sys.exit(main())
