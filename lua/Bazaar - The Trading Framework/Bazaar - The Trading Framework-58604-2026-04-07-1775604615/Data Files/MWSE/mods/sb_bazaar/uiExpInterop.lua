local uiExp = include("UI Expansion.common")
if (uiExp == nil) then return false end

local interop = {}

--- @param knownEffects table<number, boolean>
--- @param spellList tes3spellList
function interop.fillKnownEffectsTable(knownEffects, spellList)
	if (spellList == nil) then
		return
	end

	for _, spell in ipairs(spellList.iterator) do
		if (spell.castType == tes3.spellType.spell) then
			for _, effect in ipairs(spell.effects) do
				knownEffects[effect.id] = true
			end
		end
	end
end

--- @param mobile tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer
--- @return table<number, boolean>
function interop.getKnownEffectsTable(mobile)
	local knownEffects = {} --- @type table<number, boolean>

	interop.fillKnownEffectsTable(knownEffects, mobile.object.spells)

	local race = mobile.object.race
	if (race) then
		interop.fillKnownEffectsTable(knownEffects, race.abilities)
	end

	local birthsign = mobile.birthsign
	if (birthsign) then
		interop.fillKnownEffectsTable(knownEffects, birthsign.spells)
	end

	knownEffects[-1] = true

	return knownEffects
end

--- @param knownEffects table<number, boolean>
--- @param spell tes3spell
--- @return boolean
function interop.getKnowsAllSpellEffects(knownEffects, spell)
	for _, effect in ipairs(spell.effects) do
		if (knownEffects[effect.id] == nil) then
			return false
		end
	end
	return true
end

--- @param spellLabel tes3uiElement
function interop.setColour(spellLabel)
	local spell = spellLabel:getPropertyObject("MenuServiceSpells_Spell")
	local knownEffects = interop.getKnownEffectsTable(tes3.mobilePlayer)
	local knowsAllSpellEffects = interop.getKnowsAllSpellEffects(knownEffects, spell)

	if (knowsAllSpellEffects == nil) then
		spellLabel.widget.idleActive = uiExp.getColor(uiExp.config.dialogueTopicUniqueColor)
	end
end

---------

--- @param trainingGroup tes3uiElement
--- @param nameLabel tes3uiElement
--- @param levelLabel tes3uiElement
--- @param trainingButton tes3uiElement
--- @param goldLabel tes3uiElement
--- @param canAfford boolean
function interop.setTrainingColour(trainingGroup, nameLabel, limitLabel, levelLabel, trainingButton, goldLabel, canAfford)
	local skill = tes3.getSkill(trainingGroup:getPropertyInt("MenuServiceTraining_ListNumber"))
	local level = tes3.mobilePlayer.skills[skill.id + 1]
	local attr = tes3.mobilePlayer.attributes[skill.attribute + 1]
	local trainerLevel = trainingGroup:getTopLevelMenu():getPropertyObject("MenuServiceTraining_Actor").skills[skill.id + 1]

	local canTrain = level.base < attr.base and level.base < trainerLevel.base
	local enableDisableColor = (canAfford and canTrain) and tes3ui.getPalette(tes3.palette.normalColor) or tes3ui.getPalette(tes3.palette.disabledColor)

	nameLabel.color = enableDisableColor
	limitLabel.color = enableDisableColor

	if (canAfford and canTrain) then
		levelLabel.color = enableDisableColor
		trainingButton.disabled = false
		trainingButton.color = {1, 1, 1}
		trainingButton.children[1].alpha = 1
	else
		levelLabel.color = tes3ui.getPalette(tes3.palette.negativeColor)
		trainingButton.disabled = true
		trainingButton.color = {0, 0, 0}
		trainingButton.children[1].alpha = 0.25
	end

	if (level.base < trainerLevel.base) then
		goldLabel.color = canAfford and tes3ui.getPalette(tes3.palette.normalColor) or tes3ui.getPalette(tes3.palette.negativeColor)
	end
end

return interop