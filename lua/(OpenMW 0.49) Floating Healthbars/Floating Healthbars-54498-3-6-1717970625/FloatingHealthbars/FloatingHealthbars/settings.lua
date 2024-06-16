local util = require('openmw.util')
local storage = require('openmw.storage')
local playerSettings = storage.playerSection('SettingsPlayerHPBars')
local types = require('openmw.types')
local core = require('openmw.core')
local v2 = require('openmw.util').vector2
local I = require("openmw.interfaces")

settings = {
    key = "SettingsPlayerHPBars",
    page = "HPBars",
    l10n = "HPBars",
    name = "HPBars",
	description = "",
    permanentStorage = true,
    settings = {
		--{
        --    key = "TESTKEY",
        --    renderer = "textKey",
        --    name = "Toggle",
        --    default = input.getKeyName(KEY.Minus) .. " Key",
        --    argument = { keyName = "asd" },
        --},
		{
			key = "ROW1",
			name = "Row 1 Widget",
			description = "The HP Bars consist of 4 rows, select what's displayed on the first",
			default = "nothing", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "LocalizationContext", 
				items = {"nothing", "Actor Name", "HP", "HP/MaxHP", "Buffs"},
			},
		},
		{
			key = "ROW2",
			name = "Row 2 Widget",
			description = "",
			default = "nothing", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "LocalizationContext", 
				items = {"nothing", "Actor Name", "HP", "HP/MaxHP", "Buffs"},
			},
		},
		{
			key = "ROW3",
			name = "Row 3 Text (on bar)",
			description = "Can only be text",
			default = "HP/MaxHP", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "LocalizationContext", 
				items = {"nothing", "Actor Name", "HP", "HP/MaxHP"},
			},
		},
		{
			key = "ROW4",
			name = "Row 4 Widget",
			description = "",
			default = "Buffs", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "LocalizationContext", 
				items = {"nothing", "Actor Name", "HP", "HP/MaxHP", "Buffs"},
			},
		},
		{
			key = "RESOURCES",
			name = "Resources",
			description = "Fatigue + Magicka",
			default = "nothing", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "LocalizationContext", 
				items = {"nothing", "Fatigue", "Magicka", "Fatigue + Magicka"},
			},
		},
		{
			key = "OWN_BAR",
			renderer = "checkbox",
			name = "Own bar",
			description = "Show your own healthbar (in 3rd person)",
			default = false,
		},
		{
			key = "ONLY_IN_COMBAT",
			name = "Only Render Bars For Actors In Combat",
			description = "Only shows bars for actors with a weapon or spell readied (works for creatures too)",
			default = true, 
			renderer = "checkbox",
		},
		{
			key = "ALWAYS_CHECK_BUFFS",
			name = "Always show spell targets",
			description = "Always show bars for actors that have active magic effects from you",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "MAX_DISTANCE",
			name = "Max Distance",
			description = "Disables HP bars for actors that are further away than this",
			min = 100,
			default = 1500, 
			renderer = "number",
		},
		{
			key = "RAYTRACING",
			name = "Occlusion Detection",
			description = "Hide healthbars for actors that are behind objects",
			default = true, 
			renderer = "checkbox",
		},
		{
			key = "DAMAGED_ACTORS",
			name = "Damaged Actors",
			description = "Always show bars of actors that don't have full health",
			default = true, 
			renderer = "checkbox",
		},
		{
			key = "UNDER_CROSSHAIR",
			name = "Targeted Actor",
			description = "Always show bar of the actor under the crosshair",
			default = "off", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "LocalizationContext", 
				items = {"off", "Weapon readied", "always", "Weapon readied = everyone"},
			},
		},
		{
			key = "LAGBAR",
			renderer = "checkbox",
			name = "Damage-Bar",
			description = "Visualizes recently taken damage",
			default = true,
		},
		{
			key = "HEALBAR",
			renderer = "checkbox",
			name = "Enemy healbar",
			description = "Visualizes incoming enemy healing",
			default = true,
		},
		--{
		--	key = "HPTEXT",
		--	name = "HP Numbers",
		--	description = "Choose what text should be displayed on the bar",
		--	default = "HP/MaxHP", 
		--	renderer = "select",
		--	argument = {
		--		disabled = false,
		--		l10n = "LocalizationContext", 
		--		items = {"none", "HP", "HP/MaxHP"},
		--	},
		--},
		{
			key = "REQUIRED_HP",
			name = "Required level to see HP",
			description = "Relative to the actor's level",
			renderer = "number",
			default = -4,
			integer = true
		},
		{
			key = "HP_SIZE",
			name = "HP Text size",
			description = "Percentage of bar height, 0-1",
			renderer = "number",
			max = 1,
			min = 0.01,
			default = 0.73,
		},
		{
			key = "LEVEL",
			name = "Level number",
			description = "Level color and hide/show",
			default = "color-coded", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "LocalizationContext", 
				items = {"hidden", "white", "gray", "bar-color", "color-coded"},
			},
		},
		{
			key = "LEVEL_POSITION",
			name = "Level Position",
			description = "Right or left of the HP Bar if not hidden in the setting above",
			default = "left", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "LocalizationContext", 
				items = {"left", "right"},
			},
		},
		{
			key = "REQUIRED_LEVEL",
			name = "Required level to see level",
			description = "Relative to the actor's level",
			renderer = "number",
			default = -8,
			integer = true
		},
		{
			key = "hideLevelInsteadOfObscuring",
			name = "Hide Level Instead Of Obscuring",
			description = "If your level is too low, hides the actor's level instead of using the daedric font",
			renderer = "checkbox",
			default = false,
		},
		{
			key = "LEVELTEXT_SIZE",
			name = "Level Number size",
			description = "Percentage of bar height, 0-1",
			renderer = "number",
			max = 0.1,
			min = 1,
			default = 0.8,
		},
		{
			key = "FONT",
			name = "Font",
			description = "Global Addon Font",
			default = "Pelagiad", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "LocalizationContext", 
				items = {"Pelagiad", "MysticCards", "Daedra", "OpenSans", "Roboto", "BlackOps", "Asul"},
			},
		},
		{
			key = "TEXT_OFFSET",
			name = "Text offset",
			description = "Global text offset, 0-1",
			renderer = "number",
			max = 0.5,
			min = 0.01,
			default = 0.08,
		},
		{
			key = "NAME_SIZE",
			name = "Name size",
			description = "Percentage of bar height, 0-1",
			renderer = "number",
			max = 0.1,
			min = 1,
			default = 0.7,
		},
		{
			key = "NAME_COLOR",
			name = "Name Color",
			description = "Color of the Actor's name, if enabled",
			default = "reaction", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "LocalizationContext", 
				items = {"white", "gray", "reaction", "hidden in combat"},
			},
		},
		--{
		--	key = "HP_POSITION",
		--	name = "HP Text Position",
		--	description = "Small performance hit",
		--	renderer = "select",
		--	default = "on bar",
		--	argument = {
		--		disabled = false,
		--		l10n = "LocalizationContext", 
		--		items = {"on bar", "other side of buffs"},
		--	},
		--},
		--{
		--	key = "BUFFS",
		--	name = "Buffs & Debuffs",
		--	description = "Small performance hit",
		--	renderer = "select",
		--	default = "below", 
		--	argument = {
		--		disabled = false,
		--		l10n = "LocalizationContext", 
		--		items = {"hidden", "above", "below"},
		--	},
		--},
		{
			key = "BUFF_ICONSIZE",
			name = "Buff IconSize",
			description = "",
			renderer = "number",
			max = 0.1,
			min = 1,
			default = 1,
		},
		{
			key = "ANCHOR",
			name = "Bar anchor",
			description = "",
			default = "head", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "LocalizationContext", 
				items = {"feet", "head"},
			},
		},
		--{
		--	key = "ACTOR_NAME",
		--	name = "Actor Name",
		--	description = "Show the actor's name above or below the Nameplate where it fits\nSome options may have no effect depending on your other settings",
		--	default = "head", 
		--	renderer = "select",
		--	argument = {
		--		disabled = false,
		--		l10n = "LocalizationContext", 
		--		items = {"hidden", "higher","middle", "lower"},
		--	},
		--},
		{
			key = "OFFSET_X",
			name = "Offset X",
			description = "Moves the bars left or right",
			default = 0, 
			renderer = "number",
		},
		{
			key = "OFFSET_Y",
			name = "Offset Y",
			description = "Moves the bars up or down",
			default = -15, 
			renderer = "number",
		},
		{
			key = "LERPSPEED",
			name = "Animation Speed",
			description = "How fast the bars are animated, for example on physical damage taken",
			default = 128,
			min = 1,
			renderer = "number",
		},
		{
			key = "LAGDURATION",
			name = "Damage Taken Visualizer Duration",
			description = "For how long the damage bar will indicate recently taken damage",
			default = 0.7, 
			min = 0.1,
			renderer = "number",
		},
		{
			key = "SCALE",
			name = "HP Bars Scale",
			description = "Multiplier on the final bar scale (after distance scaling)",
			default = 0.9,
			min = 0.1,
			renderer = "number",
		},
		
		{
			key = "THICKNESS",
			name = "HP Bars Thickness",
			description = "Multiplier on the bar thichness",
			default = 0.999,
			min = 0.1,
			renderer = "number",
		},
		{
			key = "BORDER_STYLE",
			name = "Border style",
			description = "Max performance disables the transparency changing of the borders (which is in 0.1 steps), but then the bars will look less natural in the distance",
			default = "thin", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "LocalizationContext", 
				items = {"none", "max performance", "thin", "normal", "thick", "verythick"}--,"stylized 1", "stylized 2", "stylized 3", "stylized 4"},
			},
		},
		{
			key = "BORDER_COLOR",
			name = "Color Borders",
			description = "Colors the borders based on ..",
			default = "default", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "LocalizationContext", 
				items = {"default", "relative level", "reaction"}--,"stylized 1", "stylized 2", "stylized 3", "stylized 4"},
			},
		},
		{
			key = "COLOR_PRESET",
			name = "Color Preset",
			description = "Feel free to share cool color combinations in the comments",
			default = "Y/T/B/R/G  ", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "LocalizationContext", 
				items = {"Y/T/B/R/G  ", "O/T/B/R/G  ", "R/T/B/W/G ", "O/Y2/B/W/G","O/Y/B/R/G  ","O/B/R/G    "},
			},
		},
		{
			key = "HOSTILE_COL",
			name = "Hostile HP Bar Color",
			description = "Health color for actors that are attacking you.",
			disabled = false,
			--default = util.color.hex("9a5e3a"), --tan (unused)
			--default =  util.color.hex("c5a15e"), --paper
			--default =  util.color.hex("b55500"), --orange
			default =  util.color.hex("a00004"),
			--default =  util.color.hex("a00004"), --red
			renderer = "color",
		},
		{
			key = "HOSTILE_DAMAGED_COL",
			name = "Hostile+Damaged HP Bar Color",
			description = "Health color at 0 HP for actors that are attacking you.",
			disabled = false,
			--default = util.color.hex("9a5e3a"), --tan (unused)
			--default =  util.color.hex("c5a15e"), --paper
			--default =  util.color.hex("b55500"), --orange
			default =  util.color.hex("300004"), --yellow
			--default =  util.color.hex("a00004"), --red
			renderer = "color",
		},
		{
			key = "NEUTRAL_COL",
			name = "Neutral HP Bar Color",
			description = "Health color for normal actors",
			disabled = false,
			--default = util.color.hex("9a5e3a"), --tan (unused)
			--default =  util.color.hex("c5a15e"), --paper
			--default =  util.color.hex("b55500"), --orange
			default =  util.color.hex("ccbb00"), --yellow
			--default =  util.color.hex("a00004"), --red
			renderer = "color",
		},
		{
			key = "NEUTRAL_DAMAGED_COL",
			name = "Neutral+Damaged HP Bar Color",
			description = "Health color at 0 HP for normal actors.",
			disabled = false,
			--default = util.color.hex("9a5e3a"), --tan (unused)
			--default =  util.color.hex("c5a15e"), --paper
			--default =  util.color.hex("b55500"), --orange
			default =  util.color.hex("a00004"), --yellow
			--default =  util.color.hex("a00004"), --red
			renderer = "color",
		},
		{
			key = "ALLY_COL",
			name = "Allied HP Bar Color",
			description = "Allied Health color",
			disabled = false,
			default =  util.color.hex("1263b0"), --blue
			--default =  util.color.hex("999999"), --gray-white
			--default =  util.color.hex("ccbb00"), --yellow
			renderer = "color",
		},
		{
			key = "ALLY_DAMAGED_COL",
			name = "Allied+Damaged HP Bar Color",
			description = "Health color at 0 HP for allied actors.",
			disabled = false,
			default =  util.color.hex("1263b0"), --blue
			--default =  util.color.hex("999999"), --gray-white
			--default =  util.color.hex("ccbb00"), --yellow
			renderer = "color",
		},
		{
			key = "DAMAGE_COL",
			name = "Damage Color",
			description = "'Lag-Bar' color",
			disabled = false,
			default =  util.color.hex("a00004"), --red
			--default =  util.color.hex("a00004"), --red
			--default =  util.color.hex("b7b7b7"), --white
			renderer = "color",
		},
		{
			key = "HEAL_COL",
			name = "Healing Color",
			description = "Color of incoming healing",
			disabled = false,
			default = util.color.hex("3ca01e"), --green
			renderer = "color",
		},
		{
			key = "FATIGUE_COL",
			name = "Fatigue Color",
			description = "Color of the fatigue bar, if enabled",
			disabled = false,
			default = util.color.hex("cccc00"), --yellow
			renderer = "color",
		},
		{
			key = "MAGICKA_COL",
			name = "Magicka Color",
			description = "Color of the magicka bar, if enabled",
			disabled = false,
			default = util.color.hex("0011ee"), --green
			renderer = "color",
		},

	}
}


