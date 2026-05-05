local cfg  = require("msoc.config")
-- include() is cached; same handle main.lua received.
local msoc = include("msoc")

-- Runtime sync: whenever a control commits a change, push the whole
-- Lua config table across the FFI boundary so the native statics
-- (msoc::Configuration::Foo) match the edited Lua table the same
-- frame. Cheap — one lua_getfield per field per change.
local function applyChange()
    cfg.syncToNative(msoc)
end

--- Threadpool guard. Intel's CullingThreadpool crashes if ThreadCount
--- exceeds BinsW * BinsH. The MCM clamps to that product on every
--- relevant edit so the user can't escape the bound accidentally. If
--- they bypass the MCM and edit msoc.json directly, the native side
--- will still catch it at threadpool creation.
--- @type mwseMCMSlider|nil
local threadCountSlider = nil

local function captureThreadCountSlider(self)
    threadCountSlider = self
end

local function clampThreadCount()
    if cfg.config.OcclusionThreadpoolThreadCount == 0 then return end
    local maxThreads = cfg.config.OcclusionThreadpoolBinsW
                     * cfg.config.OcclusionThreadpoolBinsH
    if cfg.config.OcclusionThreadpoolThreadCount > maxThreads then
        if threadCountSlider then
            threadCountSlider:setVariableValue(maxThreads)
        else
            cfg.config.OcclusionThreadpoolThreadCount = maxThreads
        end
    end
end

local function applyChangeClamped()
    clampThreadCount()
    cfg.syncToNative(msoc)
end

--- Center an MCM info/hyperlink widget horizontally.
--- @param self mwseMCMInfo|mwseMCMHyperlink
local function center(self)
    self.elements.info.absolutePosAlignX = 0.5
end

--- Shared sidebar. Mirrors Take That's per-page credit block.
--- @param container mwseMCMSideBarPage
local function createSidebar(container)
    container.sidebar:createInfo({
        text = "Masked Software Occlusion Culling\n\n"
            .. "Intel's software occluder-rasterisation pass, wedged between the engine's "
            .. "frustum test and its Display call. Large opaque meshes are rasterised into "
            .. "a low-resolution depth buffer; every other mesh is queried against that "
            .. "buffer and culled when fully hidden.\n\n"
            .. "All distance and size values are in Morrowind world units (1 unit ~ 1.4 cm). "
            .. "Changes take effect on the next frame; no restart required.",
        postCreate = center,
    })
end

