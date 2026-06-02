return {
    -- ----------------------------------------------------------------
    -- Shared sidebar
    -- ----------------------------------------------------------------
    ["sidebar"] = "Masked Software Occlusion Culling\n\n"
        .. "Intel's software occluder-rasterisation pass, wedged between the engine's "
        .. "frustum test and its Display call. Large opaque meshes are rasterised into "
        .. "a low-resolution depth buffer; every other mesh is queried against that "
        .. "buffer and culled when fully hidden.\n\n"
        .. "All distance and size values are in Morrowind world units (1 unit ~ 1.4 cm). "
        .. "Changes take effect on the next frame; no restart required.",

    -- ----------------------------------------------------------------
    -- Page labels
    -- ----------------------------------------------------------------
    ["page.main"]       = "Main",
    ["page.occluder"]   = "Occluder",
    ["page.occludee"]   = "Occludee",
    ["page.threadpool"] = "Threadpool",
    ["page.debug"]      = "Debug",

    -- ----------------------------------------------------------------
    -- Category labels
    -- ----------------------------------------------------------------
    ["category.interior"] = "Interior",
    ["category.exterior"] = "Exterior",
    ["category.tinting"]  = "Tinting",
    ["category.logging"]  = "Logging",

    -- ----------------------------------------------------------------
    -- Main page
    -- ----------------------------------------------------------------
    ["EnableMSOC.label"] = "Enable occlusion culling",
    ["EnableMSOC.description"] = "Master switch for the MSOC pass. When off, the scene-graph "
        .. "traversal falls back to the engine's original frustum-only path and "
        .. "rasterisation + queries stop the next frame. The CullShow detour "
        .. "remains installed either way.",

    ["OcclusionEnableInterior.label"] = "Enable in interiors",
    ["OcclusionEnableInterior.description"] = "Interior scenes with lots of walls and doors "
        .. "(Vivec cantons, tombs, Dwemer ruins) are the highest-benefit case for "
        .. "occlusion culling.",

    ["OcclusionEnableExterior.label"] = "Enable in exteriors",
    ["OcclusionEnableExterior.description"] = "Open-world scenes with dense architecture "
        .. "(Balmora, Vivec exterior) benefit most. Sparse wilderness sees little gain "
        .. "and can be disabled here without affecting interiors.",

    ["OcclusionSkipTerrainOccludees.label"] = "Skip terrain occludee queries",
    ["OcclusionSkipTerrainOccludees.description"] = "Landscape patches (25 verts / 32 tris, "
        .. "4x4 per cell) sit under the camera and are visible from nearly every "
        .. "viewpoint. Enabled: they bypass the visibility test and render unconditionally, "
        .. "saving one TestRect call per patch per frame. Disable only to A/B test.",

    ["OcclusionAggregateTerrain.label"] = "Terrain occluder mode",
    ["OcclusionAggregateTerrain.description"] = "Off: no terrain in the occlusion mask "
        .. "(lowest CPU, lowest cull rate). "
        .. "Raster (default for medium/high hardware tier): rasterizes terrain triangles "
        .. "directly into the mask. With Async Occluders enabled, the threadpool "
        .. "parallelizes the rasterization, hiding most of its cost on multi-core CPUs. "
        .. "Horizon (default for low hardware tier): builds a 1D screen-space silhouette "
        .. "and submits ~120 curtain triangles synchronously. Construction is "
        .. "bounded-cost regardless of how much terrain is in view, which makes it the "
        .. "safer pick when async is off — its cost stays on the main thread but is "
        .. "predictable. "
        .. "Cull rate is comparable across both modes in most scenes — pick based on the "
        .. "cost shape that fits your hardware. The default tracks your hardware tier; "
        .. "flip it manually only if your specific setup contradicts the tier auto-pick.",
    ["OcclusionAggregateTerrain.option.0"] = "Off",
    ["OcclusionAggregateTerrain.option.1"] = "Raster",
    ["OcclusionAggregateTerrain.option.2"] = "Horizon",

    ["OcclusionTerrainResolution.label"] = "Terrain occluder resolution",
    ["OcclusionTerrainResolution.description"] = "How many triangles each terrain subcell "
        .. "contributes to the aggregate occluder. Downsampled vertices take the lowest "
        .. "world-Z across the neighbourhood they replace, so the silhouette can only "
        .. "shrink (safe under-occlude).",
    ["OcclusionTerrainResolution.option.0"] = "Full (5x5, 32 tris/subcell)",
    ["OcclusionTerrainResolution.option.1"] = "Half (3x3, 8 tris/subcell)",
    ["OcclusionTerrainResolution.option.2"] = "Corners (2x2, 2 tris/subcell)",

    ["OcclusionTemporalCoherenceFrames.label"] = "Temporal coherence frames",
    ["OcclusionTemporalCoherenceFrames.description"] = "Frames to reuse a deferred shape's "
        .. "visibility verdict before re-querying. 0 disables the cache; higher values skip "
        .. "more TestRect calls at the cost of up to N frames of latency on "
        .. "occluder->visible transitions. Entries invalidate on movement, so only static "
        .. "geometry benefits.",

    -- ----------------------------------------------------------------
    -- Occluder page
    -- ----------------------------------------------------------------
    ["OcclusionOccluderRadiusMinInterior.label"] = "Min radius (interior)",
    ["OcclusionOccluderRadiusMinInterior.description"] = "Minimum world-bound sphere radius "
        .. "for a mesh to qualify as an occluder in interior cells. Interiors usually want "
        .. "this lower so pillars, crates, and larger furniture contribute to occlusion.",

    ["OcclusionOccluderRadiusMaxInterior.label"] = "Max radius (interior)",
    ["OcclusionOccluderRadiusMaxInterior.description"] = "Maximum world-bound sphere radius "
        .. "for a mesh to qualify in interior cells. Rooms are bounded; large cell-hull "
        .. "meshes above this usually cover most of the view and hurt more than they help.",

    ["OcclusionOccluderMinDimensionInterior.label"] = "Min thin-axis dimension (interior)",
    ["OcclusionOccluderMinDimensionInterior.description"] = "Reject pencil-shaped meshes in "
        .. "interiors: a mesh is rejected if two or more world-AABB axes are shorter than "
        .. "this. Walls / floors (thin on one axis) still qualify.",

    ["OcclusionInsideOccluderMarginInterior.label"] = "Inside-occluder margin (interior)",
    ["OcclusionInsideOccluderMarginInterior.description"] = "Slack added to an occluder's "
        .. "world AABB when testing whether the camera sits inside. If within this margin "
        .. "of the tight AABB, the mesh is skipped for the frame. Interiors may want this "
        .. "tighter because the camera clips architecture more often.",

    ["OcclusionOccluderRadiusMinExterior.label"] = "Min radius (exterior)",
    ["OcclusionOccluderRadiusMinExterior.description"] = "Minimum world-bound sphere radius "
        .. "for a mesh to qualify as an occluder in exterior cells. Exteriors usually want "
        .. "this higher to skip clutter; only building-scale meshes contribute meaningfully.",

    ["OcclusionOccluderRadiusMaxExterior.label"] = "Max radius (exterior)",
    ["OcclusionOccluderRadiusMaxExterior.description"] = "Maximum world-bound sphere radius "
        .. "for a mesh to qualify in exterior cells. Meshes above this (terrain patches, "
        .. "skydomes, whole-cell hulls) are skipped.",

    ["OcclusionOccluderMinDimensionExterior.label"] = "Min thin-axis dimension (exterior)",
    ["OcclusionOccluderMinDimensionExterior.description"] = "Reject pencil-shaped meshes in "
        .. "exteriors: flagpoles, railings, antennae. Walls / floors (thin on one axis) "
        .. "still qualify.",

    ["OcclusionInsideOccluderMarginExterior.label"] = "Inside-occluder margin (exterior)",
    ["OcclusionInsideOccluderMarginExterior.description"] = "Slack added to an occluder's "
        .. "world AABB when testing whether the camera sits inside, evaluated in exterior "
        .. "cells.",

    ["OcclusionOccluderMaxTriangles.label"] = "Max triangles",
    ["OcclusionOccluderMaxTriangles.description"] = "Upper bound on triangle count for any "
        .. "occluder, regardless of scene type. Rasterisation cost scales linearly with "
        .. "triangles, so very dense meshes cost more than they pay back in occlusion.",

    -- ----------------------------------------------------------------
    -- Occludee page
    -- ----------------------------------------------------------------
    ["OcclusionDepthSlackWorldUnits.label"] = "Depth slack (world units)",
    ["OcclusionDepthSlackWorldUnits.description"] = "Extra world-space distance added to a "
        .. "shape's near-surface estimate before TestRect. Biases toward visible; prevents "
        .. "flicker when a mesh sits nearly flush with an occluder. Raise if you see shapes "
        .. "popping behind their own walls.",

    ["OcclusionOccludeeMinRadius.label"] = "Min radius",
    ["OcclusionOccludeeMinRadius.description"] = "Shapes below this world-bound sphere radius "
        .. "skip the visibility test entirely. Footprints too small for the hierarchical "
        .. "depth buffer to decide reliably, and the test cost exceeds any cull benefit.",

    -- ----------------------------------------------------------------
    -- Threadpool page
    -- ----------------------------------------------------------------
    ["OcclusionAsyncOccluders.label"] = "Async occluder rasterisation",
    ["OcclusionAsyncOccluders.description"] = "Submits occluders to Intel's CullingThreadpool "
        .. "for parallel rasterisation on worker threads; main thread continues scene-graph "
        .. "traversal while occluders are drawn. A Flush barrier before the drain guarantees "
        .. "the depth buffer is complete. Enable when rasterizeUs > drainUs in MSOC.log; "
        .. "disable on low core counts.",

    ["OcclusionThreadpoolThreadCount.label"] = "Worker count",
    ["OcclusionThreadpoolThreadCount.description"] = "Worker threads used to rasterise "
        .. "occluders (when Async is on). 0 = auto (min(hardware_concurrency - 2, "
        .. "BinsW*BinsH / 2), floor 1). Manual values must not exceed BinsW*BinsH; the MCM "
        .. "clamps on every change.",

    ["OcclusionThreadpoolBinsW.label"] = "Bins (width)",
    ["OcclusionThreadpoolBinsW.description"] = "The screen is divided into BinsW x BinsH "
        .. "rectangular bins for load balancing across worker threads. Total bins should be "
        .. "at least equal to the worker count.",

    ["OcclusionThreadpoolBinsH.label"] = "Bins (height)",
    ["OcclusionThreadpoolBinsH.description"] = "The screen is divided into BinsW x BinsH "
        .. "rectangular bins for load balancing across worker threads.",

    -- ----------------------------------------------------------------
    -- Debug page
    -- ----------------------------------------------------------------
    ["DebugOcclusionTintOccluder.label"] = "Tint occluders yellow",
    ["DebugOcclusionTintOccluder.description"] = "Overlays a yellow emissive tint on every "
        .. "mesh rasterised as an occluder. Use to check which meshes qualify under the "
        .. "current Occluder settings.",

    ["DebugOcclusionTintOccluded.label"] = "Tint occluded shapes red",
    ["DebugOcclusionTintOccluded.description"] = "Keeps shapes that failed the visibility "
        .. "test visible and tints them red. Verify the culler is rejecting the right meshes.",

    ["DebugOcclusionTintTested.label"] = "Tint visible occludees green",
    ["DebugOcclusionTintTested.description"] = "Tints meshes that passed the visibility test "
        .. "green. Combined with red and yellow, gives a full visual classification of the "
        .. "frame's occlusion decisions.",

    ["OcclusionLogPerFrame.label"] = "Log per-frame culling events",
    ["OcclusionLogPerFrame.description"] = "Writes one MSOC.log line per frame that produced "
        .. "at least one OCCLUDED verdict. Verbose; leave off unless investigating.",

    ["OcclusionLogAggregate.label"] = "Log periodic aggregate stats",
    ["OcclusionLogAggregate.description"] = "Writes one MSOC.log line every 300 frames with "
        .. "cumulative culler counters (rasterised, occluded/tested, view-culled, drain "
        .. "timings). For steady-state profiling.",

    ["OcclusionForensicsWatchdog.label"] = "Freeze-forensics watchdog",
    ["OcclusionForensicsWatchdog.description"] = "Spawns a background thread that polls the "
        .. "MSOC pipeline's checkpoints every 250 ms and overwrites MSOC.forensics.txt next to "
        .. "MWSE.log. If the game hard-freezes and Windows kills it, the file shows which "
        .. "stage the main thread was stuck in, the recursion depth, and the time since the "
        .. "last clean frame. Diagnostic-only — leave off unless you are reproducing a freeze. "
        .. "RESTART REQUIRED: this toggle is read once when the plugin loads; changes here are "
        .. "saved to msoc.json but only take effect on the next launch.",
}
