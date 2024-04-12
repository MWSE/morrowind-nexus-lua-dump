---@type tes3uiElement
local dnMenu
---@type string
local targetText
---@type tes3.damageSource
local causeValue
---@type tes3.effect
local cause2Value
---@type number
local delayValue

local causes = {
	{ text = "(1/5) Attack", value = tes3.damageSource.attack },
	{ text = "(2/5) Falling", value = tes3.damageSource.fall },
	{ text = "(3/5) Magic with...", value = tes3.damageSource.magic },
	{ text = "(4/5) Sheild", value = tes3.damageSource.shield },
	{ text = "(5/5) Suffocation", value = tes3.damageSource.suffocation },
}

local causes2 = {
	{ text = "(1/7) ...Fire", value = tes3.effect["fireDamage"] },
	{ text = "(2/7) ...Shock", value = tes3.effect["shockDamage"] },
	{ text = "(3/7) ...Frost", value = tes3.effect["frostDamage"] },
	{ text = "(4/7) ...Drain", value = tes3.effect["drainHealth"] },
	{ text = "(5/7) ...Damage", value = tes3.effect["damageHealth"] },
	{ text = "(6/7) ...Absorb", value = tes3.effect["absorbHealth"] },
	{ text = "(7/7) ...Sun", value = tes3.effect["sunDamage"] },
}

local delays = {
	{ text = "4 seconds", value = 4 },
	{ text = "8 seconds", value = 8 },
	{ text = "12 seconds", value = 12 },
	{ text = "16 seconds", value = 16 },
	{ text = "20 seconds", value = 20 },
	{ text = "24 seconds", value = 24 },
	{ text = "28 seconds", value = 28 },
	{ text = "32 seconds", value = 32 },
	{ text = "36 seconds", value = 36 },
	{ text = "40 seconds", value = 40 },
}

local function findNearestLivingBeing() end

