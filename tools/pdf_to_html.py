#!/usr/bin/env python3
"""Convert one paper PDF into ONE self-contained, page-labelled, anchored HTML file.

Anchors:  <section id="p3">  per PDF page,  id="p3-b7" per block (page-block).
Text is kept as extracted (only ligature glyphs are expanded and line-break
hyphenation is joined). Figures / complex tables / equations are also rendered
to base64 PNG and flagged with a note.

usage: pdf_to_html.py in.pdf out.html   (prints a JSON stats line)
"""
import base64, html, json, re, sys, unicodedata
from collections import Counter
import warnings
warnings.filterwarnings("ignore")
import pymupdf as fitz

LIG = {"ﬀ": "ff", "ﬁ": "fi", "ﬂ": "fl", "ﬃ": "ffi", "ﬄ": "ffl",
       "ﬅ": "st", "ﬆ": "st", "­": ""}
MATH_FONTS = re.compile(r"CMSY|CMMI|CMEX|CMR\d|MSBM|MSAM|Math|Symbol|MTMI|MTSY|MTEX|Euclid|STIXMath|Cambria", re.I)
CAPTION = re.compile(r"^\s*(Figure|Fig\.|Table|Exhibit|Panel|Chart)\s*[A-Z]?\d+", re.I)
REFHEAD = re.compile(r"^\s*(\d+[\.\s]*)?(references|bibliography|works cited|literature cited)\s*$", re.I)
OTHERHEAD = re.compile(r"^\s*(\d+[\.\s]*)?(appendix|appendices|online appendix|supplementary|web appendix)", re.I)
DPI = 120
MAX_PX = 1500


def fix(t):
    for k, v in LIG.items():
        t = t.replace(k, v)
    return re.sub(r"[\x00-\x08\x0b\x0c\x0e-\x1f]", "", t)


def png_b64(page, rect, dpi=DPI):
    rect = fitz.Rect(rect) & page.rect
    if rect.is_empty or rect.width < 2 or rect.height < 2:
        return None
    zoom = dpi / 72
    if rect.width * zoom > MAX_PX:
        zoom = MAX_PX / rect.width
    pix = page.get_pixmap(matrix=fitz.Matrix(zoom, zoom), clip=rect, alpha=False)
    return base64.b64encode(pix.tobytes("png")).decode()


def block_info(b):
    """Return dict with html, text, maxsize, boldfrac, mathfrac for a text block."""
    lines_html, lines_txt = [], []
    sizes, bold_ch, math_ch, tot = [], 0, 0, 0
    for ln in b["lines"]:
        parts, plain = [], []
        for sp in ln["spans"]:
            t = fix(sp["text"])
            if not t.strip() and not t:
                continue
            n = len(t.strip())
            tot += n
            sizes.append((round(sp["size"], 1), n))
            isb = bool(sp["flags"] & 16) or "bold" in sp["font"].lower() or "black" in sp["font"].lower()
            isi = bool(sp["flags"] & 2) or "italic" in sp["font"].lower() or "oblique" in sp["font"].lower()
            sup = bool(sp["flags"] & 1)
            if isb: bold_ch += n
            if MATH_FONTS.search(sp["font"]): math_ch += n
            e = html.escape(t)
            if sup and t.strip(): e = f"<sup>{e}</sup>"
            if isi and t.strip(): e = f"<i>{e}</i>"
            if isb and t.strip(): e = f"<b>{e}</b>"
            parts.append(e); plain.append(t)
        lines_html.append("".join(parts)); lines_txt.append("".join(plain))
    # join lines, resolving line-break hyphenation
    out_h, out_t = "", ""
    for i, (h, t) in enumerate(zip(lines_html, lines_txt)):
        if not t.strip():
            continue
        if out_t:
            nxt = t.lstrip()
            if re.search(r"[A-Za-zÀ-ɏ]-$", out_t) and nxt[:1].islower():
                out_h = re.sub(r"-((?:</[bi]>|</sup>)*)$", r"\1", out_h)
                out_t = out_t[:-1]
                sep = ""
            else:
                sep = " "
            out_h += sep; out_t += sep
        out_h += h.strip() if not out_h else h.lstrip()
        out_t += t.strip() if not out_t else t.lstrip()
    out_h = re.sub(r"</b>(\s*)<b>", r"\1", out_h)
    out_h = re.sub(r"</i>(\s*)<i>", r"\1", out_h)
    big = max(sizes, default=(0, 0))[0] if sizes else 0
    return dict(html=out_h, text=out_t.strip(), size=big, tot=tot,
                boldfrac=(bold_ch / tot if tot else 0), mathfrac=(math_ch / tot if tot else 0),
                nlines=len(b["lines"]), bbox=fitz.Rect(b["bbox"]))


