local ui = require('openmw.ui')
local I = require("openmw.interfaces")
local util = require("openmw.util")
local input = require('openmw.input')
local async = require('openmw.async')
local types = require("openmw.types")
local self = require('openmw.self')
local v2 = require('openmw.util').vector2
local auxUi = require('openmw_aux.ui')
local Player = require('openmw.types').Player
local ambient = require('openmw.ambient')
local storage = require('openmw.storage')

I.Settings.registerPage {
    key = 'AlternativeLevelingPage',
    l10n = 'AlternativeLeveling',
    name = 'name',
    description = "description",
}
I.Settings.registerGroup {
    key = 'SettingsALMod',
    page = 'AlternativeLevelingPage',
    l10n = 'AlternativeLeveling',
    name = "skillpointsTitle",
    description = "skillPointsDescription",
    permanentStorage = false,
    settings = {
        {
            key = 'MajorMinorSkillPoints',
            renderer = 'number',
			argument = {
				integer = true,
				min = 0,
			},
            name = 'MajorMinorSkillPointsName',
            description = 'MajorMinorSkillPointsDescription',
            default = 10,
        },
		{
            key = 'MiscSkillPoints',
            renderer = 'number',
			argument = {
				integer = true,
				min = 0,
			},
            name = 'MiscSkillPointsName',
            description = 'MiscSkillPointsDescription',
            default = 5,
        },
		{
            key = 'AttributeSkillPoints',
            renderer = 'number',
			argument = {
				integer = true,
				min = 0,
			},
            name = 'AttributeSkillPointsName',
            description = 'AttributeSkillPointsDescription',
            default = 7,
        },
		{
            key = 'LevelOffset',
            renderer = 'checkbox',
			argument = {
				l10n = 'AlternativeLeveling',
				trueLabel = 'yes',
				falseLabel = 'no',
			},
            name = 'LevelOffsetName',
            description = 'LevelOffsetDescription',
            default = true,
        },
		{
            key = 'retroactiveEndurance',
            renderer = 'checkbox',
			argument = {
				l10n = 'AlternativeLeveling',
				trueLabel = 'yes',
				falseLabel = 'no',
			},
            name = 'retroactiveEnduranceName',
            description = 'retroactiveEnduranceDescription',
            default = false,
        },
    },
}

local playerSettings = storage.playerSection('SettingsALMod')

local playerSkillsMap = {
	["acrobatics"] = types.NPC.stats.skills.acrobatics(self),
	["alchemy"] = types.NPC.stats.skills.alchemy(self),
	["alteration"] = types.NPC.stats.skills.alteration(self),
	["armorer"] = types.NPC.stats.skills.armorer(self),
	["athletics"] = types.NPC.stats.skills.athletics(self),
	["axe"] = types.NPC.stats.skills.axe(self),
	["block"] = types.NPC.stats.skills.block(self),
	["bluntweapon"] = types.NPC.stats.skills.bluntweapon(self),
	["conjuration"] = types.NPC.stats.skills.conjuration(self),
	["destruction"] = types.NPC.stats.skills.destruction(self),
	["enchant"] = types.NPC.stats.skills.enchant(self),
	["handtohand"] = types.NPC.stats.skills.handtohand(self),
	["heavyarmor"] = types.NPC.stats.skills.heavyarmor(self),
	["lightarmor"] = types.NPC.stats.skills.lightarmor(self),
	["illusion"] = types.NPC.stats.skills.illusion(self),
	["longblade"] = types.NPC.stats.skills.longblade(self),
	["marksman"] = types.NPC.stats.skills.marksman(self),
	["mediumarmor"] = types.NPC.stats.skills.mediumarmor(self),
	["mercantile"] = types.NPC.stats.skills.mercantile(self),
	["mysticism"] = types.NPC.stats.skills.mysticism(self),
	["restoration"] = types.NPC.stats.skills.restoration(self),
	["security"] = types.NPC.stats.skills.security(self),
	["shortblade"] = types.NPC.stats.skills.shortblade(self),
	["sneak"] = types.NPC.stats.skills.sneak(self),
	["spear"] = types.NPC.stats.skills.spear(self),
	["speechcraft"] =types.NPC.stats.skills.speechcraft(self),
	["unarmored"] = types.NPC.stats.skills.unarmored(self),
}

