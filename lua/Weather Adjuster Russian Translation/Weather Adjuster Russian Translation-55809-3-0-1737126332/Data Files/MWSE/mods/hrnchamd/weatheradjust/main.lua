--[[
    Mod: Weather Adjuster
    Author: Hrnchamd
    Version: 3.0
]]--

local mcm = require("hrnchamd.weatheradjust.mcm")
local weatherPatch = require("hrnchamd.weatheradjust.patch")
weatherPatch.patchCloudVertexColours()

local this = {}
local verString = "3.0"

local configId = "Weather Adjuster"
local configDefault = {
    presets = {},
    regions = {},
    keybind = { keyCode = tes3.scanCode.F4, isShiftDown = true, isAltDown = false, isControlDown = false },
    messageOnRegionChange = false,
    disableSkyTextureChanges = false
}

local config = mwse.loadConfig(configId, configDefault)
-- Remove default preset, to be set from starting values later.
config.presets.default = nil

local regionTransitionDuration = 20.0
local weatherNames = { "Clear", "Cloudy", "Foggy", "Overcast", "Rain", "Thunderstorm", "Ashstorm", "Blight", "Snow", "Blizzard" }
local weatherLabels = { "Ясно", "Облачно", "Туманно", "Пасмурно", "Дождь", "Гроза", "Пепельная буря", "Моровая буря", "Снег", "Метель" }
local weatherSettingsPath = "WeatherAdjuster.txt"

local function isShiftPressed()
    local input = tes3.worldController.inputController
    return input:isKeyDown(tes3.scanCode.lShift) or input:isKeyDown(tes3.scanCode.rShift)
end

local function copyOptionalVec3(src, default)
    if src then
        return { src[1], src[2], src[3] }
    else
        return table.deepcopy(default)
    end
end

local function invertScatterCol(c)
    return { r = 1 - c[1], g = 1 - c[2], b = 1 - c[3] }
end

local function updateInverseScattering()
    this.outscatterInv = invertScatterCol(this.outscatter)
    this.inscatterInv = invertScatterCol(this.inscatter)
    this.skylightScatterCol = { r = this.skylightScatter[1], g = this.skylightScatter[2], b = this.skylightScatter[3] }
end

local function captureDefaultScattering()
    this.defaultScattering = mge.weather.getScattering()
    
    -- Check if the skylight API is available from MGE XE 0.15+
    if (mge.weather.getSkylightScattering) then
        this.defaultSkylightScattering = mge.weather.getSkylightScattering()
    else
        this.defaultSkylightScattering = { skylight = { 0,0,0 }, mix = 0 }
    end
end

local function defaultScattering()
    this.outscatter = table.deepcopy(this.defaultScattering.outscatter)
    this.inscatter = table.deepcopy(this.defaultScattering.inscatter)
    this.skylightScatter = table.deepcopy(this.defaultSkylightScattering.skylight)
    this.skylightScatterMix = this.defaultSkylightScattering.mix

    updateInverseScattering()
end

local function setScattering()
    mge.weather.setScattering{ outscatter = this.outscatter, inscatter = this.inscatter }

    -- Check if the skylight API is available from MGE XE 0.15+
    if (mge.weather.setSkylightScattering) then
        mge.weather.setSkylightScattering{ skylight = this.skylightScatter, mix = this.skylightScatterMix }
    end
end

-- Update scattering from colour picker.
local function updateScattering()
    -- Invert user-facing colour and clamp to acceptable range.
    this.outscatter = {
        math.max(0.005, 1 - this.outscatterInv.r),
        math.max(0.005, 1 - this.outscatterInv.g),
        math.max(0.005, 1 - this.outscatterInv.b)
    }
    this.inscatter = {
        math.max(0.005, 1 - this.inscatterInv.r),
        math.max(0.005, 1 - this.inscatterInv.g),
        math.max(0.005, 1 - this.inscatterInv.b)
    }
    this.skylightScatter = {
        this.skylightScatterCol.r,
        this.skylightScatterCol.g,
        this.skylightScatterCol.b
    }

    setScattering()
end

-- Save current weather to a preset table.
local function currentWeatherToPreset()
    local function RGBtoLua(c)
        return { c.r, c.g, c.b }
    end

    local p = {}

    local wc = tes3.worldController.weatherController
    for i, w in ipairs(wc.weathers) do
        p[weatherNames[i]] = {
            skySunriseColor = RGBtoLua(w.skySunriseColor),
            skyDayColor = RGBtoLua(w.skyDayColor),
            skySunsetColor = RGBtoLua(w.skySunsetColor),
            skyNightColor = RGBtoLua(w.skyNightColor),
            fogSunriseColor = RGBtoLua(w.fogSunriseColor),
            fogDayColor = RGBtoLua(w.fogDayColor),
            fogSunsetColor = RGBtoLua(w.fogSunsetColor),
            fogNightColor = RGBtoLua(w.fogNightColor),
            ambientSunriseColor = RGBtoLua(w.ambientSunriseColor),
            ambientDayColor = RGBtoLua(w.ambientDayColor),
            ambientSunsetColor = RGBtoLua(w.ambientSunsetColor),
            ambientNightColor = RGBtoLua(w.ambientNightColor),
            sunSunriseColor = RGBtoLua(w.sunSunriseColor),
            sunDayColor = RGBtoLua(w.sunDayColor),
            sunSunsetColor = RGBtoLua(w.sunSunsetColor),
            sunNightColor = RGBtoLua(w.sunNightColor),
            sundiscSunsetColor = RGBtoLua(w.sundiscSunsetColor)
        }
        if (w.cloudTexture ~= this.defaultClouds[i]) then
            p[weatherNames[i]].cloudTexture = w.cloudTexture
        end
    end

    p.outscatter = table.deepcopy(this.outscatter)
    p.inscatter = table.deepcopy(this.inscatter)
    
    -- Only write skylight if it's editable
    if (mge.weather.getSkylightScattering) then
        p.skylightScatter = table.deepcopy(this.skylightScatter)
        p.skylightScatterMix = this.skylightScatterMix
    end
    return p
end

-- Load current weather from a preset table. Updates visuals.
local function presetToCurrentWeather(p)
    local function setWeatherRGB(dest, src)
        dest.r = src[1]
        dest.g = src[2]
        dest.b = src[3]
    end

    local changeTextures = not config.disableSkyTextureChanges
    local wc = tes3.worldController.weatherController
    for i, w in ipairs(wc.weathers) do
        local x = p[weatherNames[i]]
        setWeatherRGB(w.skySunriseColor, x.skySunriseColor)
        setWeatherRGB(w.skyDayColor, x.skyDayColor)
        setWeatherRGB(w.skySunsetColor, x.skySunsetColor)
        setWeatherRGB(w.skyNightColor, x.skyNightColor)
        setWeatherRGB(w.fogSunriseColor, x.fogSunriseColor)
        setWeatherRGB(w.fogDayColor, x.fogDayColor)
        setWeatherRGB(w.fogSunsetColor, x.fogSunsetColor)
        setWeatherRGB(w.fogNightColor, x.fogNightColor)
        setWeatherRGB(w.ambientSunriseColor, x.ambientSunriseColor)
        setWeatherRGB(w.ambientDayColor, x.ambientDayColor)
        setWeatherRGB(w.ambientSunsetColor, x.ambientSunsetColor)
        setWeatherRGB(w.ambientNightColor, x.ambientNightColor)
        setWeatherRGB(w.sunSunriseColor, x.sunSunriseColor)
        setWeatherRGB(w.sunDayColor, x.sunDayColor)
        setWeatherRGB(w.sunSunsetColor, x.sunSunsetColor)
        setWeatherRGB(w.sunNightColor, x.sunNightColor)
        setWeatherRGB(w.sundiscSunsetColor, x.sundiscSunsetColor)
        if (changeTextures) then
            w.cloudTexture = x.cloudTexture or this.defaultClouds[i]
        end
    end

    -- Weather switch required to load cloud texture, try to preserve transitions.
    if (wc.nextWeather) then
        local t = wc.transitionScalar
        wc:switchTransition(wc.nextWeather.index)
        wc.transitionScalar = t
    else
        wc:switchImmediate(wc.currentWeather.index)
    end

    wc:updateVisuals()

    this.outscatter = copyOptionalVec3(p.outscatter, this.defaultScattering.outscatter)
    this.inscatter = copyOptionalVec3(p.inscatter, this.defaultScattering.inscatter)
    this.skylightScatter = copyOptionalVec3(p.skylightScatter, this.defaultSkylightScattering.skylight)
    this.skylightScatterMix = p.skylightScatterMix or this.defaultSkylightScattering.mix

    updateInverseScattering()
    setScattering()
