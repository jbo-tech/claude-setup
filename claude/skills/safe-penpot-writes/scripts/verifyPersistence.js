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
const versionsNow = (await file.findVersions()).length;
const probe = penpotUtils.findShapeById(storage.probeId);
if (probe) probe.remove();
const persisted = file.revn > storage.revnBefore;
return {
  revnBefore: storage.revnBefore, revnAfter: file.revn,
  newServerSnapshots: versionsNow - storage.versionsBefore,
  persisted,                       // false → STOP. Nothing you write will survive.
  probeRemoved: !!probe,
  strays: penpotUtils.findShapes(s => s.name === "persistence-probe-TEMP").length,
};
---- */