local previousSettings = {
	ROW1 = playerSettings:get("ROW1"),
	ROW2 = playerSettings:get("ROW2"),
	ROW3 = playerSettings:get("ROW3"),
	ROW4 = playerSettings:get("ROW4"),
}


local function verifyRows (changedSetting, option, backwards)
print(backwards)
	local currentSetting = option or playerSettings:get(changedSetting)
	if currentSetting == "nothing" then
		return currentSetting
	end
	local options = {"nothing", "Actor Name", "HP", "HP/MaxHP", "Buffs"}
	local occupiedSettings = {}
	for i=1,4 do
		if "ROW"..i ~= changedSetting then
			occupiedSettings[playerSettings:get("ROW"..i)] = true
		end
	end
	if occupiedSettings["HP"] or occupiedSettings["HP/MaxHP"] then 
		occupiedSettings["HP/MaxHP"] = true
		occupiedSettings["HP"] = true
	end
	local nextSetting = currentSetting
	local infiniteLoop = 0
	while nextSetting == nil or occupiedSettings[nextSetting] and nextSetting ~= "nothing" do
		nextSetting = nextValue(options, nextSetting, backwards)
		print(nextSetting)
		if changedSetting == "ROW3" and nextSetting == "Buffs" then
			nextSetting = nextValue(options, nextSetting, backwards)
		end
		infiniteLoop = infiniteLoop +1
		if infiniteLoop > 7 then
			return "nothing"
		end
	end
	return nextSetting