local playerAttributeMap = {
	["strength"] = types.Actor.stats.attributes.strength(self),
	["intelligence"] = types.Actor.stats.attributes.intelligence(self),
	["willpower"] = types.Actor.stats.attributes.willpower(self),
	["agility"] = types.Actor.stats.attributes.agility(self),
	["speed"] = types.Actor.stats.attributes.speed(self),
	["endurance"] = types.Actor.stats.attributes.endurance(self),
	["personality"] = types.Actor.stats.attributes.personality(self),
	["luck"] = types.Actor.stats.attributes.luck(self),
}

local allSkills = {
	"acrobatics",	"alchemy",	"alteration",	"armorer",	"athletics",	"axe",	"block",	"bluntweapon",
	"conjuration",	"destruction",	"enchant",	"handtohand",	"heavyarmor",	"lightarmor",	"illusion",
	"longblade",	"marksman",	"mediumarmor",	"mercantile",	"mysticism",	"restoration",	"security",
	"shortblade",	"sneak",	"spear",	"speechcraft",	"unarmored"
}

local orderedAttributeIds = { "strength", "intelligence", "willpower", "agility", "speed", "endurance", "personality", "luck" }

local skillXpPenaltiesInit = {
	["acrobatics"] = 0,
	["alchemy"] = 0,
	["alteration"] = 0,
	["armorer"] = 0,
	["athletics"] = 0,
	["axe"] = 0,
	["block"] = 0,
	["bluntweapon"] = 0,
	["conjuration"] = 0,
	["destruction"] = 0,
	["enchant"] = 0,
	["handtohand"] = 0,
	["heavyarmor"] = 0,
	["lightarmor"] = 0,
	["illusion"] = 0,
	["longblade"] = 0,
	["marksman"] = 0,
	["mediumarmor"] = 0,
	["mercantile"] = 0,
	["mysticism"] = 0,
	["restoration"] = 0,
	["security"] = 0,
	["shortblade"] = 0,
	["sneak"] = 0,
	["spear"] = 0,
	["speechcraft"] = 0,
	["unarmored"] = 0,
}

local skillXpPenaltiesCurrent

local majorMinorSkillPoints
local miscSkillPoints
local attributeSkillPoints

local majorMinorSkillDeductions 
local miscSkillDeductions
local attributeSkillDeductions

local startingHealth

local function onSave()
	return {
		majMinSkillPoints = majorMinorSkillDeductions,
		mSkillPoints = miscSkillDeductions,
		atbSkillPoints = attributeSkillDeductions,
		skillXpPenalties = skillXpPenaltiesCurrent, 
		startHealth = startingHealth,
	}
end

local function onInit()
	majorMinorSkillDeductions = 0
	miscSkillDeductions = 0
	attributeSkillDeductions = 0
	skillXpPenaltiesCurrent = skillXpPenaltiesInit
end

local function onLoad(data)
	majorMinorSkillDeductions = data.majMinSkillPoints
	miscSkillDeductions = data.mSkillPoints
	attributeSkillDeductions = data.atbSkillPoints
	skillXpPenaltiesCurrent = data.skillXpPenalties
	startingHealth = data.startHealth
end


local levelupMenu

-- Helpers

-- Arrays

local function indexOf(value, array)
    for i = 1, #array do
        if array[i] == value then
            return i
        end
    end
end

local function isInArray(value, array)
    for _, otherValue in ipairs(array) do
        if otherValue == value then
            return true
        end
    end
    return false
end

local function insertMultipleInArray(sourceArray, array)
    for _, value in ipairs(array) do
        table.insert(sourceArray, value)
    end
end

local function insertAtMultipleInArray(sourceArray, pos, array)
    for i, value in ipairs(array) do
        table.insert(sourceArray, pos + i - 1, value)
    end
end

local function capitalize(s)
    -- THANKS: https://stackoverflow.com/a/2421843
    return s:sub(1, 1):upper() .. s:sub(2)
end

local skillsMapV48 = {
    ["mediumarmor"] = "Medium Armor",
    ["heavyarmor"] = "Heavy Armor",
    ["bluntweapon"] = "Blunt Weapon",
    ["longblade"] = "Long Blade",
    ["lightarmor"] = "Light Armor",
    ["shortblade"] = "Short Blade",
    ["handtohand"] = "Hand To Hand",
}

local function getStatName(statId)
	local statName = capitalize(statId)
	if skillsMapV48[statId] ~= nil then
		statName = skillsMapV48[statId]
	end
	return statName
end


--UI

local boxTemplate = I.MWUI.templates.boxTransparentThick

