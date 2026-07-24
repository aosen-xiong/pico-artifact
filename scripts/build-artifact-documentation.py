#!/usr/bin/env python3
"""Build the standalone OOPSLA artifact-evaluation documentation PDF."""

import argparse
import html
import re
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    BaseDocTemplate,
    Frame,
    KeepTogether,
    ListFlowable,
    ListItem,
    PageBreak,
    PageTemplate,
    Paragraph,
    Preformatted,
    Spacer,
    Table,
    TableStyle,
)


ROOT = Path(__file__).resolve().parent.parent
SOURCES = [
    ROOT / "Artifact-Evaluation.md",
    ROOT / "Artifact-Evaluation-Checker.md",
    ROOT / "Artifact-Evaluation-Rocq.md",
    ROOT / "REUSABILITY.md",
]


def inline_markup(text: str) -> str:
    """Translate the small Markdown subset used by the guides to ReportLab XML."""
    placeholders = []

    def protect(pattern: str, replacement) -> None:
        nonlocal text

        def capture(match):
            placeholders.append(replacement(match))
            return f"@@INLINE{len(placeholders) - 1}@@"

        text = re.sub(pattern, capture, text)

    def render_link(match) -> str:
        label, target = match.group(1), match.group(2)
        if re.match(r"^(?:https?|mailto):", target):
            return (
                f'<link href="{html.escape(target, quote=True)}" '
                f'color="#145da0">{html.escape(label)}</link>'
            )
        return f'<font color="#145da0">{html.escape(label)}</font>'

    protect(r"\[([^]]+)\]\(([^)]+)\)", render_link)
    protect(
        r"`([^`]+)`",
        lambda match: f'<font name="Courier">{html.escape(match.group(1))}</font>',
    )
    text = html.escape(text)
    text = re.sub(r"\*\*([^*]+)\*\*", r"<b>\1</b>", text)
    text = re.sub(r"(?<!\*)\*([^*]+)\*(?!\*)", r"<i>\1</i>", text)
    for index, replacement in enumerate(placeholders):
        text = text.replace(f"@@INLINE{index}@@", replacement)
    return text


def is_table_separator(line: str) -> bool:
    cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
    return bool(cells) and all(re.fullmatch(r":?-{3,}:?", cell) for cell in cells)


def parse_table(lines: list[str], index: int, styles) -> tuple[Table, int]:
    rows = []
    while index < len(lines) and lines[index].lstrip().startswith("|"):
        line = lines[index]
        if not is_table_separator(line):
            cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
            rows.append(
                [Paragraph(inline_markup(cell), styles["TableCell"]) for cell in cells]
            )
        index += 1

    columns = max(len(row) for row in rows)
    for row in rows:
        row.extend(Paragraph("", styles["TableCell"]) for _ in range(columns - len(row)))
    available_width = letter[0] - 1.1 * inch
    table = Table(
        rows,
        colWidths=[available_width / columns] * columns,
        repeatRows=1,
        hAlign="LEFT",
    )
    table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#DCEAF7")),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.HexColor("#17324D")),
                ("FONTNAME", (0, 0), (-1, 0), "Arial-Bold"),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("GRID", (0, 0), (-1, -1), 0.35, colors.HexColor("#AAB7C4")),
                ("LEFTPADDING", (0, 0), (-1, -1), 3),
                ("RIGHTPADDING", (0, 0), (-1, -1), 3),
                ("TOPPADDING", (0, 0), (-1, -1), 3),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
            ]
        )
    )
    return table, index


