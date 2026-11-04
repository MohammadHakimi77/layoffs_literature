#!/usr/bin/env python3
"""Locate a quote / phrase / reference in the HTML literature library.

Returns file, page, block id (anchor), and surrounding text.
Tolerant of hyphenation, line breaks, ligatures, curly quotes, case, punctuation and spacing:
both the query and the paper text are "squashed" (NFKC, lowercase, only letters/digits kept)
before comparing.  Standard library only.

  find_quote.py "exact words from the paper"                 # exact (squashed) match, default
  find_quote.py --fuzzy "approximate wording ..."            # ranks blocks by 4-gram overlap
  find_quote.py "quote" --topic Downsizing --paper Brauer    # narrow the search
  find_quote.py "quote" --context 1 --json
  find_quote.py "first part ... last part"                   # '...' / '…' = gap: parts must occur in order, close together

Exit code 0 = at least one hit, 1 = none.
"""
import argparse, html, json, os, re, sys, unicodedata

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..", ".."))
LIG = {"ﬀ": "ff", "ﬁ": "fi", "ﬂ": "fl", "ﬃ": "ffi", "ﬄ": "ffl", "ﬅ": "st", "ﬆ": "st", "­": ""}
BLOCK_RE = re.compile(r'id="(p(\d+)-b(\d+))" class="([^"]*)"')


def squash(s):
    s = unicodedata.normalize("NFKC", s)
    for k, v in LIG.items():
        s = s.replace(k, v)
    return "".join(c for c in s.lower() if c.isalnum())


def squash_map(s):
    """squashed string + for each squashed char its index in s."""
    out, idx = [], []
    s2 = unicodedata.normalize("NFKC", s)
    for i, c in enumerate(s2):
        for k, v in LIG.items():
            if c == k:
                c = v
        for d in c.lower():
            if d.isalnum():
                out.append(d); idx.append(i)
    return "".join(out), idx


def tidy(h):
    h = re.sub(r'src="data:[^"]*"', 'src=""', h)
    h = re.sub(r'<details class="eqimg">.*?</details>', "", h, flags=re.S)
    h = re.sub(r'<div class="note">.*?</div>|<figcaption>.*?</figcaption>|<summary>.*?</summary>|<style>.*?</style>', "", h, flags=re.S)
    h = re.sub(r"</t[dh]>", " ", h)
    h = re.sub(r"<[^>]+>", "", h)
    return re.sub(r"\s+", " ", html.unescape(h)).strip()


def load_paper(path):
    raw = open(path, encoding="utf-8").read()
    raw = re.sub(r'src="data:[^"]*"', 'src=""', raw)
    ms = list(BLOCK_RE.finditer(raw))
    blocks = []
    for k, m in enumerate(ms):
        end = ms[k + 1].start() if k + 1 < len(ms) else len(raw)
        seg = raw[m.end():end]
        seg = seg.split("</section>")[0]
        seg = re.sub(r"<[a-z0-9]*\s*$", "", seg)  # next block's partial open tag
        txt = tidy("<x " + seg)  # drop remainder of open tag
        txt = txt.lstrip("> ").strip() if txt.startswith(">") else txt
        blocks.append(dict(id=m.group(1), page=int(m.group(2)), n=int(m.group(3)), cls=m.group(4), text=txt))
    return blocks


def find_html(root, topic, paper):
    for d, ds, fs in os.walk(root):
        ds[:] = [x for x in ds if not x.startswith(".") and x not in ("records", "tools", "node_modules", "source-pdfs")]
        for f in fs:
            if not f.endswith(".html") or f == "index.html" and d == root:
                continue
            rel = os.path.relpath(os.path.join(d, f), root)
            if topic and topic.lower() not in rel.lower().split(os.sep)[0].lower() and topic.lower() not in rel.lower():
                continue
            if paper and paper.lower() not in f.lower():
                continue
            yield rel


