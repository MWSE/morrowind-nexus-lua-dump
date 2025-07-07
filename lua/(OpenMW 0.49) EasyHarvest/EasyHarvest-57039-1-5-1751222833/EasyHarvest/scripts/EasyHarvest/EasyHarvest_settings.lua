local function getColorFromGameSettings(colorTag)
    local result = core.getGMST(colorTag)
	if not result then
		return util.color.rgb(1,1,1)
	end
    local rgb = {}
    for color in string.gmatch(result, '(%d+)') do
        table.insert(rgb, tonumber(color))
    end
    if #rgb ~= 3 then
        print("UNEXPECTED COLOR: rgb of size=", #rgb)
        return util.color.rgb(1, 1, 1)
    end
    return util.color.rgb(rgb[1] / 255, rgb[2] / 255, rgb[3] / 255)
end

settings = {
    key = 'SettingsPlayer'..MODNAME,
    page = MODNAME,
    l10n = "EasyHarvest",
    name = "EasyHarvest",
	description = "",
    permanentStorage = true,
    settings = {
		--{
		--	key = "DISPOSE_CORPSE",
		--	name = "Dispose corpse Key",
		--	description = "",
		--	default = "Shift + F", 
		--	renderer = "select",
		--	argument = {
		--		disabled = false,
		--		l10n = "LocalizationContext", 
		--		items = {"disabled", "Shift + F", "Jump"}--,"stylized 1", "stylized 2", "stylized 3", "stylized 4"},
		--	},
		--},
		--{
		--	key = "TRANSPARENCY",
		--	name = "Transparency",
		--	description = "",
		--	renderer = "number",
		--	default = 0.4,
		--	argument = {
		--		min = 0,
		--		max = 1,
		--	},
		--},
		{
			key = "HoldHarvest",
			name = "HoldHarvest",
			description = "",
			renderer = "checkbox",
			default = true
		},
		{
			key = "ShotgunHarvest1",
			name = "ShotgunHarvest 1",
			description = "a barrage of raycasts (8)",
			renderer = "checkbox",
			default = true
		},
		{
			key = "ShotgunHarvest2",
			name = "ShotgunHarvest 2",
			description = "another barrage of raycasts (12) with a bigger radius",
			renderer = "checkbox",
			default = true
		},
		{
			key = "ShotgunReturn",
			name = "Shotgun First Hit",
			description = "Stop casting rays after the first harvestable plant was found",
			renderer = "checkbox",
			default = true
		},
	}
		
}




local function updateSettings()

end


I.Settings.registerGroup(settings)


I.Settings.registerPage {
    key = MODNAME,
    l10n = "EasyHarvest",
    name = "EasyHarvest",
    description = "asd"
}


playerSection:subscribe(async:callback(updateSettings))
return true