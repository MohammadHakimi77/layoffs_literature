---
name: layoffs-library
description: Use when the user asks about the layoffs / downsizing / sentiment / DiD-methods literature kept in this repo (papers as page-anchored HTML), wants a paper's content, a quote, a reference, or the exact page/paragraph where something is said, or wants papers cited by file + anchor. Covers finding the right topic folder, reading papers, locating quotes, and citing by anchor id.
---

# Layoffs literature library

This repo (`layoffs_literature`, branch `main`) holds ~150 academic papers converted from PDF to **one self-contained HTML file each**, in the same folder tree as the user's local literature folder. Original PDFs live only on branch `staging-pdfs` (`source-pdfs/`).

## Layout
- `README.md` — structure and conventions (read first if anything below is unclear)
- `catalog.json` — one entry per paper: `id, title, authors, year, journal, topic_folder, file, page_count, doi, uncertain_fields`
- `records/<id>.json` — fuller per-paper record (conversion stats, flags)
- `MANIFEST.json` — file list with hashes; also lists replication files
- `index.html` — human-readable list by topic
- Topic folders: `Downsizing/` (+ `Downsizing/Others/`), `Sentiment/` (+ `Community/`, `Word of mouth/`), `Methods/` (+ `SDID/`, `Staggered/`), `Behavioral.md/` (a directory despite the name).
- `Methods/**/…Replication…` and `Methods/Staggered/ananthakrishnan-et-al-…/` hold **unconverted PDFs** (replication code/figure output). They are not papers; don't cite them as such.

## Anchors (how every paper HTML is built)
- each PDF page: `<section id="p3">` with a visible "Page 3" label (page = PDF page index, **not** the printed journal page number)
- each block (paragraph, heading, footnote, caption, table, figure): `id="p3-b7"` = page 3, block 7
- classes: `furniture` (running headers/footers/page numbers — ignore for content), `heading`, `footnote`, `caption`, `ref` (reference list entry), `eq` (math; has an image of the original), `table`/`fig` (see below)
- A paragraph that continues across a column/page break is split into two blocks; quotes spanning blocks are reported as `pX-bK..pY-bM`.

## Workflow
1. **Pick the paper.** Read `catalog.json` (or grep it) — filter by `topic_folder`, `year`, `first_author_surname`, title words. Prefer the topic folder that matches the question (e.g. investor reactions to layoffs → `Downsizing/`; SDID / staggered DiD estimators → `Methods/`; word-of-mouth / online community reaction → `Sentiment/`).
2. **Read the HTML** with the Read tool (strip nothing; base64 images are in `<img>`, so for large files prefer reading specific pages: grep for `id="p5"` or use `scripts/find_quote.py`). Do not rely on memory of the paper.
3. **Locate quotes/references** with the finder, never by guessing:
   ```bash
   python .claude/skills/layoffs-library/scripts/find_quote.py "exact words" [--topic Downsizing] [--paper Brauer]
   python .claude/skills/layoffs-library/scripts/find_quote.py --fuzzy "approximate wording"
   ```
   Exact mode ignores case, punctuation, hyphenation, line breaks, ligatures, curly quotes. `...` between fragments = gap. `--json` for machine output; `--context N` for more surrounding blocks. Fuzzy mode ranks blocks (score 0–1); treat scores < ~0.7 as "probable, verify by reading".
4. **Cite** as `relative/path/File.html#pX-bY` (add the paper's author/year). Example: `Downsizing/Brauer-DownsizingFirmPerformance-2014-JMS.html#p5-b3`. Give the PDF page number as "PDF p. 5" and note it may differ from the printed page.

## Rules
- Cite and quote **only text that is actually in the HTML**. If you can't find it with the finder or by reading, say so — do not reconstruct from memory.
- **Never invent anchors.** Every `pX-bY` you cite must come from a finder result or from a block you read. Re-check with `grep -o 'id="p5-b3"' file.html` if in doubt.
- Quote verbatim. The converter only expands ligature glyphs (ﬁ→fi) and joins line-end hyphenation (so "down-\nsizing" → "downsizing"; a genuine hyphenated compound broken at a line end may have lost its hyphen). Mention this if exact typography matters.
- **Figures, some tables and equations are images.** A `<figure class="fig">` (or `table-img`) is an image of the PDF region with a NOTE; say explicitly "this is a figure/table shown as an image", and don't read numbers out of it unless you actually looked at the image. HTML tables (`div.table`) are reconstructed from layout; cell alignment may be imperfect. `eq` blocks have the PDF text layer plus an image of the original — symbols may be mis-extracted.
- Pages with no text layer are rendered whole as images (`class="fig pageimage"`); check `records/<id>.json` → `note_flags`.
- Metadata in `catalog.json` is parsed from file names and first-page text; fields in `uncertain_fields` (often `authors`, `journal`, `title`) must be verified on page 1 of the HTML before being put in a bibliography. Year is from the file name (may be online-first year).
- Furniture blocks are not paper content; don't quote them.
- This library has no spreadsheets, notes or ideas — it is only the papers. Don't claim what the user thinks of a paper.
- To re-run the conversion or rebuild the catalog, see `tools/` (needs `source-pdfs/` from branch `staging-pdfs`).
