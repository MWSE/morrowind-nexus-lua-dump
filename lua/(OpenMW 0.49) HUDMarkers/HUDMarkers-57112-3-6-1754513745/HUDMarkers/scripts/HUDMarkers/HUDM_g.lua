local computeBoundingBoxes = false

local storage = require('openmw.storage')
local modData = storage.globalSection('HPBars')


local async = require('openmw.async')
local types = require('openmw.types')
local core = require('openmw.core')
local acti = require("openmw.interfaces").Activation
local util = require('openmw.util')
local world = require('openmw.world')
local I = require("openmw.interfaces")
local playerProgress = {}
local queue = {}
local lastObject = nil
local lastId = nil


local function HPBars_VFX(data)
	local cell = data[1].cell
	local pos = data[2]
	local effect = core.magic.effects.records[9]
	print(effect.castStatic)
	local fx = world.createObject("ED_RFD_DetectEnchantment", 1)
	fx:teleport(cell,pos)
	--world.vfx.spawn("Meshes/OJ/ED/ED_RFD_DetectEnchantment.nif", pos)
end
local function HUDM_resolveAll(data)
	local player = data[1]
	local todo = data[2]
	--for _,cont in pairs(player.cell:getAll()) do
	for _,cont in pairs(todo) do
		if not cont.type.inventory(cont):isResolved() then
			cont.type.inventory(cont):resolve()
			if I.FreshLoot then
				if I.FreshLoot.processLoot then
					I.FreshLoot.processLoot(cont, player)
				else
					print("PLEASE UPDATE FRESHLOOT")
				end
			end
		end
	end
	player:sendEvent("HUDM_resolveRefresh")
end

local function activateActor(actor, player)
	player:sendEvent("HUDM_recheckActor", actor)
end

local function activateContainer(cont, player)
	player:sendEvent("HUDM_recheckContainer", cont)
end


local function activateItem(item, player)
	print(11111)
	player:sendEvent("HUDM_recheckItem", item)
end
	
	

--acti.addHandlerForType(types.Container, activateContainer)
--acti.addHandlerForType(types.NPC, activateActor)
--acti.addHandlerForType(types.Creature, activateActor)
--acti.addHandlerForType(types.Light, activateItem)
local function onActivate(object, player)
	player:sendEvent("HUDM_recheckObject", object)
end

return {
engineHandlers = {
	onActivate = onActivate,
	},
    eventHandlers = {
		HUDM_VFX = HPBars_VFX,
		HUDM_resolveAll = HUDM_resolveAll
    }
}

--(-0.25228118896484375, -18.89730072021484375, 91.965118408203125)
--        (170.847442626953125, 81.17101287841796875, 67.776947021484375)