def norm_key(t):
    return re.sub(r"\d+", "#", re.sub(r"\s+", " ", t.lower())).strip()


def convert(pdf, out_path):
    doc = fitz.open(pdf)
    n = len(doc)
    pages = []
    size_counter = Counter()
    for pno in range(n):
        page = doc[pno]
        d = page.get_text("dict")
        blocks = []
        for b in d["blocks"]:
            if b["type"] == 0:
                bi = block_info(b)
                if not bi["text"]:
                    continue
                bi["kind"] = "text"
                blocks.append(bi)
                for sp_size in [bi["size"]]:
                    size_counter[sp_size] += bi["tot"]
            elif b["type"] == 1:
                blocks.append(dict(kind="img", bbox=fitz.Rect(b["bbox"])))
        pages.append(dict(page=page, blocks=blocks, rect=page.rect))
    body = size_counter.most_common(1)[0][0] if size_counter else 10

    # ---- furniture detection: repeated text in top/bottom margin, bare page numbers
    keycount = Counter()
    for p in pages:
        H = p["rect"].height
        seen = set()
        for b in p["blocks"]:
            if b["kind"] != "text": continue
            r = b["bbox"]
            if r.y1 < H * 0.10 or r.y0 > H * 0.90:
                k = norm_key(b["text"])
                if k not in seen:
                    keycount[k] += 1; seen.add(k)
    thresh = max(3, int(0.25 * n))
    for p in pages:
        H, W = p["rect"].height, p["rect"].width
        for b in p["blocks"]:
            if b["kind"] != "text": continue
            r, t = b["bbox"], b["text"]
            margin = r.y1 < H * 0.10 or r.y0 > H * 0.90
            side = r.x1 < W * 0.06 or r.x0 > W * 0.94
            b["furn"] = False
            if margin and (keycount[norm_key(t)] >= thresh and n >= 3):
                b["furn"] = True
            elif margin and re.fullmatch(r"(page\s*)?\d{1,4}(\s*(of|/)\s*\d{1,4})?|[ivxlc]{1,6}", t.strip(), re.I):
                b["furn"] = True
            elif (margin or side) and re.search(r"downloaded from|electronic copy available|all rights reserved|terms and conditions|for personal use only|jstor|ssrn\.com/abstract|see discussions, stats", t, re.I) and len(t) < 300:
                b["furn"] = True
            elif side and len(t) < 200 and b["nlines"] >= 1 and (r.height > r.width * 2):
                b["furn"] = True  # rotated margin text (arXiv stamp etc.)

    stats = Counter(pages=n)
    parts = []
    in_refs = False
    for pi, p in enumerate(pages, 1):
        page, blocks, W, H = p["page"], p["blocks"], p["rect"].width, p["rect"].height
        ntext = sum(len(b["text"]) for b in blocks if b["kind"] == "text")
        items = []   # (order_key, html)
        sect = [f'<section id="p{pi}" class="page" data-page="{pi}">',
                f'<div class="pagelabel">Page {pi}</div>']
        bn = 0

        def nid():
            nonlocal bn
            bn += 1
            return f"p{pi}-b{bn}"

        if ntext < 25:
            # scanned / image-only page: render whole page
            b64 = png_b64(page, page.rect, 130)
            i = nid()
            sect.append(f'<figure id="{i}" class="fig pageimage" data-kind="page-image"><img alt="Page {pi} (image, no text layer)" src="data:image/png;base64,{b64}">'
                        f'<figcaption>NOTE: Page {pi} has no extractable text layer; it is shown as an image of the PDF page. Text on this page cannot be searched.</figcaption></figure>')
            sect.append("</section>")
            stats["image_only_pages"] += 1
            parts.append("\n".join(sect))
            continue

        # ---- tables
        tables = []
        try:
            tf = page.find_tables()
            tables = list(tf.tables)
        except Exception:
            tables = []
        caps = [b for b in blocks if b["kind"] == "text" and CAPTION.match(b["text"]) and b["text"].lower().lstrip().startswith("table")]
        if caps and not tables:
            try:
                tables = list(page.find_tables(strategy="text").tables)
                # keep only tables adjacent to a Table caption
                good = []
                for t in tables:
                    tb = fitz.Rect(t.bbox)
                    if any(abs(c["bbox"].y1 - tb.y0) < 60 or abs(tb.y1 - c["bbox"].y0) < 60 for c in caps) and t.row_count >= 3 and t.col_count >= 2:
                        good.append(t)
                tables = good
            except Exception:
                tables = []
        tinfo = []
        for t in tables:
            try:
                rows = t.extract()
            except Exception:
                continue
            tb = fitz.Rect(t.bbox)
            if tb.width < W * 0.2 or tb.height < 20 or len(rows) < 2:
                continue
            ncell = sum(len(r) for r in rows)
            filled = sum(1 for r in rows for c in r if c and str(c).strip())
            clean = (len(rows[0]) >= 2 and len(rows[0]) <= 14 and filled / max(ncell, 1) >= 0.45
                     and all(len(str(c or "")) < 220 for r in rows for c in r))
            # text of the table must be covered by the table cells
            tinfo.append(dict(rect=tb, rows=rows, clean=clean))

        # ---- figures: image blocks + vector drawing clusters
        figs = []
        for b in blocks:
            if b["kind"] == "img":
                r = b["bbox"]
                if r.width > 80 and r.height > 60 and r.width * r.height < 0.85 * W * H:
                    figs.append(r)
        try:
            for r in page.cluster_drawings():
                r = fitz.Rect(r)
                if r.width < 100 or r.height < 70 or r.width * r.height > 0.85 * W * H:
                    continue
                if any(r.intersects(t["rect"]) and (r & t["rect"]).get_area() > 0.5 * r.get_area() for t in tinfo):
                    continue
                figs.append(r)
        except Exception:
            pass
        # merge overlapping figure rects
        merged = []
        for r in sorted(figs, key=lambda r: (r.y0, r.x0)):
            for m in merged:
                if (m & r).get_area() > 0.2 * min(m.get_area(), r.get_area()) or m.contains(r):
                    m |= r; break
            else:
                merged.append(fitz.Rect(r))
        figs = merged

        # ---- classify text blocks
        consumed_by = {}
        for bi_, b in enumerate(blocks):
            if b["kind"] != "text": continue
            for ti, t in enumerate(tinfo):
                if (b["bbox"] & t["rect"]).get_area() >= 0.6 * max(b["bbox"].get_area(), 1) and not CAPTION.match(b["text"]):
                    consumed_by[bi_] = ("t", ti); break
            else:
                for fi_, fr in enumerate(figs):
                    if (b["bbox"] & fr).get_area() >= 0.8 * max(b["bbox"].get_area(), 1) and not CAPTION.match(b["text"]) and not b.get("furn"):
                        consumed_by[bi_] = ("f", fi_); break
            # image blocks themselves never emit
        figtext = {i: [] for i in range(len(figs))}
        placed = set()
        out = []

        def emit_obj(kind, idx):
            if (kind, idx) in placed: return
            placed.add((kind, idx))
            if kind == "t":
                t = tinfo[idx]
                i = nid()
                if t["clean"]:
                    rows_h = []
                    for ri, row in enumerate(t["rows"]):
                        tag = "th" if ri == 0 else "td"
                        rows_h.append("<tr>" + "".join(f"<{tag}>{html.escape(fix(str(c or '')).replace(chr(10), ' '))}</{tag}>" for c in row) + "</tr>")
                    out.append(f'<div id="{i}" class="blk table" data-kind="table"><table>{"".join(rows_h)}</table>'
                               f'<div class="note">NOTE: table converted from PDF layout to HTML text; cell boundaries are reconstructed. See PDF if exact alignment matters.</div></div>')
                    stats["tables_html"] += 1
                else:
                    b64 = png_b64(page, t["rect"] + (-3, -3, 3, 3))
                    txt = " | ".join(" ; ".join(str(c or "").replace("\n", " ") for c in r) for r in t["rows"])
                    out.append(f'<figure id="{i}" class="fig table-img" data-kind="table-image"><img alt="Table (image)" src="data:image/png;base64,{b64}">'
                               f'<figcaption>NOTE: complex table shown as an image of the PDF; the text below is a rough machine extraction and may be mis-aligned.</figcaption>'
                               f'<details><summary>extracted text (unreliable layout)</summary><div class="figtext">{html.escape(fix(txt))}</div></details></figure>')
                    stats["tables_image"] += 1
            else:
                fr = figs[idx]
                i = nid()
                b64 = png_b64(page, fr + (-2, -2, 2, 2))
                ft = "".join(f'<p class="figtext-line">{x}</p>' for x in figtext[idx])
                det = f'<details><summary>text found inside the figure</summary>{ft}</details>' if ft else ""
                out.append(f'<figure id="{i}" class="fig" data-kind="figure"><img alt="Figure (image)" src="data:image/png;base64,{b64}">'
                           f'<figcaption>NOTE: figure/graphic rendered as an image from the PDF; its content is not machine-readable text. Caption (if any) follows as the next block.</figcaption>{det}</figure>')
                stats["figures"] += 1

        # figure-text must be collected before emitting figs
        for bi_, (k, idx) in consumed_by.items():
            if k == "f":
                figtext[idx].append(blocks[bi_]["html"])

        # unconsumed fig/tables get placed by y position
        pending = [("t", i, tinfo[i]["rect"].y0) for i in range(len(tinfo))] + [("f", i, figs[i].y0) for i in range(len(figs))]
        pending.sort(key=lambda x: x[2])

        for bi_, b in enumerate(blocks):
            # place any object whose y0 is above this block and which has no consumed block anchoring (consumed first-block handled below)
            if b["kind"] == "img":
                continue
            if bi_ in consumed_by:
                emit_obj(*consumed_by[bi_])
                continue
            # objects without any consumed blocks: insert before first block lower than them
            for (k, idx, y0) in pending:
                if (k, idx) in placed: continue
                has_consumed = any(v == (k, idx) for v in consumed_by.values())
                if not has_consumed and y0 <= b["bbox"].y0:
                    emit_obj(k, idx)
            t = b["text"]
            i = nid()
            cls, tag = ["blk"], "p"
            hh = b["html"]
            is_head = False
            if b.get("furn"):
                cls.append("furniture")
            else:
                short = len(t) < 140 and b["nlines"] <= 3
                if short and (b["size"] >= body * 1.12 or (b["boldfrac"] > 0.85 and not t.rstrip().endswith((".", ",", ";")) and len(t) < 110)) and not CAPTION.match(t):
                    is_head = True
                if is_head:
                    tag = "h3" if b["size"] >= body * 1.25 else "h4"
                    if b["size"] >= body * 1.7: tag = "h2"
                    cls.append("heading")
                    if REFHEAD.match(t): in_refs = True
                    elif OTHERHEAD.match(t): in_refs = False
                elif CAPTION.match(t):
                    cls.append("caption")
                elif b["size"] <= body * 0.92 and b["bbox"].y0 > H * 0.6 and b["size"] > 0:
                    cls.append("footnote")
                if in_refs and not is_head and "caption" not in cls:
                    cls.append("ref")
                if b["mathfrac"] >= 0.25 and len(t) < 600 and not is_head:
                    cls.append("eq")
            attrs = f'id="{i}" class="{" ".join(cls)}" data-kind="{"furniture" if b.get("furn") else ("heading" if is_head else "text")}"'
            if "eq" in cls and not b.get("furn"):
                b64 = png_b64(page, b["bbox"] + (-3, -3, 3, 3), 150)
                extra = (f'<details class="eqimg"><summary>equation / math rendering (image)</summary><img alt="equation image" src="data:image/png;base64,{b64}">'
                         f'<div class="note">NOTE: contains mathematical notation; text above is the PDF text layer and symbols may be mis-extracted. Image shows the original.</div></details>')
                out.append(f'<div {attrs}><{tag}>{hh}</{tag}>{extra}</div>' if False else f'<{tag} {attrs}>{hh}{extra}</{tag}>')
                stats["equations_img"] += 1
            else:
                out.append(f'<{tag} {attrs}>{hh}</{tag}>')
            stats["blocks"] += 1
            if b.get("furn"): stats["furniture"] += 1
        # remaining objects
        for (k, idx, y0) in pending:
            emit_obj(k, idx)
        sect.extend(out)
        sect.append("</section>")
        parts.append("\n".join(sect))

    meta = doc.metadata or {}
    title = html.escape(meta.get("title") or pdf.rsplit("/", 1)[-1])
    css = CSS
    htmldoc = (f'<!doctype html>\n<html lang="en"><head><meta charset="utf-8"><title>{title}</title>'
               f'<meta name="source-pdf" content="{html.escape(pdf.rsplit("/", 1)[-1])}">'
               f'<meta name="page-count" content="{n}"><style>{css}</style></head><body>\n'
               f'<header class="doc"><div class="srcnote">Converted from PDF <code>{html.escape(pdf.rsplit("/",1)[-1])}</code> &middot; {n} pages &middot; anchors: page <code>#pN</code>, block <code>#pN-bK</code></div></header>\n'
               + "\n".join(parts) + "\n</body></html>\n")
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(htmldoc)
    stats["bytes"] = len(htmldoc.encode())
    stats["body_size"] = body
    return dict(stats)


