/* Phase -1 — does this session reach the SERVER? Run BEFORE any campaign, and
   again at its end. Reads and writes both hit the client state, so every other
   check in this skill can pass on work the server never received (#7).
   Two parts: run part A, then part B in a SEPARATE call — revn does not
   increment inside the call that writes.
   Verify any unfamiliar signature with penpot_api_info first. */

/* ---- PART A — write a probe, record the baseline ---- */
const file = penpot.currentFile;
storage.revnBefore = file.revn;
storage.versionsBefore = (await file.findVersions()).length;
const probe = penpot.createRectangle();
probe.name = "persistence-probe-TEMP";
probe.resize(10, 10);
probe.x = -5000; probe.y = -5000;      // off-canvas: invisible to the designer
storage.probeId = probe.id;
return { revnBefore: storage.revnBefore, versionsBefore: storage.versionsBefore };

/* ---- PART B — next call: verify, then clean up ----
const file = penpot.currentFile;

// `storage` surviving between calls is an ASSUMPTION, not a measured fact. If it did
// not survive, revnBefore is undefined and `file.revn > undefined` is false — which
// would report a healthy session as unpersisted. Say "I lost the baseline" instead.
if (storage.revnBefore === undefined) {
  return {
    baselineLost: true,
    hint: "storage did not survive between calls — re-run part A and part B back to back, " +
          "or carry revnBefore by hand. Nothing is proven either way.",
    strays: penpotUtils.findShapes(s => s.name === "persistence-probe-TEMP").length,
  };
}

const versionsNow = (await file.findVersions()).length;
const persisted = file.revn > storage.revnBefore;

// Clean up by NAME, not by stored id: the probe must go even when the id is gone.
// Inside a component, remove() may only hide (#8) — the probe is created at page
// root precisely so that trap does not apply here.
const probes = penpotUtils.findShapes(s => s.name === "persistence-probe-TEMP");
for (const probe of probes) probe.remove();

return {
  baselineLost: false,
  revnBefore: storage.revnBefore, revnAfter: file.revn,
  newServerSnapshots: versionsNow - storage.versionsBefore,
  persisted,                       // false → STOP. Nothing you write will survive.
  probesRemoved: probes.length,    // verify in the NEXT call: strays must be 0
};
---- */