end




local function applyRows ()
	NAME = nil
	HP = nil
	HP_MAXHP = nil
	BUFFS = nil
	local borderOffset = playerSettings:get("BORDER_STYLE") == "verythick" and 4 or playerSettings:get("BORDER_STYLE") == "thick" and 3 or playerSettings:get("BORDER_STYLE") == "normal" and 2 or (playerSettings:get("BORDER_STYLE") == "thin" or playerSettings:get("BORDER_STYLE") == "max performance") and 1 or 0
	HPBARS = {
		relativePosition = v2(0.25,0.5+ playerSettings:get("THICKNESS")*0.25),
		position = v2(borderOffset, -borderOffset),
		size = v2(-borderOffset*2,1), -- !! at least 1 pixel width
		anchor = v2(0,1),
	}
	local resourcesHeight = playerSettings:get("RESOURCES") == "Stamina + Mana" and 4 or 2
	RESOURCES = {
		relativePosition = v2(0.25,0.5+ playerSettings:get("THICKNESS")*0.25),
		relativeSize = v2(0.5,playerSettings:get("THICKNESS")*0.25),
		--position = v2(0,math.min(resourcesHeight,borderOffset)),
		position = v2(borderOffset, -borderOffset),
		size = v2(-borderOffset*2,-borderOffset*2),
		anchor = v2(0,1),
	}
	BORDERS = {
		relativePosition = v2(0.25,0.5+ playerSettings:get("THICKNESS")*0.25),
		relativeSize  = v2(0.5,playerSettings:get("THICKNESS")*0.25),
		size = v2(0,borderOffset*2+1), --playerSettings:get("BORDER_STYLE") == "verythick" and v2(8,8) or playerSettings:get("BORDER_STYLE") == "thick" and v2(6,6) or playerSettings:get("BORDER_STYLE") == "normal" and v2(4,4) or (playerSettings:get("BORDER_STYLE") == "thin" or playerSettings:get("BORDER_STYLE") == "max performance")and v2(2,2) or v2(0,0),
		anchor = v2(0,1),
	}
	LEVELTEXT = {
		position = v2(0,-borderOffset),
		relativePosition = v2(playerSettings:get("LEVEL_POSITION") == "left" and 0.24 or 0.77, 0.5 + playerSettings:get("THICKNESS")*0.125),
	}
	--local options = {"nothing", "Actor Name", "HP", "HP/MaxHP", "Buffs"}
	local dublicates = {}
	local ROWS = {
		ROW1 = playerSettings:get("ROW1"),
		ROW2 = playerSettings:get("ROW2"),
		ROW3 = playerSettings:get("ROW3"),
		ROW4 = playerSettings:get("ROW4"),
	}
	
	local ROWSETTINGS = {
		ROW1 = {
			relativePosition = v2(0.5, 0.125+ 0),
			position = v2(0,0),
			anchor = v2(0,0),
		},
		ROW2 = {
			relativePosition = v2(0.5, 0.125+ 0.250),
			position = v2(0,0),
			anchor = v2(0,0),
		},
		ROW3 = {
			relativePosition = v2(0.5,0.5+ playerSettings:get("THICKNESS")*0.125),
			position = v2(0,-borderOffset),
			anchor = v2(0,0.5),
		},
		ROW4 = {
			relativePosition = v2(0.5, 0.125+ 0.5+0.25*playerSettings:get("THICKNESS")),
			position = v2(0,borderOffset),
			anchor = v2(0,0),
		},
	}
	local BUFFSETTINGS = {
		ROW1 = {
			relativePosition = v2(0.5, 0),
			position = v2(0,0),
			anchor = v2(0.5,0),
		},
		ROW2 = {
			relativePosition = v2(0.5, 0.5),
			position = v2(0,0),
			anchor = v2(0.5,1),
			BUFFANCHOR = "bottom",
		},
		ROW4 = {
			relativePosition = v2(0.5, 0.25*playerSettings:get("THICKNESS")+ 0.5),
			anchor = v2(0.5,0),
		},
	}
	
	if ROWS.ROW2 == "Buffs" then --buffs above
		--borderOffset = borderOffset *-1
		BORDERS = {
			relativeSize  = v2(0.5,playerSettings:get("THICKNESS")*0.25),
			relativePosition= v2(0.25,0.5),
			size = v2(0,borderOffset*2+1),
		}
		HPBARS = {
			relativePosition = v2(0.25,0.5),
			anchor = v2(0,0),
			position = v2(borderOffset, borderOffset),
			size = v2(-borderOffset*2,1),
		}
		
		RESOURCES.anchor = v2(0,0)
		RESOURCES.relativePosition = v2(0.25,0.5)
								-- 	 v2(0.25,0.5+ playerSettings:get("THICKNESS")*0.25),
		RESOURCES.position = v2(borderOffset, borderOffset)
		RESOURCES.size = v2(-borderOffset*2,1)
		ROWSETTINGS.ROW2.relativePosition = v2(0.5,0.5)
		ROWSETTINGS.ROW2.position = v2(0,0)
		ROWSETTINGS.ROW2.anchor = v2(0,1)
		
		ROWSETTINGS.ROW3.position = v2(0,borderOffset)
		LEVELTEXT = {
			position = v2(0,borderOffset),
			relativePosition = v2(playerSettings:get("LEVEL_POSITION") == "left" and 0.24 or 0.77, 0.5 + playerSettings:get("THICKNESS")*0.125), --same
		}
	end
	
	for a,b in pairs (ROWS) do
		local s = b
		if s == "HP/MaxHP" then
			s = "HP"
		end
		if dublicates[s] then
			--table.insert(queueSettingsChange,{a,"nothing"})
			--return
		end
		dublicates[s] = true
		if b == "Actor Name" then
			NAME = {relativePosition = ROWSETTINGS[a].relativePosition, position = ROWSETTINGS[a].position}
		elseif b == "HP" then
			HP = {relativePosition = ROWSETTINGS[a].relativePosition, position = ROWSETTINGS[a].position}
		elseif b == "HP/MaxHP" then
			HP_MAXHP = {relativePosition = ROWSETTINGS[a].relativePosition, position = ROWSETTINGS[a].position}
		elseif b == "Buffs" then
			BUFFS = BUFFSETTINGS[a]
		end
	end