local function centerWindow(content)
    return {
        layer = "Windows",
        template = boxTemplate,
		type = ui.TYPE.Container,
        props = {
            relativePosition = v2(.5, .5),
            anchor = v2(.5, .5),
			autosize = true
        },
        content = ui.content { content }
    }
end

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

local function text(str, extraProps)
    local props = { text = str,}
    if extraProps then
        for k, v in pairs(extraProps) do
            props[k] = v
        end
    end
    return {
        type = ui.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = props,
    }
end

local function createButtonTextContent(buttonText,buttonSize) 
	return {
	
	type = ui.TYPE.Text,
	template = I.MWUI.templates.textNormal,
	props = {
		text = buttonText,
		visible = true,
		size = buttonSize,
		--anchor = util.vector2(0, 0), 
		textAlignH = ui.ALIGNMENT.End,
		textAlignV = ui.ALIGNMENT.End,
	}
}
end

local function createButton(clickCallback,buttonText,buttonPos,buttonSize) 

	local buttonTextWidget = createButtonTextContent(buttonText,buttonSize)
	return {

	userData = {
		isFocused = false,
		textColorOver = util.color.rgb(242 / 255, 205 / 255, 136 / 255),
		textColorIdle = I.MWUI.templates.textNormal.props.textColor,
		textColorPressed = util.color.rgb(101 / 255, 82 / 255, 48 / 255),
		textWidget = buttonTextWidget,
		onPressed = clickCallback,
	},

	type = ui.TYPE.Container,
	props = {
		relativePosition = buttonPos,
		size = buttonSize,
		anchor = util.vector2(0.5, 0.5),
		visible = true,
	},
	template = I.MWUI.templates.boxSolid, 
	content = ui.content({
		buttonTextWidget,
		{ type = ui.TYPE.Image,
			props = {
				alpha = 0.0,
				size = buttonSize,
				visible = true,
				anchor = util.vector2(0.5, 0.5),
			},
		},
		
	}),
	events = {
		mousePress = async:callback(function(e, thisObject)

			thisObject.userData.textWidget.props.textColor = thisObject.userData.textColorPressed
		end),
		mouseRelease = async:callback(function(e, thisObject)

			thisObject.userData.textWidget.props.textColor = thisObject.userData.textColorOver
			thisObject.userData.onPressed(e,thisObject)
			ambient.playSound("Menu Click")
		end),
		focusGain = async:callback(function(e, thisObject)

			thisObject.userData.textWidget.props.textColor = thisObject.userData.textColorOver
			end),
		focusLoss = async:callback(function(e, thisObject)

			thisObject.userData.textWidget.props.textColor = thisObject.userData.textColorIdle
			end),
	},
}
end



