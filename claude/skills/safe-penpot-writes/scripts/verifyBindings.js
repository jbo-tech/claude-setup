/* Phase 2 — the read-back. MUST run in a call of its own: state read inside the
   call that wrote is stale by construction (#1-#3).
   Read-only across every page, including closed ones — never calls openPage (#1).
   Inputs : TOKEN_NAME, PROP, EXPECTED (the Phase 0 total), OLD_NAME (optional,
            when verifying a rename — expect 0).
   Output : { bound, oldName, delta, sample }. `delta !== 0` means STOP and
            report; do not re-run the write (re-applying unbinds — #2). */

const TOKEN_NAME = "REPLACE-ME";
const PROP = "REPLACE-ME";
const EXPECTED = 0;
const OLD_NAME = null;

/* A text shape returns "mixed" when its ranges disagree. "mixed" reads like a
   value and passes the eye — it is not proof, so it is rejected as a sample. */
const readRendered = (s) => {
  if (PROP === "typography") {
    const size = s.fontSize, weight = s.fontWeight;
    if (size === "mixed" || weight === "mixed") return null;
    return size + "/" + weight;
  }
  if (PROP === "fill") return s.fills && s.fills[0] ? s.fills[0].fillColor : null;
  if (PROP === "strokeWidth") return s.strokes && s.strokes[0] ? s.strokes[0].strokeWidth : null;
  return s[PROP] === undefined ? null : s[PROP];
};

let bound = 0, old = 0, sample = null, mixedSkipped = 0;
for (const p of penpotUtils.getPages()) {
  const page = penpotUtils.getPageById(p.id);
  const hits = penpotUtils.findShapes((s) => (s.tokens || {})[PROP] === TOKEN_NAME, page.root);
  bound += hits.length;
  for (const s of hits) {
    if (sample) break;
    const rendered = readRendered(s);
    if (rendered === null) { mixedSkipped += 1; continue; }
    sample = { name: s.name, page: p.name, rendered };
  }
  if (OLD_NAME) {
    old += penpotUtils.findShapes(
      (s) => (s.tokens || {})[PROP] === OLD_NAME, page.root).length;
  }
}

/* No usable sample means no proof of the rendered value — say so, don't return
   a shape that reads "mixed/mixed". */
if (!sample && bound > 0) sample = { name: null, reason: "mixed-range", mixedSkipped };

return { bound, expected: EXPECTED, delta: bound - EXPECTED, oldName: old, sample };
