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

## Conversion stats (153 papers, 4,086 pages)
- 68,973 anchored blocks (4,810 marked `furniture`); 781 tables as HTML, 158 complex tables as images; 922 figures/graphics as images; 5,308 math blocks with an attached original image; 94 replication-package PDFs copied unchanged.
- Text check vs PDF (6-word shingles per page, all 153 papers): median coverage 98.7%, min 86.0%; all papers have one `<section>` per PDF page and unique block ids. Lower coverage (<90%: Piza 2021, Macaluso 2023, Ahmadjian 2001, Wu 2025, Trahms 2013, MartinsNeto 2024, Keller 2025-SSRN) comes from numeric tables, whose cells are reconstructed column-wise rather than row-wise.
- Quote finder spot-check: 14/14 sentences sampled from 14 papers in all topic folders resolved to the correct page.
- Pages with no text layer (rendered as page images): 1 page each in Dial-1995-JFE, Kwon-2007-JMIS (two copies, in `Downsizing/Others/` and `Sentiment/Community/`).
- Known limits: running headers that alternate (e.g. Datta 2010) are not always marked `furniture`; paragraphs split at column/page breaks; the "Replication" rule also covered `Methods/Staggered/ananthakrishnan-et-al-2025-…/` (code/figure output); `Claude-SDIDLiteratureReview-2026-Note` and `Jo-…Appendix` are converted as documents; 1 title flagged uncertain, authors/journal fields are heuristic (see `uncertain_fields`).
- `tools/verification.json` and `tools/conversion_log.json` hold per-paper numbers.