def markdown_story(path: Path, styles) -> list:
    lines = path.read_text(encoding="utf-8").splitlines()
    story = []
    paragraph = []

    def flush_paragraph() -> None:
        if paragraph:
            story.append(
                Paragraph(inline_markup(" ".join(part.strip() for part in paragraph)), styles["Body"])
            )
            story.append(Spacer(1, 5))
            paragraph.clear()

    index = 0
    while index < len(lines):
        line = lines[index]
        stripped = line.strip()

        if stripped.startswith("```"):
            flush_paragraph()
            index += 1
            code = []
            while index < len(lines) and not lines[index].strip().startswith("```"):
                code.append(lines[index].expandtabs(4))
                index += 1
            story.append(Preformatted("\n".join(code), styles["Code"], maxLineLength=92))
            story.append(Spacer(1, 6))
        elif stripped.startswith("|") and index + 1 < len(lines) and is_table_separator(lines[index + 1]):
            flush_paragraph()
            table, index = parse_table(lines, index, styles)
            story.append(table)
            story.append(Spacer(1, 7))
            continue
        elif re.match(r"^#{1,4}\s+", stripped):
            flush_paragraph()
            match = re.match(r"^(#{1,4})\s+(.*)$", stripped)
            level = len(match.group(1))
            story.append(Paragraph(inline_markup(match.group(2)), styles[f"Heading{level}"]))
        elif re.match(r"^[-*]\s+", stripped):
            flush_paragraph()
            items = []
            while index < len(lines) and re.match(r"^\s*[-*]\s+", lines[index]):
                parts = [re.sub(r"^\s*[-*]\s+", "", lines[index]).strip()]
                index += 1
                while (
                    index < len(lines)
                    and lines[index].strip()
                    and not re.match(r"^\s*[-*]\s+", lines[index])
                    and not re.match(r"^\d+\.\s+", lines[index].strip())
                    and not re.match(r"^#{1,4}\s+", lines[index].strip())
                    and not lines[index].strip().startswith("```")
                ):
                    parts.append(lines[index].strip())
                    index += 1
                items.append(
                    ListItem(
                        Paragraph(inline_markup(" ".join(parts)), styles["Body"])
                    )
                )
            story.append(ListFlowable(items, bulletType="bullet", leftIndent=18, bulletFontName="Arial"))
            story.append(Spacer(1, 5))
            continue
        elif re.match(r"^\d+\.\s+", stripped):
            flush_paragraph()
            items = []
            while index < len(lines) and re.match(r"^\s*\d+\.\s+", lines[index]):
                parts = [re.sub(r"^\s*\d+\.\s+", "", lines[index]).strip()]
                index += 1
                while (
                    index < len(lines)
                    and lines[index].strip()
                    and not re.match(r"^\s*\d+\.\s+", lines[index])
                    and not re.match(r"^\s*[-*]\s+", lines[index])
                    and not re.match(r"^#{1,4}\s+", lines[index].strip())
                    and not lines[index].strip().startswith("```")
                ):
                    parts.append(lines[index].strip())
                    index += 1
                items.append(
                    ListItem(
                        Paragraph(inline_markup(" ".join(parts)), styles["Body"])
                    )
                )
            story.append(ListFlowable(items, bulletType="1", leftIndent=22, bulletFontName="Arial"))
            story.append(Spacer(1, 5))
            continue
        elif not stripped:
            flush_paragraph()
        else:
            paragraph.append(stripped)
        index += 1

    flush_paragraph()
    return story


def register_fonts() -> None:
    font_dir = Path("/System/Library/Fonts/Supplemental")
    pdfmetrics.registerFont(TTFont("Arial", font_dir / "Arial.ttf"))
    pdfmetrics.registerFont(TTFont("Arial-Bold", font_dir / "Arial Bold.ttf"))
    pdfmetrics.registerFont(TTFont("Arial-Italic", font_dir / "Arial Italic.ttf"))


