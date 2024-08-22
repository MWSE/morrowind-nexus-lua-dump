local nearby = require('openmw.nearby')
local ui = require('openmw.ui')
local self = require('openmw.self')
local async = require('openmw.async')
local types = require('openmw.types')
local input = require('openmw.input')
local camera = require('openmw.camera')
local core = require('openmw.core')
local storage = require('openmw.storage')
local util = require('openmw.util')
local I = require("openmw.interfaces")
local HarvestedCorpses = storage.playerSection("IsHarvested")
HarvestedCorpses:setLifeTime(storage.LIFE_TIME.Temporary)
local function RayCast()
	local position = nearby.castRay(camera.getPosition(), camera.getPosition() + camera.viewportToWorldVector(util.vector2(0.5, 0.5))* 300, {collisionType=nearby.COLLISION_TYPE.HeightMap + nearby.COLLISION_TYPE.Water + nearby.COLLISION_TYPE.World,radius = 10,})
	core.sendGlobalEvent("GetNavmeshPosition", position.hitPos)
end

local function SetPosition(key)
          if key.code == input.KEY.LeftCtrl then
                core.sendGlobalEvent("SetPropPosition")
            end
end

local function GetPropID(obj)
	PropID = obj	
	print(PropID)
end

local function SendNavmeshPosition(position)
	core.sendGlobalEvent("GetNavmeshPosition", position)
	
end

return { 
eventHandlers = { GetPropID = GetPropID },
engineHandlers = {onUpdate = RayCast, onKeyPress = SetPosition}

 }
