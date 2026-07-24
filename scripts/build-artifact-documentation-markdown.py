#!/usr/bin/env python3
"""Build one copy-friendly Markdown document for the HotCRP submission."""

from pathlib import Path
import re
import textwrap


ROOT = Path(__file__).resolve().parent.parent
OUTPUT = ROOT / "output" / "artifact-documentation.md"
SOURCES = (
    ROOT / "Artifact-Evaluation.md",
    ROOT / "Artifact-Evaluation-Checker.md",
    ROOT / "Artifact-Evaluation-Rocq.md",
    ROOT / "REUSABILITY.md",
)
INTERNAL_LINKS = {
    "Artifact-Evaluation.md": "#artifact-evaluation-guide",
    "Artifact-Evaluation-Checker.md": (
        "#pico-checker-framework-artifact-evaluation-guide"
    ),
    "Artifact-Evaluation-Rocq.md": "#rocq-artifact-evaluation-guide",
    "REUSABILITY.md": "#reusing-and-extending-the-pico-artifact",
}


def wrap_markdown(text: str, width: int = 88) -> str:
    """Wrap prose while preserving fenced code, tables, and headings."""
    result = []
    in_fence = False
    for line in text.splitlines():
        stripped = line.lstrip()
        if stripped.startswith(("```", "~~~")):
            in_fence = not in_fence
            result.append(line)
            continue
        if (
            in_fence
            or len(line) <= width
            or stripped.startswith(("#", "|", "<", "---"))
            or len(line) - len(stripped) >= 4
        ):
            result.append(line)
            continue

        marker = re.match(r"^(\s*(?:[-+*]|\d+\.)\s+)", line)
        subsequent_indent = " " * len(marker.group(1)) if marker else ""
        result.extend(
            textwrap.wrap(
                line,
                width=width,
                subsequent_indent=subsequent_indent,
                break_long_words=False,
                break_on_hyphens=False,
                replace_whitespace=False,
                drop_whitespace=True,
            )
        )
    return "\n".join(result)


def prepare_source(path: Path) -> str:
    """Demote headings and turn links between included guides into anchors."""
    lines = []
    in_fence = False
    for line in path.read_text(encoding="utf-8").rstrip().splitlines():
        if line.lstrip().startswith(("```", "~~~")):
            in_fence = not in_fence
        elif not in_fence:
            line = re.sub(r"^(#{1,5})(?=\s)", r"#\1", line)
        lines.append(line)
    text = "\n".join(lines)
    for filename, anchor in INTERNAL_LINKS.items():
        text = text.replace(f"]({filename})", f"]({anchor})")
    return wrap_markdown(text)


def main() -> None:
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    sections = [prepare_source(path) for path in SOURCES]
    preamble = """# Artifact Documentation

This document contains the complete kick-the-tires, evaluation, and reusability
instructions for the artifact accompanying **Transitive, Abstract, and Class
Polymorphic Immutability**. Start with the Artifact Evaluation Guide and follow
the detailed Checker Framework or Rocq guide when directed.

- [Artifact Evaluation Guide](#artifact-evaluation-guide)
- [PICO Checker Framework guide](#pico-checker-framework-artifact-evaluation-guide)
- [Rocq Artifact Evaluation Guide](#rocq-artifact-evaluation-guide)
- [Reusing and extending the PICO artifact](#reusing-and-extending-the-pico-artifact)
"""
    OUTPUT.write_text(
        preamble.rstrip() + "\n\n---\n\n" + "\n\n---\n\n".join(sections) + "\n",
        encoding="utf-8",
    )
    print(f"Created {OUTPUT}")


if __name__ == "__main__":
    main()