def make_styles():
    sample = getSampleStyleSheet()
    styles = {
        "Title": ParagraphStyle(
            "Title",
            parent=sample["Title"],
            fontName="Arial-Bold",
            fontSize=22,
            leading=27,
            textColor=colors.HexColor("#17324D"),
            alignment=TA_CENTER,
            spaceAfter=18,
        ),
        "Subtitle": ParagraphStyle(
            "Subtitle",
            parent=sample["BodyText"],
            fontName="Arial",
            fontSize=13,
            leading=18,
            alignment=TA_CENTER,
            textColor=colors.HexColor("#445566"),
        ),
        "Body": ParagraphStyle(
            "Body",
            parent=sample["BodyText"],
            fontName="Arial",
            fontSize=9.3,
            leading=12.3,
            textColor=colors.HexColor("#20262D"),
            allowWidows=0,
            allowOrphans=0,
        ),
        "Code": ParagraphStyle(
            "Code",
            parent=sample["Code"],
            fontName="Courier",
            fontSize=7.2,
            leading=9.1,
            leftIndent=8,
            rightIndent=8,
            borderColor=colors.HexColor("#C5CED6"),
            borderWidth=0.5,
            borderPadding=5,
            backColor=colors.HexColor("#F6F8FA"),
            spaceBefore=2,
            spaceAfter=2,
        ),
        "TableCell": ParagraphStyle(
            "TableCell",
            parent=sample["BodyText"],
            fontName="Arial",
            fontSize=6.6,
            leading=8.2,
            textColor=colors.HexColor("#20262D"),
        ),
    }
    for level, size, leading, before, after in (
        (1, 17, 21, 12, 10),
        (2, 13.5, 17, 11, 7),
        (3, 11.5, 14, 9, 5),
        (4, 10, 12, 7, 4),
    ):
        styles[f"Heading{level}"] = ParagraphStyle(
            f"Heading{level}",
            parent=sample[f"Heading{min(level, 3)}"],
            fontName="Arial-Bold",
            fontSize=size,
            leading=leading,
            textColor=colors.HexColor("#17324D"),
            spaceBefore=before,
            spaceAfter=after,
            keepWithNext=True,
        )
    return styles


def page_decoration(canvas, document) -> None:
    canvas.saveState()
    width, height = letter
    canvas.setStrokeColor(colors.HexColor("#D4DCE3"))
    canvas.setLineWidth(0.4)
    canvas.line(0.55 * inch, height - 0.43 * inch, width - 0.55 * inch, height - 0.43 * inch)
    canvas.setFont("Arial", 7.5)
    canvas.setFillColor(colors.HexColor("#65717C"))
    canvas.drawString(0.55 * inch, height - 0.31 * inch, "PICO Artifact Documentation")
    canvas.drawRightString(width - 0.55 * inch, 0.35 * inch, f"Page {document.page}")
    canvas.restoreState()


def build(output: Path) -> None:
    register_fonts()
    styles = make_styles()
    output.parent.mkdir(parents=True, exist_ok=True)

    document = BaseDocTemplate(
        str(output),
        pagesize=letter,
        leftMargin=0.55 * inch,
        rightMargin=0.55 * inch,
        topMargin=0.58 * inch,
        bottomMargin=0.55 * inch,
        title="PICO Artifact Documentation",
        author="PICO Developers",
        subject="OOPSLA 2026 artifact evaluation instructions",
    )
    frame = Frame(
        document.leftMargin,
        document.bottomMargin,
        document.width,
        document.height,
        id="body",
    )
    document.addPageTemplates(PageTemplate(id="main", frames=[frame], onPage=page_decoration))

    story = [
        Spacer(1, 1.1 * inch),
        Paragraph("PICO Artifact Documentation", styles["Title"]),
        Paragraph(
            "Transitive, Abstract, and Class Polymorphic Immutability",
            styles["Subtitle"],
        ),
        Spacer(1, 0.35 * inch),
        Paragraph(
            "Kick-the-tires instructions, complete evaluation procedures, "
            "claim mapping, and reusability guidance for OOPSLA 2026 artifact evaluation.",
            styles["Subtitle"],
        ),
        PageBreak(),
    ]
    for source_index, source in enumerate(SOURCES):
        if source_index:
            story.append(PageBreak())
        story.extend(markdown_story(source, styles))

    document.build(story)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "output",
        nargs="?",
        type=Path,
        default=ROOT / "output" / "pdf" / "artifact-documentation.pdf",
    )
    args = parser.parse_args()
    build(args.output.resolve())
    print(args.output.resolve())


if __name__ == "__main__":
    main()