--- @param e equipEventData
local function equipCallback(e)
	if e.reference == tes3.player and e.item.objectType == tes3.objectType.book and e.item.id == "sb_DeathNote" then
		dnMenu = tes3ui.createMenu({ id = "sb_DeathNote", fixedFrame = true })
		dnMenu.minWidth = tes3.getViewportSize() / 3
		dnMenu.maxWidth = tes3.getViewportSize() / 2
		dnMenu.autoWidth = true
		dnMenu.autoHeight = true

		local title = dnMenu:createLabel({ text = "Life Devourer" })
		title.color = { 0.875, 0.788, 0.624, 1.000 }
		title.widthProportional = 1
		title.absolutePosAlignX = 0.5
		title.paddingBottom = 8

		local rules = dnMenu:createLabel({
			text = "Rules:\n1. The name written must be a living being.\n2. If a cause of death is specified, it will be carried out.\n3. If no time is specified, the living being will die in 4 seconds.\n4. If multiple living beings share the same name, the closest will die.\n5. If a living being dies before the cause of death can take effect, the nearest living being with the same name will die instead.",
		})
		rules.widthProportional = 1
		rules.wrapText = true

		dnMenu:createLabel({ text = "Target:" })
		local targetBox = dnMenu:createThinBorder({})
		targetBox.autoHeight = true
		targetBox.widthProportional = 1
		local targetElement = targetBox:createTextInput({ autoFocus = true })
		targetElement.borderAllSides = 4
		targetElement:registerAfter(tes3.uiEvent.keyPress, function(ea)
			targetText = targetElement.text:trim()
		end)

		dnMenu:createLabel({ text = "Cause of death:" })
		local damageLayout = dnMenu:createBlock()
		damageLayout.flowDirection = tes3.flowDirection.leftToRight
		damageLayout.autoHeight = true
		damageLayout.widthProportional = 1
		local causeElement = damageLayout:createCycleButton({ options = causes })
		causeElement.widthProportional = 1
		causeValue = tes3.damageSource.attack
		causeElement:registerAfter(tes3.uiEvent.mouseClick, function(ea)
			causeValue = ea.source.widget.value
		end)
		local cause2Element = damageLayout:createCycleButton({ options = causes2 })
		cause2Element.widthProportional = 1
		cause2Value = tes3.effect["fireDamage"]
		cause2Element:registerAfter(tes3.uiEvent.mouseClick, function(ea)
			cause2Value = ea.source.widget.value
		end)

		dnMenu:createLabel({
			text = "Delay until death:",
		})
		local delayElement = dnMenu:createCycleButton({ options = delays })
		delayElement.widthProportional = 1
		delayValue = 4
		delayElement:registerAfter(tes3.uiEvent.mouseClick, function(ea)
			delayValue = ea.source.widget.value
		end)

		local buttonLayout = dnMenu:createBlock()
		buttonLayout.flowDirection = tes3.flowDirection.leftToRight
		buttonLayout.autoWidth = true
		buttonLayout.height = 37 -- trying to set this to autoheight makes it invisible despite evident height appearing in the menu
		buttonLayout.absolutePosAlignX = 0.5
		buttonLayout.paddingTop = 8
		local confirmElement = buttonLayout:createButton({ text = "Write" })
		confirmElement:register(tes3.uiEvent.mouseClick, function(ea)
			---@type mwseSafeObjectHandle | nil
			local nearestReference
			---@param cell tes3cell
			for _, cell in ipairs(tes3.getActiveCells()) do
				---@param reference tes3npc | tes3creature
				for reference in cell:iterateReferences({ tes3.objectType["npc"], tes3.objectType["creature"] }) do
					if
						(
							reference.object.objectType == tes3.objectType.npc
							or reference.object.objectType == tes3.objectType.creature
						) and (reference.mobile and reference.mobile.health.current > 0)
					then
						---@type tes3npc | tes3creature
						local object = reference.object
						if (targetText ~= "" and object.name == targetText) or object.id == targetText then
							if
								nearestReference == nil
								or reference.position:distance(tes3.player.position)
									< nearestReference:getObject().position:distance(tes3.player.position)
							then
								nearestReference = tes3.makeSafeObjectHandle(reference)
							end
						end
					end
				end
			end
			if nearestReference then
				if causeValue == tes3.damageSource.magic then
					timer.start({
						type = timer.simulate,
						duration = delayValue,
						callback = function(eb)
							if nearestReference:valid() and nearestReference:getObject().mobile.health.current > 0 then
								tes3.applyMagicSource({
									reference = nearestReference:getObject(),
									name = "Life Devourer",
									effects = { { id = cause2Value, min = 9999999, max = 9999999, duration = 1 } },
									bypassResistances = true,
								})
							else
								---@type mwseSafeObjectHandle | nil
								local nextNearestReference
								---@param cell tes3cell
								for _, cell in ipairs(tes3.getActiveCells()) do
									---@param reference tes3npc | tes3creature
									for reference in
										cell:iterateReferences({ tes3.objectType["npc"], tes3.objectType["creature"] })
									do
										if
											(
												reference.object.objectType == tes3.objectType.npc
												or reference.object.objectType == tes3.objectType.creature
											)
											and (reference.mobile and reference.mobile.health.current > 0)
										then
											---@type tes3npc | tes3creature
											local object = reference.object
											if
												(targetText ~= "" and object.name == targetText)
												or object.id == targetText
											then
												if
													nextNearestReference == nil
													or reference.position:distance(
															nearestReference:getObject().position
														)
														< nextNearestReference
															:getObject().position
															:distance(nearestReference:getObject().position)
												then
													nextNearestReference = tes3.makeSafeObjectHandle(reference)
												end
											end
										end
									end
									if nextNearestReference and nextNearestReference:valid() then
										tes3.applyMagicSource({
											reference = nextNearestReference:getObject(),
											effects = { cause2Value },
										})
									end
								end
							end
						end,
					})
				else
					timer.start({
						type = timer.simulate,
						duration = delayValue,
						callback = function(eb)
							if nearestReference:valid() and nearestReference:getObject().mobile.health.current > 0 then
								nearestReference
									:getObject().mobile
									:applyDamage({ damage = 9999999, playerAttack = true })
							else
								---@type mwseSafeObjectHandle | nil
								local nextNearestReference
								---@param cell tes3cell
								for _, cell in ipairs(tes3.getActiveCells()) do
									---@param reference tes3npc | tes3creature
									for reference in
										cell:iterateReferences({ tes3.objectType["npc"], tes3.objectType["creature"] })
									do
										if
											(
												reference.object.objectType == tes3.objectType.npc
												or reference.object.objectType == tes3.objectType.creature
											)
											and (reference.mobile and reference.mobile.health.current > 0)
										then
											---@type tes3npc | tes3creature
											local object = reference.object
											if
												(targetText ~= "" and object.name == targetText)
												or object.id == targetText
											then
												if
													nextNearestReference == nil
													or reference.position:distance(
															nearestReference:getObject().position
														)
														< nextNearestReference
															:getObject().position
															:distance(nearestReference:getObject().position)
												then
													nextNearestReference = tes3.makeSafeObjectHandle(reference)
												end
											end
										end
									end
									if nextNearestReference and nextNearestReference:valid() then
										nextNearestReference
											:getObject().mobile
											:applyDamage({ damage = 9999999, playerAttack = true })
									end
								end
							end
						end,
					})
				end
			end
			dnMenu:destroy()
			tes3ui.leaveMenuMode()
		end)
		local cancelElement = buttonLayout:createButton({ text = "Cancel" })
		cancelElement:register(tes3.uiEvent.mouseClick, function(ea)
			dnMenu:destroy()
		end)

		dnMenu:updateLayout()

		-- tes3ui.showMessageMenu({
		-- 	buttons = {
		-- 		{
		-- 			text = "Write",
		-- 			callback = function(callbackParams)
		-- 				---@type tes3reference | nil
		-- 				local nearestReference
		-- 				---@param cell tes3cell
		-- 				for _, cell in ipairs(tes3.getActiveCells()) do
		-- 					---@param reference tes3reference
		-- 					for reference in tes3.iterate(cell.actors) do
		-- 						if
		-- 							reference.object.objectType == tes3.objectType.npc
		-- 							or reference.object.objectType == tes3.objectType.creature
		-- 						then
		-- 							---@type tes3npc | tes3creature
		-- 							local object = reference.object
		-- 							if (targetText ~= "" and object.name == targetText) or object.id == targetText then
		-- 								if
		-- 									nearestReference == nil
		-- 									or reference.position:distance(tes3.player.position)
		-- 										< nearestReference.position:distance(tes3.player.position)
		-- 								then
		-- 									nearestReference = reference
		-- 								end
		-- 							end
		-- 						end
		-- 					end
		-- 				end
		-- 				if nearestReference then
		-- 					if causeValue == tes3.damageSource.magic then
		-- 						timer.start({
		-- 							type = timer.simulate,
		-- 							duration = delayValue - 2,
		-- 							callback = function(e)
		-- 								tes3.applyMagicSource({
		-- 									reference = nearestReference,
		-- 									effects = { cause2Value },
		-- 								})
		-- 							end,
		-- 						})
		-- 						timer.start({
		-- 							type = timer.simulate,
		-- 							duration = delayValue,
		-- 							callback = function(e)
		-- 								nearestReference.mobile:applyDamage({ damage = 9999999, playerAttack = true })
		-- 							end,
		-- 						})
		-- 					else
		-- 						-- event.trigger(tes3.event.damage, { damage = 9999999, mobile = nearestReference.mobile, reference = nearestReference, source = tes3.damageSource.attack})
		-- 						-- event.trigger(tes3.event.damaged, { damage = 9999999, mobile = nearestReference.mobile, reference = nearestReference, source = tes3.damageSource.attack})
		-- 						timer.start({
		-- 							type = timer.simulate,
		-- 							duration = delayValue,
		-- 							callback = function(e)
		-- 								nearestReference.mobile:applyDamage({ damage = 9999999, playerAttack = true })
		-- 							end,
		-- 						})
		-- 					end
		-- 					-- nearestReference.mobile.health.current = 0
		-- 				end
		-- 				tes3ui.leaveMenuMode()
		-- 			end,
		-- 		},
		-- 		{ text = "Cancel" },
		-- 	},
		-- 	leaveMenuMode = false,
		-- 	header = "Life Devourer",
		-- 	-- message = "Rules:\n1. The name written must be a living being.\n2. If a cause of death is specified, it will be carried out.\n3. If no time is specified, the living being will die in 4 seconds.\n4. If multiple living beings share the same name, the closest will die.",
		-- 	message = "Rules:\n1. The living being you're looking at will be written.\n2. If a cause of death is specified, it will be carried out.\n3. If no time is specified, the living being will die in 4 seconds.\n4. If a living being dies before the cause of death can take effect, the nearest living being with the same name will die instead.",
		-- 	customBlock = function(parent)
		-- 		parent.parent.maxWidth = 528
		-- 		parent.parent.minWidth = 528

		-- 		parent.autoWidth = false
		-- 		parent.widthProportional = 1

		-- 		parent:createLabel({ text = "Target:" })
		-- 		local targetBox = parent:createThinBorder({})
		-- 		targetBox.autoHeight = true
		-- 		targetBox.widthProportional = 1
		-- 		local targetElement = targetBox:createTextInput({ placeholderText = "Fargoth" })
		-- 		targetElement.widthProportional = 1
		-- 		-- targetElement:registerAfter(tes3.uiEvent.keyPress, function(e)
		-- 		-- 	targetText = e.widget.text
		-- 		-- end)
		-- 		local hit = tes3.rayTest({
		-- 			position = tes3.getPlayerEyePosition(),
		-- 			direction = tes3.getPlayerEyeVector(),
		-- 			maxDistance = 9999999,
		-- 			ignore = { tes3.player },
		-- 		})
		-- 		mwse.log("death")
		-- 		if hit and hit.reference then
		-- 			if
		-- 				hit.reference.object.objectType == tes3.objectType.npc
		-- 				or hit.reference.object.objectType == tes3.objectType.creature
		-- 			then
		-- 				targetElement.text = hit.reference.object.name
		-- 				targetText = hit.reference.object.name
		-- 			else
		-- 				targetElement.text = ""
		-- 				targetText = ""
		-- 			end
		-- 		end
		-- 		-- tes3ui.acquireTextInput(targetElement)

		-- 		parent:createLabel({ text = "Cause of death:" })
		-- 		local damageLayout = parent:createBlock()
		-- 		damageLayout.flowDirection = tes3.flowDirection.leftToRight
		-- 		damageLayout.autoHeight = true
		-- 		damageLayout.widthProportional = 1
		-- 		local causeElement = damageLayout:createCycleButton({ options = causes })
		-- 		causeElement.widthProportional = 1
		-- 		causeValue = tes3.damageSource.attack
		-- 		causeElement:registerAfter(tes3.uiEvent.mouseClick, function(e)
		-- 			causeValue = e.source.widget.value
		-- 		end)
		-- 		local cause2Element = damageLayout:createCycleButton({ options = causes2 })
		-- 		cause2Element.widthProportional = 1
		-- 		cause2Value = tes3.effect["fireDamage"]
		-- 		cause2Element:registerAfter(tes3.uiEvent.mouseClick, function(e)
		-- 			cause2Value = e.source.widget.value
		-- 		end)

		-- 		parent:createLabel({
		-- 			text = "Delay until death: " --[[.. tostring(delayElement and delayElement.widget.current or 4) .. " seconds"]],
		-- 		})
		-- 		-- delayElement = parent:createSlider{current = 4, max = 40, jump = 4}
		-- 		local delayElement = parent:createCycleButton({ options = delays })
		-- 		delayElement.widthProportional = 1
		-- 		delayValue = 4
		-- 		delayElement:registerAfter(tes3.uiEvent.mouseClick, function(e)
		-- 			delayValue = e.source.widget.value
		-- 		end)
		-- 	end,
		-- })
		return false
	end
end
event.register(tes3.event.equip, equipCallback)

-- --- @param e menuExitEventData
-- local function menuExitCallback(e)
-- 	if dnMenu then
-- 		dnMenu:destroy()
-- 	end
-- end
-- event.register(tes3.event.menuExit, menuExitCallback)