end

-- Load non-active weathers from a preset table. Used for transitions.
local function presetToTransitionWeather(p)
    local function setWeatherRGB(dest, src)
        dest.r = src[1]
        dest.g = src[2]
        dest.b = src[3]
    end

    local changeTextures = not config.disableSkyTextureChanges
    local wc = tes3.worldController.weatherController
    for i, w in ipairs(wc.weathers) do
        local x = p[weatherNames[i]]

        -- Current and next weather should be set by transition lerp.
        if (w ~= wc.currentWeather and w ~= wc.nextWeather) then
            setWeatherRGB(w.skySunriseColor, x.skySunriseColor)
            setWeatherRGB(w.skyDayColor, x.skyDayColor)
            setWeatherRGB(w.skySunsetColor, x.skySunsetColor)
            setWeatherRGB(w.skyNightColor, x.skyNightColor)
            setWeatherRGB(w.fogSunriseColor, x.fogSunriseColor)
            setWeatherRGB(w.fogDayColor, x.fogDayColor)
            setWeatherRGB(w.fogSunsetColor, x.fogSunsetColor)
            setWeatherRGB(w.fogNightColor, x.fogNightColor)
            setWeatherRGB(w.ambientSunriseColor, x.ambientSunriseColor)
            setWeatherRGB(w.ambientDayColor, x.ambientDayColor)
            setWeatherRGB(w.ambientSunsetColor, x.ambientSunsetColor)
            setWeatherRGB(w.ambientNightColor, x.ambientNightColor)
            setWeatherRGB(w.sunSunriseColor, x.sunSunriseColor)
            setWeatherRGB(w.sunDayColor, x.sunDayColor)
            setWeatherRGB(w.sunSunsetColor, x.sunSunsetColor)
            setWeatherRGB(w.sunNightColor, x.sunNightColor)
            setWeatherRGB(w.sundiscSunsetColor, x.sundiscSunsetColor)
        end
        -- Set all clouds except for transition target, or it will jump when starting the next transition.
        if (changeTextures) then
            if (w ~= wc.nextWeather or wc.transitionScalar <= 0.05) then
                w.cloudTexture = x.cloudTexture or this.defaultClouds[i]
            end
        end
    end
end

-- Switch weather to named preset, either immediately or partially for transitions.
local function switchPreset(name, isTransition)
    local p = config.presets[name]
    this.activePreset = name
    this.undoStack = {}
    this.redoStack = {}

    if (isTransition) then
        presetToTransitionWeather(p)
    else
        presetToCurrentWeather(p)
    end

    local menu = tes3ui.findMenu(this.id_menu)
    if (menu) then
        menu:findChild(this.id_activePreset).text = "Активный: " .. this.activePreset
        menu:updateLayout()
    end
end

-- Calculate deltas for interpolating a single weather to a preset.
local function calcPresetDeltas(p, weather)
    local function calcDelta(to, from)
        return { to[1] - from.r, to[2] - from.g, to[3] - from.b }
    end
    local function calcDeltaScatter(to, from)
        return { to[1] - from[1], to[2] - from[2], to[3] - from[3] }
    end

    local to = p[weatherNames[weather.index+1]]
    local deltas = { t = 0 }

    deltas.skySunriseColor = calcDelta(to.skySunriseColor, weather.skySunriseColor)
    deltas.skyDayColor = calcDelta(to.skyDayColor, weather.skyDayColor)
    deltas.skySunsetColor = calcDelta(to.skySunsetColor, weather.skySunsetColor)
    deltas.skyNightColor = calcDelta(to.skyNightColor, weather.skyNightColor)
    deltas.fogSunriseColor = calcDelta(to.fogSunriseColor, weather.fogSunriseColor)
    deltas.fogDayColor = calcDelta(to.fogDayColor, weather.fogDayColor)
    deltas.fogSunsetColor = calcDelta(to.fogSunsetColor, weather.fogSunsetColor)
    deltas.fogNightColor = calcDelta(to.fogNightColor, weather.fogNightColor)
    deltas.ambientSunriseColor = calcDelta(to.ambientSunriseColor, weather.ambientSunriseColor)
    deltas.ambientDayColor = calcDelta(to.ambientDayColor, weather.ambientDayColor)
    deltas.ambientSunsetColor = calcDelta(to.ambientSunsetColor, weather.ambientSunsetColor)
    deltas.ambientNightColor = calcDelta(to.ambientNightColor, weather.ambientNightColor)
    deltas.sunSunriseColor = calcDelta(to.sunSunriseColor, weather.sunSunriseColor)
    deltas.sunDayColor = calcDelta(to.sunDayColor, weather.sunDayColor)
    deltas.sunSunsetColor = calcDelta(to.sunSunsetColor, weather.sunSunsetColor)
    deltas.sunNightColor = calcDelta(to.sunNightColor, weather.sunNightColor)
    deltas.sundiscSunsetColor = calcDelta(to.sundiscSunsetColor, weather.sundiscSunsetColor)

    local to_outscatter = copyOptionalVec3(p.outscatter, this.defaultScattering.outscatter)
    local to_inscatter = copyOptionalVec3(p.inscatter, this.defaultScattering.inscatter)
    local to_skylightScatter = copyOptionalVec3(p.skylightScatter, this.defaultSkylightScattering.skylight)
    local to_skylightScatterMix = p.skylightScatterMix or this.defaultSkylightScattering.mix

    deltas.outscatter = calcDeltaScatter(to_outscatter, this.outscatter)
    deltas.inscatter = calcDeltaScatter(to_inscatter, this.inscatter)
    deltas.skylightScatter = calcDeltaScatter(to_skylightScatter, this.skylightScatter)
    deltas.skylightScatterMix = to_skylightScatterMix - this.skylightScatterMix

    return deltas
end

