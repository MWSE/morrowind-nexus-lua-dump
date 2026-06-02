local cfg  = require("msoc.config")
-- include() is cached; same handle main.lua received.
local msoc = include("msoc")

-- Translations live in i18n/<locale>.lua. eng.lua is the source of truth and
-- mandatory; other locales are optional drop-ins. mwse.loadTranslations falls
-- back to the eng.lua key whenever a translated key is missing.
local i18n = mwse.loadTranslations("msoc")

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
        text = i18n("sidebar"),
        postCreate = center,
    })
end

local function registerModConfig()
    -- "MSOC" is the brand name and intentionally not localised.
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
        label     = i18n("page.main"),
        showReset = true,
    }) --[[@as mwseMCMSideBarPage]]
    createSidebar(main)

    main:createOnOffButton({
        label       = i18n("EnableMSOC.label"),
        description = i18n("EnableMSOC.description"),
        configKey   = "EnableMSOC",
        callback    = applyChange,
    })

    main:createOnOffButton({
        label       = i18n("OcclusionEnableInterior.label"),
        description = i18n("OcclusionEnableInterior.description"),
        configKey   = "OcclusionEnableInterior",
        callback    = applyChange,
    })

    main:createOnOffButton({
        label       = i18n("OcclusionEnableExterior.label"),
        description = i18n("OcclusionEnableExterior.description"),
        configKey   = "OcclusionEnableExterior",
        callback    = applyChange,
    })

    main:createOnOffButton({
        label       = i18n("OcclusionSkipTerrainOccludees.label"),
        description = i18n("OcclusionSkipTerrainOccludees.description"),
        configKey   = "OcclusionSkipTerrainOccludees",
        callback    = applyChange,
    })

    -- LAYER-A-HORIZON: tri-state replaces the previous on/off checkbox.
    -- Off skips terrain occlusion entirely. Raster submits the merged
    -- subcell triangle mesh to MOC; Horizon submits a ~120-tri silhouette
    -- curtain. They have different cost characteristics — Raster wins
    -- on multi-core+async, Horizon wins on weaker hardware.
    main:createDropdown({
        label       = i18n("OcclusionAggregateTerrain.label"),
        description = i18n("OcclusionAggregateTerrain.description"),
        options     = {
            { label = i18n("OcclusionAggregateTerrain.option.0"), value = 0 },
            { label = i18n("OcclusionAggregateTerrain.option.1"), value = 1 },
            { label = i18n("OcclusionAggregateTerrain.option.2"), value = 2 },
        },
        configKey   = "OcclusionAggregateTerrain",
        callback    = applyChange,
    })

    main:createDropdown({
        label       = i18n("OcclusionTerrainResolution.label"),
        description = i18n("OcclusionTerrainResolution.description"),
        options     = {
            { label = i18n("OcclusionTerrainResolution.option.0"), value = 0 },
            { label = i18n("OcclusionTerrainResolution.option.1"), value = 1 },
            { label = i18n("OcclusionTerrainResolution.option.2"), value = 2 },
        },
        configKey   = "OcclusionTerrainResolution",
        callback    = applyChange,
    })

    -- The "Cull occluded lights" toggle and its hysteresis slider were
    -- exposed in 1.0.0 but removed from the MCM in 1.1.0 after the
    -- feature tested net-negative (~12% FPS regression). The native
    -- knob `OcclusionCullLights` is still read from msoc.json so a
    -- power user can flip it on for re-testing.

    main:createSlider({
        label       = i18n("OcclusionTemporalCoherenceFrames.label"),
        description = i18n("OcclusionTemporalCoherenceFrames.description"),
        min = 0, max = 10, step = 1, jump = 2,
        configKey   = "OcclusionTemporalCoherenceFrames",
        callback    = applyChange,
    })

    ----------------------------------------------------------------
    -- Occluder selection (split per scene type: interiors favour
    -- smaller occluders, exteriors skip clutter).
    ----------------------------------------------------------------
    local occluder = template:createSideBarPage({
        label     = i18n("page.occluder"),
        showReset = true,
    }) --[[@as mwseMCMSideBarPage]]
    createSidebar(occluder)

    local interiors = occluder:createCategory({ label = i18n("category.interior") })
    interiors:createSlider({
        label       = i18n("OcclusionOccluderRadiusMinInterior.label"),
        description = i18n("OcclusionOccluderRadiusMinInterior.description"),
        min = 0, max = 2048, step = 16, jump = 128,
        configKey   = "OcclusionOccluderRadiusMinInterior",
        callback    = applyChange,
    })
    interiors:createSlider({
        label       = i18n("OcclusionOccluderRadiusMaxInterior.label"),
        description = i18n("OcclusionOccluderRadiusMaxInterior.description"),
        min = 256, max = 16384, step = 128, jump = 1024,
        configKey   = "OcclusionOccluderRadiusMaxInterior",
        callback    = applyChange,
    })
    interiors:createSlider({
        label       = i18n("OcclusionOccluderMinDimensionInterior.label"),
        description = i18n("OcclusionOccluderMinDimensionInterior.description"),
        min = 0, max = 1024, step = 8, jump = 64,
        configKey   = "OcclusionOccluderMinDimensionInterior",
        callback    = applyChange,
    })
    interiors:createSlider({
        label       = i18n("OcclusionInsideOccluderMarginInterior.label"),
        description = i18n("OcclusionInsideOccluderMarginInterior.description"),
        min = 0, max = 512, step = 8, jump = 32,
        configKey   = "OcclusionInsideOccluderMarginInterior",
        callback    = applyChange,
    })

    local exteriors = occluder:createCategory({ label = i18n("category.exterior") })
    exteriors:createSlider({
        label       = i18n("OcclusionOccluderRadiusMinExterior.label"),
        description = i18n("OcclusionOccluderRadiusMinExterior.description"),
        min = 0, max = 2048, step = 16, jump = 128,
        configKey   = "OcclusionOccluderRadiusMinExterior",
        callback    = applyChange,
    })
    exteriors:createSlider({
        label       = i18n("OcclusionOccluderRadiusMaxExterior.label"),
        description = i18n("OcclusionOccluderRadiusMaxExterior.description"),
        min = 256, max = 16384, step = 128, jump = 1024,
        configKey   = "OcclusionOccluderRadiusMaxExterior",
        callback    = applyChange,
    })
    exteriors:createSlider({
        label       = i18n("OcclusionOccluderMinDimensionExterior.label"),
        description = i18n("OcclusionOccluderMinDimensionExterior.description"),
        min = 0, max = 1024, step = 8, jump = 64,
        configKey   = "OcclusionOccluderMinDimensionExterior",
        callback    = applyChange,
    })
    exteriors:createSlider({
        label       = i18n("OcclusionInsideOccluderMarginExterior.label"),
        description = i18n("OcclusionInsideOccluderMarginExterior.description"),
        min = 0, max = 512, step = 8, jump = 32,
        configKey   = "OcclusionInsideOccluderMarginExterior",
        callback    = applyChange,
    })

    -- Shared (cost, not scene-dependent).
    occluder:createSlider({
        label       = i18n("OcclusionOccluderMaxTriangles.label"),
        description = i18n("OcclusionOccluderMaxTriangles.description"),
        min = 64, max = 16384, step = 64, jump = 512,
        configKey   = "OcclusionOccluderMaxTriangles",
        callback    = applyChange,
    })

    ----------------------------------------------------------------
    -- Occludee / query
    ----------------------------------------------------------------
    local occludee = template:createSideBarPage({
        label     = i18n("page.occludee"),
        showReset = true,
    }) --[[@as mwseMCMSideBarPage]]
    createSidebar(occludee)

    occludee:createSlider({
        label       = i18n("OcclusionDepthSlackWorldUnits.label"),
        description = i18n("OcclusionDepthSlackWorldUnits.description"),
        min = 0, max = 1024, step = 8, jump = 32,
        configKey   = "OcclusionDepthSlackWorldUnits",
        callback    = applyChange,
    })

    occludee:createSlider({
        label       = i18n("OcclusionOccludeeMinRadius.label"),
        description = i18n("OcclusionOccludeeMinRadius.description"),
        min = 0, max = 256, step = 1, jump = 16,
        configKey   = "OcclusionOccludeeMinRadius",
        callback    = applyChange,
    })

    ----------------------------------------------------------------
    -- Async threadpool
    ----------------------------------------------------------------
    local threadpool = template:createSideBarPage({
        label     = i18n("page.threadpool"),
        showReset = true,
    }) --[[@as mwseMCMSideBarPage]]
    createSidebar(threadpool)

    threadpool:createOnOffButton({
        label       = i18n("OcclusionAsyncOccluders.label"),
        description = i18n("OcclusionAsyncOccluders.description"),
        configKey   = "OcclusionAsyncOccluders",
        callback    = applyChange,
    })

    threadpool:createSlider({
        label       = i18n("OcclusionThreadpoolThreadCount.label"),
        description = i18n("OcclusionThreadpoolThreadCount.description"),
        min = 0, max = 16, step = 1, jump = 2,
        configKey   = "OcclusionThreadpoolThreadCount",
        postCreate  = captureThreadCountSlider,
        callback    = applyChangeClamped,
    })

    threadpool:createSlider({
        label       = i18n("OcclusionThreadpoolBinsW.label"),
        description = i18n("OcclusionThreadpoolBinsW.description"),
        min = 1, max = 8, step = 1, jump = 2,
        configKey   = "OcclusionThreadpoolBinsW",
        callback    = applyChangeClamped,
    })

    threadpool:createSlider({
        label       = i18n("OcclusionThreadpoolBinsH.label"),
        description = i18n("OcclusionThreadpoolBinsH.description"),
        min = 1, max = 8, step = 1, jump = 2,
        configKey   = "OcclusionThreadpoolBinsH",
        callback    = applyChangeClamped,
    })

    ----------------------------------------------------------------
    -- Debug tinting / logging
    ----------------------------------------------------------------
    local debugPage = template:createSideBarPage({
        label     = i18n("page.debug"),
        showReset = true,
    }) --[[@as mwseMCMSideBarPage]]
    createSidebar(debugPage)

    local tinting = debugPage:createCategory({ label = i18n("category.tinting") })
    tinting:createOnOffButton({
        label       = i18n("DebugOcclusionTintOccluder.label"),
        description = i18n("DebugOcclusionTintOccluder.description"),
        configKey   = "DebugOcclusionTintOccluder",
        callback    = applyChange,
    })
    tinting:createOnOffButton({
        label       = i18n("DebugOcclusionTintOccluded.label"),
        description = i18n("DebugOcclusionTintOccluded.description"),
        configKey   = "DebugOcclusionTintOccluded",
        callback    = applyChange,
    })
    tinting:createOnOffButton({
        label       = i18n("DebugOcclusionTintTested.label"),
        description = i18n("DebugOcclusionTintTested.description"),
        configKey   = "DebugOcclusionTintTested",
        callback    = applyChange,
    })

    local logging = debugPage:createCategory({ label = i18n("category.logging") })
    logging:createOnOffButton({
        label       = i18n("OcclusionLogPerFrame.label"),
        description = i18n("OcclusionLogPerFrame.description"),
        configKey   = "OcclusionLogPerFrame",
        callback    = applyChange,
    })
    logging:createOnOffButton({
        label       = i18n("OcclusionLogAggregate.label"),
        description = i18n("OcclusionLogAggregate.description"),
        configKey   = "OcclusionLogAggregate",
        callback    = applyChange,
    })

    -- Restart-only diagnostic. The native side reads this once during
    -- installPatches() (which runs before msoc.configure() is ever
    -- called), so the toggle below only takes effect on the next launch.
    -- The description spells that out for the user.
    logging:createOnOffButton({
        label       = i18n("OcclusionForensicsWatchdog.label"),
        description = i18n("OcclusionForensicsWatchdog.description"),
        configKey   = "OcclusionForensicsWatchdog",
        callback    = applyChange,
    })
end

event.register("modConfigReady", registerModConfig)
