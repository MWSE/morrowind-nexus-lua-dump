local async = require('openmw.async')
local core = require('openmw.core')
local input = require('openmw.input')
local self = require('openmw.self')
local storage = require('openmw.storage')
local types = require('openmw.types')
local ui = require('openmw.ui')
local v2 = require('openmw.util').vector2
local I = require("openmw.interfaces")

local MOD_NAME = "MBSP_Uncapper"

local Player = require('openmw.types').Player
local L = core.l10n(MOD_NAME)
local playerStorage = storage.playerSection("SettingsPlayer" .. MOD_NAME)
local dynamic = types.Actor.stats.dynamic

local storedMagicka = 0

local progressStatsMenu

I.Settings.registerRenderer(
	'MBSP_Uncapper_hotkey', function(value, set)
		return {
			template = I.MWUI.templates.textEditLine,
			props = {
				text = value and input.getKeyName(value) or '',
			},
			events = {
				keyPress = async:callback(function(e)
						set(e.code)
				end)
			}
		}
	end)

I.Settings.registerPage {
	key = MOD_NAME,
	l10n = MOD_NAME,
	name = "name",
	description = "description"
}

I.Settings.registerGroup {
	key = "SettingsPlayer" .. MOD_NAME,
	l10n = MOD_NAME,
	name = "settingsTitle",
	page = MOD_NAME,
	description = "settingsDesc",
	permanentStorage = true,
	settings = {
		{
			key = "uncapperEnabled",
			name = "Enable Uncapper",
			default = true,
			renderer = "checkbox",
			description = "uncapper_desc",
		},
		{
			key = "progressMenuKey",
			name = "Progress Menu Key",
			default = nil,
			renderer = "MBSP_Uncapper_hotkey",
			description = "progress_desc",
		},
		{
			key = "magickaXPRate",
			name = "Magicka XP Rate",
			default = '10',
			argument = {
				l10n = MOD_NAME,
				items = {'5', '10', '15', '20', '25'}
			},
			renderer = "select",
			description = "xprate_desc",
		},
		{
			key = "refundEnabled",
			name = "Enable Refund",
			default = true,
			renderer = "checkbox",
			description = "refund_desc",
		},
		{
			key = "refundMult",
			name = "Magicka Refund Multiplier",
			default = '4',
			argument = {
				l10n = MOD_NAME,
				items = {'1', '2', '3', '4', '5'}
			},
			renderer = "select",
			description = "refundMult_desc"
		},
		{
			key = "refundStart",
			default = 35,
			renderer = 'number',
			name = "Refund Skill Start",
			description = "refundStart_desc",
			argument = {
				integer = true,
				min = 1,
				max = 1000,
			},
		},
	}
}

--All Skills, sans Magic Skills
local skills = {
   'block',
   'armorer',
   'mediumarmor',
   'heavyarmor',
   'bluntweapon',
   'longblade',
   'axe',
   'spear',
   'athletics',
   'enchant',
   'alchemy',
   'unarmored',
   'security',
   'sneak',
   'acrobatics',
   'lightarmor',
   'shortblade',
   'marksman',
   'mercantile',
   'speechcraft',
   'handtohand',
}

local magicSkills = {
   'destruction',
   'restoration',
   'conjuration',
   'mysticism',
   'illusion',
   'alteration',
}

local skillNames = {
   block = 'Block',
   armorer = 'Armorer',
   mediumarmor = 'Medium Armor',
   heavyarmor = 'Heavy Armor',
   bluntweapon = 'Blunt Weapon',
   longblade = 'Long Blade',
   axe = 'Axe',
   spear = 'Spear',
   athletics = 'Athletics',
   enchant = 'Enchant',
   destruction = 'Destruction',
   illusion = 'Illusion',
   alteration = 'Alteration',
   restoration = 'Restoration',
   mysticism = 'Mysticism',
   conjuration = 'Conjuration',
   alchemy = 'Alchemy',
   unarmored = 'Unarmored',
   security = 'Security',
   sneak = 'Sneak',
   acrobatics = 'Acrobatics',
   lightarmor = 'Light Armor',
   shortblade = 'Short Blade',
   marksman = 'Marksman',
   mercantiile = 'Mercantile',
   speechcraft = 'Speechcraft',
   handtohand = 'Hand to Hand',
}

