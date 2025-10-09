local core = require("openmw.core")
local types = require("openmw.types")

local function selected_items(actor)
	local have_spell = false
	local items = {}
	local active_spells =  types.Actor.activeSpells(actor)
	local spells_to_remove = {}
	for _, active_spell in pairs(types.Actor.activeSpells(actor)) do
		if active_spell.id == "transfer books" then
			have_spell = true
			table.insert(spells_to_remove, active_spell.activeSpellId)
			for _, item in ipairs(types.Actor.inventory(actor):getAll(types.Book)) do
				if not item.type.record(item).isScroll then
					table.insert(items, item)
				end
			end
		end
		if active_spell.id == "transfer ingredients" then
			have_spell = true
			table.insert(spells_to_remove, active_spell.activeSpellId)
			for _, item in ipairs(types.Actor.inventory(actor):getAll(types.Ingredient)) do
				table.insert(items, item)
			end
		end
		if active_spell.id == "transfer potions" then
			have_spell = true
			table.insert(spells_to_remove, active_spell.activeSpellId)
			active_spells:remove(active_spell.activeSpellId)
			for _, item in ipairs(types.Actor.inventory(actor):getAll(types.Potion)) do
				table.insert(items, item)
			end
		end
		if active_spell.id == "transfer projectiles" then
			have_spell = true
			table.insert(spells_to_remove, active_spell.activeSpellId)
			for _, item in ipairs(types.Actor.inventory(actor):getAll(types.Weapon)) do
				if  item.type.record(item).type == types.Weapon.TYPE.Arrow or
				item.type.record(item).type == types.Weapon.TYPE.Bolt or
				item.type.record(item).type == types.Weapon.TYPE.MarksmanThrown then
					table.insert(items, item)
				end
			end
		end
		if active_spell.id == "transfer scrolls" then
			have_spell = true
			table.insert(spells_to_remove, active_spell.activeSpellId)
			for _, item in ipairs(types.Actor.inventory(actor):getAll(types.Book)) do
				if item.type.record(item).isScroll then
					table.insert(items, item)
				end
			end
		end
		if active_spell.id == "transfer miscellaneous" then
			have_spell = true
			table.insert(spells_to_remove, active_spell.activeSpellId)
			for _, item in ipairs(types.Actor.inventory(actor):getAll(types.Miscellaneous)) do
				if not (item.type.record(item).isKey or
				string.find(item.recordId, "gold_") or
				string.find(item.recordId, "_soulgem") or
				string.find(item.recordId, "_soul_gem") or
				string.find(item.recordId, "Generated")) then -- Excluding Corporeal Carryable Containers
					table.insert(items, item)
				end
			end
		end
		if active_spell.id == "transfer keys" then
			have_spell = true
			table.insert(spells_to_remove, active_spell.activeSpellId)
			for _, item in ipairs(types.Actor.inventory(actor):getAll(types.Miscellaneous)) do
				if item.type.record(item).isKey then
					table.insert(items, item)
				end
			end
		end
		if active_spell.id == "transfer soul gems" then
			have_spell = true
			table.insert(spells_to_remove, active_spell.activeSpellId)
			for _, item in ipairs(types.Actor.inventory(actor):getAll(types.Miscellaneous)) do
				if string.find(item.recordId, "_soulgem") or
				string.find(item.recordId, "_soul_gem") then
					table.insert(items, item)
				end
			end
		end
		if active_spell.id == "transfer tools" then
			have_spell = true
			table.insert(spells_to_remove, active_spell.activeSpellId)
			for _, item in ipairs(types.Actor.inventory(actor):getAll(types.Probe)) do
				table.insert(items, item)
			end
			for _, item in ipairs(types.Actor.inventory(actor):getAll(types.Lockpick)) do
				table.insert(items, item)
			end
			for _, item in ipairs(types.Actor.inventory(actor):getAll(types.Repair)) do
				table.insert(items, item)
			end
		end
		if active_spell.id == "transfer lights" then
			have_spell = true
			table.insert(spells_to_remove, active_spell.activeSpellId)
			for _, item in ipairs(types.Actor.inventory(actor):getAll(types.Light)) do
				if not ( types.Actor.hasEquipped(actor, item) ) then
					table.insert(items, item)
				end
			end
		end
		if active_spell.id == "transfer weapons" then
			have_spell = true
			table.insert(spells_to_remove, active_spell.activeSpellId)
			for _, item in ipairs(types.Actor.inventory(actor):getAll(types.Weapon)) do
				if not ( types.Actor.hasEquipped(actor, item) or
				item.type.record(item).type == types.Weapon.TYPE.Arrow or
				item.type.record(item).type == types.Weapon.TYPE.Bolt or
				item.type.record(item).type == types.Weapon.TYPE.MarksmanThrown) then
					table.insert(items, item)
				end
			end
		end
		if active_spell.id == "transfer armors" then
			have_spell = true
			table.insert(spells_to_remove, active_spell.activeSpellId)
			for _, item in ipairs(types.Actor.inventory(actor):getAll(types.Armor)) do
				if not ( types.Actor.hasEquipped(actor, item) ) then
					table.insert(items, item)
				end
			end
		end
		for _, spell_id in ipairs(spells_to_remove) do
			types.Actor.activeSpells(actor):remove(spell_id)
		end
	end
	return items, have_spell
end

local function move_selected_items_to_container(actor, container)
	local count = 0
	local cont_inv = types.Container.inventory(container)
	local have_spell
	if cont_inv then
		local items
		items, have_spell = selected_items(actor)
		if #items > 0 then
			core.sound.playSound3d("item misc down", container)
			for _, item in ipairs(items) do
				if item.count > 0 then
					item:moveInto(cont_inv)
				end
			end
		end
	else
		print("Error: failed to get inventory of container, container is ", tostring(container))
	end
	return have_spell
end

function transferItemsToContainer(actor, container)
	if move_selected_items_to_container(actor, container) then
		-- hide/open container to update it, recursion is avoided by removing spells in moveSelectedItemsToContainer() --
		actor:sendEvent("SetUiMode", {''})
		actor:sendEvent("SetUiMode", {mode = "Container", target = container})
	end
end

return {
	interfaceName = "TransferItemsSpells",
	interface = {
		version = 1,
		selectedItems = function(actor)
			return selected_items(actor)
		end,
		moveSelectedItemsToContainer = function(actor, container)
			return move_selected_items_to_container(actor, container)
		end
	},
	eventHandlers = {
		transferItemsToContainer = function(data)
			transferItemsToContainer(data.actor, data.container)
		end
	}
}