-- Apply transition deltas.
local function applyWeatherDeltas(w, deltas, dt)
    local function lerpWeatherCol(c, delta)
        c.r = c.r + dt * delta[1]
        c.g = c.g + dt * delta[2]
        c.b = c.b + dt * delta[3]
    end
    local function lerpScatterCol(c, delta)
        c[1] = c[1] + dt * delta[1]
        c[2] = c[2] + dt * delta[2]
        c[3] = c[3] + dt * delta[3]
    end
    local function lerpScalar(c, delta)
        return c + dt * delta
    end

    lerpWeatherCol(w.skySunriseColor, deltas.skySunriseColor)
    lerpWeatherCol(w.skyDayColor, deltas.skyDayColor)
    lerpWeatherCol(w.skySunsetColor, deltas.skySunsetColor)
    lerpWeatherCol(w.skyNightColor, deltas.skyNightColor)
    lerpWeatherCol(w.fogSunriseColor, deltas.fogSunriseColor)
    lerpWeatherCol(w.fogDayColor, deltas.fogDayColor)
    lerpWeatherCol(w.fogSunsetColor, deltas.fogSunsetColor)
    lerpWeatherCol(w.fogNightColor, deltas.fogNightColor)
    lerpWeatherCol(w.ambientSunriseColor, deltas.ambientSunriseColor)
    lerpWeatherCol(w.ambientDayColor, deltas.ambientDayColor)
    lerpWeatherCol(w.ambientSunsetColor, deltas.ambientSunsetColor)
    lerpWeatherCol(w.ambientNightColor, deltas.ambientNightColor)
    lerpWeatherCol(w.sunSunriseColor, deltas.sunSunriseColor)
    lerpWeatherCol(w.sunDayColor, deltas.sunDayColor)
    lerpWeatherCol(w.sunSunsetColor, deltas.sunSunsetColor)
    lerpWeatherCol(w.sunNightColor, deltas.sunNightColor)
    lerpWeatherCol(w.sundiscSunsetColor, deltas.sundiscSunsetColor)
    tes3.worldController.weatherController:updateVisuals()

    lerpScatterCol(this.outscatter, deltas.outscatter)
    lerpScatterCol(this.inscatter, deltas.inscatter)
    lerpScatterCol(this.skylightScatter, deltas.skylightScatter)
    this.skylightScatterMix = lerpScalar(this.skylightScatterMix, deltas.skylightScatterMix)

    setScattering()
    deltas.t = deltas.t + dt
end

-- Colour space conversions for picker. sRGB to CIE LCh perceptual.
local function sRGBToLCh(sRGB)
    -- sRGB with domain [0, 1] to linear RGB.
    local linRGB = {}
    for i = 1, 3 do
        if (sRGB[i] > 0.04045) then
            linRGB[i] = math.pow((sRGB[i] + 0.055) / 1.055, 2.4)
        else
            linRGB[i] = sRGB[i] / 12.91
        end
    end

    -- To XYZ with [0, 1] domain. Relative to D65/2deg.
    local xyz = {
        0.4123866 * linRGB[1] + 0.3575915 * linRGB[2] + 0.1804505 * linRGB[3],
        0.2126368 * linRGB[1] + 0.7151830 * linRGB[2] + 0.0721802 * linRGB[3],
        0.0193306 * linRGB[1] + 0.1191972 * linRGB[2] + 0.9503726 * linRGB[3]
    }

    -- To L*ab D65.
    xyz = { xyz[1] / 0.95047, xyz[2], xyz[3] / 1.08883 }
    for i = 1, 3 do
        if (xyz[i] > 0.008856) then
            xyz[i] = math.pow(xyz[i], 1/3)
        else
            xyz[i] = 7.787*xyz[i] + 16/116
        end
    end

    local Lab = {
        116 * xyz[2] - 16,
        500 * (xyz[1] - xyz[2]),
        200 * (xyz[2] - xyz[3])
    }

    -- To LCh.
    local h = math.atan2(Lab[3], Lab[2])
    if (h < 0) then
        h = h + 2*math.pi
    end

    local LCh = { Lab[1], math.sqrt(Lab[2]*Lab[2] + Lab[3]*Lab[3]), math.deg(h) }
    --print(string.format("XYZ %.5f %.5f %.5f", xyz[1], xyz[2], xyz[3]))
    --print(string.format("Lab %.5f %.5f %.5f", Lab[1], Lab[2], Lab[3]))
    --print(string.format("LCh %.5f %.5f %.5f", LCh[1], LCh[2], LCh[3]))
    return LCh
end

-- Colour space conversions for picker. CIE LCh perceptual to unclamped sRGB.
local function LChTosRGB(LCh)
    -- LCh to L*ab D65.
    local Lab = {
        LCh[1],
        LCh[2] * math.cos(math.rad(LCh[3])),
        LCh[2] * math.sin(math.rad(LCh[3]))
    }

    -- To XYZ with domain [0, 1]. Relative to D65/2deg.
    local xyz_pre = {}
    xyz_pre[2] = (Lab[1] + 16) / 116
    xyz_pre[1] = Lab[2] / 500 + xyz_pre[2]
    xyz_pre[3] = xyz_pre[2] - Lab[3] / 200

    local xyz = { math.pow(xyz_pre[1], 3), math.pow(xyz_pre[2], 3), math.pow(xyz_pre[3], 3) }
    for i = 1, 3 do
        if (xyz[i] <= 0.008856) then
            xyz[i] = (xyz_pre[i] - 16/116) / 7.787
        end
    end
    xyz = { xyz[1] * 0.95047, xyz[2], xyz[3] * 1.08883 }

    -- To sRGB with domain [0, 1]. Does not clamp.
    local rgb = {
        3.2410032 * xyz[1] + -1.5373990 * xyz[2] + -0.4986159 * xyz[3],
        -0.9692242 * xyz[1] + 1.8759300 * xyz[2] + 0.0415542 * xyz[3],
        0.0556394 * xyz[1] + -0.2040112 * xyz[2] + 1.0571490 * xyz[3]
    }

    for i = 1, 3 do
        if (rgb[i] > 0.0031307) then
            rgb[i] = 1.055 * math.pow(rgb[i], 1/2.4) - 0.055
        else
            rgb[i] = 12.92 * rgb[i]
        end
    end

    --print(string.format("Lab %.5f %.5f %.5f", Lab[1], Lab[2], Lab[3]))
    --print(string.format("XYZ %.5f %.5f %.5f", xyz[1], xyz[2], xyz[3]))
    --print(string.format("sRGB %.5f %.5f %.5f", rgb[1], rgb[2], rgb[3]))
    return rgb
end

-- Colour space conversions for picker. CIE LCh to in-gamut sRGB, using chroma reduction to move colours into gamut.
local function LChTosRGBContainChroma(LCh)
    local LCh_adj = { LCh[1], LCh[2], LCh[3] }
    local validChroma = 0
    local upperChroma = LCh[2]
    local sRGB = LChTosRGB(LCh_adj)

    -- Binary search for chroma that produces an in-gamut sRGB result.
    for _ = 1,16 do
        -- Check result is within sRGB, with a little leeway for rounding error.
        local withinGamut = true
        for i = 1, 3 do
            if (sRGB[i] < -0.5/255 or sRGB[i] > 255.5/255) then
                withinGamut = false
                break
            end
        end

        -- Terminate on acceptable convergence.
        if (math.abs(LCh_adj[2] - validChroma) < 0.1) then
            break
        end

        -- Calculate new LCh and sRGB.
        if (withinGamut) then
            validChroma = LCh_adj[2]
        else
            upperChroma = LCh_adj[2]
        end
        LCh_adj[2] = 0.5 * (validChroma + upperChroma)
        sRGB = LChTosRGB(LCh_adj)
    end

    -- Clamp sRGB.
    for i = 1, 3 do
        sRGB[i] = math.max(0, math.min(1, sRGB[i]))
    end
    return sRGB
end

