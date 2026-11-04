#!/usr/bin/env python3
"""Build catalog.json, MANIFEST.json, records/*.json, index.html from the HTML tree + source-pdfs (page 1 text)."""
import hashlib, html, json, os, re, sys, warnings
warnings.filterwarnings("ignore")
import pymupdf as fitz
sys.path.insert(0, os.path.dirname(__file__))
from convert_all import is_replication

SRC = "source-pdfs"
JOURNALS = {
 "MKSC": "Marketing Science", "JM": "Journal of Marketing", "JMR": "Journal of Marketing Research",
 "JCR": "Journal of Consumer Research", "JAMS": "Journal of the Academy of Marketing Science",
 "IJRM": "International Journal of Research in Marketing", "JCP": "Journal of Consumer Psychology",
 "MS": "Management Science", "AMJ": "Academy of Management Journal", "AMR": "Academy of Management Review",
 "ASQ": "Administrative Science Quarterly", "SMJ": "Strategic Management Journal", "JMS": "Journal of Management Studies",
 "JOM": "Journal of Management", "OS": "Organization Science", "JMO": "Journal of Management & Organization",
 "BJM": "British Journal of Management", "JBR": "Journal of Business Research", "JBE": "Journal of Business Ethics",
 "JFE": "Journal of Financial Economics", "JF": "Journal of Finance", "QJE": "Quarterly Journal of Economics",
 "JEL": "Journal of Economic Literature", "JAE": "Journal of Accounting and Economics", "JEEA": "Journal of the European Economic Association",
 "JEG": "Journal of Economic Geography", "AEJAE": "American Economic Journal: Applied Economics", "REStud": "Review of Economic Studies",
 "PNAS": "Proceedings of the National Academy of Sciences", "ISR": "Information Systems Research", "JMIS": "Journal of Management Information Systems",
 "HRMJ": "Human Resource Management Journal", "HRM": "Human Resource Management", "IJHRM": "International Journal of Human Resource Management",
 "IR": "Industrial Relations", "SER": "Socio-Economic Review", "JSR": "Journal of Service Research", "IMM": "Industrial Marketing Management",
 "POM": "Production and Operations Management", "JIM": "Journal of International Marketing", "SF": "Social Forces",
 "SSRN": "SSRN working paper", "arXiv": "arXiv preprint", "NBER": "NBER working paper", "IZA": "IZA discussion paper",
 "CEPR": "CEPR discussion paper", "CESifo": "CESifo working paper", "IFAU": "IFAU working paper", "Chapter": "Book chapter",
 "Note": "Note (non-journal)", "TI": "(uncertain: 'TI')", "WSJ": "Wall Street Journal",
}
# codes whose expansion is a best guess from the abbreviation -> flagged uncertain
GUESS = {"TI", "JMO", "SJR", "RP", "WD", "TQMBE", "MCS", "JSM", "ICC", "AJM", "JRCS", "JPA", "JOB", "JMD", "JEJ", "IMDS", "IJSSHR",
         "IJCHM", "HSR", "EJPE", "DSS", "Socius", "SMR", "JMI", "ACMGames", "SER", "IMM", "JIM", "POM"}


def camel_words(s):
    return [w.lower() for w in re.findall(r"[A-Z][a-z0-9]+|[A-Z]+(?![a-z])|[a-z]+|\d+", s)]


def parse_name(stem):
    m = re.match(r"^(.+?)-(.+)-(\d{4})-([A-Za-z0-9]+)$", stem)
    if not m: return None
    return dict(author=m.group(1), topic=m.group(2), year=int(m.group(3)), code=m.group(4))


def first_page(pdf):
    doc = fitz.open(pdf)
    pages = min(2, len(doc))
    lines = []
    for pn in range(pages):
        d = doc[pn].get_text("dict")
        H = doc[pn].rect.height
        for b in d["blocks"]:
            if b["type"] != 0: continue
            for ln in b["lines"]:
                t = "".join(s["text"] for s in ln["spans"]).strip()
                if t:
                    lines.append(dict(t=t, size=max(s["size"] for s in ln["spans"]), y=ln["bbox"][1] / H, page=pn))
    meta = doc.metadata or {}
    txt = " ".join(l["t"] for l in lines)
    return doc.page_count, lines, meta, txt


