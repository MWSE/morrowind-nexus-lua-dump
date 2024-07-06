local acti = require("openmw.interfaces").Activation
local types = require('openmw.types')
local world = require('openmw.world')
local aux_util = require('openmw_aux.util')
local MOD_NAME = "UnpausedTradeskills"
local storage = require('openmw.storage')
local globalSection = storage.globalSection("SettingsGlobal" .. MOD_NAME)
local async = require('openmw.async')
local I = require("openmw.interfaces")
local view = aux_util.deepToString
local playerModes = {}

local slowMoMadness = false
local durationSlowdownCurve = {
[1] = 1,
[2] = 0.99,
[3] = 0.97,
[4] = 0.94,
[5] = 0.9,
[6] = 0.85,
[7] = 0.80,
[8] = 0.75,
[9] = 0.70,
[10] = 0.65,
[11] = 0.60,
[12] = 0.55,
[13] = 0.5,
[14] = 0.45,
[15] = 0.4,
}



local function updateSettings()
	unpauseUIs = {
		-- ["Book"] = true,
		-- ["Scroll"] = true,
		-- ["Interface"] = true,
		-- ["Inventory"] = true,
		-- ["MainMenu"] = true,
		-- ["Rest"] = true,
		-- ["QuickKeysMenu"] = true,
		-- ["Journal"] = true,
		-- ["Name"] = true,
		-- ["Race"] = true,
		-- ["Class"] = true,
		-- ["ClassPick"] = true,
		-- ["ClassCreate"] = true,
		-- ["Birth"] = true,
		-- ["ClassGenerate"] = true,
		-- ["Review"] = true,
		-- ["Levelup"] = true,
		-- ["Jail"] = true,
		-- ["Companion"] = true,
		
		["Dialogue"] = not globalSection:get("pauseOnDialogue"),
		["Container"] = not globalSection:get("pauseOnContainer"),
		["SpellBuying"] = true,
		["SpellCreation"] = true,
		["Barter"] = true,
		["Alchemy"] = true,
		["Recharge"] = true,
		["Enchanting"] = true,
		["Training"] = true,
		["MerchantRepair"] = true,
		["Repair"] = true,
		["Travel"] = true,
	}
end
updateSettings()
--local function activateContainer(cont, player)
--	player:sendEvent("TakeAll_openedContainer", {cont, player})
--end



local function unpackTable(t)
	r = "" 
	for a,b in pairs(t) do
		r = r..a.."="..tostring(b)..", "
	end
	return r
end

local function playerChangesMode(data)
	--print(data.player, data.mode)
	if data.mode == nil then
		playerModes[data.player.id] = nil
	else
		local shortestBuff = 99999
		if globalSection:get("slowMoMadness") then
			for a,b in pairs(types.Actor.activeSpells(data.player)) do
				for c,d in pairs(b.effects) do
					print(d.id,d.hasDuration,d.duration)
					if (d.id == "fortifyattribute" or d.id == "fortifyskill") and d.duration then
						shortestBuff = math.min(shortestBuff,d.duration)
					end
				end
			end
		end
		playerModes[data.player.id] = {mode = data.mode, shortestBuff = shortestBuff}
		--print(shortestBuff)
	end
	if world.getPausedTags().ui then
		local unpause = true
		local shortestBuff = 99999
		for i,m in pairs(playerModes) do
			--print(m,unpauseUIs[m])
			if not unpauseUIs[m.mode] then
				unpause = false
			else
				shortestBuff = math.min(shortestBuff,m.shortestBuff)
			end
		end
		if unpause then
			world.unpause("ui")
			if shortestBuff ~= 99999 then
				local slowDown = 1
				for a,b in ipairs(durationSlowdownCurve) do
					if shortestBuff >= a then
						slowDown = b
					end
				end
				world.setSimulationTimeScale(math.min(1,(math.max(0.05, slowDown))))
				--print(world.getSimulationTimeScale())
			else
				world.setSimulationTimeScale(1)
				--print(1)
			end
		else
		--	world.pause("ui") -- game does this automatically?
			world.setSimulationTimeScale(1)
			--print(1)
		end
	else
		world.setSimulationTimeScale(1)
		--print(1)
	end
end


I.Settings.registerGroup {
	key = "SettingsGlobal" .. MOD_NAME,
	l10n = MOD_NAME,
	name = "",
	page = MOD_NAME,
	description = "",
	permanentStorage = true,
	settings = {
		
		{
			key = "pauseOnDialogue",
			name = "pauseOnDialogue",
			description = "",
			default = false,
			renderer = 'checkbox',
		},
		{
			key = "pauseOnContainer",
			name = "pauseOnContainer",
			description = "",
			default = true,
			renderer = 'checkbox',
		},
		{
			key = "slowMoMadness",
			name = "Slow Mo Relaxed Tradeskills",
			description = "Slows down time if your shortest fortify spell is pretty long",
			default = false,
			renderer = 'checkbox',
		},
	}
}
globalSection:subscribe(async:callback(updateSettings))

return {
	eventHandlers = {
		UnpausedTradeskills_playerChangesMode = playerChangesMode,
	},
	engineHandlers = { 
		onUpdate = onUpdate,
	},
}