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
			default = false
		},
		{
			key = "ShotgunHarvest2",
			name = "ShotgunHarvest 2",
			description = "another barrage of raycasts (12) with a bigger radius",
			renderer = "checkbox",
			default = false
		},
		{
			key = "ShotgunReturn",
			name = "Shotgun First Hit",
			description = "Stop casting rays after the first harvestable plant was found (no effect when using HoldHarvest)",
			renderer = "checkbox",
			default = true
		},
		{
			key = "CollectItems",
			name = "CollectItems",
			description = "",
			renderer = "checkbox",
			default = true
		},
		{
			key = "CollectContainers",
			name = "CollectContainers",
			description = "Requires Quickloot 1.42",
			renderer = "checkbox",
			default = true
		},
		{
			key = "CollectCorpses",
			name = "CollectCorpses",
			description = "Requires Quickloot 1.42",
			renderer = "checkbox",
			default = false
		},
		{
			key = "ContainerDelay",
			name = "ContainerDelay",
			description = "The delay between looting items from a container using quickloot",
			renderer = "number",
			default = 0.12,
			argument = {
				min = 0,
				max = 1000000,
			},
		},
		{
			key = "OrganicExtraRange",
			name = "OrganicExtraRange",
			description = "Does not affect items",
			renderer = "number",
			default = 30,
			argument = {
				min = 0,
				max = 1000,
			},
		},
	}
		
}




local function updateSettings()
	COLLECT_ITEMS = playerSection:get("CollectItems")
	COLLECT_CONTAINERS = playerSection:get("CollectContainers")
	COLLECT_CORPSES = playerSection:get("CollectCorpses")
	ORGANIC_EXTRA_RANGE = playerSection:get("OrganicExtraRange")
	CONTAINER_DELAY = playerSection:get("ContainerDelay")
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