local function createSkillRow(skillName,InUIWindow,inType)

	if inType == "attribute" then
		skillStarting = playerAttributeMap[skillName].base
	else
		skillStarting = playerSkillsMap[skillName].base
	end

	local skillRowWidget = {
		type = ui.TYPE.Flex,
		layer = "Windows",
		userData = {
			newSkillIncrease = 0,
			skillBase = skillStarting,
			skillId = skillName,
			callbacks = {
				skillAddCallback = function (e, thisObject)
					thisObject.userData.parentWidget.userData.newSkillIncrease = thisObject.userData.parentWidget.userData.newSkillIncrease + 1
					thisObject.userData.parentWidget.userData.valueWidget.props.text = tostring(thisObject.userData.parentWidget.userData.skillBase + thisObject.userData.parentWidget.userData.newSkillIncrease)
					if thisObject.userData.parentWidget.userData.skillType == "major" or thisObject.userData.parentWidget.userData.skillType == "minor" then
						thisObject.userData.parentWidget.userData.uiWindowWidget.userData.majorMinorPoints = thisObject.userData.parentWidget.userData.uiWindowWidget.userData.majorMinorPoints - 1
						thisObject.userData.parentWidget.userData.uiWindowWidget.userData.callbacks.refreshSkillPointWidget(thisObject.userData.parentWidget.userData.uiWindowWidget)
					elseif thisObject.userData.parentWidget.userData.skillType == "misc" then
						thisObject.userData.parentWidget.userData.uiWindowWidget.userData.miscPoints = thisObject.userData.parentWidget.userData.uiWindowWidget.userData.miscPoints - 1
						thisObject.userData.parentWidget.userData.uiWindowWidget.userData.callbacks.refreshSkillPointWidget(thisObject.userData.parentWidget.userData.uiWindowWidget)
					else
						thisObject.userData.parentWidget.userData.uiWindowWidget.userData.attributePoints = thisObject.userData.parentWidget.userData.uiWindowWidget.userData.attributePoints - 1
						thisObject.userData.parentWidget.userData.uiWindowWidget.userData.callbacks.refreshSkillPointWidget(thisObject.userData.parentWidget.userData.uiWindowWidget)
					end
				end,
				skillMinusCallback = function (e, thisObject)
					thisObject.userData.parentWidget.userData.newSkillIncrease = thisObject.userData.parentWidget.userData.newSkillIncrease - 1
					thisObject.userData.parentWidget.userData.valueWidget.props.text = tostring(thisObject.userData.parentWidget.userData.skillBase + thisObject.userData.parentWidget.userData.newSkillIncrease)
					if thisObject.userData.parentWidget.userData.skillType == "major" or thisObject.userData.parentWidget.userData.skillType == "minor" then
						thisObject.userData.parentWidget.userData.uiWindowWidget.userData.majorMinorPoints = thisObject.userData.parentWidget.userData.uiWindowWidget.userData.majorMinorPoints + 1
						thisObject.userData.parentWidget.userData.uiWindowWidget.userData.callbacks.refreshSkillPointWidget(thisObject.userData.parentWidget.userData.uiWindowWidget)
					elseif thisObject.userData.parentWidget.userData.skillType == "misc" then
						thisObject.userData.parentWidget.userData.uiWindowWidget.userData.miscPoints = thisObject.userData.parentWidget.userData.uiWindowWidget.userData.miscPoints + 1
						thisObject.userData.parentWidget.userData.uiWindowWidget.userData.callbacks.refreshSkillPointWidget(thisObject.userData.parentWidget.userData.uiWindowWidget)
					else
						thisObject.userData.parentWidget.userData.uiWindowWidget.userData.attributePoints = thisObject.userData.parentWidget.userData.uiWindowWidget.userData.attributePoints + 1
						thisObject.userData.parentWidget.userData.uiWindowWidget.userData.callbacks.refreshSkillPointWidget(thisObject.userData.parentWidget.userData.uiWindowWidget)
					end
				end
			},
			skillType = inType,
			uiWindowWidget = InUIWindow
		},
		props =
		{
			horizontal = true,
			autosize = false,
			size = util.vector2(20, 20),
			anchor = util.vector2(0.5, 0.5),
			align = ui.ALIGNMENT.End,
			arrange = ui.ALIGNMENT.End,
		},
	}

	local skillValueWidget = text(tostring(skillRowWidget.userData.skillBase + skillRowWidget.userData.newSkillIncrease))

	skillRowWidget.userData.valueWidget = skillValueWidget

	local minusButton = createButton(skillRowWidget.userData.callbacks.skillMinusCallback,"-",util.vector2(0.8, 0.5),util.vector2(32, 7))
	local plusButton = createButton(skillRowWidget.userData.callbacks.skillAddCallback,"+",util.vector2(0, 0),util.vector2(32, 7))

	skillRowWidget.userData.minusButtonWidget = minusButton
	skillRowWidget.userData.plusButtonWidget = plusButton

	minusButton.userData.parentWidget = skillRowWidget
	plusButton.userData.parentWidget = skillRowWidget

	skillRowWidget.content = ui.content({
		minusButton,
		padding(5,0),
		skillValueWidget,
		padding(5,0),
		plusButton,
	})

	return skillRowWidget
end

local function createSkillsTable(skillsList,InUIWindow,inType)
	local skillsBox = {
		type = ui.TYPE.Flex,
		props = {
			horizontal = true,
			autosize = false,
			align = ui.ALIGNMENT.Start,
			arrange = ui.ALIGNMENT.Start,
		},
	}
	local nameContent = {padding(0,1)}
	local skillRowContent = {}
	
	if inType == "attribute" then
		for i, v in ipairs(skillsList) do
			table.insert(nameContent, text(capitalize(v)))
			table.insert(nameContent, padding(0,4))
			table.insert(skillRowContent,createSkillRow(v,InUIWindow,inType))
		end
	else
		for i, v in ipairs(skillsList) do
			table.insert(nameContent, text(getStatName(v)))
			table.insert(nameContent, padding(0,4))
			table.insert(skillRowContent,createSkillRow(v,InUIWindow,inType))
		end
	end

	skillsBox.userData = {
		skillRows = skillRowContent,
	}

	skillsBox.content = ui.content({
		padding(12,10),
		{
			type = ui.TYPE.Flex,
			props = {
				autosize = false,
				size = util.vector2(100, 20),
				align = ui.ALIGNMENT.Start,
				arrange = ui.ALIGNMENT.Start,
			},
			content = ui.content(nameContent),
		},
		padding(50,10),
		{
			type = ui.TYPE.Flex,
			props = {
				autosize = false,
				size = util.vector2(100, 20),
				align = ui.ALIGNMENT.End,
				arrange = ui.ALIGNMENT.End,
			},
			content = ui.content(skillRowContent),
		},

	})

	return skillsBox