local skillProgress = {
	block = 0,
	armorer = 0,
	mediumarmor = 0,
	heavyarmor = 0,
	bluntweapon = 0,
	longblade = 0,
	axe = 0,
	spear = 0,
	athletics = 0,
	enchant = 0,
	destruction = 0,
	illusion = 0,
	alteration = 0,
	restoration = 0,
	mysticism = 0,
	conjuration = 0,
	alchemy = 0,
	unarmored = 0,
	security = 0,
	sneak = 0,
	acrobatics = 0,
	lightarmor = 0,
	shortblade = 0,
	marksman = 0,
	mercantile = 0,
	speechcraft = 0,
	handtohand = 0,
}

local deltaMTable = {}


local function modSkillLevel(skill, amnt)
    types.Player.stats.skills[skill](self).base = types.Player.stats.skills[skill](self).base + amnt
end

local function modMagicka(amnt)
    dynamic.magicka(self).current = dynamic.magicka(self).current + amnt
end

local function getRefund(skill, cost)
	local refund
	refund = playerStorage:get("refundMult") * cost * (math.sqrt(math.max((skill - playerStorage:get("refundStart")),0)) / 100)
	if refund > cost then refund = cost end
	return refund
end

local function findIndex(table, value)
    for i = 1, #table do
        if table[i] == value then return i end
    end
end

local function addDeltaMagicka(val)
	table.insert(deltaMTable, val)
end

local function removeDeltaMagicka(val)
	table.remove(deltaMTable,findIndex(deltaMTable,val))
end

local function getDeltaMagicka()
	if #deltaMTable > 0 then
		return math.max(unpack(deltaMTable),0)
	else 
		return 0
	end
end

-----------------------------UI STUFF-----------------------------

local function padding(horizontal, vertical)
	return { props = { size = v2(horizontal, vertical) } }
end

local function head(text)
    return {
        type = ui.TYPE.Text,
        template = I.MWUI.templates.textHeader,
        props = { text = text }
    }
end

local function text(str)
    return {
        type = ui.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = { text = str }
    }
end

local function centerWindow(content)
	return {
        layer = "Windows",
        template = I.MWUI.templates.boxTransparent,
        props = {
            relativePosition = v2(.5, .5),
            anchor = v2(.5, .5)
        },
        content = ui.content {content}
    }
end

local function menu(content, width, height)
    return centerWindow(
        {
            type = ui.TYPE.Flex,
            props = {
                position = v2(75, 0),
                size = v2(width, height)
            },
            content = ui.content(content)
        }
    )
end

local function row(key, value)
	return {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
        },
        content = ui.content {
            text(string.format("%s: ", key)),
            text(value)
        }
    }
end

