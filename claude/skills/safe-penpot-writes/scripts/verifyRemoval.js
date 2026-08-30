/* Phase 3 — prove a deletion actually deleted. Inside a component, remove() is
   reported to turn visibility off instead of removing the shape (#8): nothing
   throws, the canvas looks right, and every tree walk still finds it.
   Two parts: run part A, then remove(), then part B in a SEPARATE call.
   The proof is the PARENT's child count, not the shape's own state.
   Verify any unfamiliar signature with penpot_api_info first. */

/* ---- PART A — record the parent, before removing anything ---- */
const TARGET_NAME = "REPLACE-ME";

const target = penpotUtils.findShape((s) => s.name === TARGET_NAME, penpot.currentPage.root);
if (!target) throw new Error("target not found: " + TARGET_NAME);

const parent = target.parent;
// Is the target inside a component at all? If not, #8 does not apply and a plain
// remove() is enough — but the read-back costs nothing, so do it anyway.
let inComponent = false;
for (let n = target; n; n = n.parent) {
  if (typeof n.component === "function" && n.component()) { inComponent = true; break; }
}

return {
  targetId: target.id,
  parentId: parent.id,
  parentName: parent.name,
  childrenBefore: (parent.children || []).length,
  inComponent,                       // true → expect the trap, plan the rebuild
};

/* ---- PART B — after remove(), in its own call ----
const TARGET_ID = "REPLACE-ME";      // targetId from part A
const PARENT_ID = "REPLACE-ME";      // parentId from part A
const CHILDREN_BEFORE = 0;           // childrenBefore from part A

const parent = penpotUtils.findShapeById(PARENT_ID);
const still = penpotUtils.findShapeById(TARGET_ID);
const childrenAfter = parent ? (parent.children || []).length : null;

return {
  childrenBefore: CHILDREN_BEFORE,
  childrenAfter,
  removed: childrenAfter === CHILDREN_BEFORE - 1,
  stillInTree: !!still,
  // the signature of the trap: present in the tree, merely invisible
  hiddenNotRemoved: !!still && still.visible === false,
};
// removed:false with hiddenNotRemoved:true → #8 confirmed. The shape cannot be
// deleted in place: make the structural change in the MAIN component, then rebuild
// the copies (scripts/rebuildCopy.js). Same conclusion as #5, reached backwards.
---- */