def guess_title(lines, topic_words, meta):
    cands = []
    p1 = [l for l in lines if l["page"] == 0 and l["y"] < 0.65]
    # group consecutive lines of (nearly) same size
    i = 0
    while i < len(p1):
        j = i
        while j + 1 < len(p1) and abs(p1[j + 1]["size"] - p1[i]["size"]) < 0.6: j += 1
        t = " ".join(l["t"] for l in p1[i:j + 1])
        if 12 <= len(t) <= 300:
            cands.append((p1[i]["size"], t, i, j))
        i = j + 1
    mt = (meta.get("title") or "").strip()
    if len(mt) > 12 and not re.search(r"\.(pdf|docx?)$|microsoft word|untitled|^doi", mt, re.I): cands.append((0, mt, -1, -1))
    best, bs = None, -1
    for size, t, i, j in cands:
        w = set(re.findall(r"[a-z0-9]+", t.lower()))
        ov = sum(1 for x in topic_words if any(x in y or y in x for y in w if len(y) > 2)) / max(1, len(topic_words))
        sc = ov * 10 + size / 10
        if sc > bs: best, bs, bov = (size, t, i, j), sc, ov
    if not best: return None, "uncertain", None, None
    conf = "good" if bov >= 0.5 else "uncertain"
    return re.sub(r"\s+", " ", best[1]), conf, best[2], best[3]


def guess_authors(lines, endidx, first_author):
    if endidx is None or endidx < 0: return None
    p1 = [l for l in lines if l["page"] == 0 and l["y"] < 0.65]
    cand = []
    for l in p1[endidx + 1: endidx + 7]:
        t = l["t"]
        if re.search(r"abstract|keywords|university|institute|department|school|college|\d{3,}|@|http", t, re.I): 
            if cand: break
            continue
        if re.match(r"^[A-Z][\w'’.\-]+(\s+[A-Z][\w'’.\-]+){0,4}(\s*(,|and|&)\s*[A-Z][\w'’.\-]+(\s+[A-Z][\w'’.\-]+){0,4})*\W*$", t):
            cand.append(t)
        elif cand: break
    s = " ".join(cand).strip() or None
    if s and first_author.lower() not in s.lower(): return None
    return s