local function createPickerAdv(params)
    local value = params.initial
    local channelText = { "L", "C", "h" }
    local channelRange = { 100, 140, 360 }

    local pickerBlock = params.parent:createBlock{}
    pickerBlock.flowDirection = tes3.flowDirection.leftToRight
    pickerBlock.widthProportional = 1.0
    pickerBlock.height = 24*3

    local channelLabels = {}
    for i = 1, 3 do
        local y = 0.45 * i - 0.4
        local label = pickerBlock:createLabel({ text = channelText[i] })
        label.absolutePosAlignX = 0.02
        label.absolutePosAlignY = y

        channelLabels[i] = pickerBlock:createLabel({ text = string.format("%.0f", value[i]) })
        channelLabels[i].absolutePosAlignX = 0.08
        channelLabels[i].absolutePosAlignY = y
    end

    local picker = pickerBlock:createRect{ color = {1, 1, 1} }
    picker.borderLeft = 75
    picker.width = 361
    picker.height = 72
    picker.imageScaleX = picker.width / 256
    picker.imageScaleY = picker.height / 3
    picker.texture = params.texture
    picker.imageFilter = false

    local indicators = {}
    for i = 1, 3 do
        indicators[i] = picker:createRect{ color = { 0.2, 0.2, 0.2 } }
        indicators[i].width = 2
        indicators[i].height = 8
        indicators[i].absolutePosAlignX = value[i] / channelRange[i]
        indicators[i].absolutePosAlignY = 0.375 * (i - 1)
        indicators[i].consumeMouseEvents = false
    end

    local function updatePalette()
        local offset = 0
        for channel = 1, 3 do
            local c = { value[1], value[2], value[3] }
            for i = 0, 255 do
                c[channel] = channelRange[channel] * i/255

                local rgb = LChTosRGBContainChroma(c)
                this.pixBuffer[offset+1] = rgb[1]
                this.pixBuffer[offset+2] = rgb[2]
                this.pixBuffer[offset+3] = rgb[3]
                this.pixBuffer[offset+4] = 1
                offset = offset + 4
            end
            indicators[channel].absolutePosAlignX = value[channel] / channelRange[channel]
        end
        picker.texture.pixelData:setPixelsFloat(this.pixBuffer)
        pickerBlock:getTopLevelMenu():updateLayout()
        -- imageFilter has to run after the layout has created a scene node.
        picker.imageFilter = false
    end

    picker:register(tes3.uiEvent.mouseDown, function(e)
        table.insert(this.undoStack, currentWeatherToPreset())
        this.redoStack = {}
        tes3ui.captureMouseDrag(true)
    end)
    picker:register(tes3.uiEvent.mouseRelease, function(e)
        tes3ui.captureMouseDrag(false)
    end)
    picker:register(tes3.uiEvent.mouseStillPressed, function(e)
        local propX = math.max(0, math.min(1, e.relativeX / picker.width))
        local propY = math.max(0, math.min(1, e.relativeY / picker.height))
        local channel = math.min(3, 1 + math.floor(3 * propY))
        local x = channelRange[channel] * propX

        value[channel] = x
        channelLabels[channel].text = string.format("%.0f", x)
        updatePalette()

        if (params.onUpdate) then
            params.onUpdate(value)
        end
    end)

    updatePalette()
    return { block = horizontalBlock, label = label, pickerLabel = pickerLabel, picker = picker }
end

local function createRadioButtonPackage(params)
    local buttons = {}

    local horizontalBlock = params.parent:createBlock{ id = params.id }
    horizontalBlock.flowDirection = tes3.flowDirection.leftToRight
    horizontalBlock.widthProportional = 1.0
    horizontalBlock.autoHeight = true

    for i, label in ipairs(params.labels) do
        buttons[i] = horizontalBlock:createButton{ text = label }
        buttons[i]:register(tes3.uiEvent.mouseClick, function(e)
            local n = -1
            for i, button in ipairs(buttons) do
                if (button == e.source) then
                    n = i
                    button.widget.state = 4
                else
                    button.widget.state = 1
                end
            end

            if (params.onUpdate) then
                e.option = n
                params.onUpdate(e)
            end
            horizontalBlock:getTopLevelParent():updateLayout()
        end)
    end

    local n = params.initial or 1
    buttons[n].widget.state = 4

    return { block = horizontalBlock, buttons = buttons }
end

local function createLChEdit(parent, text, tip, textureID, binding, updateMGE)
    local c = sRGBToLCh({ binding.r, binding.g, binding.b })
    local pickers = {}

    local label = parent:createLabel{ text = text }
    label.borderTop = 6
    label.borderBottom = 2
    label:register(tes3.uiEvent.help, function(e)
        local tooltip = tes3ui.createTooltipMenu()
        tooltip:createLabel{ text = tip }
    end)

    local callback = function(value)
        local rgb = LChTosRGBContainChroma(value)
        binding.r, binding.g, binding.b = rgb[1], rgb[2], rgb[3]
        tes3.worldController.weatherController:updateVisuals()

        local swatches = parent:findChild(this.id_swatches)
        if (swatches) then
            swatches:triggerEvent("update")
        end
        if (updateMGE) then
            updateScattering()
        end
    end

    createPickerAdv{ parent = parent, initial = c, texture = this.lchTextures[textureID], onUpdate = callback }
end

local function lerpSwatchColours(x, y, t)
    local c = {}
    for i = 1,3 do
        c[i] = (1 - t) * x[i] + t * y[i]
    end
    return c
end

local function createSkyMixEdit(parent, text, tip)
    local value = this.skylightScatterMix

    local label = parent:createLabel{ text = text }
    label.borderTop = 6
    label.borderBottom = 2
    label:register(tes3.uiEvent.help, function(e)
        local tooltip = tes3ui.createTooltipMenu()
        tooltip:createLabel{ text = tip }
    end)

    local textColour = { 0.96, 0.96, 0.96 }
    local editBlock = parent:createBlock{ id = this.id_swatches }
    editBlock.flowDirection = tes3.flowDirection.leftToRight
    editBlock.widthProportional = 1
    editBlock.height = 45
    editBlock.borderLeft = 35

    local swatchSky = editBlock:createRect{}
    swatchSky.width = 70
    swatchSky.heightProportional = 1
    label = swatchSky:createLabel{ text = "Небо" }
    label.absolutePosAlignX = 0.5
    label.color = textColour

    local swatchSkylight = editBlock:createRect{}
    swatchSkylight.width = 70
    swatchSkylight.heightProportional = 1
    label = swatchSkylight:createLabel{ text = "Свет" }
    label.absolutePosAlignX = 0.5
    label.color = textColour

    local swatchMixed = editBlock:createRect{}
    swatchMixed.width = 70
    swatchMixed.heightProportional = 1
    label = swatchMixed:createLabel{ text = "Смеш." }
    label.absolutePosAlignX = 0.5
    label.color = textColour

    local sliderBlock = editBlock:createBlock{}
    sliderBlock.widthProportional = 1
    sliderBlock.heightProportional = 1
    sliderBlock.flowDirection = tes3.flowDirection.topToBottom

    local s = sliderBlock:createSlider{ current = value * 1000, min = 0, max = 1000, step = 10, jump = 50 }
    s.width = 175
    s.borderLeft = 15
    s.borderRight = 20
    s.borderTop = 4

    local sliderLabel = sliderBlock:createLabel{ text = "%" }
    sliderLabel.absolutePosAlignX = 0.5

    local updateControl = function()
        local currentSkyColour = tes3.worldController.weatherController.currentSkyColor
        currentSkyColour = { currentSkyColour.r, currentSkyColour.g, currentSkyColour.b }
        swatchSky.color = currentSkyColour
        swatchSkylight.color = this.skylightScatter
        swatchMixed.color = lerpSwatchColours(currentSkyColour, this.skylightScatter, this.skylightScatterMix)
        sliderLabel.text = string.format("%d%%", math.round(100 * this.skylightScatterMix))
    end
    
    updateControl()
    editBlock:register(tes3.uiEvent.update, updateControl)
    s:register(tes3.uiEvent.partScrollBarChanged, function(e)
        table.insert(this.undoStack, currentWeatherToPreset())

        value = e.source.widget.current / 1000
        this.skylightScatterMix = value

        updateControl()
        updateScattering()
    end)
end

