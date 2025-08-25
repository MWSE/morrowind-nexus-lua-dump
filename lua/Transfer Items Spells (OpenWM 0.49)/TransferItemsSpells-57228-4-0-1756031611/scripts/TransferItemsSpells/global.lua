local core = require("openmw.core")
local types = require("openmw.types")

local function selected_items(actor)
	local items = {}
	local active_spells =  types.Actor.activeSpells(actor)
	local spells_to_remove = {}
	for _, active_spell in pairs(types.Actor.activeSpells(actor)) do
		if active_spell.id == "transfer books" then
			table.insert(spells_to_remove, active_spell.activeSpellId)
			for _, item in ipairs(types.Actor.inventory(actor):getAll(types.Book)) do
				if not item.type.record(item).isScroll then
					table.insert(items, item)
				end
			end
		end
		if active_spell.id == "transfer ingredients" then
			table.insert(spells_to_remove, active_spell.activeSpellId)
			for _, item in ipairs(types.Actor.inventory(actor):getAll(types.Ingredient)) do
				table.insert(items, item)
			end
		end
		if active_spell.id == "transfer potions" then
			table.insert(spells_to_remove, active_spell.activeSpellId)
			active_spells:remove(active_spell.activeSpellId)
			for _, item in ipairs(types.Actor.inventory(actor):getAll(types.Potion)) do
				table.insert(items, item)
			end
		end
		if active_spell.id == "transfer projectiles" then
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
			table.insert(spells_to_remove, active_spell.activeSpellId)
			for _, item in ipairs(types.Actor.inventory(actor):getAll(types.Book)) do
				if item.type.record(item).isScroll then
					table.insert(items, item)
				end
			end
		end
		if active_spell.id == "transfer miscellaneous" then
			table.insert(spells_to_remove, active_spell.activeSpellId)
			for _, item in ipairs(types.Actor.inventory(actor):getAll(types.Miscellaneous)) do
				if not (item.type.record(item).isKey or
				string.find(item.recordId, "gold_") or
				string.find(item.recordId, "_soulgem_")) then
					table.insert(items, item)
				end
			end
		end
		if active_spell.id == "transfer keys" then
			table.insert(spells_to_remove, active_spell.activeSpellId)
			for _, item in ipairs(types.Actor.inventory(actor):getAll(types.Miscellaneous)) do
				if item.type.record(item).isKey then
					table.insert(items, item)
				end
			end
		end
		if active_spell.id == "transfer weapons" then
			table.insert(spells_to_remove, active_spell.activeSpellId)
			for _, item in ipairs(types.Actor.inventory(actor):getAll(types.Weapon)) do
				if not (item.type.record(item).type == types.Weapon.TYPE.Arrow or
				item.type.record(item).type == types.Weapon.TYPE.Bolt or
				item.type.record(item).type == types.Weapon.TYPE.MarksmanThrown) then
					table.insert(items, item)
				end
			end
		end
		for _, spell_id in ipairs(spells_to_remove) do
			types.Actor.activeSpells(actor):remove(spell_id)
		end
	end
	return items
end

local function move_selected_items_to_container(actor, container)
	local count = 0
	local cont_inv = types.Container.inventory(container)
	if cont_inv then
		local selected_items = selected_items(actor)
		if #selected_items > 0 then
			for _, item in ipairs(selected_items) do
				if item.count > 0 then
					item:moveInto(cont_inv)
				end
			end
			return true
		end
	else
		print("Error: failed to get inventory of container, container is ", tostring(container))
	end
	return false
end

function transferItemsToContainer(actor, container)
	if move_selected_items_to_container(actor, container) then
		-- hide/open container to update it, recursion is avoided by removing spells in moveSelectedItemsToContainer() --
		actor:sendEvent("SetUiMode", {''})
		core.sound.playSound3d("item misc down", container)
		actor:sendEvent("SetUiMode", {mode = "Container", target = container})
	end
end

return {
	eventHandlers = {
		transferItemsToContainer = function(data)
			transferItemsToContainer(data.actor, data.container)
		end
	}
}