local function displayProgressStatsMenu()
    local width, height = 475, 380
    local gap20 = padding(0, 20)
    local gap10 = padding(0, 10)

    local function skillPercent(skillProgVal)
        return string.format("%s%%", math.floor(skillProgVal * 100))
    end

    local leftBlock = {
        head("Skill Progress"),
        gap10,
        head("Warrior Skills"),
        row("Block", skillPercent(skillProgress["block"])),
        row("Armorer", skillPercent(skillProgress["armorer"])),
        row("Medium Armor", skillPercent(skillProgress["mediumarmor"])),
        row("Heavy Armor", skillPercent(skillProgress["heavyarmor"])),
        row("Blunt Weapon", skillPercent(skillProgress["bluntweapon"])),
        row("Long Blade", skillPercent(skillProgress["longblade"])),
        row("Axe", skillPercent(skillProgress["axe"])),
        row("Spear", skillPercent(skillProgress["spear"])),
        row("Athletics", skillPercent(skillProgress["athletics"])),
        gap10,
        head("Mage Skills"),
        row("Enchant", skillPercent(skillProgress["enchant"])),
        row("Destruction", skillPercent(skillProgress["destruction"])),
        row("Alteration", skillPercent(skillProgress["alteration"])),
        row("Illusion", skillPercent(skillProgress["illusion"])),
        row("Conjuration", skillPercent(skillProgress["conjuration"])),
        row("Mysticism", skillPercent(skillProgress["mysticism"])),
        row("Restoration", skillPercent(skillProgress["restoration"])),
        row("Alchemy", skillPercent(skillProgress["alchemy"])),
        row("Unarmored", skillPercent(skillProgress["unarmored"]))
    }

    local rightBlock = {
        gap20,
        padding(0, 6),
        head("Thief Skills"),
        row("Security", skillPercent(skillProgress["security"])),
        row("Sneak", skillPercent(skillProgress["sneak"])),
        row("Acrobatics", skillPercent(skillProgress["acrobatics"])),
        row("Light Armor", skillPercent(skillProgress["lightarmor"])),
        row("Short Blade", skillPercent(skillProgress["shortblade"])),
        row("Marksman", skillPercent(skillProgress["marksman"])),
        row("Mercantile", skillPercent(skillProgress["mercantile"])),
        row("Speechcraft", skillPercent(skillProgress["speechcraft"])),
        row("Hand To Hand", skillPercent(skillProgress["handtohand"])),
    }

    return {
        layer = "Windows",
        template = I.MWUI.templates.boxTransparent,
        props = {
            relativePosition = v2(.5, .5),
            anchor = v2(.5, .5)
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = {
                    position = v2(75, 20),
                    size = v2(width, height)
                },
                content = ui.content {
                    {
                        type = ui.TYPE.Flex,
                        props = {
                            horizontal = true,
                        },
                        content = ui.content {
                            {
                                type = ui.TYPE.Flex,
                                props = {
                                    position = v2(75, 0),
                                    size = v2(200, 200)
                                },
                                content = ui.content(leftBlock)
                            },
                            {
                                type = ui.TYPE.Flex,
                                props = {
                                    position = v2(75, 0),
                                    size = v2(200, 200)
                                },
                                content = ui.content(rightBlock)
                            }
                        }
                    }
                }
            }
        }
    }
end

----------------Engine Handlers--------------------


local function onUpdate(dt)
	
	--Stores all changes in magicka in the last 2 seconds
	if (storedMagicka - dynamic.magicka(self).current) > 1 then
		addDeltaMagicka(storedMagicka - dynamic.magicka(self).current)
		
		async:newSimulationTimer(
			2,
			async:registerTimerCallback(
				"addDeltaMagickaToList",
				function(val)
					removeDeltaMagicka(val)
				end
			),
			tempMagicka
		)
	end
	local deltaMagicka = getDeltaMagicka()
	
	--Non-Magicka Skills
	if playerStorage:get("uncapperEnabled") then
		for _, skill in ipairs(skills) do
			if types.Player.stats.skills[skill](self).base > 99 then
				local dif = types.Player.stats.skills[skill](self).progress
				if dif > 0.01 then
					skillProgress[skill] = skillProgress[skill] + dif
					if skillProgress[skill] >= 1 then
						modSkillLevel(skill, 1)
						skillProgress[skill] = 0
						ui.showMessage('Your ' .. skillNames[skill] .. ' skill increased to ' .. types.Player.stats.skills[skill](self).base .. '.')
					end
					types.Player.stats.skills[skill](self).progress = 0
				end
			end
		end
	end
	
	--Magicka Skills
	for _, skill in ipairs(magicSkills) do
		if types.Player.stats.skills[skill](self).base > 99 then
			local dif = types.Player.stats.skills[skill](self).progress
			if dif > 0.001 then
				
				if playerStorage:get("uncapperEnabled") then
					skillProgress[skill] = skillProgress[skill] + (deltaMagicka / playerStorage:get("magickaXPRate")) * dif
					
					if skillProgress[skill] >= 1 then
						modSkillLevel(skill, 1)
						skillProgress[skill] = 0
						ui.showMessage('Your ' .. skillNames[skill] .. ' skill increased to ' .. types.Player.stats.skills[skill](self).base .. '.')
					end
					types.Player.stats.skills[skill](self).progress = 0
				end
				
				if playerStorage:get("refundEnabled") then
					modMagicka(getRefund(types.Player.stats.skills[skill](self).base, deltaMagicka))
					deltaMagicka = 0
				else
					deltaMagicka = 0
				end
			end
		else
			local dif = types.Player.stats.skills[skill](self).progress - skillProgress[skill]
			
			--If the skill has leveled up normally
			if dif < (-0.5) then 
				dif = types.Player.stats.skills[skill](self).progress
				skillProgress[skill] = 0
				if playerStorage:get("refundEnabled") then
					modMagicka(getRefund(types.Player.stats.skills[skill](self).base, deltaMagicka))
					deltaMagicka = 0
				else
					deltaMagicka = 0
				end
			end
			--If increase in skill progress is detected
			if dif > 0.001 then
				types.Player.stats.skills[skill](self).progress = types.Player.stats.skills[skill](self).progress + (deltaMagicka / playerStorage:get("magickaXPRate")) * dif - dif
				
				if types.Player.stats.skills[skill](self).progress >= 1 then
					modSkillLevel(skill, 1)
					skillProgress[skill] = 0
					types.Player.stats.skills[skill](self).progress = 0
					ui.showMessage('Your ' .. skillNames[skill] .. ' skill increased to ' .. types.Player.stats.skills[skill](self).base .. '.')
				end
				
				skillProgress[skill] = types.Player.stats.skills[skill](self).progress
				
				if playerStorage:get("refundEnabled") then
					modMagicka(getRefund(types.Player.stats.skills[skill](self).base, deltaMagicka))
					deltaMagicka = 0
				else
					deltaMagicka = 0
				end
			end
		end
	end
	
	storedMagicka = dynamic.magicka(self).current