end


local updateSettings = function (_,setting)
	--if #queueSettingsChange > 0 then
	--	return
	--end
	--items = {"Y/T/B/R/G  ", "O/T/B/R/G  ", "R/T/B/W/G ", "O/Y2/B/W/G","O/Y/B/R/G  ","O/B/R/G    "},
	--"R/T/B/W/G", "O/Y2/B/W/G"
	if setting=="COLOR_PRESET" then
		if playerSettings:get("COLOR_PRESET") == "Y/T/B/R/G  " then
			table.insert(queueSettingsChange,{"HOSTILE_COL",util.color.rgb(204/255,187/255,0)})
			table.insert(queueSettingsChange,{"HOSTILE_DAMAGED_COL",util.color.rgb(204/255,42/255,0)})
			table.insert(queueSettingsChange,{"NEUTRAL_COL",util.color.hex("c5a15e")})
			table.insert(queueSettingsChange,{"NEUTRAL_DAMAGED_COL",util.color.hex("9a5e3a")})
			table.insert(queueSettingsChange,{"ALLY_COL",util.color.hex("1263b0")})
			table.insert(queueSettingsChange,{"ALLY_DAMAGED_COL",util.color.hex("4c6188")})
			table.insert(queueSettingsChange,{"DAMAGE_COL",util.color.hex("a00004")})
			table.insert(queueSettingsChange,{"HEAL_COL",util.color.hex("3ca01e")})
		elseif playerSettings:get("COLOR_PRESET") == "O/T/B/R/G  " then
			table.insert(queueSettingsChange,{"HOSTILE_COL",util.color.hex("b55500")})
			table.insert(queueSettingsChange,{"HOSTILE_DAMAGED_COL",util.color.hex("bb2100")})
			table.insert(queueSettingsChange,{"NEUTRAL_COL",util.color.hex("c5a15e")})
			table.insert(queueSettingsChange,{"NEUTRAL_DAMAGED_COL",util.color.hex("9a5e3a")})--
			table.insert(queueSettingsChange,{"ALLY_COL",util.color.hex("1263b0")})
			table.insert(queueSettingsChange,{"ALLY_DAMAGED_COL",util.color.hex("4c6188")})
			table.insert(queueSettingsChange,{"DAMAGE_COL",util.color.hex("a00004")})
			table.insert(queueSettingsChange,{"HEAL_COL",util.color.hex("3ca01e")})
		elseif playerSettings:get("COLOR_PRESET") == "R/T/B/W/G " then
			table.insert(queueSettingsChange,{"HOSTILE_COL",util.color.hex("a00004")})
			table.insert(queueSettingsChange,{"HOSTILE_DAMAGED_COL",util.color.hex("600004")})
			table.insert(queueSettingsChange,{"NEUTRAL_COL",util.color.hex("c5a15e")})
			table.insert(queueSettingsChange,{"NEUTRAL_DAMAGED_COL",util.color.hex("9a5e3a")})
			table.insert(queueSettingsChange,{"ALLY_COL",util.color.hex("1263b0")})
			table.insert(queueSettingsChange,{"ALLY_DAMAGED_COL",util.color.hex("4c6188")})
			table.insert(queueSettingsChange,{"DAMAGE_COL",util.color.hex("AAAAAA")})
			table.insert(queueSettingsChange,{"HEAL_COL",util.color.hex("3ca01e")})
		elseif playerSettings:get("COLOR_PRESET") == "O/Y2/B/W/G" then
			table.insert(queueSettingsChange,{"HOSTILE_COL",util.color.hex("b55500")})
			table.insert(queueSettingsChange,{"HOSTILE_DAMAGED_COL",util.color.hex("a00004")})
			table.insert(queueSettingsChange,{"NEUTRAL_COL",util.color.hex("ccbb00")})
			table.insert(queueSettingsChange,{"NEUTRAL_DAMAGED_COL",util.color.hex("ccbb00")})
			table.insert(queueSettingsChange,{"ALLY_COL",util.color.hex("1263b0")})
			table.insert(queueSettingsChange,{"ALLY_DAMAGED_COL",util.color.hex("4c6188")})
			table.insert(queueSettingsChange,{"DAMAGE_COL",util.color.hex("FFFFFF")})
			table.insert(queueSettingsChange,{"HEAL_COL",util.color.hex("3ca01e")})
		elseif playerSettings:get("COLOR_PRESET") == "O/Y/B/R/G  " then
			table.insert(queueSettingsChange,{"HOSTILE_COL",util.color.hex("b55500")})
			--table.insert(queueSettingsChange,{"HOSTILE_DAMAGED_COL",util.color.hex("996542")})
			table.insert(queueSettingsChange,{"HOSTILE_DAMAGED_COL",util.color.hex("9a5517")})
			table.insert(queueSettingsChange,{"NEUTRAL_COL",util.color.hex("ccbb00")})
			--table.insert(queueSettingsChange,{"NEUTRAL_DAMAGED_COL",util.color.hex("c7ba73")})
			table.insert(queueSettingsChange,{"NEUTRAL_DAMAGED_COL",util.color.hex("ada11a")})
			
			table.insert(queueSettingsChange,{"ALLY_COL",util.color.hex("1263b0")})
			table.insert(queueSettingsChange,{"ALLY_DAMAGED_COL",util.color.hex("4c6188")})

			table.insert(queueSettingsChange,{"DAMAGE_COL",util.color.hex("a00004")})
			table.insert(queueSettingsChange,{"HEAL_COL",util.color.hex("3ca01e")})
			
		elseif playerSettings:get("COLOR_PRESET") == "O/B/R/G    " then
			table.insert(queueSettingsChange,{"HOSTILE_COL",util.color.rgb(204/255,187/255,0)})
			table.insert(queueSettingsChange,{"NEUTRAL_COL",util.color.rgb(204/255,187/255,0)})
			table.insert(queueSettingsChange,{"HOSTILE_DAMAGED_COL",util.color.rgb(204/255,42/255,0)})
			table.insert(queueSettingsChange,{"NEUTRAL_DAMAGED_COL",util.color.rgb(204/255,42/255,0)})
			
			table.insert(queueSettingsChange,{"ALLY_COL",		 util.color.rgb(18/255,99/255,176/255)})
			table.insert(queueSettingsChange,{"ALLY_DAMAGED_COL",util.color.rgb(173/255,99/255,100/255)})

			
			table.insert(queueSettingsChange,{"DAMAGE_COL",util.color.hex("a00004")})
			table.insert(queueSettingsChange,{"HEAL_COL",util.color.hex("3ca01e")})
			
			
			--	HPBAR_COL = util.color.rgb(204/255,(42+145*currentHealth/maxHealth)/255,0/255)
			--	ALLY_HPBAR_COL = util.color.rgb((18+155*(1-currentHealth/maxHealth))/255,99/255,(100+76*currentHealth/maxHealth)/255)
			----default =  util.color.hex("1263b0"), --blue
			----default =  util.color.hex("999999"), --gray-white
			----default =  util.color.hex("ccbb00"), --yellow
			----default = util.color.hex("9a5e3a"), --tan (unused)
			----default =  util.color.hex("c5a15e"), --paper
			----default =  util.color.hex("b55500"), --orange
			----default =  util.color.hex("a00004"), --red
		end
	elseif setting == "FONT" then
		glyphs,lineHeight = readFont("textures\\fonts\\"..playerSettings:get("FONT")..".fnt")
		lineXOffset = 0.0
	elseif setting:sub(1,-2) == "ROW" then
		local options = {"nothing", "Actor Name", "HP", "HP/MaxHP", "Buffs"}
		local newSettingIndex = tableFind(options, playerSettings:get(setting))
		local oldSettingIndex = tableFind(options, previousSettings[setting])
		print(oldSettingIndex," -> ",newSettingIndex)
		local backwards =false
		if newSettingIndex < oldSettingIndex and oldSettingIndex - newSettingIndex <2 or newSettingIndex - oldSettingIndex > 2 then
			backwards = true
		end
		--print(playerSettings:get(setting))
		--print(backwards)
		print("validate:")
		local validSetting = verifyRows (setting, nil, backwards) 
		--print(validSetting)
		if validSetting ~= playerSettings:get(setting) then
			table.insert(queueSettingsChange,{setting,validSetting})
			
		end
		previousSettings = {
			ROW1 = playerSettings:get("ROW1"),
			ROW2 = playerSettings:get("ROW2"),
			ROW3 = playerSettings:get("ROW3"),
			ROW4 = playerSettings:get("ROW4"),
		}
		--previousSettings[
	end
	
	for a,c in pairs(barCache) do
		if c.bar then
			c.bar:destroy()
		end
		c.bar = nil
		c.cachedHealth = types.Actor.stats.dynamic.health(c.actor).current
		c.cachedLerpHealth = c.lerpHealth
		c.allyCache = nil
		c.cachedHealthLag = c.healthLag
		c.cachedIncomingHealing = 0
		c.cachedBorderAlpha = 0.5
		c.textVisible = true
		c.lastBuffUpdate = core.getRealTime()
		c.hasBuffs = true
	end
	applyRows ()
end


I.Settings.registerGroup(settings)


I.Settings.registerPage {
    key = "HPBars",
    l10n = "HPBars",
    name = 'HPBars',
    description = 'Floating Healthbars'
}



return {updateSettings,applyRows}