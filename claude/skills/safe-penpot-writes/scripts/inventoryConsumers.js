/* Phase 0 — count the consumers of a token, per page, BEFORE any write.
   Paste into an execute_code call. Read-only; safe to run anywhere: reads do not
   need the page open, and this script deliberately never calls openPage (#1).
   Inputs : TOKEN_NAME, PROP (a TokenProperty: "typography", "fill", "columnGap"…).
   Output : per-page counts + the total. WRITE THE TOTAL DOWN — after the write it
            is the only thing that distinguishes "applied" from "silently skipped".
   Verify any unfamiliar signature with penpot_api_info first. */

const TOKEN_NAME = "REPLACE-ME";
const PROP = "REPLACE-ME";

const perPage = {};
let total = 0;
for (const p of penpotUtils.getPages()) {
  const page = penpotUtils.getPageById(p.id);
  const n = penpotUtils.findShapes(
    (s) => (s.tokens || {})[PROP] === TOKEN_NAME, page.root).length;
  perPage[p.name] = n;
  total += n;
}
return { token: TOKEN_NAME, prop: PROP, perPage, total };
