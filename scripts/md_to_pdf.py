"""Convert a simple Markdown file (headings, paragraphs, tables, images, bold/italic/code, rules) to PDF.
Uses Microsoft Edge in headless mode for the PDF, so no extra packages are needed.
  python md_to_pdf.py docs/outputs_summary.md docs/outputs_summary.pdf
"""
import html
import os
import re
import subprocess
import sys

EDGES = [r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
         r"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
         r"C:\Program Files\Google\Chrome\Application\chrome.exe"]


def inline(t):
    t = html.escape(t, quote=False)
    t = re.sub(r"!\[([^\]]*)\]\(([^)]+)\)", r'<img alt="\1" src="\2">', t)
    t = re.sub(r"`([^`]+)`", r"<code>\1</code>", t)
    t = re.sub(r"\*\*(.+?)\*\*", r"<b>\1</b>", t)
    t = re.sub(r"(?<![\w*])\*([^*\n]+?)\*(?![\w*])", r"<i>\1</i>", t)
    return t


def convert(md):
    out, lines, i = [], md.split("\n"), 0
    while i < len(lines):
        ln = lines[i]
        if ln.startswith("|"):
            rows = []
            while i < len(lines) and lines[i].startswith("|"):
                rows.append([c.strip() for c in lines[i].strip().strip("|").split("|")]); i += 1
            head, body = rows[0], [r for r in rows[2:]]
            out.append("<table><tr>" + "".join("<th>%s</th>" % inline(c) for c in head) + "</tr>" +
                       "".join("<tr>" + "".join("<td>%s</td>" % inline(c) for c in r) + "</tr>" for r in body) + "</table>")
            continue
        m = re.match(r"^(#{1,3}) (.*)", ln)
        if m:
            n = len(m.group(1)); out.append("<h%d>%s</h%d>" % (n, inline(m.group(2)), n))
        elif ln.strip() == "---":
            out.append("<hr>")
        elif ln.strip():
            out.append("<p>%s</p>" % inline(ln))
        i += 1
    return "\n".join(out)


CSS = """body{font-family:Segoe UI,Arial,sans-serif;font-size:10.5pt;line-height:1.4;margin:0}
h1{font-size:17pt;border-bottom:2px solid #444;padding-bottom:3px;margin-top:22px}
h2{font-size:14pt;margin-top:20px;page-break-after:avoid}
p{margin:5px 0}img{max-width:100%;max-height:300px;display:block;margin:6px auto;border:1px solid #ddd}
table{border-collapse:collapse;margin:8px 0;font-size:9.5pt}th,td{border:1px solid #999;padding:3px 6px;vertical-align:top}
th{background:#eee}code{background:#f2f2f2;padding:0 2px;font-size:9.5pt}hr{border:0;border-top:1px solid #ccc;margin:14px 0}
@page{size:A4;margin:16mm 14mm}"""


def main():
    src, dst = sys.argv[1], sys.argv[2]
    md = open(src, encoding="utf8").read()
    body = convert(md)
    tmp = os.path.splitext(os.path.abspath(src))[0] + "._tmp.html"
    open(tmp, "w", encoding="utf8").write("<html><head><meta charset='utf-8'><style>%s</style></head><body>%s</body></html>" % (CSS, body))
    exe = next(e for e in EDGES if os.path.exists(e))
    url = "file:///" + tmp.replace("\\", "/")
    import tempfile, time
    prof = tempfile.mkdtemp()                       # own browser profile, so a running Edge does not swallow the command
    dst = os.path.abspath(dst)
    if os.path.exists(dst):
        os.remove(dst)
    subprocess.run([exe, "--headless=new", "--disable-gpu", "--no-pdf-header-footer", "--user-data-dir=" + prof,
                    "--print-to-pdf=" + dst, url], timeout=180)
    for _ in range(60):                             # the file may appear a moment after the process returns
        if os.path.exists(dst) and os.path.getsize(dst) > 0:
            break
        time.sleep(1)
    os.remove(tmp)
    if not os.path.exists(dst):
        sys.exit("PDF was not created")


if __name__ == "__main__":
    main()
