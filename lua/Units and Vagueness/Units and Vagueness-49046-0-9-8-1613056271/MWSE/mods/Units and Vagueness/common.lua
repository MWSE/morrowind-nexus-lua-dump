local common = {}

----------------------------------------------------------------------------------------------------
-- Generic helper functions.
----------------------------------------------------------------------------------------------------

-- Performs a test on one or more keys.
--[[function common.complexKeybindTest(keybind)
	local keybindType = type(keybind)
	local inputController = tes3.worldController.inputController
	if (keybindType == "number") then
		return inputController:isKeyDown(keybind)
	elseif (keybindType == "table") then
		for _, k in pairs(keybind) do
			if (not common.complexKeybindTest(k)) then
				return false
			end
		end
		return true
	elseif (keybindType == "string") then
		return inputController:keybindTest(tes3.keybind[keybind])
	end

	return false
end]]

-- Formats a float number to a string without trailing zeros after decimal point
function common.formatStripZeros(value)
	return string.format("%.2f", value):gsub("%.?0+$", "")
end

-- Performs a test on one or more keys.
function common.complexKeybindTest(keybind)
	local keybindType = type(keybind)
	local inputController = tes3.worldController.inputController
	if (keybindType == "number") then
		return inputController:isKeyDown(keybind)
	elseif (keybindType == "table") then
		for _, k in pairs(keybind) do
			if (not common.complexKeybindTest(k)) then
				return false
			end
		end
		return true
	elseif (keybindType == "string") then
		return inputController:keybindTest(tes3.keybind[keybind])
	end

	return false
end

-- Parses a color from either a table or a string.
function common.getColor(color)
	local colorType = type(color)
	if (colorType == "table" and #color == 3) then
		return color
	elseif (colorType == "string") then
		return tes3ui.getPalette(color)
	end
end

common.effectsWithAttributes = {
	[tes3.effect.absorbAttribute] = true,
	[tes3.effect.damageAttribute] = true,
	[tes3.effect.drainAttribute] = true,
	[tes3.effect.fortifyAttribute] = true,
	[tes3.effect.restoreAttribute] = true,
}

function common.getIngredientEffectAttributeId(ingredient, index)
	if (common.effectsWithAttributes[ingredient.effects[index]]) then
		return ingredient.effectAttributeIds[index]
	else
		return -1
	end
end

common.effectsWithSkills = {
	[tes3.effect.absorbSkill] = true,
	[tes3.effect.damageSkill] = true,
	[tes3.effect.drainSkill] = true,
	[tes3.effect.fortifySkill] = true,
	[tes3.effect.restoreSkill] = true,
}

function common.getIngredientEffectSkillId(ingredient, index)
	if (common.effectsWithSkills[ingredient.effects[index]]) then
		return ingredient.effectSkillIds[index]
	else
		return -1
	end
end

----------------------------------------------------------------------------------------------------
-- Expose function to (re)load translations.
----------------------------------------------------------------------------------------------------

-- copied from qqqbbbs Non-Clairvoyant-Nerevarine
local function GetLanguage()
	local file = io.open("Morrowind.ini","r");
	local lines = file:read("*all")

	if string.find(lines, 'Language=French', 1, true) then
		file:close();
		return 'fre';
	elseif string.find(lines, 'Language=German', 1, true) then
		file:close();
		return 'deu';
	end

	file:close();
	return 'eng';
end

function common.loadTranslation()
	-- Get the ISO language code.
	--local language = tes3.getLanguage()
	local language = GetLanguage()

	-- Load the dictionaries, and start off with English.
	local dictionaries = require("Units and Vagueness.translations")
	local dictionary = dictionaries["eng"]

	-- If we aren't doing English, copy over translated entries.
	if (language ~= "eng" and dictionaries[language]) then
		table.copy(dictionaries[language], dictionary)
	end

	-- Set the dictionary.
	common.dictionary = dictionary
end

----------------------------------------------------------------------------------------------------

return common