local function createTextureAdjuster(parent)
    local wc = tes3.worldController.weatherController

    local label1 = parent:createLabel{ text = "Имя файла текстуры облаков:" }
    label1.borderLeft = 8
    label1.borderTop = 8
    label1.borderBottom = 6

    local texturePathFrame = parent:createThinBorder{}
    texturePathFrame.width = 400
    texturePathFrame.height = 30
    texturePathFrame.borderLeft = 8
    texturePathFrame.borderBottom = 4
    texturePathFrame.paddingLeft = 4
    texturePathFrame.childAlignY = 0.5
    local texturePathInput = texturePathFrame:createTextInput{}
    texturePathInput.color = tes3ui.getPalette(tes3.palette.active_color)
    texturePathInput.text = wc.currentWeather.cloudTexture or "<use default>"
    texturePathInput.consumeMouseEvents = false
    local textureReset = parent:createButton{ text = "Сбросить" }
    textureReset.borderLeft = 8
    textureReset.borderBottom = 12

    texturePathFrame:register(tes3.uiEvent.mouseClick, function(e)
        if (not wc.currentWeather.cloudTexture) then
            texturePathInput.text = ""
        end

        -- Add text caret.
        if (not string.find(texturePathInput.text, '%|')) then
            texturePathInput.text = texturePathInput.text .. "|"
        end

        tes3ui.acquireTextInput(texturePathInput)
        e.source:getTopLevelMenu():updateLayout()
    end)
    texturePathInput:register(tes3.uiEvent.keyEnter, function(e)
        if (texturePathInput.text == "") then
            texturePathInput.color = { 0.5, 0.5, 0.5 }
            texturePathInput.text = wc.currentWeather.cloudTexture
        else
            local path = texturePathInput.text

            -- Remove text caret.
            texturePathInput.text = path

            -- Colour text depending on valid path. getFileExists checks BSAs.
            -- Update cloud texture if it exists.
            if (tes3.getFileExists(path)) then
                texturePathInput.color = tes3ui.getPalette(tes3.palette.active_color)
                if (path ~= wc.currentWeather.cloudTexture) then
                    table.insert(this.undoStack, currentWeatherToPreset())
                    this.redoStack = {}

                    wc.currentWeather.cloudTexture = path
                    wc:switchImmediate(wc.currentWeather.index)
                end
            else
                texturePathInput.color = tes3ui.getPalette(tes3.palette.answer_color)
            end
        end

        tes3ui.acquireTextInput(nil)
        e.source:getTopLevelMenu():updateLayout()
    end)
    textureReset:register(tes3.uiEvent.mouseClick, function(e)
        texturePathInput.text = this.defaultClouds[wc.currentWeather.index+1]
        texturePathInput:triggerEvent(tes3.uiEvent.keyEnter)
    end)
end

local function changeAdjuster(e)
    local menu = tes3ui.findMenu(this.id_menu)
    local block = menu:findChild(this.id_colourBlock)
    block:destroyChildren()

    skyTip = "Влияет на цвет неба вместе с туманом."
    fogTip = "Влияет на цвет тумана, облаков и горизонта."
    sunTip = "Влияет на цвет солнечного света."
    ambTip = "Базовый уровень освещенности, влияет на цвет теней с солнечным светом."
    sundiscTip = "Влияет на изображение солнца на закате. С шейдером sun shafts создает эффект только солнечного ореола."
    outscatterTip = "Высококачественная настройка MGE. Используется всеми погодными условиями в этом пресете.\nТолько ясная, облачная и переходная погода. Влияет на цвет неба вблизи солнца."
    inscatterTip = "Высококачественная настройка MGE. Используется всеми погодными условиями в этом пресете.\nТолько ясная, облачная и переходная погода. Влияет на цвет неба вдали от солнца."
    skylightTip = "Высококачественная настройка MGE. Используется всеми погодными условиями в этом пресете.\nДополнительный цвет окружения за счет многократного рассеивания, которое смешивается с цветом неба и используется для изображения неба и дымки в течение дня.\nПозволяет дополнительно регулировать яркость и тон окружения. Рекомендуется использовать нейтральный цвет.\nПроцент смешивания регулируется ниже."
    skylightMixTip = "Высококачественная настройка MGE. Используется всеми погодными условиями в этом пресете.\nУправляет смешиванием цвета неба из базовой игры и цвета небесного света,для получения цвета, используемого для цвета неба и дымки.\nРекомендуется использовать 20-50% смешивания."

    if (e.option == 1) then
        createLChEdit(block, "Небо, Утро", skyTip, 1, this.w.skySunriseColor)
        createLChEdit(block, "Туман, Утро", fogTip, 2, this.w.fogSunriseColor)
        createLChEdit(block, "Солнце, Утро", sunTip, 3, this.w.sunSunriseColor)
        createLChEdit(block, "Окружение, Утро", ambTip, 4, this.w.ambientSunriseColor)
    elseif (e.option == 2) then
        createLChEdit(block, "Небо, День", skyTip, 1, this.w.skyDayColor)
        createLChEdit(block, "Туман, День", fogTip, 2, this.w.fogDayColor)
        createLChEdit(block, "Солнце, День", sunTip, 3, this.w.sunDayColor)
        createLChEdit(block, "Окружение, День", ambTip, 4, this.w.ambientDayColor)
    elseif (e.option == 3) then
        createLChEdit(block, "Небо, Вечер", skyTip, 1, this.w.skySunsetColor)
        createLChEdit(block, "Туман, Вечер", fogTip, 2, this.w.fogSunsetColor)
        createLChEdit(block, "Солнце, Вечер", sunTip, 3, this.w.sunSunsetColor)
        createLChEdit(block, "Окружение, Вечер", ambTip, 4, this.w.ambientSunsetColor)
    elseif (e.option == 4) then
        createLChEdit(block, "Небо, Ночь", skyTip, 1, this.w.skyNightColor)
        createLChEdit(block, "Туман, Ночь", fogTip, 2, this.w.fogNightColor)
        createLChEdit(block, "Солнце, Ночь", sunTip, 3, this.w.sunNightColor)
        createLChEdit(block, "Окружение, Ночь", ambTip, 4, this.w.ambientNightColor)
    elseif (e.option == 5) then
        createLChEdit(block, "Солнечный диск, Вечер  [?]", sundiscTip, 1, this.w.sundiscSunsetColor)
        createLChEdit(block, "Атмосферное рассеивание  [?]", outscatterTip, 2, this.outscatterInv, true)
        createLChEdit(block, "Атмосферное зарлонение  [?]", inscatterTip, 3, this.inscatterInv, true)
        if (mge.weather.getSkylightScattering) then
            createLChEdit(block, "Атмосферный свет неба  [?]", skylightTip, 4, this.skylightScatterCol, true)
            createSkyMixEdit(block, "Сочетание цвета и света неба  [?]", skylightMixTip)
        end
    elseif (e.option == 6) then
        createTextureAdjuster(block)
    end

    this.editorMode = e.option
    menu:updateLayout()
end

local function refreshEditor()
    local menu = tes3ui.findMenu(this.id_menu)
    local label = menu:findChild(this.id_weatherName)
    local t = tes3.worldController.hour.value
    local h = math.floor(t)
    local m = math.floor(60 * (t - h))

    local wc = tes3.worldController.weatherController
    local weatherTxt
	local weatherTxtlable
    if (wc.nextWeather) then
        weatherTxt = string.format("%s to %s", weatherNames[wc.currentWeather.index+1], weatherNames[wc.nextWeather.index+1])
        weatherTxtlable = string.format("Смена %s на %s", weatherLabels[wc.currentWeather.index+1], weatherLabels[wc.nextWeather.index+1])
    else
        weatherTxt = weatherNames[wc.currentWeather.index+1]
		weatherTxtlable = weatherLabels[wc.currentWeather.index+1]
    end
    label.text = string.format("%s, %d:%02d", weatherTxtlable, h, m)

    changeAdjuster{ option = this.editorMode }
    menu:updateLayout()
end

local function changeWeather(n)
    if (isShiftPressed()) then
        tes3.worldController.weatherController:switchTransition(n-1)
    else
        tes3.worldController.weatherController:switchImmediate(n-1)
    end
    tes3.worldController.weatherController:updateVisuals()
    this.w = tes3.getCurrentWeather()
    this.undoStack = {}
    this.redoStack = {}
    refreshEditor()
end

