local seph = require("seph")

local power = seph.Module:new()

power.powerId = "aa_astro_reading"
power.description = "Read your fate in the stars and receive a blessing or a curse"
power.blessings = {
	"aa_astro_bless_01",
	"aa_astro_bless_02",
	"aa_astro_bless_03",
	"aa_astro_bless_04",
	"aa_astro_bless_05",
	"aa_astro_bless_06"
}
power.curses = {
	"aa_astro_curse_01",
	"aa_astro_curse_02",
	"aa_astro_curse_03",
	"aa_astro_curse_04",
	"aa_astro_curse_05",
	"aa_astro_curse_06",
	"aa_astro_curse_07"
}
power.shortBlessMessage = "The stars have blessed you."
power.shortCurseMessage = "The stars have cursed you."
power.longBlessMessage = "The stars have blessed you with '%s'."
power.longCurseMessage = "The stars have cursed you with '%s'."
power.lastUpdate = -1

function power:addRandomSpell(spells)
	local spell = tes3.getObject(spells[math.random(#spells)])
	tes3.addSpell{
		reference = tes3.player,
		spell = spell
	}
	return spell
end

function power:addRandomBlessing()
	local spell = self:addRandomSpell(self.blessings)
	self.logger:debug(string.format("Selected blessing '%s'", spell.id))
	return spell
end

function power:addRandomCurse()
	local spell = self:addRandomSpell(self.curses)
	self.logger:debug(string.format("Selected curse '%s'", spell.id))
	return spell
end

function power:removeSpells(spells)
	for _, spell in pairs(spells) do
		tes3.removeSpell{
			reference = tes3.player,
			spell = spell
		}
	end
end

function power:removeBlessings()
	self:removeSpells(self.blessings)
end

function power:removeCurses()
	self:removeSpells(self.curses)
end

function power:removeBlessingsAndCurses()
	self:removeBlessings()
	self:removeCurses()
end

function power:addBlessingOrCurse()
	local spell = nil
	local message = ""
	if math.random(0, 100) <= self.mod.config.current.blessingChance then
		spell = self:addRandomBlessing()
		-- The first one is without spell name, the second one is with spell name.
		--message = self.shortBlessMessage
		message = string.format(self.longBlessMessage, spell.name)
	else
		spell = self:addRandomCurse()
		-- The first one is without spell name, the second one is with spell name.
		--message = self.shortCurseMessage
		message = string.format(self.longCurseMessage, spell.name)
	end
	-- This first one is without button, the second one is with buttons.
	--tes3.messageBox{message = message}
	tes3.messageBox{message = message, buttons = {tes3.findGMST(tes3.gmst.sOK).value}}
end

function power:update()
	if tes3.worldController.daysPassed.value > self.lastUpdate then
		self:removeBlessingsAndCurses()
		self.lastUpdate = tes3.worldController.daysPassed.value
		self.logger:debug("Updated")
	end
end

function power.onMagicCasted(eventData)
	if eventData.caster == tes3.player and eventData.source.id == power.powerId then
		power:update()
		power:addBlessingOrCurse()
	end
end

function power.onUiSpellTooltip(eventData)
	if eventData.spell.id == power.powerId then
		local effectElement = eventData.tooltip:findChild("effect")
		if effectElement then
			effectElement.visible = false
		end
		local descriptionLabel = eventData.tooltip:createLabel{
			id = "astrologer:powerDescriptionLabel",
			text = power.description
		}
	end
end

function power.onLoaded(eventData)
	if eventData.newGame then
		power.lastUpdate = -1
	else
		power.lastUpdate = tes3.worldController.daysPassed.value
	end
	local updateTimer = nil
	updateTimer = timer.start{
		type = timer.simulate,
		duration = 1.0,
		iterations = -1,
		callback =
			function()
				power.logger:trace("Update timer expired")
				power:update()
			end
	}
end

function power:onEnabled()
	event.register(tes3.event.loaded, self.onLoaded)
	event.register(tes3.event.magicCasted, self.onMagicCasted)
	event.register(tes3.event.uiSpellTooltip, self.onUiSpellTooltip)
end

function power:onDisabled()
	event.unregister(tes3.event.loaded, self.onLoaded)
	event.unregister(tes3.event.magicCasted, self.onMagicCasted)
	event.unregister(tes3.event.uiSpellTooltip, self.onUiSpellTooltip)
end

return power