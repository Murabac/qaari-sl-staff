import re
import sys
from pathlib import Path

xml = Path(sys.argv[1]).read_text(encoding="utf-8", errors="ignore")
for m in re.finditer(
    r'(?:content-desc|text)="([^"]*)"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"',
    xml,
):
    t = m.group(1)
    if not t.strip():
        continue
    a, b, c, d = map(int, m.groups()[1:])
    print(f"{(a + c) // 2:4d},{(b + d) // 2:4d}  {t[:100]}")