local function changeColourEditPage(e)
    if (isShiftPressed()) then
        local wc = tes3.worldController.weatherController

        if (e.option == 1) then
            tes3.worldController.hour.value = wc.sunriseHour + 1
        elseif (e.option == 2) then
            tes3.worldController.hour.value = 13
        elseif (e.option == 3) then
            tes3.worldController.hour.value = wc.sunsetHour + wc.sunsetDuration - 1
        elseif (e.option == 4) then
            tes3.worldController.hour.value = 1
        end

        wc:updateVisuals()
    end

    this.w = tes3.getCurrentWeather()
    this.editorMode = e.option
    refreshEditor()
end

local function saveIniData(e)
    local function RGBtoINI(text, c)
        return string.format("%s=%03d,%03d,%03d\n", text, math.round(255*c.r), math.round(255*c.g), math.round(255*c.b))
    end

    local file = io.open(weatherSettingsPath, "a")
    if (not file) then
        tes3.messageBox{ message = "Не удалось открыть файл вывода." }
        return
    end

    file:write("\n; ----------------------------------------\n; Weather Adjuster\n")
    file:write("; Preset \"" .. this.activePreset .. "\", " .. os.date("%Y-%m-%d %H:%M:%S"))

    file:write("\n\n; Morrowind.ini compatible data\n\n")
    for i, w in ipairs(tes3.worldController.weatherController.weathers) do
        file:write(string.format("[Weather %s]\n", weatherNames[i]))
        file:write(RGBtoINI("Sky Sunrise Color", w.skySunriseColor))
        file:write(RGBtoINI("Sky Day Color", w.skyDayColor))
        file:write(RGBtoINI("Sky Sunset Color", w.skySunsetColor))
        file:write(RGBtoINI("Sky Night Color", w.skyNightColor))
        file:write(RGBtoINI("Fog Sunrise Color", w.fogSunriseColor))
        file:write(RGBtoINI("Fog Day Color", w.fogDayColor))
        file:write(RGBtoINI("Fog Sunset Color", w.fogSunsetColor))
        file:write(RGBtoINI("Fog Night Color", w.fogNightColor))
        file:write(RGBtoINI("Ambient Sunrise Color", w.ambientSunriseColor))
        file:write(RGBtoINI("Ambient Day Color", w.ambientDayColor))
        file:write(RGBtoINI("Ambient Sunset Color", w.ambientSunsetColor))
        file:write(RGBtoINI("Ambient Night Color", w.ambientNightColor))
        file:write(RGBtoINI("Sun Sunrise Color", w.sunSunriseColor))
        file:write(RGBtoINI("Sun Day Color", w.sunDayColor))
        file:write(RGBtoINI("Sun Sunset Color", w.sunSunsetColor))
        file:write(RGBtoINI("Sun Night Color", w.sunNightColor))
        file:write(RGBtoINI("Sun Disc Sunset Color", w.sundiscSunsetColor))
        file:write("\n")
    end

    file:close()
    tes3.messageBox{ message = this.activePreset .. " добавлен в " .. weatherSettingsPath }
end

local function setModeFromTime()
    local wc = tes3.worldController.weatherController
    local t = tes3.worldController.hour.value

    if (t < wc.sunriseHour) then
        this.editorMode = 4
    elseif (t < wc.sunriseHour + wc.sunriseDuration) then
        this.editorMode = 1
    elseif (t < wc.sunsetHour) then
        this.editorMode = 2
    elseif (t < wc.sunsetHour + wc.sunsetDuration) then
        this.editorMode = 3
    else
        this.editorMode = 4
    end
end

