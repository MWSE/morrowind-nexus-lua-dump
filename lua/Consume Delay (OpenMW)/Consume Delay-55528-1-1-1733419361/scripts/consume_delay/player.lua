local types = require("openmw.types")
local Actor = types.Actor
local core = require("openmw.core")
local self = require("openmw.self")
local async = require("openmw.async")

local consumeTime

-- This is the consume delay (game time in seconds):
local consumeDelay = 30

local Inventory = Actor.inventory(self.object)

local function delayCheck()
	
	-- if time has not come, we will re-check when it will be the case
	local timeLeft = consumeTime - core.getGameTime()
	if timeLeft > 0 then
		async:newUnsavableGameTimer(timeLeft, delayCheck)
		return
	end

	-- So now we allow the player to consume again (we are going to move back the potions & ingredients to his inventory):
	
	core.sendGlobalEvent('CD_MoveBack', {
		player = self,
	})
	
	consumeTime = nil
end

local function onConsume(item)

	local potions = Inventory:getAll(types.Potion)
	local ingredients = Inventory:getAll(types.Ingredient)
	
	-- if there is no other potion and ingredient, there is nothing to do:
	if #potions < 1 and #ingredients < 1 then return end
	
	-- So now we have to move away the potions and ingredients
	-- Order to global.lua to move away the potions and ingredients:
	core.sendGlobalEvent('CD_Move', {
		potions = potions,
		ingredients = ingredients,
	})
	
	-- Now we are going to check when the player can consume again
	-- consumeTime = time when the player is allowed to consume again
	consumeTime = core.getGameTime() + consumeDelay
	async:newUnsavableGameTimer(consumeDelay, delayCheck)
end

local function onSave()
    return {
		CT = consumeTime,
    }
end

local function onLoad(data)
	if data then
		consumeTime = data.CT
		-- if we have to move away the potions and ingredients, we are going to check if the time has come
		if consumeTime then
			delayCheck()
		end
	end
end

return {
    engineHandlers = {
		onLoad = onLoad,
		onSave = onSave,
		onConsume = onConsume,
    },
    eventHandlers = {
    }
}