end

local getMiscSkills = function ()
	local miscSkills = {}
	local majorMinorSkills = types.NPC.classes.record(types.NPC.record(self).class).majorSkills


	for i, v in ipairs(allSkills) do
		if isInArray(v,types.NPC.classes.record(types.NPC.record(self).class).minorSkills) or isInArray(v,types.NPC.classes.record(types.NPC.record(self).class).majorSkills) then
		else
			table.insert(miscSkills,v)
		end
	end

	return miscSkills
end

local function createSkillPointsBox()
	
	local majorMinorSkillPointsText = text(tostring(majorMinorSkillPoints))
	local miscSkillPointsText = text(tostring(miscSkillPoints))
	local attributeSkillPointsText = text(tostring(attributeSkillPoints))

	local horzBox = {
		type = ui.TYPE.Flex,
		userData = {
			majorMinorWidget = majorMinorSkillPointsText,
			miscWidget = miscSkillPointsText,
			attributeWidget = attributeSkillPointsText,
		},
		props = {
			horizontal = true,
			autosize = true,
			align = ui.ALIGNMENT.Start,
			arrange = ui.ALIGNMENT.Start,
		},
	}
	horzBox.content = ui.content({
		{
			type = ui.TYPE.Flex,
			props = {
				horizontal = false,
				autosize = false,
				align = ui.ALIGNMENT.Center,
				arrange = ui.ALIGNMENT.Center,
			},
		
			content = ui.content({
				text("Major / Minor Skills:"),
				padding(6,10),
				text("Misc Skills:"),
				padding(6,10),
				text("Attributes:"),
			})
		},
		padding(10,5),
		{
			type = ui.TYPE.Flex,
			props = {
				horizontal = false,
				autosize = false,
				align = ui.ALIGNMENT.Center,
				arrange = ui.ALIGNMENT.Center,
			},
		
			content = ui.content({
				horzBox.userData.majorMinorWidget,
				padding(6,10),
				horzBox.userData.miscWidget,
				padding(6,10),
				horzBox.userData.attributeWidget,
			})
		}
	})
	

	return horzBox
end

local function updateMaxStats(oldEndurance)
	local oldhealth = types.Actor.stats.dynamic.health(self).base
	local endurance = types.Actor.stats.attributes.endurance(self).base
	
	if (types.Actor.stats.level(self).current == 2) then
		startingHealth = types.Actor.stats.dynamic.health(self).base
	end

	if playerSettings:get("retroactiveEndurance") then
		if (startingHealth ~= 0 and startingHealth ~= nil) then
			local bonus = (endurance / 10) * (types.Actor.stats.level(self).current - 1)
			types.Actor.stats.dynamic.health(self).base = startingHealth + bonus
		else
			print("Could not find starting health value, character was not running script when leveling up for the first time, defaulting to vanilla behaviour")
			types.Actor.stats.dynamic.health(self).base = oldhealth + (endurance / 10)
		end
	else
		types.Actor.stats.dynamic.health(self).base = oldhealth + (endurance / 10)
	end
end

local closeLevelupMenu = function ()
	if (levelupMenu == nil) then
	else
		levelupMenu:destroy()
		levelupMenu = nil
	end
end

