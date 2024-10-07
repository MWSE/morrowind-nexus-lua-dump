local T = require('openmw.types')

local function hasOwner(object, skipSetting)
    if (object.ownerRecordId ~= nil) then
        return true
    elseif (object.ownerFactionId ~= nil) then
        return true
    end
    return false
end

local function AddItem(itemId, count, actor)
    if not itemId then return nil end
	local world = require('openmw.world')
    local item = world.createObject(itemId, count)
    item:moveInto(T.Actor.inventory(actor))
    return item
end

local function Player()
	World = require('openmw.world')
	if World and World.players and World.players[1] then
		return World.players[1]
	end
	Self = require('openmw.self')
	if Self.object and Self.object.recordId == 'player' then
		return Self.object
	end
end

function dump(obj, indent)
	indent = indent or ""
	if type(obj) ~= "table" then
		print(indent .. tostring(obj) .. " (" .. type(obj) .. ")")
		return
	end
	print(indent .. tostring(obj) .. " (table)")
	for k, v in pairs(obj) do
		if type(v) == "table" then
			print(indent .. "  " .. tostring(k) .. ":")
			dump(v, indent .. "    ")
		else
			print(indent .. "  " .. tostring(k) .. ": " .. tostring(v) .. " (" .. type(v) .. ")")
		end
	end
end


M = {
	Dump = dump,
	AddItem = AddItem,
	Player = Player,
	Symbol = {
		ring_of_ingredients = 'ring_of_storing_ingredients',

		Settings = {
			AllwaysPickUp = 'stin_pick_up_ring_always',
			PollInterval = 'stin_interval',
			Halt = 'stin_halt',
		},

		PlayerSection = {
			SettingsPage = 'StoreIngredientsRing',
			SettingsPageG1 = 'StoreIngredientsRingG1',
			L10Ncontext = 'StoreIngredientsRing',
		},

	}
}

M.settings = {
		isHalted = function ()
			S = require('openmw.storage')
			print(" storage type ... ", S.playerSection)
			if S.playerSection then
				SettingsG1 = S.playerSection(M.Symbol.PlayerSection.SettingsPageG1)
				return SettingsG1:get(M.Symbol.Settings.Halt)
			end
			return false
		end
	}

return M
