--[[
	Directional Sunrays v1.2
	By Kynesifnar
]]

local config = require("DirectionalSunrays.config")
local glowInTheDahrk = require("GlowInTheDahrk.interop")
local glowInTheDahrkConfig = require("GlowInTheDahrk.config")

local ffi = require("ffi")
local TES3_WeatherController_updateSun = ffi.cast("void(__thiscall*)(void*, float)", 0x43FF80)		-- Code given by G7 on 8/17/2025 in MMC's MWSE channel

local sunriseStart = 6
local sunriseMidPoint = 7
local sunsetMidPoint = 19.125
local sunsetStop = 21.25

local radianOuterLimit = math.rad(config.outerLimit)
local radianInnerLimit
if config.innerLimit < config.outerLimit then radianInnerLimit = math.rad(config.innerLimit)
else radianInnerLimit = radianOuterLimit end

local northMarkerMatrix = tes3matrix33.new()
northMarkerMatrix:fromEulerXYZ(0, 0, 0)

-- This function gives every sunray NiTriShape a unique material upon entering a cell so that their alphas can be changed independently
---@param e cellChangedEventData
local function cloneSunrayMaterials(e)
	if glowInTheDahrkConfig.addInteriorSunrays and not e.cell.isOrBehavesAsExterior then
		for reference,meshData in pairs(glowInTheDahrk.trackedReferences) do
			---@cast reference tes3reference
			if meshData ~= false and not config.ignoredMeshes[reference.baseObject.id:lower()] then
				local sceneNode = reference.sceneNode
				if sceneNode then
					local switchNode = sceneNode.children[meshData.switchChildIndex]
					if switchNode then
						local interiorNode = switchNode.children[meshData.indexInDay]
						if meshData.interiorRayIndex then
							local rays = interiorNode.children[meshData.interiorRayIndex]
							for ray in table.traverse({ rays }) do										-- Iterate through all of the sunray NiTriShapes
								---@cast ray niTriShape
								if ray:isOfType(ni.type.NiTriShape) then								-- Just to be safe
									---@cast ray niTriShape
									ray.materialProperty = ray.materialProperty:clone()					-- New materials must be made for every ray so that each ray can have its own alpha value
								end
							end
						end
					end
				end
			end
		end
	end
end

---@param e cellChangedEventData
local function getNorthAngle(e)
	if not e.cell.isOrBehavesAsExterior then
		for ref in e.cell:iterateReferences(tes3.objectType.static) do
			if ref.baseObject.id == "NorthMarker" then
				northMarkerMatrix:fromEulerXYZ(0, 0, -ref.orientation.z)	-- The orientation must be made negative, otherwise values that are not multiples of Pi cause the code to treat the sun as if it is on the opposite side of the sky
				return
			end
		end
	end

	northMarkerMatrix:fromEulerXYZ(0, 0, 0)
end

local function updateSun()
    local this = ffi.cast("void*", mwse.memory.addressOf(tes3.worldController.weatherController))
    TES3_WeatherController_updateSun(this, tes3.worldController.hour.value)		-- Updates tes3.worldController.weatherController.sceneSunVis
end