def ctx(blocks, i, n):
    lo, hi = max(0, i - n), min(len(blocks), i + n + 1)
    return [dict(id=b["id"], text=b["text"], cls=b["cls"]) for b in blocks[lo:hi]]


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("quote")
    ap.add_argument("--fuzzy", action="store_true", help="approximate matching (ranked)")
    ap.add_argument("--topic", help="only folders/paths containing this (e.g. Downsizing, Methods/SDID)")
    ap.add_argument("--paper", help="only files whose name contains this (e.g. Brauer)")
    ap.add_argument("--root", default=ROOT)
    ap.add_argument("--context", type=int, default=1, help="blocks of context each side (default 1)")
    ap.add_argument("--max", type=int, default=5, help="max hits to print (default 5)")
    ap.add_argument("--min-score", type=float, default=0.55, help="fuzzy threshold 0-1 (default 0.55)")
    ap.add_argument("--json", action="store_true")
    a = ap.parse_args()

    parts = [p for p in re.split(r"\.\.\.|…", a.quote) if squash(p)]
    qs = [squash(p) for p in parts]
    if not qs:
        sys.exit("empty query")
    hits = []
    for rel in sorted(find_html(a.root, a.topic, a.paper)):
        blocks = load_paper(os.path.join(a.root, rel))
        if not blocks:
            continue
        # document-level squashed text with block offsets
        sq, starts, pos = [], [], 0
        for b in blocks:
            s = squash(b["text"])
            starts.append(pos); sq.append(s); pos += len(s)
        doc = "".join(sq)
        import bisect
        def blk(o): return bisect.bisect_right(starts, o) - 1
        if not a.fuzzy:
            o = doc.find(qs[0]); 
            while o != -1:
                ok, end = True, o + len(qs[0])
                for q in qs[1:]:   # later parts must follow within 3000 chars
                    j = doc.find(q, end, end + 3000)
                    if j == -1: ok = False; break
                    end = j + len(q)
                if ok:
                    i0, i1 = blk(o), blk(max(o, end - 1))
                    hits.append(dict(file=rel, page=blocks[i0]["page"], block=blocks[i0]["id"], end_block=blocks[i1]["id"],
                                     anchor=f"{rel}#{blocks[i0]['id']}", score=1.0, mode="exact",
                                     match=" ".join(b["text"] for b in blocks[i0:i1 + 1])[:1500], context=ctx(blocks, i0, a.context)))
                o = doc.find(qs[0], o + 1)
        else:
            q = "".join(qs)
            grams = {q[k:k + 4] for k in range(max(1, len(q) - 3))}
            for i in range(len(blocks)):
                cand = []
                for span in (1, 2, 3):
                    if i + span > len(blocks): break
                    t = "".join(sq[i:i + span])
                    if len(t) < 8: continue
                    tg = {t[k:k + 4] for k in range(max(1, len(t) - 3))}
                    cand.append((len(grams & tg) / len(grams), span))
                if not cand: continue
                mx = max(c[0] for c in cand)
                score, span = min((c for c in cand if c[0] >= mx - 0.05), key=lambda c: c[1])
                if score >= a.min_score:
                    hits.append(dict(file=rel, page=blocks[i]["page"], block=blocks[i]["id"], end_block=blocks[i + span - 1]["id"],
                                     anchor=f"{rel}#{blocks[i]['id']}", score=round(score, 3), mode="fuzzy", _i=i, _span=span,
                                     match=" ".join(b["text"] for b in blocks[i:i + span])[:1500], context=ctx(blocks, i, a.context)))
    if a.fuzzy:
        kept = []
        for h in sorted(hits, key=lambda h: (-h["score"], h["_span"])):
            if any(k["file"] == h["file"] and not (h["_i"] + h["_span"] <= k["_i"] or k["_i"] + k["_span"] <= h["_i"]) for k in kept):
                continue
            kept.append(h)
        hits = kept
        for h in hits: h.pop("_i"); h.pop("_span")
    hits = hits[: a.max]
    if a.json:
        print(json.dumps(hits, indent=1, ensure_ascii=False))
    elif not hits:
        print("NO MATCH." + ("" if a.fuzzy else " Try --fuzzy, a shorter phrase, or check the quote is from body text (figures/tables may be images)."))
    else:
        for h in hits:
            print(f"== {h['file']}  page {h['page']}  block {h['block']}" + (f"..{h['end_block']}" if h['end_block'] != h['block'] else "") + f"  [{h['mode']} {h['score']}]")
            print(f"   cite: {h['anchor']}")
            for c in h["context"]:
                mark = ">>" if c["id"] == h["block"] else "  "
                print(f" {mark} [{c['id']}] {c['text'][:700]}")
            print()
    sys.exit(0 if hits else 1)


if __name__ == "__main__":
    main()
