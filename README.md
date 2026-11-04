# layoffs_literature

A Claude-readable literature library on layoffs / downsizing, sentiment and DiD methods.
Every paper PDF is converted to **one self-contained HTML file** (same name, same folder path) with exact-location anchors, so a quote or reference can be traced to a page and block.

## Structure
| Path | Content |
|---|---|
| `Downsizing/`, `Downsizing/Others/`, `Sentiment/` (+`Community/`, `Word of mouth/`), `Methods/` (+`SDID/`, `Staggered/`), `Behavioral.md/` | paper HTML files (topic folders mirror the local literature folder) |
| `Methods/**/…Replication…`, `Methods/Staggered/ananthakrishnan-et-al-…/` | replication-package PDFs, copied **unchanged** (not papers) |
| `catalog.json` | one entry per paper: id, title, authors, year, journal, topic folder, file, page count, DOI, `uncertain_fields` |
| `records/<id>.json` | per-paper record (conversion stats, flags, hash) |
| `MANIFEST.json` | all files with sizes/hashes |
| `index.html` | papers by topic folder with links |
| `.claude/skills/layoffs-library/` | Claude skill + `scripts/find_quote.py` |
| `tools/` | converter and catalog builder (need the PDFs from branch `staging-pdfs`) |

Original PDFs are only on branch `staging-pdfs` (`source-pdfs/`).

## HTML conventions
- Each PDF page: `<section id="p3">` with a visible "Page 3" label (PDF page index, not the printed page number).
- Each block: `id="p3-b7"` (page 3, block 7). Classes: `heading`, `footnote`, `caption`, `ref` (reference list), `furniture` (running headers/footers/page numbers, shown lighter), `eq`.
- Figures and complex tables are embedded as base64 PNG with a NOTE; text found inside figures is kept in a collapsed `<details>`. Math blocks keep the PDF text plus an image of the original.
- Text is not paraphrased. Only ligature glyphs are expanded and line-end hyphenation is joined.
- Cite as `path/File.html#p3-b7`.

## Finding a quote
```bash
python .claude/skills/layoffs-library/scripts/find_quote.py "exact phrase" [--topic Downsizing] [--paper Brauer]
python .claude/skills/layoffs-library/scripts/find_quote.py --fuzzy "approximate wording"
```
Returns file, page, block id and surrounding text; tolerant of hyphenation, line breaks, ligatures, case and punctuation.

## Caveats
- Metadata comes from file names and PDF first pages only; fields in `uncertain_fields` are heuristic.
- Layout reconstruction is automatic: multi-column order, paragraphs split across columns/pages, and table cell alignment can be imperfect.
- Two scanned 1990s papers were intentionally excluded.