end

local function onKeyPress(key)
    --Prevent the stats menu from rendering over the escape menu
    if key.code == input.KEY.Escape then
        if progressStatsMenu ~= nil then
            progressStatsMenu:destroy()
            progressStatsMenu = nil
        end
        return
    end

    if key.code == playerStorage:get("progressMenuKey") then
        local menu
        menu = displayProgressStatsMenu()

        if progressStatsMenu == nil then
            progressStatsMenu = ui.create(menu)
        else
            progressStatsMenu.layout = menu
            progressStatsMenu:update()
        end
	end
	
end

local function onKeyRelease(key)
    if key.code == playerStorage:get("progressMenuKey") then
        if progressStatsMenu ~= nil then
            progressStatsMenu:destroy()
            progressStatsMenu = nil
        end
    end
end

local function onLoad(data)
    skillProgress = data.skillProgress
	
	--Handle Loading Save Without Mod--
	
	--Normal Skills
	for _, skill in ipairs(skills) do
		--If below vanilla skill cap, update skill progress for use in calculations
		if types.Player.stats.skills[skill](self).base < 100 and types.Player.stats.skills[skill](self).progress > 0 then
			skillProgress[skill] = types.Player.stats.skills[skill](self).progress
		elseif types.Player.stats.skills[skill](self).base < 100 and (skillProgress[skill] - types.Player.stats.skills[skill](self).progress) > 0 then
			types.Player.stats.skills[skill](self).progress = skillProgress[skill]
			skillProgress[skill] = 0
		--If at or above vanilla skill cap, get current progress, then override
		elseif types.Player.stats.skills[skill](self).base > 99 and types.Player.stats.skills[skill](self).progress > 0 then
			skillProgress[skill] = types.Player.stats.skills[skill](self).progress
			types.Player.stats.skills[skill](self).progress = 0
		end
	end
	
	--Magicka Skills
	for _, skill in ipairs(magicSkills) do
		--If below vanilla skill cap, update skill progress for use in calculations
		if types.Player.stats.skills[skill](self).base < 100 and types.Player.stats.skills[skill](self).progress > 0 then
			skillProgress[skill] = types.Player.stats.skills[skill](self).progress
		elseif types.Player.stats.skills[skill](self).base < 100 and (skillProgress[skill] - types.Player.stats.skills[skill](self).progress) > 0 then
			types.Player.stats.skills[skill](self).progress = skillProgress[skill]
		--If at or above vanilla skill cap, get current progress, then override
		elseif types.Player.stats.skills[skill](self).base > 99 and types.Player.stats.skills[skill](self).progress > 0 then
			skillProgress[skill] = types.Player.stats.skills[skill](self).progress
			types.Player.stats.skills[skill](self).progress = 0
		end
	end
end

local function onSave()
    return {
        skillProgress = skillProgress,
    }
end

return {
	engineHandlers = {
		onKeyPress = onKeyPress,
		onKeyRelease = onKeyRelease,
		onUpdate = onUpdate,
		onLoad = onLoad,
        onSave = onSave,
	}
}