---@param e simulateEventData
local function disableSunrays(e)
	if glowInTheDahrkConfig.addInteriorSunrays and not tes3.player.cell.isOrBehavesAsExterior then
		local gameHour = tes3.worldController.hour.value
		if gameHour >= sunriseStart and gameHour <= sunsetStop then
			updateSun()
			local sunPosition = tes3.worldController.weatherController.sceneSunVis.translation
			local sunAzimuth = sunPosition * tes3vector3.new(1, 1, 0)

			local dimmer = glowInTheDahrk.getCurrentWeatherBrightness()
			if gameHour <= sunriseMidPoint then
				dimmer = dimmer * math.remap(gameHour, sunriseStart, sunriseMidPoint, 0.0, 1.0)
			elseif sunsetMidPoint <= gameHour then
				dimmer = dimmer * math.remap(gameHour, sunsetStop, sunsetMidPoint, 0.0, 1.0)
			end

			for reference,meshData in pairs(glowInTheDahrk.trackedReferences) do
				---@cast reference tes3reference
				if meshData ~= false and not config.ignoredMeshes[reference.baseObject.id:lower()] then
					local sceneNode = reference.sceneNode
					if sceneNode then
						local switchNode = sceneNode.children[meshData.switchChildIndex]
						if switchNode then
							local interiorNode = switchNode.children[meshData.indexInDay]
							if meshData.interiorRayIndex then
								local rays = interiorNode.children[meshData.interiorRayIndex]
								for ray in table.traverse({ rays }) do							-- Iterate through all of the sunray NiTriShapes
									---@cast ray niTriShape
									if ray:isOfType(ni.type.NiTriShape) then					-- Just to be safe
										---@cast ray niTriShape

										local angleDifference
										if not config.nonstandardMeshes[reference.baseObject.id:lower()] or not ray.worldTransform.rotation == tes3matrix33.identity() then			-- If rotations have been applied to the shape or its parents (as in GitD's own meshes), then it is assumed that they suffice for finding the rayVector
											local rayVector = (ray.worldTransform.rotation * northMarkerMatrix):getForwardVector() * tes3vector3.new(1, 1, 0) 						-- Find the direction of the sunray in the xy-plane
											angleDifference = rayVector:angle(sunAzimuth)																							-- Find the angle formed by the sunray versus the sun, ignoring the sun's altitude
										else																		-- Otherwise, all of the vertices are iterated over to find the rayVector manually. This is more reliable, but much more costly.
											local highestVertex = tes3vector3.new(0, 0, -math.huge)
											local lowestVertex = tes3vector3.new(0, 0, math.huge)

											for _,vertex in pairs(ray.vertices) do
												local worldPosition = ray.worldTransform.rotation * vertex			-- Since vertices are not being compared with those in other shapes, only the rotation is relevant

												if worldPosition.z > highestVertex.z then
													highestVertex = worldPosition
												end

												if worldPosition.z < lowestVertex.z then
													lowestVertex = worldPosition
												end
											end

											local rayX = highestVertex.x - lowestVertex.x
											local rayY = highestVertex.y - lowestVertex.y
											local rayVector = northMarkerMatrix * tes3vector3.new(rayX, rayY, 0)
											angleDifference = rayVector:angle(sunAzimuth)
										end

										if angleDifference > radianOuterLimit then
											ray.materialProperty.alpha = 0									-- If the angle is greater than the outer limit, do not show the ray
										elseif angleDifference > radianInnerLimit then
											ray.materialProperty.alpha = (-1 / (radianOuterLimit - radianInnerLimit)) * (angleDifference - radianOuterLimit)	-- If the angle is between the limits, show the ray at partial intensity
										else
											ray.materialProperty.alpha = 1									-- If the angle is less than the inner limit, show the ray at full intensity
										end
										ray.materialProperty.alpha = ray.materialProperty.alpha * dimmer	-- GitD's dimming of the alpha during sunrise and sunset is overwritten by the conditions above, so it has to be reapplied here

										ray:updateProperties()
									end
								end
							end
						end
					end
				end
			end
		end
	end
end

-- Setup MCM
dofile("DirectionalSunrays.mcm")

event.register(tes3.event.loaded, function()
	if config.enabled == true then
		radianOuterLimit = math.rad(config.outerLimit)
		if config.innerLimit < config.outerLimit then radianInnerLimit = math.rad(config.innerLimit)
		else radianInnerLimit = radianOuterLimit end

		sunriseStart, sunriseMidPoint, _, _, sunsetMidPoint, sunsetStop = glowInTheDahrk.getSunHours()

		event.register(tes3.event.simulate, disableSunrays, { priority = -5, unregisterOnLoad = true })
		event.register(tes3.event.cellChanged, getNorthAngle, { unregisterOnLoad = true })
		event.register(tes3.event.cellChanged, cloneSunrayMaterials, { unregisterOnLoad = true })
	end
end)