def main():
    htmls = []
    for d, ds, fs in os.walk("."):
        ds[:] = [x for x in ds if not x.startswith(".") and x not in ("records", "tools", "source-pdfs")]
        for f in fs:
            if f.endswith(".html") and not (d == "." and f == "index.html"):
                htmls.append(os.path.relpath(os.path.join(d, f), "."))
    htmls.sort()
    os.makedirs("records", exist_ok=True)
    catalog, ids = [], set()
    log = {r["rel"]: r for r in json.load(open("tools/conversion_log.json"))["results"]} if os.path.exists("tools/conversion_log.json") else {}
    for rel in htmls:
        stem = os.path.splitext(os.path.basename(rel))[0]
        pdf = os.path.join(SRC, os.path.splitext(rel)[0] + ".pdf")
        folder = os.path.dirname(rel)
        pn = parse_name(stem)
        uncertain = []
        rec = dict(file=rel, topic_folder=folder, source_pdf_on_branch_staging_pdfs=pdf)
        if pn:
            tw = [w for w in camel_words(pn["topic"]) if len(w) > 2]
            rec.update(first_author_surname=pn["author"], year=pn["year"], journal_code=pn["code"], filename_topic=pn["topic"])
            rec["journal"] = JOURNALS.get(pn["code"], pn["code"])
            if pn["code"] in GUESS or pn["code"] not in JOURNALS: uncertain.append("journal")
        else:
            tw = camel_words(stem); uncertain += ["year", "journal", "first_author_surname"]
            rec.update(first_author_surname=None, year=None, journal_code=None, journal=None)
        pcount, lines, meta, txt = first_page(pdf)
        rec["page_count"] = pcount
        title, conf, ti, tj = guess_title(lines, tw, meta)
        rec["title"] = title
        if conf != "good": uncertain.append("title")
        au = guess_authors(lines, tj, pn["author"]) if pn else None
        rec["authors"] = au
        uncertain.append("authors") # always heuristic from PDF text; first_author_surname is from filename
        m = re.search(r"\b(10\.\d{4,9}/[^\s\"<>]+)", txt)
        rec["doi"] = m.group(1).rstrip(".,;)") if m else None
        yrs = sorted({int(y) for y in re.findall(r"(?:©|\(c\)|copyright)\s*(\d{4})", txt, re.I)})
        rec["copyright_years_on_first_pages"] = yrs
        if pn and yrs and pn["year"] not in yrs: uncertain.append("year")
        rec["uncertain_fields"] = sorted(set(uncertain))
        base = re.sub(r"[^a-z0-9]+", "-", (folder + "-" + stem).lower()).strip("-")
        rid = base; k = 2
        while rid in ids: rid = f"{base}-{k}"; k += 1
        ids.add(rid); rec = {"id": rid, **rec}
        st = log.get(os.path.splitext(rel)[0] + ".pdf", {})
        rec["conversion"] = {k: st.get(k, 0) for k in ("blocks", "furniture", "figures", "tables_html", "tables_image", "equations_img", "image_only_pages")}
        h = open(rel, "rb").read()
        rec["html_bytes"] = len(h); rec["html_sha256"] = hashlib.sha256(h).hexdigest()
        rec["note_flags"] = []
        if rec["conversion"]["image_only_pages"]: rec["note_flags"].append("has pages without text layer (rendered as images)")
        if not pn: rec["note_flags"].append("filename does not follow Author-Topic-Year-Journal pattern (news article/other)")
        if "Appendix" in stem: rec["note_flags"].append("appendix/supplement document")
        if pn and pn["code"] == "Note": rec["note_flags"].append("non-journal note")
        json.dump(rec, open(f"records/{rid}.json", "w"), indent=1, ensure_ascii=False)
        catalog.append(rec)
    slim = [{k: r[k] for k in ("id", "title", "authors", "first_author_surname", "year", "journal", "journal_code", "topic_folder", "file", "page_count", "doi", "uncertain_fields")} for r in catalog]
    json.dump(dict(note="Metadata parsed from file names (Author-Topic-Year-Journal) and PDF first pages. Fields listed in uncertain_fields are heuristic; verify against the HTML page 1.",
                   count=len(slim), papers=slim), open("catalog.json", "w"), indent=1, ensure_ascii=False)
    repl = sorted(json.load(open("tools/conversion_log.json"))["replication_copied"]) if os.path.exists("tools/conversion_log.json") else []
    man = dict(generated_from_branch="staging-pdfs", papers=[dict(id=r["id"], file=r["file"], source_pdf=r["source_pdf_on_branch_staging_pdfs"], pages=r["page_count"], bytes=r["html_bytes"], sha256=r["html_sha256"]) for r in catalog],
               replication_files=[dict(file=f, bytes=os.path.getsize(f)) for f in repl if os.path.exists(f)])
    json.dump(man, open("MANIFEST.json", "w"), indent=1, ensure_ascii=False)
    # index.html
    by = {}
    for r in catalog: by.setdefault(r["topic_folder"], []).append(r)
    from urllib.parse import quote
    out = ['<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Layoffs literature library</title>'
           '<style>body{font:15px/1.5 system-ui,sans-serif;max-width:960px;margin:0 auto;padding:16px}h2{margin-top:1.6em;border-bottom:1px solid #ccc}li{margin:.25em 0}small{color:#666}'
           '@media(prefers-color-scheme:dark){body{background:#16181b;color:#ddd}a{color:#8cf}small{color:#999}}</style></head><body>',
           f'<h1>Layoffs / downsizing literature library</h1><p>{len(catalog)} papers as page-anchored HTML. See <a href="README.md">README.md</a>. Metadata marked <b>?</b> is uncertain.</p>']
    for folder in sorted(by):
        out.append(f'<h2>{html.escape(folder)} <small>({len(by[folder])})</small></h2><ul>')
        for r in sorted(by[folder], key=lambda r: (r["year"] or 0, r["file"])):
            q = "?" if "title" in r["uncertain_fields"] else ""
            out.append(f'<li><a href="{quote(r["file"])}">{html.escape(r["title"] or os.path.basename(r["file"]))}</a>{q} <small>— {html.escape(r["first_author_surname"] or "")} {r["year"] or ""}, {html.escape(r["journal_code"] or "")}, {r["page_count"]} p.</small></li>')
        out.append("</ul>")
    out.append("</body></html>")
    open("index.html", "w", encoding="utf-8").write("\n".join(out))
    print(len(catalog), "papers;", sum("title" in r["uncertain_fields"] for r in catalog), "uncertain titles")

if __name__ == "__main__":
    main()
