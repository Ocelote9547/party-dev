import re
from pathlib import Path

ROOT = Path(r"C:\Users\Daniu\Desktop\party\lib")
DYNAMIC = re.compile(
    r"PartyColors\.(text|textSecondary|textMuted|surface|surfaceLight|"
    r"background|backgroundLight|border)\b"
)


def find_matching_paren(s: str, open_idx: int) -> int:
    depth = 0
    i = open_idx
    while i < len(s):
        c = s[i]
        if c == "(":
            depth += 1
        elif c == ")":
            depth -= 1
            if depth == 0:
                return i
        elif c in ("'", '"'):
            quote = c
            i += 1
            while i < len(s):
                if s[i] == "\\":
                    i += 2
                    continue
                if s[i] == quote:
                    break
                i += 1
        i += 1
    return -1


def fix_content(src: str) -> str:
    pattern = re.compile(r"\bconst\s+(?=[A-Z_])")
    changed = True
    while changed:
        changed = False
        for m in pattern.finditer(src):
            start = m.start()
            rest = src[m.end() :]
            paren = rest.find("(")
            if paren < 0:
                continue
            head = rest[:paren]
            if not re.match(r"^[A-Za-z_][\w.<>,\s]*$", head):
                continue
            open_idx = m.end() + paren
            close_idx = find_matching_paren(src, open_idx)
            if close_idx < 0:
                continue
            body = src[open_idx : close_idx + 1]
            if DYNAMIC.search(body):
                src = src[:start] + src[m.end() :]
                changed = True
                break
    return src


def main() -> None:
    fixed_files = 0
    for path in ROOT.rglob("*.dart"):
        original = path.read_text(encoding="utf-8")
        updated = fix_content(original)
        updated = updated.replace(
            "foregroundColor: PartyColors.background",
            "foregroundColor: PartyColors.onPrimary",
        )
        # Icons sitting on primary-colored buttons used background as contrast color
        updated = updated.replace(
            "color: PartyColors.background)",
            "color: PartyColors.onPrimary)",
        )
        if updated != original:
            path.write_text(updated, encoding="utf-8")
            fixed_files += 1
            print(f"fixed {path.relative_to(ROOT)}")
    print(f"TOTAL {fixed_files}")


if __name__ == "__main__":
    main()