local confirmFnc = function (thisObject)
	print(tostring(thisObject.userData.parentWidget.userData.majorMinorPoints))
	print(tostring(thisObject.userData.parentWidget.userData.miscPoints))
	print(tostring(thisObject.userData.parentWidget.userData.attributePoints))
	if (thisObject.userData.parentWidget.userData.majorMinorPoints == 0) and (thisObject.userData.parentWidget.userData.miscPoints == 0) and (thisObject.userData.parentWidget.userData.attributePoints == 0) then
		
		local oldEndurance = 0

		for i, v in ipairs(thisObject.userData.parentWidget.userData.majorSkillsTable.userData.skillRows) do
			if v.userData.newSkillIncrease > 0 then
				local skillName = v.userData.skillId
				Player.stats.skills[skillName](self).base = v.userData.newSkillIncrease + v.userData.skillBase
				skillXpPenaltiesCurrent[skillName] = skillXpPenaltiesCurrent[skillName] - v.userData.newSkillIncrease * 2
				if skillXpPenaltiesCurrent[skillName] < 0 then
					skillXpPenaltiesCurrent[skillName] = 0
				end
			end
		end

		for i, v in ipairs(thisObject.userData.parentWidget.userData.minorSkillsTable.userData.skillRows) do
			if v.userData.newSkillIncrease > 0 then
				local skillName = v.userData.skillId
				Player.stats.skills[skillName](self).base = v.userData.newSkillIncrease + v.userData.skillBase
				skillXpPenaltiesCurrent[skillName] = skillXpPenaltiesCurrent[skillName] - v.userData.newSkillIncrease * 2
				if skillXpPenaltiesCurrent[skillName] < 0 then
					skillXpPenaltiesCurrent[skillName] = 0
				end
			end
		end

		for i, v in ipairs(thisObject.userData.parentWidget.userData.miscSkillsTable.userData.skillRows) do
			if v.userData.newSkillIncrease > 0 then
				local skillName = v.userData.skillId
				Player.stats.skills[skillName](self).base = v.userData.newSkillIncrease + v.userData.skillBase
			end
		end

		for i, v in ipairs(thisObject.userData.parentWidget.userData.attributesTable.userData.skillRows) do
			if v.userData.newSkillIncrease > 0 then
				local skillName = v.userData.skillId
				types.Actor.stats.attributes[skillName](self).base = v.userData.newSkillIncrease + v.userData.skillBase
				if (skillName == "endurance") then
					oldEndurance = v.userData.skillBase
				end
			end
		end

		types.Actor.stats.level(self).progress = 0
		types.Actor.stats.level(self).current = types.Actor.stats.level(self).current + 1

		updateMaxStats(oldEndurance)

		majorMinorSkillDeductions = 0
		miscSkillDeductions = 0
		attributeSkillDeductions = 0

		I.UI.removeMode("LevelUp")

	else
		ui.showMessage("You must distribute all your points to continue.")
	end
	
end
	