CSS = """
body{font:16px/1.55 Georgia,serif;max-width:860px;margin:0 auto;padding:12px 16px;color:#1b1b1b;background:#fff}
.srcnote{font:12px sans-serif;color:#666;border-bottom:1px solid #ddd;padding-bottom:6px;margin-bottom:10px}
section.page{border-top:2px solid #9ab;margin-top:28px;padding-top:4px}
.pagelabel{font:bold 12px sans-serif;color:#fff;background:#456;display:inline-block;padding:1px 8px;border-radius:3px}
.blk{margin:.55em 0}
h2.blk,h3.blk,h4.blk{margin:.9em 0 .3em;line-height:1.25}
.furniture{color:#aaa;font:11px sans-serif;margin:.2em 0}
.footnote{font-size:13px;color:#444}
.ref{font-size:14px;padding-left:1.5em;text-indent:-1.5em}
.caption{font-style:normal;color:#334;font-size:14px}
figure.fig{border:1px dashed #89a;padding:6px;margin:.8em 0;background:#f7f9fb}
figure.fig img{max-width:100%;height:auto}
.note,figcaption{font:12px sans-serif;color:#567}
table{border-collapse:collapse;font-size:13px;margin:.4em 0}
td,th{border:1px solid #ccc;padding:2px 6px;vertical-align:top}
details{font:12px sans-serif;color:#555}
@media (prefers-color-scheme:dark){body{background:#16181b;color:#ddd}.furniture{color:#666}figure.fig{background:#1d2126}td,th{border-color:#444}}
"""

if __name__ == "__main__":
    print(json.dumps(convert(sys.argv[1], sys.argv[2])))
