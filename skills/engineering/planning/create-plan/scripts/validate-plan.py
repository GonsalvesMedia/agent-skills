#!/usr/bin/env python3
"""
validate-plan.py

Machine-checks a plan document for universal readiness structure.
Does not hardcode repository categories, folder layouts, or product-specific
section names beyond common planning headings.

Usage:
  python3 validate-plan.py <path-to-plan.md>
  python3 validate-plan.py --draft <path-to-plan.md>

Exit codes:
  0 — all checks passed (implementation-ready, or draft-valid with --draft)
  1 — errors found
  2 — warnings only
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


def section_body(content: str, name_pattern: str) -> str | None:
    pattern = re.compile(
        rf"^#{{1,3}}\s+(?:{name_pattern})\s*$",
        re.IGNORECASE | re.MULTILINE,
    )
    match = pattern.search(content)
    if not match:
        return None
    start = match.end()
    next_h = re.search(r"^#{1,3}\s+", content[start:], re.MULTILINE)
    end = start + next_h.start() if next_h else len(content)
    return content[start:end]


def has_heading(content: str, name_pattern: str) -> bool:
    return (
        re.search(
            rf"^#{{1,3}}\s+(?:{name_pattern})\s*$",
            content,
            re.IGNORECASE | re.MULTILINE,
        )
        is not None
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Validate universal plan readiness structure."
    )
    parser.add_argument("path", help="Path to plan markdown file")
    parser.add_argument(
        "--draft",
        action="store_true",
        help="Allow unresolved open questions when each has a recommended answer",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    path = Path(args.path)

    if not path.exists():
        print(f"File not found: {path}", file=sys.stderr)
        return 1

    content = path.read_text(encoding="utf-8")
    errors: list[str] = []
    warnings: list[str] = []

    def readiness_issue(message: str) -> None:
        if args.draft:
            warnings.append(message)
        else:
            errors.append(message)

    if not content.strip():
        errors.append("Plan file is empty")
        report(path.name, errors, warnings)
        return 1

    # Optional frontmatter: validate only if present
    fm_match = re.match(r"^---\r?\n([\s\S]*?)\r?\n---", content)
    if fm_match:
        fm = fm_match.group(1)
        status_match = re.search(r"^status:\s*(\S+)", fm, re.MULTILINE)
        if status_match and not status_match.group(1).strip():
            errors.append("Frontmatter status is empty")

    required = [
        (
            r"Problem(?:\s*/\s*Motivation)?|Motivation",
            "Problem / Motivation",
        ),
        (r"Goal", "Goal"),
        (
            r"Verification|Acceptance Criteria|Success Criteria",
            "Verification / Acceptance Criteria",
        ),
        (r"Confidence Scorecard", "Confidence Scorecard"),
        (
            r"Implementation Plan|Phases|Implementation",
            "Implementation Plan / Phases",
        ),
        (
            r"Files(?:\s*/\s*Contract Impacts)?|Files to (?:Create|Modify)|Contract Impacts",
            "Files / Contract Impacts",
        ),
    ]
    for pattern, name in required:
        if not has_heading(content, pattern):
            errors.append(f'Missing required section: "{name}"')

    # Confidence scorecard quality
    sc = section_body(content, r"Confidence Scorecard")
    if sc is not None:
        score_rows = re.findall(
            r"^\|\s*(?:Technical|Requirement|Impact)\b[^|]*\|\s*([^|]+)\|",
            sc,
            re.IGNORECASE | re.MULTILINE,
        )
        if len(score_rows) < 3:
            readiness_issue(
                "Confidence scorecard must include Technical, Requirement, and Impact scores"
            )
        for raw_score in score_rows:
            score_text = raw_score.strip()
            if not re.fullmatch(r"10|[1-9]", score_text):
                errors.append(
                    f'Confidence score "{score_text}" must be an integer from 1 to 10'
                )
                continue
            score = int(score_text)
            if score < 7:
                warnings.append(
                    f"Confidence score {score}/10 is below typical readiness threshold (7)"
                )
        if re.search(r"\|\s*X\s*\|", sc):
            errors.append(
                'Confidence scorecard has unfilled placeholder scores ("X")'
            )
        if re.search(r"Why:\s*\.{2,}", sc):
            errors.append(
                'Confidence scorecard has unfilled reasoning ("Why: ...")'
            )
        if not re.search(r"Reversibility", sc, re.IGNORECASE):
            readiness_issue(
                'Confidence scorecard missing "Reversibility" — state how to undo or disable'
            )
        if re.search(r"\*\*Reversibility\*\*:\s*\[[^\]]+\]", sc, re.IGNORECASE):
            errors.append(
                'Confidence scorecard has placeholder "Reversibility" text'
            )
        if not re.search(r"Blast\s+[Rr]adius", sc):
            readiness_issue(
                'Confidence scorecard missing "Blast radius" — state worst-case failure scope'
            )
        if re.search(r"\*\*Blast\s+[Rr]adius\*\*:\s*\[[^\]]+\]", sc, re.IGNORECASE):
            errors.append(
                'Confidence scorecard has placeholder "Blast radius" text'
            )
        if re.search(r"\*\*Open questions\*\*:\s*\[Count\]", sc, re.IGNORECASE):
            errors.append(
                'Confidence scorecard has placeholder open-question count ("[Count]")'
            )

    # Open questions
    oq = section_body(content, r"Open Questions")
    if oq is None:
        errors.append(
            'Missing "Open Questions" subsection — include under Confidence Scorecard '
            "(use an empty resolved list when none remain)"
        )
    else:
        unchecked = re.findall(r"^\s*-\s*\[\s\]\s+(.+)$", oq, re.MULTILINE)
        if unchecked:
            missing_rec = [
                q
                for q in unchecked
                if not re.search(
                    r"(?:\*{1,2})?Recommended(?:\*{1,2})?\s*:",
                    q,
                    re.IGNORECASE,
                )
            ]
            if missing_rec:
                errors.append(
                    f"{len(missing_rec)} unresolved open question(s) lack a Recommended answer"
                )
            if args.draft:
                if not missing_rec:
                    warnings.append(
                        f"{len(unchecked)} unresolved open question(s) — OK for --draft; "
                        "must be 0 for implementation-ready"
                    )
            else:
                errors.append(
                    f"{len(unchecked)} unresolved open question(s) — must be 0 for "
                    "implementation-ready (use --draft to validate a draft)"
                )

    # Vague file rows
    vague = 0
    for row in re.findall(r"\|[^|\n]+\|[^|\n]+\|", content):
        if re.search(
            r"\|\s*(Update|Modify|Edit|Change|Fix)\s+\w+\s*\|", row, re.IGNORECASE
        ):
            vague += 1
    if vague:
        warnings.append(
            f'{vague} file table row(s) may be vague (e.g. "Update Foo") — '
            'write specific "change A to B" guidance'
        )

    # Placeholders
    if re.search(r"\bTODO\b", content):
        readiness_issue("Plan contains TODO placeholder(s)")
    if re.search(r"\bTBD\b", content):
        readiness_issue("Plan contains TBD placeholder(s)")

    # Non-trivial heuristics
    phase_count = len(re.findall(r"^###\s+Phase\s+\d", content, re.IGNORECASE | re.MULTILINE))
    file_rows = len(
        re.findall(r"^\|\s*`[^`]+\.[A-Za-z0-9._/-]+`\s*\|", content, re.MULTILINE)
    )
    file_bullets = len(
        re.findall(r"^\s*-\s*`[^`]+\.[A-Za-z0-9._/-]+`", content, re.MULTILINE)
    )
    non_trivial = phase_count >= 2 or (file_rows + file_bullets) >= 6

    if non_trivial:
        if not has_heading(content, r"Non-goals|Out[- ]of[- ][Ss]cope"):
            warnings.append(
                'Non-trivial plan missing "Non-goals / Out of scope"'
            )
        if not has_heading(content, r"Assumptions(?:\s*\+\s*Constraints)?"):
            warnings.append(
                'Non-trivial plan missing "Assumptions + Constraints"'
            )
        if not has_heading(content, r"Risk(?:\s*\+\s*Pre-mortem)?|Pre-mortem"):
            warnings.append('Non-trivial plan missing "Risk + Pre-mortem"')
        if not has_heading(content, r"Success Metrics"):
            warnings.append('Non-trivial plan missing "Success Metrics"')
        if not re.search(r"rollback|feature[\s-]?flag", content, re.IGNORECASE):
            warnings.append(
                "No mention of rollback plan or feature flag — state reversibility"
            )

    # Decision menus in implementation sections
    impl = section_body(content, r"Implementation Plan|Phases|Implementation") or ""
    if re.search(r"\b(option\s+A|either .+ or |A\s*/\s*B)\b", impl, re.IGNORECASE):
        warnings.append(
            "Implementation section may contain undecided A/B options — "
            "implementation-ready plans commit to one approach"
        )

    report(path.name, errors, warnings)

    if errors:
        return 1
    if warnings:
        return 2
    return 0


def report(filename: str, errors: list[str], warnings: list[str]) -> None:
    print(f"\nPlan Validation — {filename}")
    print("-" * 50)

    if not errors and not warnings:
        print("\nAll checks passed — plan is implementation-ready\n")
        return

    if errors:
        print(f"\nERRORS ({len(errors)}) — must fix:\n")
        for e in errors:
            print(f"  - {e}")

    if warnings:
        print(f"\nWARNINGS ({len(warnings)}) — review before proceeding:\n")
        for w in warnings:
            print(f"  - {w}")

    print()


if __name__ == "__main__":
    sys.exit(main())
