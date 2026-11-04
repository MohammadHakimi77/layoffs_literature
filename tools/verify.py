#!/usr/bin/env python3
"""Verify every converted paper: section per page, unique ids, and text coverage vs PDF (per-page 6-word shingles)."""
import json, os, re, sys, warnings
warnings.filterwarnings("ignore")
import pymupdf
sys.path.insert(0, ".claude/skills/layoffs-library/scripts")
from find_quote import load_paper, squash
def words(t): 
    import unicodedata
    t = unicodedata.normalize("NFKC", t).replace("­", "")
    for k, v in {"ﬁ": "fi", "ﬂ": "fl", "ﬀ": "ff", "ﬃ": "ffi", "ﬄ": "ffl"}.items(): t = t.replace(k, v)
    return re.findall(r"[a-z0-9]+", t.lower())
def check(rel):
    pdf = "source-pdfs/" + os.path.splitext(rel)[0] + ".pdf"
    d = pymupdf.open(pdf)
    raw = open(rel, encoding="utf-8").read()
    secs = re.findall(r'<section id="p(\d+)"', raw)
    ids = re.findall(r' id="(p\d+-b\d+)"', raw)
    res = dict(file=rel, pages=d.page_count, sections_ok=secs == [str(i) for i in range(1, d.page_count + 1)], dup_ids=len(ids) - len(set(ids)))
    blocks = load_paper(rel)
    bypage = {}
    for b in blocks: bypage.setdefault(b["page"], []).append(b["text"])
    tot = hit = 0
    for i, p in enumerate(d, 1):
        w = words(p.get_text())
        hw = " ".join(words(" ".join(bypage.get(i, []))))
        # squash-insensitive: drop spaces to survive hyphen joins
        hs = hw.replace(" ", "")
        for k in range(0, max(0, len(w) - 5), 3):
            sh = "".join(w[k:k + 6]); tot += 1
            if sh in hs: hit += 1
    res["coverage"] = round(hit / tot, 4) if tot else None
    return res
if __name__ == "__main__":
    files = json.load(open("catalog.json"))["papers"]
    out = [check(p["file"]) for p in files]
    json.dump(out, open("tools/verification.json", "w"), indent=1)
    bad = [o for o in out if not o["sections_ok"] or o["dup_ids"] or (o["coverage"] or 1) < 0.9]
    cov = sorted(o["coverage"] for o in out if o["coverage"] is not None)
    print("papers", len(out), "min cov", cov[0], "median", cov[len(cov) // 2], "bad", len(bad))
    for o in sorted(bad, key=lambda o: o["coverage"] or 0): print(o)
