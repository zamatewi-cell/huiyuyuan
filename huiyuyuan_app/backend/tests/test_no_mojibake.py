"""
Regression test: backend Python source files must not contain mojibake.

The historical failure mode was GBK text read as UTF-8, which produced
garbled CJK glyphs in source and user-facing messages. Keep the bad samples
as Unicode escapes so this test does not flag itself.

Run: pytest tests/test_no_mojibake.py -v
"""

import re
from pathlib import Path


BACKEND_ROOT = Path(__file__).parent.parent

# Each tuple is (description, regex for a known-bad mojibake fragment).
_MOJIBAKE_PATTERNS: list[tuple[str, re.Pattern[str]]] = [
    ("payment mojibake prefix", re.compile("\u9440\u0432")),
    ("order mojibake prefix", re.compile("\u74e9\u0280")),
    ("fetch/read mojibake prefix", re.compile("\u8af7\u8afb")),
    ("product mojibake prefix", re.compile("\u9502\u00b8")),
    ("create mojibake prefix", re.compile("\u9501\u0432")),
    ("cancel mojibake prefix", re.compile("\u9516\u00e6")),
    ("use mojibake prefix", re.compile("\u6d7c\u0432")),
    ("if mojibake prefix", re.compile("\u6fc4\u00b8")),
    ("current mojibake prefix", re.compile("\u8944\u5a87")),
    ("honorific-you mojibake prefix", re.compile("\u9f3e\u3044")),
]

_SKIP_DIRS = {"venv", ".venv", "__pycache__", "migrations", ".git"}


def _collect_py_files() -> list[Path]:
    return [
        p
        for p in BACKEND_ROOT.rglob("*.py")
        if not any(part in _SKIP_DIRS for part in p.parts)
    ]


def test_no_mojibake_in_source_files() -> None:
    """All Python source files are free of known mojibake fragments."""
    py_files = _collect_py_files()
    assert py_files, "No Python files found; check BACKEND_ROOT path"

    violations: list[str] = []

    for path in py_files:
        try:
            content = path.read_text(encoding="utf-8")
        except UnicodeDecodeError as exc:
            violations.append(f"{path}: cannot decode as UTF-8: {exc}")
            continue

        for desc, pattern in _MOJIBAKE_PATTERNS:
            for match in pattern.finditer(content):
                line_no = content[: match.start()].count("\n") + 1
                snippet = content.splitlines()[line_no - 1].strip()
                violations.append(
                    f"{path.relative_to(BACKEND_ROOT)}:{line_no} "
                    f"[{desc}] -> {snippet!r}"
                )

    assert not violations, (
        f"Found {len(violations)} mojibake violation(s):\n"
        + "\n".join(f"  - {violation}" for violation in violations)
    )


def test_backup_files_removed() -> None:
    """Stale *_backup.py files must not exist in the backend tree."""
    backup_files = [
        p
        for p in BACKEND_ROOT.rglob("*_backup.py")
        if not any(part in _SKIP_DIRS for part in p.parts)
    ]
    assert not backup_files, (
        "Backup files found; delete them:\n"
        + "\n".join(f"  - {p.relative_to(BACKEND_ROOT)}" for p in backup_files)
    )
