local nearby = require('openmw.nearby')
local core = require('openmw.core')
local util = require('openmw.util')
local self = require('openmw.self')
local storage = require('openmw.storage')
local I = require('openmw.interfaces')

local t = 0.0
local velocity = nil
local gravity = util.vector3(0,0, -60)
local thrower = nil
local recordId = nil
local active = false
local rotateFactor = math.random(-0.2, 0.2)
local collided = false
local worldRef = nil
local maxDt = 1 / 20

local luaPhysicsObject = nil

local settings = storage.globalSection('SettingsPotionThrowerGameplay')

local function luaCollision(collision)
	if collided then return end
	collided = true
	core.sendGlobalEvent("ResolveCollision", { collision = collision.hitObject, thrower = thrower, object = self, worldRef = worldRef, recordId = recordId})
end

local function doPhysics(data)
	velocity = data.velocity
	thrower = data.thrower
	recordId = data.recordId
	worldRef = data.worldRef
	active = true
	if I.LuaPhysics ~= nil and settings:get('LuaPhysics') then
		luaPhysicsObject = I.LuaPhysics.physicsObject
		luaPhysicsObject:reInit()
		luaPhysicsObject:applyImpulse(data.velocity * 10, data.thrower.object)
		luaPhysicsObject.onCollision:addEventHandler(luaCollision)
		luaPhysicsObject.angularVelocity = util.vector3(math.random(-1000, 1000), math.random(-1000, 1000), math.random(-1000, 1000))
		return
	end
end

local function onUpdate(dt)
	if not self.enabled or not active then return end
	if luaPhysicsObject ~= nil then return end

	if dt > maxDt then
		dt = maxDt
	end

	t = t + dt

	local destination = self.position + velocity * t + gravity * t^2

	local rotation = self.rotation * util.transform.rotateY(0.25)

	core.sendGlobalEvent("MoveObject", { object = self, destination = destination, rotation = rotation, active = active })

	local collision = nearby.castRay(self.position, destination, {
	    ignore = { 
		self 
	     } })

	-- self.position = destination

	if collision.hit and not collided then 
		if t < 1.0 and collision.hitObject == thrower then
			return
		end
		collided = true
		-- print(tostring(collision.hitObject))
		core.sendGlobalEvent("ResolveCollision", { collision = collision.hitObject, thrower = thrower, object = self, worldRef = worldRef, recordId = recordId})
	end
end

local function cleanUp()
	active = false
	if settings:get('LuaPhysics') and luaPhysicsObject ~= nil then
		core.sendGlobalEvent("LuaPhysics_RemoveObject",{
   			object = self
		})
	else
		core.sendGlobalEvent("RemoveObject",{
			object = self
		})
	end
end

return {
	engineHandlers = { onUpdate = onUpdate },
	eventHandlers = { DoPhysics = doPhysics, CleanUp = cleanUp }
}


