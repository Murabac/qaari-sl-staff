import re
from pathlib import Path

xml = Path(r"c:\Users\lappybooks\MurabacApps\QaariSL\qaari-sl-staff\store-listing\screenshots\ui.xml").read_text(
    encoding="utf-8", errors="ignore"
)
for m in re.finditer(
    r'class="([^"]+)"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"',
    xml,
):
    cls = m.group(1).split(".")[-1]
    a, b, c, d = map(int, m.groups()[1:])
    clickable = 'clickable="true"' in m.group(0)
    print(f"{cls:20} {(a+c)//2:4d},{(b+d)//2:4d}  [{a},{b}][{c},{d}] click={clickable}")