local function createTabEditor()
    local page = tes3ui.findMenu(this.id_menu):findChild(this.id_tabPage)
    page:destroyChildren()

    local switchBlock1 = page:createBlock{}
    switchBlock1.flowDirection = tes3.flowDirection.leftToRight
    switchBlock1.widthProportional = 1.0
    switchBlock1.autoHeight = true
    switchBlock1:createLabel{ text = "Переключить на:" }
    for i = 1, 5 do
        local b = switchBlock1:createTextSelect{ text = weatherLabels[i] }
        b.borderLeft = 12
        b:register(tes3.uiEvent.mouseClick, function(e) changeWeather(i) end)
    end
    local switchBlock2 = page:createBlock{}
    switchBlock2.flowDirection = tes3.flowDirection.leftToRight
    switchBlock2.widthProportional = 1.0
    switchBlock2.autoHeight = true
    for i = 6, 10 do
        local b = switchBlock2:createTextSelect{ text = weatherLabels[i] }
        b.borderLeft = 12
        b:register(tes3.uiEvent.mouseClick, function(e) changeWeather(i) end)
    end

    local timeBlock = page:createBlock{}
    timeBlock.flowDirection = tes3.flowDirection.leftToRight
    timeBlock.widthProportional = 1.0
    timeBlock.autoHeight = true
    timeBlock.childAlignY = 0.4
    timeBlock.borderTop = 16

    local wname = timeBlock:createLabel{ id = this.id_weatherName }
    wname.minWidth = 160

    -- Time shift 30 mins, or 5 mins with Shift held
    local timeBack30 = timeBlock:createButton{ text = "-30 мин" }
    timeBack30.borderLeft = 30
    timeBack30:register(tes3.uiEvent.mouseClick, function(e)
        local timeChange = isShiftPressed() and 0.08333 or 0.5
        tes3.worldController.hour.value = (tes3.worldController.hour.value - timeChange) % 24
        tes3.worldController.weatherController:updateVisuals()
        refreshEditor()
    end)
    local timeFwd30 = timeBlock:createButton{ text = "+30 мин" }
    timeFwd30:register(tes3.uiEvent.mouseClick, function(e)
        local timeChange = isShiftPressed() and 0.08333 or 0.5
        tes3.worldController.hour.value = (tes3.worldController.hour.value + timeChange) % 24
        tes3.worldController.weatherController:updateVisuals()
        refreshEditor()
    end)


    local modesHelp = page:createLabel{ text = "Shift + переключатель для изменения времени." }
    modesHelp.borderTop = 4
    local modes = createRadioButtonPackage{ parent = page, id = this.id_modes, labels = {"Утро", "День", "Вечер", "Ночь", "Атмос.", "Облака"}, initial = this.editorMode, onUpdate = changeColourEditPage }
    modes.block.borderTop = 4

    local colourBlock = page:createBlock{ id = this.id_colourBlock }
    colourBlock.widthProportional = 1.0
    colourBlock.autoHeight = true
    colourBlock.borderTop = 6
    colourBlock.flowDirection = tes3.flowDirection.topToBottom

    local undoRedo = page:createBlock{}
    undoRedo.absolutePosAlignX = 0.96
    undoRedo.absolutePosAlignY = 0.93
    undoRedo.autoWidth = true
    undoRedo.autoHeight = true
    local undoButton = undoRedo:createButton{ text = "Назад" }
    undoButton:register(tes3.uiEvent.mouseClick, function(e)
        if (#this.undoStack > 0) then
            table.insert(this.redoStack, currentWeatherToPreset())
            presetToCurrentWeather(table.remove(this.undoStack))
            refreshEditor()
        end
    end)
    local redoButton = undoRedo:createButton{ text = "Вперед" }
    redoButton:register(tes3.uiEvent.mouseClick, function(e)
        if (#this.redoStack > 0) then
            table.insert(this.undoStack, currentWeatherToPreset())
            presetToCurrentWeather(table.remove(this.redoStack))
            refreshEditor()
        end
    end)

    local saveBlock = page:createBlock{}
    saveBlock.absolutePosAlignX = 0.02
    saveBlock.absolutePosAlignY = 0.99
    saveBlock.autoWidth = true
    saveBlock.autoHeight = true

    local save1 = saveBlock:createButton{ text = "Отменить" }
    save1:register(tes3.uiEvent.mouseClick, function(e)
        switchPreset(this.activePreset)
        refreshEditor()
        tes3.messageBox{ message = this.activePreset .. " отменен." }
    end)
    local save2 = saveBlock:createButton{ text = "Сохранить" }
    save2:register(tes3.uiEvent.mouseClick, function(e)
        if (this.activePreset == "default") then
            return
        end

        config.presets[this.activePreset] = currentWeatherToPreset()
        mwse.saveConfig(configId, config)

        tes3.messageBox{ message = this.activePreset .. " сохранен." }
    end)
    local save3 = saveBlock:createButton{ text = "Сохранить как новый пресет" }
    save3:register(tes3.uiEvent.mouseClick, function(e)
        local newId
        for n = 1,9999 do
            newId = string.format("Новый пресет %d", n)
            if not config.presets[newId] then break end
        end

        config.presets[newId] = currentWeatherToPreset()
        mwse.saveConfig(configId, config)

        switchPreset(newId)
        refreshEditor()
        tes3.messageBox{ message = newId .. " сохранен." }
    end)

    refreshEditor()
end

local function refreshPresets()
    local menu = tes3ui.findMenu(this.id_menu)
    local presetList = menu:findChild(this.id_presetList)
    presetList:getContentElement():destroyChildren()

    sorted = {}
    for k in pairs(config.presets) do
        table.insert(sorted, k)
    end
    table.sort(sorted)

    for _, name in ipairs(sorted) do
        local item = presetList:createTextSelect{ text = name }
        if (name == this.activePreset) then
            item.widget.state = 4
            item:triggerEvent(tes3.uiEvent.mouseLeave)
        end

        item:register(tes3.uiEvent.mouseClick, function(e)
            switchPreset(name)

            local listContents = e.source.parent
            for _, x in ipairs(listContents.children) do
                x.widget.state = 1
                x:triggerEvent(tes3.uiEvent.mouseLeave)
            end
            e.source.widget.state = 4
            menu:updateLayout()
        end)
    end
    menu:updateLayout()
end

local function createTabPresets()
    local menu = tes3ui.findMenu(this.id_menu)
    local page = menu:findChild(this.id_tabPage)
    page:destroyChildren()

    local toolbar = page:createBlock{}
    toolbar.flowDirection = tes3.flowDirection.leftToRight
    toolbar.widthProportional = 1.0
    toolbar.autoHeight = true

    local b
    b = toolbar:createButton{ text = "Копировать" }
    b:register(tes3.uiEvent.mouseClick, function(e)
        local copyId
        for n = 1,9999 do
            copyId = string.format("%s (%d)", this.activePreset, n)
            if not config.presets[copyId] then break end
        end

        local p = {}
        for k, v in pairs(config.presets[this.activePreset]) do
            p[k] = v
        end

        config.presets[copyId] = p
        mwse.saveConfig(configId, config)

        refreshPresets()
    end)

    b = toolbar:createButton{ text = "Переименовать" }
    b:register(tes3.uiEvent.mouseClick, function(e)
        if (this.activePreset == "default") then
            return
        end

        local renameInput = menu:findChild(this.id_renameInput)
        renameInput.text = this.activePreset .. "|"
        renameInput.parent.visible = true
        tes3ui.acquireTextInput(renameInput)
        menu:updateLayout()

        renameInput:register(tes3.uiEvent.keyEnter, function(e)
            local renameInput = menu:findChild(this.id_renameInput)
            local oldName = this.activePreset
            local newName = renameInput.text
            renameInput.parent.visible = false
            tes3ui.acquireTextInput(nil)

            if (oldName == newName or newName == "") then
                return
            end
            if (config[newName]) then
                tes3.messageBox{ message = newName .. " уже используется другой конфигурацией." }
                return
            end

            config.presets[newName] = config.presets[oldName]
            this.activePreset = newName
            for k, v in pairs(config.regions) do
                if (v == oldName) then
                    config.regions[k] = newName
                end
            end
            config.presets[oldName] = nil
            mwse.saveConfig(configId, config)

            refreshPresets()
            menu:findChild(this.id_activePreset).text = "Активный: " .. this.activePreset
            menu:updateLayout()
        end)
    end)

    b = toolbar:createButton{ text = "Удалить" }
    b:register(tes3.uiEvent.mouseClick, function(e)
        if (this.activePreset == "default") then
            return
        end

        if (isShiftPressed()) then
            for k, v in pairs(config.regions) do
                if (v == this.activePreset) then
                    config.regions[k] = nil
                end
            end
            config.presets[this.activePreset] = nil
            mwse.saveConfig(configId, config)

            switchPreset("default")
            refreshPresets()
        else
            tes3.messageBox{ message = "Нажатие на эту кнопку с зажатой клавишей Shift подтвердит удаление." }
        end
    end)

    b = toolbar:createButton{ text = "Сохранить в INI" }
    --b.borderLeft = 125
    b:register(tes3.uiEvent.mouseClick, saveIniData)

    local renamer = page:createThinBorder{}
    renamer.visible = false
    renamer.widthProportional = 1.0
    renamer.height = 30
    renamer.childAlignY = 0.5
    renamer.borderTop = 4
    renamer.borderBottom = 4
    renamer.paddingLeft = 4
    local renameInput = renamer:createTextInput{ id = this.id_renameInput }

    local presetList = page:createVerticalScrollPane{ id = this.id_presetList }
    refreshPresets()
end

local function createTabRegions()
    local menu = tes3ui.findMenu(this.id_menu)
    local page = menu:findChild(this.id_tabPage)
    page:destroyChildren()

    local region = tes3.getPlayerCell().region
    local regionLabel = page:createLabel{ text = "Текущий регион: " .. (region and region.id or "Нет") }
    regionLabel.borderBottom = 6
    local helpLabel = page:createLabel{ text = "Щелкните на регион, чтобы загрузить его пресет.\nShift-клик на регион заставит его использовать активный пресет." }
    helpLabel.borderBottom = 4

    local regionList = page:createVerticalScrollPane{ id = this.id_regionList }
    for region in tes3.iterate(tes3.dataHandler.nonDynamicData.regions) do
        local item = regionList:createTextSelect{ text = region.id }
        item.widthProportional = 1.0
        item.childOffsetX = 240
        local itemRegion = item:createLabel{ text = "- " .. (config.regions[region.id] or "default") }
        itemRegion.consumeMouseEvents = false

        item:register(tes3.uiEvent.mouseClick, function(e)
            if (isShiftPressed()) then
                -- Set region preset.
                config.regions[region.id] = this.activePreset
                mwse.saveConfig(configId, config)

                e.source.children[1].text = "- " .. this.activePreset

                local listContents = e.source.parent
                for i, x in ipairs(listContents.children) do
                    x.widget.state = 1
                    x:triggerEvent(tes3.uiEvent.mouseLeave)
                end
                e.source.widget.state = 4
                menu:updateLayout()
            else
                -- Load region preset.
                switchPreset(config.regions[region.id] or "default")
            end
        end)
    end

    menu:updateLayout()
end

local function onTabChange(e)
    this.tabMode = e.option

    if (e.option == 1) then
        createTabPresets()
    elseif (e.option == 2) then
        createTabRegions()
    elseif (e.option == 3) then
        setModeFromTime()
        createTabEditor()
    end
end

local function createAdjuster()
    local wc = tes3.worldController.weatherController
    local t = tes3.worldController.hour.value
    this.w = tes3.getCurrentWeather()

    local menu = tes3ui.createMenu{ id = this.id_menu, dragFrame = true }
    menu.text = "Настройка погоды"
    menu.width = 470
    menu.height = 750
    if (this.menuX) then
        menu.positionX = this.menuX
        menu.positionY = this.menuY
    else
        -- Set defaults before loading
        menu.positionX = menu.maxWidth / 2 - menu.width
        menu.positionY = 400
        menu:loadMenuPosition()
    end

    local topBar = menu:createBlock{}
    topBar.widthProportional = 1.0
    topBar.autoHeight = true
    topBar.childAlignY = 0.5

    local active = topBar:createLabel{ id = this.id_activePreset, text = "Активный: " .. this.activePreset }
    active.minWidth = 210
    active.maxWidth = 210
    createRadioButtonPackage{ parent = topBar, id = this.id_tabs, labels = {"Пресеты", "Регионы", "Редактор"}, initial = this.tabMode or 1, onUpdate = onTabChange }
    local divider = menu:createDivider{}
    divider.borderAllSides = 2

    local page = menu:createBlock{ id = this.id_tabPage }
    page.flowDirection = tes3.flowDirection.topToBottom
    page.widthProportional = 1.0
    page.heightProportional = 1.0

    menu:updateLayout()
    onTabChange{ option = this.tabMode or 1 }
end

local function toggle(e)
    if (tes3ui.findMenu(this.id_config_menu)) then
        return
    end

    if (e.keyCode == config.keybind.keyCode
        and e.isAltDown == config.keybind.isAltDown
        and e.isControlDown == config.keybind.isControlDown
        and e.isShiftDown == config.keybind.isShiftDown) then

        local menu = tes3ui.findMenu(this.id_menu)

        if (not menu) then
            createAdjuster()
            if (not tes3ui.menuMode()) then
                -- Enter menu mode without regular menus appearing.
                tes3ui.enterMenuMode(this.id_menu)
            end
        else
            this.menuX = menu.positionX
            this.menuY = menu.positionY
            menu:destroy()
            if (tes3ui.menuMode()) then
                tes3ui.leaveMenuMode()
            end
        end
    end
end

local regionTransitionK = 1 / math.max(1, regionTransitionDuration)

local function customTransition(e)
    -- Pause transition when inside.
    if (not this.lastRegion) then
        return
    end

    local wc = tes3.worldController.weatherController
    local dt = regionTransitionK * e.delta

    if (this.lerp) then
        -- Interpolate all colours for a single weather.
        applyWeatherDeltas(this.lerp.weather, this.lerp.deltas, dt)

        if (this.lerp.deltas.t >= 1) then
            this.lerp = nil
        end
    end

    if (wc.nextWeather) then
        -- Accelerate any weather transition.
        wc.transitionScalar = wc.transitionScalar + dt
    end

    if (this.lerp == nil and not wc.nextWeather) then
        if (this.secondTransition) then
            -- Second transition for cloud textures only.
            local i = wc.currentWeather.index + 1
            local presetWeather = config.presets[this.activePreset][weatherNames[i]]
            wc.currentWeather.cloudTexture = presetWeather.cloudTexture or this.defaultClouds[i]
            wc:switchTransition(wc.currentWeather.index)
            this.secondTransition = nil
        else
            -- End interpolation by setting all weathers to exact colours, without interrupting transitions.
            switchPreset(this.activePreset)

            event.unregister(tes3.event.simulate, customTransition)
            this.simulateActive = nil

            if (config.messageOnRegionChange) then
                tes3.messageBox{ message = "Преобразователь погоды: переход завершен." }
            end
        end
    end
end

local function onWeatherSwitch()
    -- Immediate change on teleports.
    this.lastRegion = nil
end

local function onCellChanged()
    local region = tes3.getPlayerCell().region
    local immediate = not this.lastRegion
    this.lastRegion = region

    if (region) then
        local pname = config.regions[region.id] or "default"
        if (pname ~= this.activePreset) then
            if (immediate) then
                -- Cancel interpolation.
                if (this.simulateActive) then
                    event.unregister(tes3.event.simulate, customTransition)
                    this.simulateActive = nil
                    this.lerp = nil
                end

                -- Switch preset and update visuals.
                switchPreset(pname)
                if (config.messageOnRegionChange) then
                    tes3.messageBox{ message = string.format("П. Переключение: %s, используется %s", region.id, pname) }
                end
            else
                local wc = tes3.worldController.weatherController
                local p = config.presets[pname]

                -- Set lerp data.
                this.lerp = {}
                this.lerp.weather = wc.nextWeather or wc.currentWeather
                this.lerp.deltas = calcPresetDeltas(p, this.lerp.weather)

                -- Switch preset without updating visuals.
                local currentWeatherOriginalClouds = wc.currentWeather.cloudTexture
                switchPreset(pname, true)

                if (not config.disableSkyTextureChanges) then
                    -- Re-trigger transition to load textures, or set up a second transition to do it later.
                    if (wc.nextWeather) then
                        local t = wc.transitionScalar
                        if (t <= 0.05) then
                            wc:switchTransition(wc.nextWeather.index)
                            wc.transitionScalar = t
                        else
                            this.secondTransition = wc.nextWeather
                        end
                    elseif (currentWeatherOriginalClouds ~= wc.currentWeather.cloudTexture) then
                        wc:switchTransition(wc.currentWeather.index)
                    end
                end

                -- Begin interpolation.
                if (not this.simulateActive) then
                    event.register(tes3.event.simulate, customTransition)
                    this.simulateActive = true
                end
                if (config.messageOnRegionChange) then
                    tes3.messageBox{ message = string.format("П. Переход: %s, используется %s", region.id, pname) }
                end
            end
        end
    end
end

local function onLoaded()
    if (not config.presets.default) then
        config.presets.default = currentWeatherToPreset()
    end

    this.lastRegion = nil
    onCellChanged()
end

local function init()
    this.id_config_menu = tes3ui.registerID("MWSE:ModConfigMenu")
    this.id_menu = tes3ui.registerID("Hrn:WeatherAdjust")
    this.id_tabs = tes3ui.registerID("Hrn:WeatherAdjust.Tabs")
    this.id_tabPage = tes3ui.registerID("Hrn:WeatherAdjust.TabPage")
    this.id_activePreset = tes3ui.registerID("Hrn:WeatherAdjust.Preset")
    this.id_renameInput = tes3ui.registerID("Hrn:WeatherAdjust.PresetRename")
    this.id_presetList = tes3ui.registerID("Hrn:WeatherAdjust.Presets")
    this.id_regionList = tes3ui.registerID("Hrn:WeatherAdjust.Regions")
    this.id_weatherName = tes3ui.registerID("Hrn:WeatherAdjust.WeatherName")
    this.id_modes = tes3ui.registerID("Hrn:WeatherAdjust.Modes")
    this.id_colourBlock = tes3ui.registerID("Hrn:WeatherAdjust.ColourBlock")
    this.id_swatches = tes3ui.registerID("Hrn:WeatherAdjust.Swatches")

    this.activePreset = "default"
    captureDefaultScattering()
    defaultScattering()

    this.defaultClouds = {}
    for i, w in ipairs(tes3.worldController.weatherController.weathers) do
        this.defaultClouds[i] = w.cloudTexture
    end

    this.undoStack = {}
    this.redoStack = {}

    this.lchTextures = {}
    for i = 1, 4 do
        this.lchTextures[i] = niPixelData.new(256, 4):createSourceTexture()
        this.lchTextures[i].isStatic = false
    end

    this.pixBuffer = {}
    for i = 1, (256*4*4) do
        this.pixBuffer[i] = 0
    end

    -- Set priority to run before other weather mods.
    local mod_priority = 1000
    event.register(tes3.event.loaded, onLoaded, { priority = mod_priority })
    event.register(tes3.event.cellChanged, onCellChanged, { priority = mod_priority })
    event.register(tes3.event.weatherChangedImmediate, onWeatherSwitch, { priority = mod_priority })
    event.register(tes3.event.keyDown, toggle)

    mwse.log("[Преобразователь погоды] v%s успешно загружен.", verString)
end

mcm.configId = configId
mcm.config = config
event.register(tes3.event.modConfigReady, mcm.registerModConfig)
event.register(tes3.event.initialized, init)
