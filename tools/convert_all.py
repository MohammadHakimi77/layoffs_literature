#!/usr/bin/env python3
"""Convert every paper PDF under source-pdfs/ to HTML at the same relative path (root tree);
copy replication-package files unchanged. Writes tools/conversion_log.json."""
import json, os, shutil, sys, time, traceback
from concurrent.futures import ProcessPoolExecutor
sys.path.insert(0, os.path.dirname(__file__))
SRC = "source-pdfs"

def is_replication(rel):
    low = rel.lower()
    if "replication" in low:
        return True
    # replication-package folder whose name lacks the word (Ananthakrishnan book-bans code outputs)
    return "/ananthakrishnan-et-al-2025-book-bans" in low

def work(rel):
    from pdf_to_html import convert
    out = os.path.splitext(rel)[0] + ".html"
    os.makedirs(os.path.dirname(out) or ".", exist_ok=True)
    t = time.time()
    try:
        st = convert(os.path.join(SRC, rel), out)
        st["status"] = "ok"
    except Exception as e:
        st = {"status": "error", "error": repr(e), "tb": traceback.format_exc()[-800:]}
    st["rel"] = rel; st["secs"] = round(time.time() - t, 1)
    return st

if __name__ == "__main__":
    papers, repl = [], []
    for d, _, fs in os.walk(SRC):
        for f in fs:
            rel = os.path.relpath(os.path.join(d, f), SRC)
            (repl if is_replication(rel) else papers).append(rel)
    for rel in repl:
        os.makedirs(os.path.dirname(rel) or ".", exist_ok=True)
        shutil.copy2(os.path.join(SRC, rel), rel)
    papers.sort()
    if len(sys.argv) > 1: papers = [p for p in papers if sys.argv[1] in p]
    res = []
    with ProcessPoolExecutor(4) as ex:
        for st in ex.map(work, papers):
            res.append(st); print(st["status"], st["rel"], st.get("pages"), st["secs"], flush=True)
    json.dump(dict(replication_copied=sorted(repl), results=res), open("tools/conversion_log.json", "w"), indent=1)