local createLevelupScreenWidget = function ()
	
	local skillPointsBoxWidget = createSkillPointsBox()

	local uiWindowWidget = {
		type = ui.TYPE.Flex,
		props = {
			horizontal = true,
			autosize = true,
			align = ui.ALIGNMENT.Start,
			arrange = ui.ALIGNMENT.Start,
		},
		userData = {
			skillPointsWidget = skillPointsBoxWidget,
			callbacks = {
				refreshSkillPointWidget = function (thisObject)
					thisObject.userData.skillPointsWidget.userData.majorMinorWidget.props.text = tostring(thisObject.userData.majorMinorPoints)
					thisObject.userData.skillPointsWidget.userData.miscWidget.props.text = tostring(thisObject.userData.miscPoints)
					thisObject.userData.skillPointsWidget.userData.attributeWidget.props.text = tostring(thisObject.userData.attributePoints)
					
					for i, v in ipairs(thisObject.userData.majorSkillsTable.userData.skillRows) do
						if thisObject.userData.majorMinorPoints == 0 or v.userData.newSkillIncrease == 5 or v.userData.skillBase + v.userData.newSkillIncrease == 100 then
							v.userData.plusButtonWidget.props.visible = false
						else
							v.userData.plusButtonWidget.props.visible = true
						end
						if v.userData.newSkillIncrease == 0 then
							v.userData.minusButtonWidget.props.visible = false
						else
							v.userData.minusButtonWidget.props.visible = true
						end
					end

					for i, v in ipairs(thisObject.userData.minorSkillsTable.userData.skillRows) do
						if thisObject.userData.majorMinorPoints == 0 or v.userData.newSkillIncrease == 5 or v.userData.skillBase + v.userData.newSkillIncrease == 100 then
							v.userData.plusButtonWidget.props.visible = false
						else
							v.userData.plusButtonWidget.props.visible = true
						end
						if v.userData.newSkillIncrease == 0 then
							v.userData.minusButtonWidget.props.visible = false
						else
							v.userData.minusButtonWidget.props.visible = true
						end
					end

					for i, v in ipairs(thisObject.userData.miscSkillsTable.userData.skillRows) do
						if thisObject.userData.miscPoints == 0 or v.userData.newSkillIncrease == 5 or v.userData.skillBase + v.userData.newSkillIncrease == 100 then
							v.userData.plusButtonWidget.props.visible = false
						else
							v.userData.plusButtonWidget.props.visible = true
						end
						if v.userData.newSkillIncrease == 0 then
							v.userData.minusButtonWidget.props.visible = false
						else
							v.userData.minusButtonWidget.props.visible = true
						end
					end

					for i, v in ipairs(thisObject.userData.attributesTable.userData.skillRows) do
						if thisObject.userData.attributePoints == 0 or v.userData.newSkillIncrease == 5 or v.userData.skillBase + v.userData.newSkillIncrease == 100 then
							v.userData.plusButtonWidget.props.visible = false
						else
							v.userData.plusButtonWidget.props.visible = true
						end
						if v.userData.newSkillIncrease == 0 then
							v.userData.minusButtonWidget.props.visible = false
						else
							v.userData.minusButtonWidget.props.visible = true
						end
					end
						
				end,
				closeWindow = function (e, thisObject)
					confirmFnc(thisObject)
				end,
			},
			majorMinorPoints = majorMinorSkillPoints,
			miscPoints = miscSkillPoints,
			attributePoints = attributeSkillPoints,
		}
	}

	uiWindowWidget.userData.majorSkillsTable = createSkillsTable(types.NPC.classes.record(types.NPC.record(self).class).majorSkills,uiWindowWidget,"major")
	uiWindowWidget.userData.minorSkillsTable = createSkillsTable(types.NPC.classes.record(types.NPC.record(self).class).minorSkills,uiWindowWidget,"minor")
	uiWindowWidget.userData.miscSkillsTable = createSkillsTable(getMiscSkills(),uiWindowWidget,"misc")
	uiWindowWidget.userData.attributesTable = createSkillsTable(orderedAttributeIds,uiWindowWidget,"attribute")

	local confirmButton = createButton(uiWindowWidget.userData.callbacks.closeWindow,"Confirm",util.vector2(0, 0),util.vector2(32, 7))

	confirmButton.userData.parentWidget = uiWindowWidget

	uiWindowWidget.content = ui.content({
		{
			type = ui.TYPE.Flex,
			props = {
				horizontal = false,
				autosize = false,
				align = ui.ALIGNMENT.Center,
				arrange = ui.ALIGNMENT.Center,
			},
		
			content = ui.content({
				head("Major Skills"),
				padding(5,5),
				{template = I.MWUI.templates.horizontalLine},
				padding(5,5),
				uiWindowWidget.userData.majorSkillsTable,
				padding(5,5),
				head("Minor Skills"),
				padding(5,5),
				{template = I.MWUI.templates.horizontalLine},
				padding(5,5),
				uiWindowWidget.userData.minorSkillsTable,
				padding(5,5),
				{template = I.MWUI.templates.horizontalLine},
				padding(5,5),
				head("Skill Points"),
				padding(5,5),
				skillPointsBoxWidget

			}),
		},
		{
			type = ui.TYPE.Flex,
			props = {
				horizontal = false,
				autosize = true,
				align = ui.ALIGNMENT.Center,
				arrange = ui.ALIGNMENT.Center,
			},
			content = ui.content({
				head("Misc Skills"),
				padding(5,5),
				{template = I.MWUI.templates.horizontalLine},
				padding(5,5),
				uiWindowWidget.userData.miscSkillsTable,
				padding(5,5),
			}),
		},
		{
			type = ui.TYPE.Flex,
			props = {
				horizontal = false,
				autosize = true,
				align = ui.ALIGNMENT.Center,
				arrange = ui.ALIGNMENT.Center,
			},
			content = ui.content({
				head("Attributes"),
				padding(5,5),
				{template = I.MWUI.templates.horizontalLine},
				padding(5,5),
				uiWindowWidget.userData.attributesTable,
				padding(30,30),
				confirmButton
			})
		}
	})

	return uiWindowWidget
end

local onUpdateFrame = function (dt)
	if (levelupMenu == nil) then
	else
		levelupMenu:update()
	end
end

local showLevelupMenu = function ()
	if (levelupMenu == nil) then
		local levelupScreenWidget = createLevelupScreenWidget()
		levelupMenu = ui.create(centerWindow(levelupScreenWidget))
		levelupScreenWidget.userData.callbacks.refreshSkillPointWidget(levelupScreenWidget)
	end
