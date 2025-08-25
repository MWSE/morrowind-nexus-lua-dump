local util = require('openmw.util')
local storage = require('openmw.storage')
local playerSection = storage.playerSection('SettingsPlayerHUDMarkers')
local types = require('openmw.types')
local core = require('openmw.core')
local v2 = require('openmw.util').vector2
local I = require("openmw.interfaces")
local MODNAME = "HUDMarkers"
local async = require('openmw.async')
local vfs = require('openmw.vfs')

settings = {
    key = "SettingsPlayer"..MODNAME,
    page = MODNAME,
    l10n = MODNAME,
    name = MODNAME,
	description = "",
    permanentStorage = true,
    settings = {
		--{
		--	key = "RANGE_MULT",
		--	name = "Range multiplier",
		--	description = "",
		--	min = 1,
		--	default = 2.5, 
		--	renderer = "number",
		--},
		--{
		--	key = "DETECT_SPELLS",
		--	name = "DETECT_SPELLS",
		--	description = "",
		--	default = true, 
		--	renderer = "checkbox",
		--},
		{
			key = "DETECT_CREATURE_MULT",
			name = "Detect Creature Range Mult",
			description = "0=disable",
			default = 2,
			renderer = "number",
		},
		{
			key = "DETECT_KEY_MULT",
			name = "Detect Key/Door Range Mult",
			description = "0=disable",
			default = 2.1,
			renderer = "number",
		},
		{
			key = "DETECT_ITEM_MULT",
			name = "Detect Item Range Mult",
			description = "0=disable",
			default = 2,
			renderer = "number",
		},
		{
			key = "DETECT_HERB_MULT2",
			name = "Detect Herb Range Mult",
			description = "0=disable",
			default = 2,
			renderer = "number",
		},
		{
			key = "DETECT_INGREDIENT_MULT2",
			name = "Detect Ingredient Range Mult",
			description = "0=disable",
			default = 2,
			renderer = "number",
		},
		{
			key = "DETECT_ORE_MULT",
			name = "Detect Ore veins Range Mult",
			description = "0=disable",
			default = 2.5,
			renderer = "number",
		},
		{
			key = "DETECT_ACTOR_LOOT",
			name = "Detect actor loot without detect creature",
			description = "Detect actor loot without detect creature",
			default = false, 
			renderer = "checkbox",
		},
		{
			key = "SHOW_UNENCHANTED_ITEMS2",
			name = "Show Unenchanted Items",
			description = "",
			default = "none", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "LocalizationContext", 
				items = {"none", "filter clutter", "all"},
			},
		},
		{
			key = "SHOW_HERBS",
			name = "Show Herbs",
			description = "When using detect enchantments",
			default = false, 
			renderer = "checkbox",
		},
		{
			key = "SHOW_INGREDIENTS",
			name = "Show Ingredients",
			description = "in containers or actors",
			default = false, 
			renderer = "checkbox",
		},
		{
			key = "SHOW_KEYS",
			name = "Show Keys",
			description = "When using detect key",
			default = true, 
			renderer = "checkbox",
		},
		{
			key = "SHOW_DOORS",
			name = "Show Doors",
			description = "When using detect key",
			default = true, 
			renderer = "checkbox",
		},
		{
			key = "DETECT_ACTOR_TARGETS",
			name = "Detect Creature Targets",
			description = "",
			default = "even mechanical", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "LocalizationContext", 
				items = {"only humanoids", "only creatures", "also daedra", "also humanoids", "also undead", "even mechanical"},
			},
		},
		{
			key = "HEART_ICON",
			name = "Heart icon style",
			description = "if using the standard icon set",
			default = "Standard", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "LocalizationContext", 
				items = {"Standard", "Alternative", "Alternative 2"},
			},
		},
		{
			key = "ICON_SET",
			name = "Icon Set",
			description = "Daedric Set by Voeille",
			default = "Standard", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "LocalizationContext", 
				items = {"Standard", "Daedric", "Legacy"},
			},
		},
		{
			key = "SCALE",
			name = "SCALE",
			description = "SCALE",
			default = 0.95, 
			renderer = "number",
		},
		{
			key = "ORE_COLORS",
			name = "Ore colors",
			description = "Distinguishable ore icons",
			default = true, 
			renderer = "checkbox",
		},
	}
}


local updateSettings = function (_,setting)
	ICON_SET = playerSection:get("ICON_SET")
	if playerSection:get("HEART_ICON") == "Alternative 2" and vfs.fileExists("HUDM_Textures/"..ICON_SET.."/heart3.dds") then
		HEART_ICON = "HUDM_Textures/"..ICON_SET.."/heart3.dds"
	elseif playerSection:get("HEART_ICON") == "Alternative" and vfs.fileExists("HUDM_Textures/"..ICON_SET.."/heart2.dds") then
		HEART_ICON = "HUDM_Textures/"..ICON_SET.."/heart2.dds"	
	else
		HEART_ICON = "HUDM_Textures/"..ICON_SET.."/heart.dds"	
	end
	HEART_DEAD_ICON = "HUDM_Textures/"..ICON_SET.."/heart_dead.dds"	
	ITEM_PURPLE_ICON = "HUDM_Textures/"..ICON_SET.."/item_purple.dds"
	ITEM_ICON = "HUDM_Textures/"..ICON_SET.."/item.dds"
	MECHANICAL_ICON = "HUDM_Textures/"..ICON_SET.."/mechanical.dds"
	MECHANICAL_BROKEN_ICON = "HUDM_Textures/"..ICON_SET.."/mechanical_broken.dds"
	UNDEAD_ICON = "HUDM_Textures/"..ICON_SET.."/undead.dds"
	UNDEAD_DEAD_ICON = "HUDM_Textures/"..ICON_SET.."/undead_dead.dds"
	KEY_ICON = "HUDM_Textures/"..ICON_SET.."/key.dds"
	DOOR_ICON = "HUDM_Textures/"..ICON_SET.."/door.dds"
	DOOR_VISITED_ICON = "HUDM_Textures/"..ICON_SET.."/door_visited.dds"
	HERB_ICON = "HUDM_Textures/"..ICON_SET.."/herb.dds"
	CONTAINER_ICON = "HUDM_Textures/"..ICON_SET.."/container.dds"
	INDEX_ICON = "HUDM_Textures/"..ICON_SET.."/propylon_index.dds"
	ORE_ICON = "HUDM_Textures/"..ICON_SET.."/ore.dds"
	
	SHOW_UNENCHANTED_ITEMS = playerSection:get("SHOW_UNENCHANTED_ITEMS2")
	SHOW_KEYS = playerSection:get("SHOW_KEYS")
	
	detectKeyCache = 9999999999999999
	detectActorCache = 9999999999999999
	detectItemCache = 9999999999999999
end


I.Settings.registerGroup(settings)


I.Settings.registerPage {
    key =  MODNAME,
    l10n = MODNAME,
    name = MODNAME,
    description = 'QuestHelper'
}


playerSection:subscribe(async:callback(updateSettings))