local function registerModConfig()
    local template = mwse.mcm.createTemplate({
        name               = "MSOC",
        config             = cfg.config,
        defaultConfig      = cfg.default,
        showDefaultSetting = true,
    })
    template:register()
    template:saveOnClose(cfg.config.confPath, cfg.config)

    ----------------------------------------------------------------
    -- Main
    ----------------------------------------------------------------
    local main = template:createSideBarPage({
        label     = "Main",
        showReset = true,
    }) --[[@as mwseMCMSideBarPage]]
    createSidebar(main)

    main:createOnOffButton({
        label       = "Enable occlusion culling",
        description = "Master switch for the MSOC pass. When off, the scene-graph "
            .. "traversal falls back to the engine's original frustum-only path and "
            .. "rasterisation + queries stop the next frame. The CullShow detour "
            .. "remains installed either way.",
        configKey   = "EnableMSOC",
        callback    = applyChange,
    })

    main:createOnOffButton({
        label       = "Enable in interiors",
        description = "Interior scenes with lots of walls and doors (Vivec cantons, "
            .. "tombs, Dwemer ruins) are the highest-benefit case for occlusion culling.",
        configKey   = "OcclusionEnableInterior",
        callback    = applyChange,
    })

    main:createOnOffButton({
        label       = "Enable in exteriors",
        description = "Open-world scenes with dense architecture (Balmora, Vivec "
            .. "exterior) benefit most. Sparse wilderness sees little gain and can "
            .. "be disabled here without affecting interiors.",
        configKey   = "OcclusionEnableExterior",
        callback    = applyChange,
    })

    main:createOnOffButton({
        label       = "Skip terrain occludee queries",
        description = "Landscape patches (25 verts / 32 tris, 4x4 per cell) sit under "
            .. "the camera and are visible from nearly every viewpoint. Enabled: they "
            .. "bypass the visibility test and render unconditionally, saving one "
            .. "TestRect call per patch per frame. Disable only to A/B test.",
        configKey   = "OcclusionSkipTerrainOccludees",
        callback    = applyChange,
    })

    -- LAYER-A-HORIZON: tri-state replaces the previous on/off checkbox.
    -- Off skips terrain occlusion entirely. Raster submits the merged
    -- subcell triangle mesh to MOC; Horizon submits a ~120-tri silhouette
    -- curtain. They have different cost characteristics — Raster wins
    -- on multi-core+async, Horizon wins on weaker hardware.
    main:createDropdown({
        label       = "Terrain occluder mode",
        description = "Off: no terrain in the occlusion mask (lowest CPU, lowest cull rate). "
            .. "Raster (default for medium/high hardware tier): rasterizes "
            .. "terrain triangles directly into the mask. With Async Occluders "
            .. "enabled, the threadpool parallelizes the rasterization, hiding "
            .. "most of its cost on multi-core CPUs. "
            .. "Horizon (default for low hardware tier): builds a 1D screen-"
            .. "space silhouette and submits ~120 curtain triangles "
            .. "synchronously. Construction is bounded-cost regardless of how "
            .. "much terrain is in view, which makes it the safer pick when "
            .. "async is off — its cost stays on the main thread but is "
            .. "predictable. "
            .. "Cull rate is comparable across both modes in most scenes — pick "
            .. "based on the cost shape that fits your hardware. The default "
            .. "tracks your hardware tier; flip it manually only if your "
            .. "specific setup contradicts the tier auto-pick.",
        options     = {
            { label = "Off",      value = 0 },
            { label = "Raster",   value = 1 },
            { label = "Horizon",  value = 2 },
        },
        configKey   = "OcclusionAggregateTerrain",
        callback    = applyChange,
    })

    main:createDropdown({
        label       = "Terrain occluder resolution",
        description = "How many triangles each terrain subcell contributes to the "
            .. "aggregate occluder. Downsampled vertices take the lowest world-Z "
            .. "across the neighbourhood they replace, so the silhouette can only "
            .. "shrink (safe under-occlude).",
        options     = {
            { label = "Full (5x5, 32 tris/subcell)",    value = 0 },
            { label = "Half (3x3, 8 tris/subcell)",     value = 1 },
            { label = "Corners (2x2, 2 tris/subcell)",  value = 2 },
        },
        configKey   = "OcclusionTerrainResolution",
        callback    = applyChange,
    })

    main:createOnOffButton({
        label       = "Cull occluded lights",
        description = "Every registered NiLight is tested once per frame against the "
            .. "MSOC depth buffer. Fully-occluded lights are temporarily disabled for "
            .. "that frame; the light stays in the scene graph but D3D8 treats it as "
            .. "if its enabled flag were cleared. Main beneficiary: dense interiors "
            .. "with many behind-wall fixtures.",
        configKey   = "OcclusionCullLights",
        callback    = applyChange,
    })

    main:createSlider({
        label       = "Light cull hysteresis frames",
        description = "Consecutive frames a light's bound sphere must be reported "
            .. "OCCLUDED before latching to the culled state. Visible verdicts unlatch "
            .. "immediately, so this only tunes the off-transition. 3 ~ 50 ms at "
            .. "60 FPS; 10 ~ 170 ms.",
        min = 0, max = 10, step = 1, jump = 5,
        configKey   = "OcclusionLightCullHysteresisFrames",
        callback    = applyChange,
    })

    main:createSlider({
        label       = "Temporal coherence frames",
        description = "Frames to reuse a deferred shape's visibility verdict before "
            .. "re-querying. 0 disables the cache; higher values skip more TestRect "
            .. "calls at the cost of up to N frames of latency on "
            .. "occluder->visible transitions. Entries invalidate on movement, so "
            .. "only static geometry benefits.",
        min = 0, max = 10, step = 1, jump = 2,
        configKey   = "OcclusionTemporalCoherenceFrames",
        callback    = applyChange,
    })

    ----------------------------------------------------------------
    -- Occluder selection (split per scene type: interiors favour
    -- smaller occluders, exteriors skip clutter).
    ----------------------------------------------------------------
    local occluder = template:createSideBarPage({
        label     = "Occluder",
        showReset = true,
    }) --[[@as mwseMCMSideBarPage]]
    createSidebar(occluder)

    local interiors = occluder:createCategory({ label = "Interior" })
    interiors:createSlider({
        label       = "Min radius (interior)",
        description = "Minimum world-bound sphere radius for a mesh to qualify as an "
            .. "occluder in interior cells. Interiors usually want this lower so "
            .. "pillars, crates, and larger furniture contribute to occlusion.",
        min = 0, max = 2048, step = 16, jump = 128,
        configKey   = "OcclusionOccluderRadiusMinInterior",
        callback    = applyChange,
    })
    interiors:createSlider({
        label       = "Max radius (interior)",
        description = "Maximum world-bound sphere radius for a mesh to qualify in "
            .. "interior cells. Rooms are bounded; large cell-hull meshes above this "
            .. "usually cover most of the view and hurt more than they help.",
        min = 256, max = 16384, step = 128, jump = 1024,
        configKey   = "OcclusionOccluderRadiusMaxInterior",
        callback    = applyChange,
    })
    interiors:createSlider({
        label       = "Min thin-axis dimension (interior)",
        description = "Reject pencil-shaped meshes in interiors: a mesh is rejected "
            .. "if two or more world-AABB axes are shorter than this. Walls / floors "
            .. "(thin on one axis) still qualify.",
        min = 0, max = 1024, step = 8, jump = 64,
        configKey   = "OcclusionOccluderMinDimensionInterior",
        callback    = applyChange,
    })
    interiors:createSlider({
        label       = "Inside-occluder margin (interior)",
        description = "Slack added to an occluder's world AABB when testing whether "
            .. "the camera sits inside. If within this margin of the tight AABB, the "
            .. "mesh is skipped for the frame. Interiors may want this tighter "
            .. "because the camera clips architecture more often.",
        min = 0, max = 512, step = 8, jump = 32,
        configKey   = "OcclusionInsideOccluderMarginInterior",
        callback    = applyChange,
    })

    local exteriors = occluder:createCategory({ label = "Exterior" })
    exteriors:createSlider({
        label       = "Min radius (exterior)",
        description = "Minimum world-bound sphere radius for a mesh to qualify as an "
            .. "occluder in exterior cells. Exteriors usually want this higher to "
            .. "skip clutter; only building-scale meshes contribute meaningfully.",
        min = 0, max = 2048, step = 16, jump = 128,
        configKey   = "OcclusionOccluderRadiusMinExterior",
        callback    = applyChange,
    })
    exteriors:createSlider({
        label       = "Max radius (exterior)",
        description = "Maximum world-bound sphere radius for a mesh to qualify in "
            .. "exterior cells. Meshes above this (terrain patches, skydomes, "
            .. "whole-cell hulls) are skipped.",
        min = 256, max = 16384, step = 128, jump = 1024,
        configKey   = "OcclusionOccluderRadiusMaxExterior",
        callback    = applyChange,
    })
    exteriors:createSlider({
        label       = "Min thin-axis dimension (exterior)",
        description = "Reject pencil-shaped meshes in exteriors: flagpoles, railings, "
            .. "antennae. Walls / floors (thin on one axis) still qualify.",
        min = 0, max = 1024, step = 8, jump = 64,
        configKey   = "OcclusionOccluderMinDimensionExterior",
        callback    = applyChange,
    })
    exteriors:createSlider({
        label       = "Inside-occluder margin (exterior)",
        description = "Slack added to an occluder's world AABB when testing whether "
            .. "the camera sits inside, evaluated in exterior cells.",
        min = 0, max = 512, step = 8, jump = 32,
        configKey   = "OcclusionInsideOccluderMarginExterior",
        callback    = applyChange,
    })

    -- Shared (cost, not scene-dependent).
    occluder:createSlider({
        label       = "Max triangles",
        description = "Upper bound on triangle count for any occluder, regardless of "
            .. "scene type. Rasterisation cost scales linearly with triangles, so "
            .. "very dense meshes cost more than they pay back in occlusion.",
        min = 64, max = 16384, step = 64, jump = 512,
        configKey   = "OcclusionOccluderMaxTriangles",
        callback    = applyChange,
    })

    ----------------------------------------------------------------
    -- Occludee / query
    ----------------------------------------------------------------
    local occludee = template:createSideBarPage({
        label     = "Occludee",
        showReset = true,
    }) --[[@as mwseMCMSideBarPage]]
    createSidebar(occludee)

    occludee:createSlider({
        label       = "Depth slack (world units)",
        description = "Extra world-space distance added to a shape's near-surface "
            .. "estimate before TestRect. Biases toward visible; prevents flicker "
            .. "when a mesh sits nearly flush with an occluder. Raise if you see "
            .. "shapes popping behind their own walls.",
        min = 0, max = 1024, step = 8, jump = 32,
        configKey   = "OcclusionDepthSlackWorldUnits",
        callback    = applyChange,
    })

    occludee:createSlider({
        label       = "Min radius",
        description = "Shapes below this world-bound sphere radius skip the "
            .. "visibility test entirely. Footprints too small for the hierarchical "
            .. "depth buffer to decide reliably, and the test cost exceeds any cull "
            .. "benefit.",
        min = 0, max = 256, step = 1, jump = 16,
        configKey   = "OcclusionOccludeeMinRadius",
        callback    = applyChange,
    })

    ----------------------------------------------------------------
    -- Async threadpool
    ----------------------------------------------------------------
    local threadpool = template:createSideBarPage({
        label     = "Threadpool",
        showReset = true,
    }) --[[@as mwseMCMSideBarPage]]
    createSidebar(threadpool)

    threadpool:createOnOffButton({
        label       = "Async occluder rasterisation",
        description = "Submits occluders to Intel's CullingThreadpool for parallel "
            .. "rasterisation on worker threads; main thread continues scene-graph "
            .. "traversal while occluders are drawn. A Flush barrier before the drain "
            .. "guarantees the depth buffer is complete. Enable when rasterizeUs > "
            .. "drainUs in MSOC.log; disable on low core counts.",
        configKey   = "OcclusionAsyncOccluders",
        callback    = applyChange,
    })

    threadpool:createSlider({
        label       = "Worker count",
        description = "Worker threads used to rasterise occluders (when Async is on). "
            .. "0 = auto (min(hardware_concurrency - 2, BinsW*BinsH / 2), floor 1). "
            .. "Manual values must not exceed BinsW*BinsH; the MCM clamps on every "
            .. "change.",
        min = 0, max = 16, step = 1, jump = 2,
        configKey   = "OcclusionThreadpoolThreadCount",
        postCreate  = captureThreadCountSlider,
        callback    = applyChangeClamped,
    })

    threadpool:createSlider({
        label       = "Bins (width)",
        description = "The screen is divided into BinsW x BinsH rectangular bins for "
            .. "load balancing across worker threads. Total bins should be at least "
            .. "equal to the worker count.",
        min = 1, max = 8, step = 1, jump = 2,
        configKey   = "OcclusionThreadpoolBinsW",
        callback    = applyChangeClamped,
    })

    threadpool:createSlider({
        label       = "Bins (height)",
        description = "The screen is divided into BinsW x BinsH rectangular bins for "
            .. "load balancing across worker threads.",
        min = 1, max = 8, step = 1, jump = 2,
        configKey   = "OcclusionThreadpoolBinsH",
        callback    = applyChangeClamped,
    })

    ----------------------------------------------------------------
    -- Debug tinting / logging
    ----------------------------------------------------------------
    local debugPage = template:createSideBarPage({
        label     = "Debug",
        showReset = true,
    }) --[[@as mwseMCMSideBarPage]]
    createSidebar(debugPage)

    local tinting = debugPage:createCategory({ label = "Tinting" })
    tinting:createOnOffButton({
        label       = "Tint occluders yellow",
        description = "Overlays a yellow emissive tint on every mesh rasterised as "
            .. "an occluder. Use to check which meshes qualify under the current "
            .. "Occluder settings.",
        configKey   = "DebugOcclusionTintOccluder",
        callback    = applyChange,
    })
    tinting:createOnOffButton({
        label       = "Tint occluded shapes red",
        description = "Keeps shapes that failed the visibility test visible and "
            .. "tints them red. Verify the culler is rejecting the right meshes.",
        configKey   = "DebugOcclusionTintOccluded",
        callback    = applyChange,
    })
    tinting:createOnOffButton({
        label       = "Tint visible occludees green",
        description = "Tints meshes that passed the visibility test green. Combined "
            .. "with red and yellow, gives a full visual classification of the "
            .. "frame's occlusion decisions.",
        configKey   = "DebugOcclusionTintTested",
        callback    = applyChange,
    })

    local logging = debugPage:createCategory({ label = "Logging" })
    logging:createOnOffButton({
        label       = "Log per-frame culling events",
        description = "Writes one MSOC.log line per frame that produced at least "
            .. "one OCCLUDED verdict. Verbose; leave off unless investigating.",
        configKey   = "OcclusionLogPerFrame",
        callback    = applyChange,
    })
    logging:createOnOffButton({
        label       = "Log periodic aggregate stats",
        description = "Writes one MSOC.log line every 300 frames with cumulative "
            .. "culler counters (rasterised, occluded/tested, view-culled, drain "
            .. "timings). For steady-state profiling.",
        configKey   = "OcclusionLogAggregate",
        callback    = applyChange,
    })
end

event.register("modConfigReady", registerModConfig)
