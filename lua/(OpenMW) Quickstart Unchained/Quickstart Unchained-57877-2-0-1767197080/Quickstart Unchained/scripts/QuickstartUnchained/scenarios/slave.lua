registerScenario({
	name = "As a slave",
	description = "Start in bondage at Dren Plantation.\nFind the key to remove your bracers.",
	locationScript = function(player)
		--return {
		--	gridX = 2,
		--	gridY = -6,
		--	position = util.vector3(20335.3, -47972.7, 649.0),
		--	rotation = util.transform.rotateZ(math.rad(156.9)),
		--}
		return {
			cell = "Dren Plantation, Storage Shack",
			refNpc = "avus belvilo",
			position = util.vector3(4188.8, 4172.9, 14259.8),
			rotation = util.transform.rotateZ(math.rad(-48.3)),
		}
	end,
	globalScripts = {
		onSelected = function(player, cell)
			if cell then
				for _, npc in pairs(cell:getAll(types.NPC)) do
					types.NPC.setBaseDisposition(npc, player, 60)
				end
			end
			giveFood(player)
			giveLockpicks(player)
			
			-- Give detect key spell and scroll
			local rndNum = math.random(1,16)
			for _, container in pairs(cell:getAll(types.Container)) do
				rndNum = rndNum - 1
				if rndNum == 0 then
					local scroll = world.createObject("sc_tevralshawkshaw", 1)
					scroll:moveInto(types.Container.inventory(container))
					break
				end
			end
			
			local rightBracer = world.createObject("slave_bracer_right", 1)
			rightBracer:moveInto(types.Actor.inventory(player))
			local leftBracer = world.createObject("slave_bracer_left", 1)
			leftBracer:moveInto(types.Actor.inventory(player))
			
			local eq = types.Actor.getEquipment(player)
			eq[types.Actor.EQUIPMENT_SLOT.LeftGauntlet] = leftBracer
			eq[types.Actor.EQUIPMENT_SLOT.RightGauntlet] = rightBracer
			
			player:sendEvent("Quickstart_Unchained_equipItems", eq)
			player:sendEvent("Quickstart_Unchained_activateScenario", "As a slave")
		end,
		onUpdate = function(player) -- fix for quickloot
			if not saveData.hasStolenScroll then
				if types.Actor.inventory(player):find("sc_tevralshawkshaw") then
					saveData.hasStolenScroll = true
					for _, npc in pairs(player.cell:getAll(types.NPC)) do
						if npc.recordId == "avus belvilo" then
							I.Crimes.commitCrime(player, {
								arg = 120,
								type = types.Player.OFFENSE_TYPE.Theft,
								victim = npc,
								victimAware = true
							})
						end
					end
				end
			end
		end,
		-- Block equipping weapons while enslaved (bracers suppress magic, can't fight back)
		onUseItem = function(item, actor)
			if types.Weapon.objectIsInstance(item) then
				actor:sendEvent("ShowMessage", {message = "The slave bracers prevent you from wielding weapons."})
				return false
			end
		end,
		-- Custom event handlers for other mods
		eventHandlers = {
			-- Example: React to Sun's Dusk sleep events
			-- SunsDusk_Sleep_wokeUp = function(player, data)
			-- 	player:sendEvent("ShowMessage", {message = "Another day of bondage begins."})
			-- end,
		},
		onEnd = function(player)
			local cell = player.cell
			if not cell then return end
			
			-- Track cells we've already added to avoid duplicates
			local seenCells = {[cell.id] = true}
			local cellsToCheck = {cell}
			local exteriorCells = {}
			
			-- Add connected cells via doors from the current cell
			for _, door in pairs(cell:getAll(types.Door)) do
				if types.Door.isTeleport(door) then
					local destCell = types.Door.destCell(door)
					if destCell and not seenCells[destCell.id] then
						seenCells[destCell.id] = true
						cellsToCheck[#cellsToCheck + 1] = destCell
						if destCell.isExterior then
							exteriorCells[#exteriorCells + 1] = destCell
						end
					end
				end
			end
			
			-- If current cell is exterior, add it to the list for 3x3 expansion
			if cell.isExterior then
				exteriorCells[#exteriorCells + 1] = cell
			end
			
			-- For each exterior cell, add 3x3 nearby cells and their connected interiors
			for _, extCell in ipairs(exteriorCells) do
				for dx = -1, 1 do
					for dy = -1, 1 do
						if dx ~= 0 or dy ~= 0 then
							local nearbyCell = world.getExteriorCell(extCell.gridX + dx, extCell.gridY + dy)
							if nearbyCell and not seenCells[nearbyCell.id] then
								seenCells[nearbyCell.id] = true
								cellsToCheck[#cellsToCheck + 1] = nearbyCell
								
								-- Add interior cells connected to this exterior cell
								for _, door in pairs(nearbyCell:getAll(types.Door)) do
									if types.Door.isTeleport(door) then
										local destCell = types.Door.destCell(door)
										if destCell and not seenCells[destCell.id] then
											seenCells[destCell.id] = true
											cellsToCheck[#cellsToCheck + 1] = destCell
										end
									end
								end
							end
						end
					end
				end
			end
			
			-- Find a non-slave NPC and commit crime against them
			for _, checkCell in ipairs(cellsToCheck) do
				for _, npc in pairs(checkCell:getAll(types.NPC)) do
					if npc ~= player and not types.Actor.isDead(npc) then
						local record = types.NPC.record(npc)
						local npcClass = record.class:lower()
						--print(npc, npcClass)
						if not npcClass:find("slave") or npcClass:find("slaver") then
							I.Crimes.commitCrime(player, {
								arg = 1000,
								type = types.Player.OFFENSE_TYPE.Theft,
								victim = npc,
								victimAware = true
							})
						end
					end
				end
			end
		end,
	},
	playerScripts = {
		onFrame = function(dt)
			local inv = types.Actor.inventory(self)
			
			-- Check if player found the key
			if inv:find("key_drenplantationslaves_01") then
				endScenario("As a slave")
				return
			end
			
			-- Force bracers to stay equipped
			local eq = types.Actor.getEquipment(self)
			local needsReequip = false
			
			local leftEquipped = eq[types.Actor.EQUIPMENT_SLOT.LeftGauntlet]
			if not leftEquipped or leftEquipped.recordId ~= "slave_bracer_left" then
				local bracer = inv:find("slave_bracer_left")
				if bracer then
					eq[types.Actor.EQUIPMENT_SLOT.LeftGauntlet] = bracer
					needsReequip = true
				end
			end
			
			local rightEquipped = eq[types.Actor.EQUIPMENT_SLOT.RightGauntlet]
			if not rightEquipped or rightEquipped.recordId ~= "slave_bracer_right" then
				local bracer = inv:find("slave_bracer_right")
				if bracer then
					eq[types.Actor.EQUIPMENT_SLOT.RightGauntlet] = bracer
					needsReequip = true
				end
			end
			
			if needsReequip then
				types.Actor.setEquipment(self, eq)
				I.UI.setMode()
				I.UI.setMode("Interface")
				ui.showMessage("The slave bracers are locked onto your wrists.")
				types.Actor.stats.dynamic.magicka(self).current = math.min(types.Actor.stats.dynamic.magicka(self).current, math.max(0, types.Actor.stats.dynamic.magicka(self).current - 3))
			end
			types.Actor.stats.dynamic.magicka(self).current = math.min(types.Actor.stats.dynamic.magicka(self).current, math.max(0, types.Actor.stats.dynamic.magicka(self).current - 1*dt))
		end,
		onSelected = function()
			types.Actor.spells(self):add("tevral's hawkshaw")
		end,
		onEnd = function()
			ui.showMessage("Finally, the key to freedom. Your owners won't be happy...")
		end,
		-- Custom event handlers for other mods
		eventHandlers = {
			-- Example: React to player-side events from other mods
			-- SomeOtherMod_PlayerEvent = function(data)
			-- 	ui.showMessage("Something happened while enslaved!")
			-- end,
		},
	},
})