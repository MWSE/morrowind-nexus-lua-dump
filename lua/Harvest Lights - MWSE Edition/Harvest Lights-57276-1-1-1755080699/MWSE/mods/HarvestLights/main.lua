--[[
	Harvest Lights - MWSE Edition v1.1
	By Kynesifnar
]]

local config = require("HarvestLights.config").settings

local containerLights = { }

local function logContainerLightsContents()
	mwse.log("[Harvest Lights] Final Container and Light Sets:")

	local count = 1

	for _,set in pairs(containerLights) do
		mwse.log("Container Set #" .. count .. ":")

		for _,container in pairs(set.containers) do
			mwse.log(container)
		end

		mwse.log("Light Set #" .. count .. ":")
		for _,light in pairs(set.lights) do
			mwse.log(light)
		end

		count = count + 1
	end
end

local function makeContainerLightsTable()
	containerLights = { }

	local containerSets = { }
	local lightSets = { }

	if config.debug then mwse.log("[Harvest Lights] Debug:") end
	if config.debug then mwse.log("Detected Container Sets:") end

	for containerSet in config.containerLights:gmatch([["%C+"%s*;]]) do
		if config.debug then mwse.log(containerSet) end
		table.insert(containerSets, containerSet)
	end

	if config.debug then mwse.log("Detected Light Sets:") end

	for lightSet in config.containerLights:gmatch([[;%s+"%C+"]]) do
		if config.debug then mwse.log(lightSet) end
		table.insert(lightSets, lightSet)
	end

	if not containerSets or not lightSets then
		containerLights = nil
		mwse.log("[Harvest Lights] Error: Containers and lights are not formatted correctly.")
		return
	end

	if #containerSets ~= #lightSets then
		containerLights = nil
		mwse.log("[Harvest Lights] Error: Number of detected container sets is different from the number of detected light sets.")
		return
	end

	for i = 1, #containerSets, 1 do
		table.insert(containerLights, { containers = { }, lights = { } })

		---@cast containerSets string[]
		for container in containerSets[i]:gmatch([[".-"]]) do
			container = container:sub(2, #container - 1)	-- Trim quotation marks
			table.insert(containerLights[i].containers, container)
		end

		---@cast lightSets string[]
		for light in lightSets[i]:gmatch([[".-"]]) do
			light = light:sub(2, #light - 1)
			table.insert(containerLights[i].lights, light)
		end
	end

	if config.debug then logContainerLightsContents() end
end

---@param object tes3container|tes3light
---@param table string[]
---@param partialIDs boolean
---@return boolean
local function objectValid(object, table, partialIDs)
	for _,string in pairs(table) do
		if (partialIDs and object.id:lower():find(string:lower())) or object.id:lower() == string:lower() then
			return true
		end
	end

	return false
end

local function enableLights()
	if not containerLights or #containerLights == 0 then return end

	for _,cell in pairs(tes3.getActiveCells()) do
		for light in cell:iterateReferences(tes3.objectType.light) do	-- Check all of the lights in loaded cells that have been disabled by this addon
			if light.data.harvestDisabled then
				for _,containerLight in pairs(containerLights) do
					if objectValid(light.baseObject, containerLight.lights, false) then		-- Get the containerLight table that contains the light's id
						for _,cell in pairs(tes3.getActiveCells()) do	-- Is it really worth considering the case where the light is in a different cell from all of its containers? 
							for container in cell:iterateReferences(tes3.objectType.container) do
								if (not container.data.GH or container.data.GH == 0) and objectValid(container.baseObject, containerLight.containers, true) and container.position:distance(light.position) <= config.singleDistance then
									light:enable()						-- If nearby containers have been replenished, then the light should be re-enabled
									light.data.harvestDisabled = nil

									if config.debug then mwse.log("[Harvest Lights] Debug: " .. light.baseObject.id .. " enabled") end

									break
								end
							end

							if not light.data.harvestDisabled then break end
						end

						if not light.data.harvestDisabled then break end
					end
				end
			end
		end
	end
end

---@param e containerClosedEventData
local function disableLights(e)
	if not containerLights or #containerLights == 0 then return end

	if config.debug then mwse.log("[Harvest Lights] Debug: " .. e.reference.baseObject.id .. " harvested") end

	if e.reference.data.GH and e.reference.data.GH > 0 then									-- Check whether the closed container has GH compatibility and has been harvested according to GH
		for _,containerLight in pairs(containerLights) do									-- Iterate through all of the tables of containers and lights in containerLights
			if objectValid(e.reference.baseObject, containerLight.containers, true) then	-- Check whether the closed container is present the table
				local lights = {}

				for _,cell in pairs(tes3.getActiveCells()) do
					for ref in cell:iterateReferences(tes3.objectType.light) do											-- Iterate through all of the lights present in loaded cells
						if not ref.disabled and objectValid(ref.baseObject, containerLight.lights, false) then			-- Only proceed with lights that are not disabled and which are in the same containerLight table
							local distance = ref.position:distance(e.reference.position)
							if distance <= config.singleDistance then													-- Check whether each applicable light is close enough to the closed container
								table.insert(lights, { reference = ref, canBeDisabled = true, distance = distance })	-- If so, add the light to a table of all of the lights that might deserve to be disabled
							end
						end
					end
				end

				if #lights == 0 then return end		-- If there are no suitable lights, then it isn't worth continuing

				for _,cell in pairs(tes3.getActiveCells()) do
					for ref in cell:iterateReferences(tes3.objectType.container) do														-- Iterate through all of the containers present in loaded cells
						if (not ref.data.GH or ref.data.GH == 0) and objectValid(ref.baseObject, containerLight.containers, true) then	-- Check whether the container belongs to the same containerLight table and has not been harvested
							local disableableLightCount = #lights
							for _,light in pairs(lights) do																				-- Check all of the nearby lights found above to see whether they are too close to the unharvested container
								if light.canBeDisabled and light.reference.position:distance(ref.position) <= config.singleDistance then
									light.canBeDisabled = false
								end

								if not light.canBeDisabled then disableableLightCount = disableableLightCount - 1 end
								if disableableLightCount == 0 then return end	-- If no lights can be disabled, then it isn't worth continuing
							end
						end
					end
				end

				for _,light in pairs(lights) do
					if light.canBeDisabled then
						light.reference:disable()						-- Disable all of the lights that made it through the gauntlet above
						light.reference.data.harvestDisabled = true		-- And mark them as having been disabled by this addon so that they can be re-enabled

						if config.debug then mwse.log("[Harvest Lights] Debug: " .. light.reference.baseObject.id .. " disabled") end
					end
				end

				return
			end
		end
	end
end

-- Setup MCM
dofile("HarvestLights.mcm")

event.register(tes3.event.initialized, function()
	if config.enabled == true then
		event.register(tes3.event.loaded, makeContainerLightsTable, { priority = 50 })

		event.register(tes3.event.containerClosed, disableLights)

		event.register(tes3.event.loaded, enableLights, { priority = -5 })				-- These three functions are set to run after GH resets the containers
		event.register(tes3.event.cellChanged, enableLights, { priority = -5 })
		event.register(tes3.event.calcRestInterrupt, enableLights, { priority = -5 })
	end
end)