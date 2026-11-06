"""Crop the vector PDF of the whole Simulink diagram into one PDF per section.

Called by export_model_sections.m (no third-party packages needed).
  python crop_pdf_sections.py <full.pdf> <spec.json> <result.json>

spec.json : {"sections": [{"name": ..., "slug": ..., "color": [r,g,b], "rect": [l,t,r,b]}, ...], "margin": 10}
            rect = the Area annotation rectangle in model coordinates; color = its fill colour.
The area rectangles are found in the PDF content stream by their fill colour, which gives the
model -> page transform, so any model rectangle can be turned into a page rectangle.
Cropping only rewrites the /MediaBox (same byte length, so the xref table stays valid).
"""
import json
import re
import sys
import zlib


def content_stream(data):
    best = b""
    for m in re.finditer(rb"stream\r?\n", data):
        s = m.end()
        e = data.find(b"endstream", s)
        try:
            t = zlib.decompress(data[s:e])
        except Exception:
            continue
        if len(t) > len(best):
            best = t
    return best


def mul(m, n):
    a, b, c, d, e, f = m
    A, B, C, D, E, F = n
    return [a * A + b * C, a * B + b * D, c * A + d * C, c * B + d * D, e * A + f * C + E, e * B + f * D + F]


def filled_rects(content):
    """Bounding boxes (page coordinates) of every filled path (rectangles and rounded rectangles)."""
    ctm, stack, fill, nums, pts, out = [1, 0, 0, 1, 0, 0], [], None, [], [], []

    def add(x, y):
        a, b, c, d, e, f = ctm
        pts.append((a * x + c * y + e, b * x + d * y + f))

    for t in content.split():
        try:
            nums.append(float(t))
            continue
        except ValueError:
            pass
        if t == b"q":
            stack.append((ctm, fill))
        elif t == b"Q":
            if stack:
                ctm, fill = stack.pop()
        elif t == b"cm" and len(nums) >= 6:
            ctm = mul(nums[-6:], ctm)
        elif t in (b"scn", b"sc") and len(nums) >= 3:
            fill = tuple(nums[-3:])
        elif t in (b"m", b"l") and len(nums) >= 2:
            add(nums[-2], nums[-1])
        elif t == b"c" and len(nums) >= 6:
            for i in (-6, -4, -2):
                add(nums[i], nums[i + 1])
        elif t == b"re" and len(nums) >= 4:
            x, y, w, h = nums[-4:]
            for px, py in ((x, y), (x + w, y), (x, y + h), (x + w, y + h)):
                add(px, py)
        elif t in (b"f", b"f*", b"F", b"B", b"b"):
            if pts:
                xs, ys = [q[0] for q in pts], [q[1] for q in pts]
                out.append(((min(xs), min(ys), max(xs), max(ys)), fill))
            pts = []
        elif t in (b"n", b"S", b"s"):
            pts = []
        nums = []
    return out


def close(c1, c2, tol=0.012):
    return c1 is not None and all(abs(a - b) < tol for a, b in zip(c1, c2))


def main():
    pdf, spec_path, res_path = sys.argv[1:4]
    spec = json.load(open(spec_path))
    margin = spec.get("margin", 10)
    data = open(pdf, "rb").read()
    rects = filled_rects(content_stream(data))
    # whole-diagram background = the biggest white rectangle
    white = [r for r, f in rects if f and close(f, (1, 1, 1))]
    bg = max(white, key=lambda r: (r[2] - r[0]) * (r[3] - r[1]))
    # model -> page transform from the area rectangles
    found = []
    for sec in spec["sections"]:
        cands = [r for r, f in rects if close(f, sec["color"])]
        if not cands:
            sys.exit("area with colour %s not found in the PDF" % sec["color"])
        found.append(max(cands, key=lambda r: (r[2] - r[0]) * (r[3] - r[1])))
    # least squares x_page = ax*x + bx (x from l and r edges), same for y
    def fit(model_vals, page_vals):
        n = len(model_vals)
        mx, my = sum(model_vals) / n, sum(page_vals) / n
        num = sum((a - mx) * (b - my) for a, b in zip(model_vals, page_vals))
        den = sum((a - mx) ** 2 for a in model_vals)
        a = num / den
        return a, my - a * mx
    xm, xp, ym, yp = [], [], [], []
    for sec, r in zip(spec["sections"], found):
        l, t, rr, b = sec["rect"]
        xm += [l, rr]; xp += [r[0], r[2]]
        ym += [t, b]; yp += [r[3], r[1]]          # model y grows downwards, page y upwards
    ax, bx = fit(xm, xp)
    ay, by = fit(ym, yp)
    result = {"bg": bg, "sections": []}
    for sec in spec["sections"]:
        l, t, r, b = sec["rect"]
        l, t, r, b = l - margin, t - margin, r + margin, b + margin
        x0, x1 = ax * l + bx, ax * r + bx
        y1, y0 = ay * t + by, ay * b + by         # t (top) -> larger page y
        box = [x0, y0, x1, y1]
        # PNG fractions (y from the top) relative to the diagram background
        W, H = bg[2] - bg[0], bg[3] - bg[1]
        frac = [(x0 - bg[0]) / W, (bg[3] - y1) / H, (x1 - bg[0]) / W, (bg[3] - y0) / H]
        result["sections"].append({"slug": sec["slug"], "box": box, "frac": frac})
        out = re.sub(
            rb"/MediaBox \[[^\]]*\]",
            lambda m: ("/MediaBox [%d %d %d %d]" % (int(x0), int(y0), int(x1 + 0.999), int(y1 + 0.999))).encode().ljust(len(m.group())),
            data,
        )
        open(sec["pdf"], "wb").write(out)
    json.dump(result, open(res_path, "w"))


if __name__ == "__main__":
    main()