end

local function calculateSkillpoints()
	majorMinorSkillPoints = playerSettings:get('MajorMinorSkillPoints') - majorMinorSkillDeductions
	miscSkillPoints = playerSettings:get('MiscSkillPoints') - miscSkillDeductions
	attributeSkillPoints = playerSettings:get('AttributeSkillPoints') -attributeSkillDeductions

	local majorMinorTotalSkill = 0
	for i, v in ipairs(types.NPC.classes.record(types.NPC.record(self).class).majorSkills) do
		majorMinorTotalSkill = majorMinorTotalSkill + Player.stats.skills[v](self).base
	end
	for i, v in ipairs(types.NPC.classes.record(types.NPC.record(self).class).minorSkills) do
		majorMinorTotalSkill = majorMinorTotalSkill + Player.stats.skills[v](self).base
	end
	if 1000 - majorMinorTotalSkill < majorMinorSkillPoints then
		majorMinorSkillPoints = 1000 - majorMinorTotalSkill
	end

	local miscTotalSkill = 0
	for i, v in ipairs(getMiscSkills()) do
		miscTotalSkill = miscTotalSkill + Player.stats.skills[v](self).base
	end
	if 1700 - miscTotalSkill < miscSkillPoints then
		miscSkillPoints = 1700 - miscTotalSkill
	end

	local attributeTotal = 0
	for i, v in ipairs(orderedAttributeIds) do
		attributeTotal = attributeTotal + types.Actor.stats.attributes[v](self).base
	end
	if 800 - attributeTotal < attributeSkillPoints then
		attributeSkillPoints = 800 - attributeTotal
	end

end

local function registerLevelUpMenu()
	I.UI.registerWindow(
		"LevelUpDialog",
		function ()
			calculateSkillpoints()
			ambient.streamMusic("Music/Special/MW_Triumph.mp3")
			showLevelupMenu()
		end,
		function ()
			closeLevelupMenu()
		end
	)
end


I.SkillProgression.addSkillUsedHandler(function(skillid, params)
	if  playerSettings:get("LevelOffset") then
			
		local skillGainOffset = -1* skillXpPenaltiesCurrent[skillid]^2 * 0.005
		if (skillGainOffset + 1) < 0.0 then
			skillGainOffset = 0.0
		end

		local oldSkillGain = params.skillGain

		params.skillGain = oldSkillGain * (skillGainOffset + 1)
	end
end)

I.SkillProgression.addSkillLevelUpHandler(function(skillid, source, options) 
	local isMajor = isInArray(skillid,types.NPC.classes.record(types.NPC.record(self).class).majorSkills)
	local isMinor = isInArray(skillid,types.NPC.classes.record(types.NPC.record(self).class).minorSkills)
	local isBook = false
	local isTrainer = false

	if source == I.SkillProgression.SKILL_INCREASE_SOURCES.Book then
		isBook = true
	end

	if source == I.SkillProgression.SKILL_INCREASE_SOURCES.Trainer then
		isTrainer = true
	end

	if isMajor or isMinor then
		
		if isBook or isTrainer then
			options.levelUpAttributeIncreaseValue = nil
			options.levelUpProgress = nil

			if isTrainer then
				types.Actor.stats.level(self).progress = types.Actor.stats.level(self).progress + 1
				majorMinorSkillDeductions = majorMinorSkillDeductions + 1
				if majorMinorSkillDeductions > (playerSettings:get('MajorMinorSkillPoints')) then
					majorMinorSkillPoints = playerSettings:get('MajorMinorSkillPoints')
				end
			end

			return true
		else
			types.Actor.stats.level(self).progress = types.Actor.stats.level(self).progress + 1
			skillXpPenaltiesCurrent[skillid] = skillXpPenaltiesCurrent[skillid] + 1
			ambient.playSound("skillraise")
			if (types.Actor.stats.level(self).progress >= 10) then
				ui.showMessage('You should rest and meditate on what you have learned.')
			else
				ui.showMessage('You have made progress towards your next level.')
			end
		end
	elseif isBook or isTrainer then
		options.levelUpAttributeIncreaseValue = nil
		return true
	end

	Player.stats.skills[skillid](self).progress = 0
	return false
end)

return {
    engineHandlers = {
		onActive = function ()
			registerLevelUpMenu()
		end,
		onFrame = function(dt)
			onUpdateFrame(dt)
		end,
		onSave = onSave,
        onLoad = onLoad,
		onInit = onInit,
    }
}