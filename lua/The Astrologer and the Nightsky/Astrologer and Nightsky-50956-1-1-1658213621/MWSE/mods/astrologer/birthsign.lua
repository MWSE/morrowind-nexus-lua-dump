local seph = require("seph")

local birthsign = seph.Module:new()

birthsign.birthsignId = "aa_astro_birthsign"
birthsign.monthlyAbilities = {
	[0] = "aa_astro_ritual",
	[1] = "aa_astro_lover",
	[2] = "aa_astro_lord",
	[3] = "aa_astro_mage",
	[4] = "aa_astro_shadow",
	[5] = "aa_astro_steed",
	[6] = "aa_astro_apprentice",
	[7] = "aa_astro_warrior",
	[8] = "aa_astro_lady",
	[9] = "aa_astro_tower",
	[10] = "aa_astro_atronach",
	[11] = "aa_astro_thief"
}
birthsign.description = "Gains the boons of another constellation every month."
birthsign.message = "The stars have altered your fate. You are now under the guidance of '%s'."
birthsign.lastUpdate = -1

function birthsign:addMonthlyAbility(month)
	local spell = tes3.getObject(self.monthlyAbilities[month])
	tes3.addSpell{
		reference = tes3.player,
		spell = spell
	}
	self.logger:debug(string.format("Selected monthly ability '%s'", spell.id))
	return spell
end

function birthsign:removeMonthlyAbilities()
	for _, spell in pairs(self.monthlyAbilities) do
		tes3.removeSpell{
			reference = tes3.player,
			spell = spell
		}
	end
end

function birthsign:update()
	if tes3.mobilePlayer.birthsign.id == self.birthsignId and tes3.worldController.daysPassed.value > self.lastUpdate then
		local month = tes3.worldController.month.value
		if not tes3.hasSpell{reference = tes3.player, spell = self.monthlyAbilities[month]} then
			self:removeMonthlyAbilities()
			local spell = self:addMonthlyAbility(month)
			tes3.messageBox{
				message = string.format(self.message, spell.name),
				buttons = {tes3.findGMST(tes3.gmst.sOK).value}
			}
		end
		self.lastUpdate = tes3.worldController.daysPassed.value
		self.logger:debug("Updated")
	end
end


function birthsign.onLoaded(eventData)
	if eventData.newGame then
		birthsign.lastUpdate = -1
	else
		birthsign.lastUpdate = tes3.worldController.daysPassed.value
	end
	local updateTimer = nil
	updateTimer = timer.start{
		type = timer.simulate,
		duration = 1.0,
		iterations = -1,
		callback =
			function()
				birthsign.logger:trace("Update timer expired")
				if tes3.worldController.charGenState.value ~= -1 then
					return
				elseif tes3.mobilePlayer.birthsign.id ~= birthsign.birthsignId then
					updateTimer:cancel()
				else
					birthsign:update()
				end
			end
	}
end

function birthsign.onUiActivated(eventData)
	local menuBirthsign = tes3ui.findMenu("MenuBirthSign")
	if menuBirthsign then
		local birthsignToModify = tes3.findBirthsign(birthsign.birthsignId)
		local birthsignScroll = menuBirthsign:findChild("MenuBirthSign_BirthSignScroll"):getContentElement()
		local function updateBirthsignMenuAbilityContents()
			local birthsignAbilities = menuBirthsign:findChild("MenuBirthSign_Abilities")
			local label = birthsignAbilities:createLabel{
				id = "astrologer:birthsignAbilityText",
				text = "Abilities:"
			}
			label.color = tes3ui.getPalette("header_color")
			label = birthsignAbilities:createLabel{
				id = "astrologer:birthsignDescriptionText",
				text = birthsign.description
			}
			menuBirthsign:updateLayout()
		end

		for _, child in pairs(birthsignScroll.children) do
			if child.text == birthsignToModify.name then
				child:registerAfter(tes3.uiEvent.mouseClick, updateBirthsignMenuAbilityContents)
				if child.widget.state == tes3.uiState.active then
					updateBirthsignMenuAbilityContents()
				end
			end
		end
	end
end

function birthsign:onEnabled()
	event.register(tes3.event.loaded, self.onLoaded)
	event.register(tes3.event.uiActivated, self.onUiActivated, {filter = "MenuBirthSign"})
end

function birthsign:onDisabled()
	event.unregister(tes3.event.loaded, self.onLoaded)
	event.unregister(tes3.event.uiActivated, self.onUiActivated, {filter = "MenuBirthSign"})
end

return birthsign