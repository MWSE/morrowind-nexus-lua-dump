local camera = require('openmw.camera')
storage = require('openmw.storage')
types = require('openmw.types')
NPC = require('openmw.types').NPC
core = require('openmw.core')
I = require("openmw.interfaces")
self = require("openmw.self")
nearby = require('openmw.nearby')
camera = require('openmw.camera')
Camera = require('openmw.interfaces').Camera
util = require('openmw.util')
ui = require('openmw.ui')
auxUi = require('openmw_aux.ui')
async = require('openmw.async')
KEY = require('openmw.input').KEY
input = require('openmw.input')
v2 = util.vector2
MODNAME = "EasyHarvest"
playerSection = storage.playerSection('SettingsPlayer'..MODNAME)
local settings = require("scripts.EasyHarvest.EasyHarvest_settings")
COLLECT_ITEMS = playerSection:get("CollectItems")
ORGANIC_EXTRA_RANGE = playerSection:get("OrganicExtraRange")
COLLECT_CONTAINERS = playerSection:get("CollectContainers")
COLLECT_CORPSES = playerSection:get("CollectCorpses")
CONTAINER_DELAY = playerSection:get("ContainerDelay")
local quickLootThrottle = core.getRealTime()

local currentControlScheme = nil
local currentActivateKey = nil
local allActivateKeys = {}
local keysThisFrame = {}

local holdHarvest = true
local shotgunHarvest = true

local organicContainers = {
	barrel_01_ahnassi_drink=true,
	barrel_01_ahnassi_food =true,
	com_chest_02_fg_supply =true,
	com_chest_02_mg_supply =true,
	flora_treestump_unique =true,
}


local function harvest()

	if I.UI.getMode() then
		return
	end
	
	
	local cameraPos = camera.getPosition()
	local iMaxActivateDist = core.getGMST("iMaxActivateDist")+0.1
	local activationDistance = iMaxActivateDist + camera.getThirdPersonDistance();
	local telekinesis = types.Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.Telekinesis);
	if (telekinesis) then
		activationDistance = activationDistance + (telekinesis.magnitude * 22);
	end
	activationDistance = activationDistance + 0.1 + ORGANIC_EXTRA_RANGE
	local res = nearby.castRenderingRay(
		cameraPos,
		cameraPos + camera.viewportToWorldVector(v2(0.5,0.5)) * activationDistance,
		{ ignore = self }
	)
	if res.hitObject then
		if COLLECT_ITEMS 
		and types.Item.objectIsInstance(res.hitObject)
		and (res.hitPos-cameraPos):length() < activationDistance - ORGANIC_EXTRA_RANGE
		then
			core.sendGlobalEvent("HoldHarvest_harvest",{self,res.hitObject})
			return
		elseif res.hitObject.type == types.Container then
			if types.Container.record(res.hitObject).isOrganic
			and not organicContainers[res.hitObject.recordId] 
			and (not types.Container.content(res.hitObject):isResolved() or types.Container.content(res.hitObject):getAll()[1])
			then
				core.sendGlobalEvent("HoldHarvest_harvest",{self,res.hitObject})
				return
			elseif COLLECT_CONTAINERS
			and not types.Container.record(res.hitObject).isOrganic
			and I.QuickLoot
			then
				local now = core.getRealTime()
				if now > quickLootThrottle+CONTAINER_DELAY then
					quickLootThrottle = now
					I.QuickLoot.lootItem()
				end
			end
		elseif COLLECT_CORPSES and types.Actor.objectIsInstance(res.hitObject) and I.QuickLoot then
			local now = core.getRealTime()
			if now > quickLootThrottle+CONTAINER_DELAY then
				quickLootThrottle = now
				I.QuickLoot.lootItem()
			end
		end
	end
	--activationDistance = activationDistance+30
	
	if playerSection:get("ShotgunHarvest1") or playerSection:get("ShotgunHarvest2") then
		-- try a radius raycast:
		local res = nearby.castRay(
			cameraPos ,
			cameraPos + camera.viewportToWorldVector(v2(0.5,0.5)) * activationDistance,
			{ radius = 10, collisionType= nearby.COLLISION_TYPE.VisualOnly}
		)
		
		if res.hitObject and res.hitObject.type == types.Container and types.Container.record(res.hitObject).isOrganic and not organicContainers[res.hitObject.recordId] and (not types.Container.content(res.hitObject):isResolved() or types.Container.content(res.hitObject):getAll()[1]) then
			core.sendGlobalEvent("HoldHarvest_harvest",{self,res.hitObject})
			if playerSection:get("ShotgunReturn") then
				return
			end
		end
		
		-- shotgun1
		if playerSection:get("ShotgunHarvest1") then
			local numPoints = 8
			local radius = 0.011
			for i = 1, numPoints do
				local angle = (2 * math.pi / numPoints) * i
				local x = 0.5 + radius * math.cos(angle)
				local y = 0.5 + radius * math.sin(angle)*16/9
				local res = nearby.castRenderingRay(
					cameraPos ,
					cameraPos + camera.viewportToWorldVector(v2(x,y)) * activationDistance,
					{ ignore = self }
				)
				
				if res.hitObject and res.hitObject.type == types.Container and types.Container.record(res.hitObject).isOrganic and not organicContainers[res.hitObject.recordId] and (not types.Container.content(res.hitObject):isResolved() or types.Container.content(res.hitObject):getAll()[1]) then
					core.sendGlobalEvent("HoldHarvest_harvest",{self,res.hitObject})
					if playerSection:get("ShotgunReturn") then
						return
					end
				end
			end
		end
		
		-- shotgun2
		if playerSection:get("ShotgunHarvest2") then
			local numPoints = 12
			local radius = 0.022
			for i = 1, numPoints do
				local angle = (2 * math.pi / numPoints) * i
				local x = 0.5 + radius * math.cos(angle)
				local y = 0.5 + radius * math.sin(angle)*16/9
				local res = nearby.castRenderingRay(
					cameraPos,
					cameraPos + camera.viewportToWorldVector(v2(x,y)) * activationDistance,
					{ ignore = self }
				)
				
				if res.hitObject and res.hitObject.type == types.Container and types.Container.record(res.hitObject).isOrganic and not organicContainers[res.hitObject.recordId] and (not types.Container.content(res.hitObject):isResolved() or types.Container.content(res.hitObject):getAll()[1]) then
					core.sendGlobalEvent("HoldHarvest_harvest",{self,res.hitObject})
					if playerSection:get("ShotgunReturn") then
						return
					end
				end
			end
		end
	end
