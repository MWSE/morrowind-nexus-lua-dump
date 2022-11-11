local previousFiremothPreset

-- World controller does not exist at this point, so we need hardcoded values
local weathers = {
    ["Clear"] = "Data Files\\Textures\\tx_sky_clear.tga",
    ["Cloudy"] = "Data Files\\Textures\\tx_sky_cloudy.tga",
    ["Foggy"] = "Data Files\\Textures\\tx_sky_foggy.tga",
    ["Overcast"] = "Data Files\\Textures\\tx_sky_overcast.tga",
    ["Rain"] = "Data Files\\Textures\\tx_sky_rainy.tga",
    ["Thunderstorm"] = "Data Files\\Textures\\tx_sky_thunder.tga",
    ["Ashstorm"] = "Data Files\\Textures\\tx_sky_ashstorm.tga",
    ["Blight"] = "Data Files\\Textures\\tx_sky_blight.tga",
    ["Snow"] = "Data Files\\Textures\\tx_bm_sky_snow.tga",
    ["Blizzard"] = "Data Files\\Textures\\tx_mb_sky_blizzard.tga"
}

-- That's what we're injecting into WA preset
local FIREMOTH_COLORS = {
    ["sunDayColor"] = {0,0,0},
    ["skySunsetColor"] = {0,0.15999999642372,0.11999999731779},
    ["fogSunsetColor"] = {0,0.17499999701977,0.15500000119209},
    ["fogDayColor"] = {0,0.17499999701977,0.15500000119209},
    ["skyNightColor"] = {0,0.15999999642372,0.11999999731779},
    ["fogSunriseColor"] = {0,0.17499999701977,0.15500000119209},
    ["ambientSunsetColor"] = {0.070000000298023,0.17000000178814,0.090000003576279},
    ["skyDayColor"] = {0,0.15999999642372,0.11999999731779},
    ["ambientDayColor"] = {0.070000000298023,0.17000000178814,0.090000003576279},
    ["sunNightColor"] = {0,0,0},
    ["ambientNightColor"] = {0.070000000298023,0.17000000178814,0.090000003576279},
    ["sunSunsetColor"] = {0,0,0},
    ["sundiscSunsetColor"] = {0,0,0},
    ["sunSunriseColor"] = {0,0,0},
    ["ambientSunriseColor"] = {0.070000000298023,0.17000000178814,0.090000003576279},
    ["fogNightColor"] = {0,0.17499999701977,0.15500000119209},
    ["skySunriseColor"] = {0,0.15999999642372,0.11999999731779}
}
local FIREMOTH_OUTSCATTER = {0.005,0.005,0.005}
local FIREMOTH_INSCATTER = {0.005,0.005,0.005}

local function overridePreset()
    local preset = mwse.loadConfig("Weather Adjuster")
    previousFiremothPreset = preset.regions["Firemoth Region"]
    mwse.saveConfig("Weather Adjuster_backup", preset)
    if preset then
        preset.presets["CC_Firemoth"] = {}
        for name, tex in pairs(weathers) do
            preset.presets["CC_Firemoth"][name] = FIREMOTH_COLORS
            preset.presets["CC_Firemoth"][name]["cloudTexture"] = tex
        end
        preset.presets["CC_Firemoth"].outscatter = FIREMOTH_OUTSCATTER
        preset.presets["CC_Firemoth"].inscatter = FIREMOTH_INSCATTER
        preset.regions["Firemoth Region"] = "CC_Firemoth"
        mwse.saveConfig("Weather Adjuster", preset)
    end
end

local function restorePreset()
    local preset = mwse.loadConfig("Weather Adjuster")
    if previousFiremothPreset then
        preset.regions["Firemoth Region"] = previousFiremothPreset
    end
    if preset then
        mwse.saveConfig("Weather Adjuster", preset)
    end
end

local function rebindExitButton(e)
	-- Try to find the options menu exit button.
	local exitButton = e.element:findChild(tes3ui.registerID("MenuOptions_Exit_container"))
	if (exitButton == nil) then return end

	-- Set our new event handler.
	exitButton:registerAfter("mouseClick", restorePreset)
end
event.register("uiCreated", rebindExitButton, { filter = "MenuOptions" })


overridePreset()