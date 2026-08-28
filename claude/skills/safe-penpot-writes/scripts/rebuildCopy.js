/* Phase 4 — rebuild a component copy after a STRUCTURAL change to its main
   component. A copy refuses insertChild/removeChild (#5), so the only way to
   propagate structure is to replace the copy.
   This script WRITES: run it on the copy's page, with that page ACTIVE (#1).
   Inputs : COPY_NAME, plus TEXTS to restore (name -> content).
   Output : geometry, index, and interactionsRestored "n/m" — a shortfall is the
            signal, not a detail.
   NOTE: read the copy FIRST in a separate call and keep the record — this script
   destroys the original, and whatever it fails to replay is gone.
   Verify addInteraction's signature with penpot_api_info before the first run. */

const COPY_NAME = "REPLACE-ME";
const TEXTS = { /* "label": "…", "value": "…" */ };

const page = penpot.currentPage;
const old = penpotUtils.findShape((s) => s.name === COPY_NAME, page.root);
if (!old) throw new Error("copy not found: " + COPY_NAME);

/* Interactions live on any descendant, not just the copy root, so they are
   indexed by child-index path and replayed onto the matching node. */
const pathOf = (shape) => {
  const path = [];
  let node = shape;
  while (node && node.id !== old.id) {
    const siblings = (node.parent && node.parent.children) || [];
    path.unshift(siblings.findIndex((x) => x.id === node.id));
    node = node.parent;
  }
  return path;
};
const atPath = (root, path) =>
  path.reduce((node, i) => (node && node.children ? node.children[i] : null), root);

const seen = new Set();
const carriers = [old, ...penpotUtils.findShapes(() => true, old)]
  .filter((s) => !seen.has(s.id) && seen.add(s.id));

const record = [];
for (const c of carriers) {
  for (const it of c.interactions || []) {
    record.push({ path: pathOf(c), trigger: it.trigger, delay: it.delay, action: it.action });
  }
}

const comp = old.component();
const props = comp.variantProps;
const parent = old.parent;
const idx = (parent.children || []).findIndex((x) => x.id === old.id);
const sizing = old.layoutChild ? old.layoutChild.horizontalSizing : null;

const target = comp.variants
  ? comp.variants.variantComponents().find(
      (v) => Object.keys(props).every((k) => v.variantProps[k] === props[k]))
  : comp;
if (!target) throw new Error("no variant matches: " + JSON.stringify(props));

const fresh = target.instance();
fresh.name = COPY_NAME;
old.remove();                    // before insertChild, or the index shifts under you
parent.insertChild(idx, fresh);
if (sizing && fresh.layoutChild) fresh.layoutChild.horizontalSizing = sizing;

for (const name of Object.keys(TEXTS)) {
  const t = penpotUtils.findShapes((x) => x.type === "text" && x.name === name, fresh)[0];
  if (t) t.characters = TEXTS[name];
}

/* Replay, counting failures rather than swallowing them: a lost interaction is
   invisible on the canvas — exactly the failure class this skill exists for. */
let restored = 0;
const failed = [];
for (const r of record) {
  const host = r.path.length ? atPath(fresh, r.path) : fresh;
  if (!host || !host.addInteraction) { failed.push(r.path.join("/") || "root"); continue; }
  try {
    host.addInteraction(r.trigger, r.action, r.delay);
    restored += 1;
  } catch (e) {
    failed.push((r.path.join("/") || "root") + ": " + e.message);
  }
}

return { name: COPY_NAME, idx, w: Math.round(fresh.width), h: Math.round(fresh.height),
         variant: JSON.stringify(props),
         interactionsRestored: restored + "/" + record.length,
         interactionsFailed: failed };