end

function onFrame(dt)
	if not playerSection:get("HoldHarvest") then
		return
	end
	keysThisFrame = {}
	if not currentActivateKey then
		return
	end
	harvest()
end

local function tableLength(t)
	local i=0
	for _ in pairs(t) do
		i=i+1
	end
	return i
end

local function averageValue(t)
	local sum = 0
	local count = 0
	for _,v in pairs(t) do
		sum=sum+v
		count = count + 1
	end
	return sum/math.max(1,count)
end

input.registerTriggerHandler('Activate', async:callback(function()

	if shotgunHarvest then
		harvest()
	end

	if not playerSection:get("HoldHarvest") then
		return
	end
	if currentActivateKey then 
		return
	end
	
	local mostLikelyKey = nil

	for key, value in pairs(allActivateKeys) do
		allActivateKeys[key] = value * 0.9
	end
	
	local highestProbability = averageValue(allActivateKeys)
	--print("highestProbability", highestProbability)
	--print("allActivateKeys:")
	--for key, probability in pairs(allActivateKeys) do
	--	print(key,probability)
	--end
	--print("keysthisframe:")
	
	for key in pairs(keysThisFrame) do
		--print(key)
		allActivateKeys[key] = (allActivateKeys[key] or 0) + 0.05
		if allActivateKeys[key] > highestProbability then
			highestProbability = allActivateKeys[key] or 0
			mostLikelyKey = key
		end
	end
	
	if mostLikelyKey then
		allActivateKeys[mostLikelyKey] = allActivateKeys[mostLikelyKey] + 0.05
	end
	currentActivateKey = mostLikelyKey
	--if currentActivateKey then
	--	print("activated")
	--end
end))

function onKeyPress (key)
	if not playerSection:get("HoldHarvest") then
		return
	end
	keysThisFrame[key.code] = true
	quickLootThrottle = core.getRealTime()+0.15 + math.max(0,0.12-CONTAINER_DELAY)
	if currentControlScheme ~= "mouse+keyboard" then
		allActivateKeys = {}
		currentControlScheme = "mouse+keyboard"
	end
end

function onKeyRelease(key)
	if not playerSection:get("HoldHarvest") then
		return
	end
	if key.code == currentActivateKey then
		currentActivateKey = nil
	end
end

function onControllerButtonPress(key)
	if not playerSection:get("HoldHarvest") then
		return
	end
	key = 10000+key
	keysThisFrame[key] = true
	if currentControlScheme ~= "gamepad" then
		allActivateKeys = {}
		currentControlScheme = "gamepad"
	end
end

function onControllerButtonRelease(key)
	if not playerSection:get("HoldHarvest") then
		return
	end
	key = 10000+key
	if key == currentActivateKey then
		currentActivateKey = nil
	end
end

function onMouseButtonPress(key)
	if not playerSection:get("HoldHarvest") then
		return
	end
	key = 1000+key
	keysThisFrame[key] = true
	if currentControlScheme ~= "mouse+keyboard" then
		allActivateKeys = {}
		currentControlScheme = "mouse+keyboard"
	end
end

function onMouseButtonRelease(key)
	if not playerSection:get("HoldHarvest") then
		return
	end
	key = 1000+key
	if key == currentActivateKey then
		currentActivateKey = nil
	end
end


return {  
	engineHandlers = {
		onFrame = onFrame,
		onKeyPress = onKeyPress,
		onKeyRelease = onKeyRelease,
		onControllerButtonPress = onControllerButtonPress,
		onControllerButtonRelease = onControllerButtonRelease,
		onMouseButtonPress = onMouseButtonPress,
		onMouseButtonRelease = onMouseButtonRelease,
    },
}