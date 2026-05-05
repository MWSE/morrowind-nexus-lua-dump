-- Bound items similarly to Bound Balance

local BOUND = trData.BOUND_ITEMS
local SLOTS = types.Actor.EQUIPMENT_SLOT

local function boundItemsStillCarried(entry)
	if not entry.items then return true end
	for _, ref in ipairs(entry.items) do
		local item = ref.item
		if not item or not item:isValid() or item.parentContainer ~= self.object then
			--print("bound item left inventory", ref.slot, item and item:isValid() and item.recordId or "nothing")
			return false
		end
	end
	return true
end

-- register events for every "bound" magic effect
for effectId, def in pairs(BOUND) do
	G.onMgefAdded[effectId] = function(key, eff, activeSpell, entry)
	
		-- added: snapshot gear in saveData, request items (callback will equip them)
		entry.prevGear = {}
		for _, slot in ipairs(def.slots) do
			local cur = types.Actor.getEquipment(self, slot)
			if cur and not saveData.knownBoundRecordIds[cur.recordId] then
				entry.prevGear[slot] = cur
			else -- slot had no gear
				entry.prevGear[slot] = false
			end
		end
		
		local slotItems = {}
		for i, baseRecordId in ipairs(def.items) do
			slotItems[i] = {
				slot         = def.slots[i],
				baseRecordId = baseRecordId,
			}
		end
		
		core.sendGlobalEvent('TD_BoundSpawn', {
			actor     = self.object,
			key       = key,
			slotItems = slotItems,
		})
	end
	
	-- tick: detect disappearing items
	G.onMgefTick[effectId] = function(key, eff, activeSpell, entry)
		if not boundItemsStillCarried(entry) then
			if entry.activeSpellId then
				G.pendingActiveSpellRemovals[#G.pendingActiveSpellRemovals + 1]
					= entry.activeSpellId
			end
		end
	end
	
	-- removed: request deletion and equip previous gear
	G.onMgefRemoved[effectId] = function(key, entry)
		if entry.items and #entry.items > 0 then
			local toDespawn = {}
			for _, ref in ipairs(entry.items) do
				toDespawn[#toDespawn + 1] = ref.item
			end
			core.sendGlobalEvent('TD_BoundDespawn', {
				actor = self.object,
				items = toDespawn,
			})
		end
		if entry.prevGear then
			local equipment = types.Actor.getEquipment(self)
			for slot, prev in pairs(entry.prevGear) do
				if prev and prev:isValid() then
					equipment[slot] = prev
				else
					equipment[slot] = nil
				end
			end
			types.Actor.setEquipment(self, equipment)
		end
	end
end

-- callback: equip spawned items
G.eventHandlers.TD_BoundEquip = function(data)
	local entry = saveData.trackedEffects[data.key]
	if not entry then
		-- error: effect already disappeared
		local stray = {}
		for _, payload in pairs(data.items) do
			stray[#stray + 1] = payload.item
		end
		core.sendGlobalEvent('TD_BoundDespawn', {
			actor = self.object,
			items = stray,
		})
		return
	end
	
	-- merge callbacks because we can do setEquipment only once per frame
	G.pendingBoundEquips = G.pendingBoundEquips or {}
	for slot, payload in pairs(data.items) do
		G.pendingBoundEquips[#G.pendingBoundEquips + 1] = {
			slot  = slot,
			item  = payload.item,
			entry = entry,
		}
	end
	
	-- next frame: equip all the items that arrived
	if G.boundEquipsScheduled then return end
	G.boundEquipsScheduled = true
	async:newUnsavableSimulationTimer(0, function()
		G.boundEquipsScheduled = false
		local refs = G.pendingBoundEquips
		G.pendingBoundEquips = nil
		if not refs or #refs == 0 then return end
		
		local equipment = types.Actor.getEquipment(self)
		local drawWeapon = false
		for _, ref in ipairs(refs) do
			equipment[ref.slot] = ref.item
			ref.entry.items = ref.entry.items or {}
			ref.entry.items[#ref.entry.items + 1] = {
				slot = ref.slot,
				item = ref.item,
			}
			-- remember this recordId for future prevGear snapshots so an already equipped bound item from a prior cast isn't mistaken for prev gear
			if ref.item and ref.item:isValid() then
				saveData.knownBoundRecordIds[ref.item.recordId] = true
			end
			if ref.slot == SLOTS.CarriedRight then
				drawWeapon = true
			end
		end
		types.Actor.setEquipment(self, equipment)
		
		-- bound weapons are immediately drawn after animation ends
		if drawWeapon then
			local extraDelay = 3
			G.sluggishJobs.boundWeaponStance = function()
				if animation.isPlaying(self.object, "spellcast") then
					extraDelay = 3
				elseif extraDelay > 0 then
					extraDelay = extraDelay - 1
				else
					G.sluggishJobs.boundWeaponStance = nil
					if types.Actor.getStance(self) ~= types.Actor.STANCE.Weapon then
						types.Actor.setStance(self, types.Actor.STANCE.Weapon)
					end
				end
			end
		end
	end)
end
