local this = {}

local config = require("tew\\Vapourmist\\config")
local version = require("tew\\Vapourmist\\version")
local VERSION = version.version

local data = require("tew\\Vapourmist\\data")

local WtC = tes3.worldController.weatherController
local lerp, simulateRegistered

-- Print debug messages
function this.debugLog(string)
    if config.debugLogOn then
		if not string then string = "n/a" end
		string = tostring(string)
		local info = debug.getinfo(2, "Sl")
        local module = info.short_src:match("^.+\\(.+).lua$")
        local prepend = ("[Vapourmist.%s.%s:%s]:"):format(VERSION, module, info.currentline)
        local aligned = ("%-36s"):format(prepend)
        mwse.log(aligned.." -- "..string.format("%s", string))
    end
end

-- Resets the cell table
function this.purgeFoggedCells(type)
	local player = tes3.player
	if player and player.data.vapourmist and player.data.vapourmist.cells and player.data.vapourmist.cells[type] then
		player.data.vapourmist.cells[type] = {}
		this.debugLog("Purged fogged cells for type: "..type)
	end
end

-- Updates cached cell data
function this.updateData(activeCell, type)
	local player = tes3.player
	if player and player.data.vapourmist and player.data.vapourmist.cells and player.data.vapourmist.cells[type] then
		table.insert(player.data.vapourmist.cells[type], activeCell)
		this.debugLog("Cell: "..activeCell.editorName.." added to "..type.." fog cache.")
	end
end

-- Returns true if the cell is fogged
function this.isCellFogged(activeCell, type)
	local player = tes3.player
	if player and player.data.vapourmist and player.data.vapourmist.cells and player.data.vapourmist.cells[type] then
		for _, cell in ipairs(player.data.vapourmist.cells[type]) do
			if cell == activeCell then
				this.debugLog("Cell: "..cell.editorName.." is fogged.")
				return true
			end
		end
	end
	return false
end

function this.isFogAppculled(type)
	local vfxRoot = tes3.game.worldSceneGraphRoot.children[9]
	for _, node in pairs(vfxRoot.children) do
		if node and node.name == "tew_"..type then
			for _, fog in pairs(node.children) do
				if fog.name == "Mist Emitter" then
					if fog.appCulled == true then
						this.debugLog("Fog is appculled.")
						return true
					end
				end
			end
		end
	end
end

function this.isWeatherBlocked(weather, blockedWeathers)
    for _, i in ipairs(blockedWeathers) do
        if weather.index == i then
            return true
        end
    end
    return false
end

-- Determine fog position
local function getFogPosition(activeCell, height)
	local average = 0
	local denom = 0
	for stat in activeCell:iterateReferences() do
		average = average + stat.position.z
		denom = denom + 1
	end

	if average == 0 or denom == 0 then
		return height
	else
		if ((average/denom) + height) <= 0 then
			return height
		elseif ((average/denom) + height) > height then
			return height + 100
		end
	end

	return (average/denom) + height
end

-- Determine fog position
local function getInteriorCellPosition(cell)
	local pos = {x = 0, y = 0, z = 0}
	local denom = 0

	for stat in cell:iterateReferences() do
		pos.x = pos.x + stat.position.x
		pos.y = pos.y + stat.position.y
		pos.z = pos.z + stat.position.z
		denom = denom + 1
	end

	return {x = pos.x/denom, y = pos.y/denom, z = pos.z/denom}
end

-- Determine time of day
function this.getTime(gameHour)
	if (gameHour >= WtC.sunriseHour - 0.3) and (gameHour < WtC.sunriseHour + 1.9) then
		return "dawn"
	elseif (gameHour >= WtC.sunriseHour + 1.9) and (gameHour < WtC.sunsetHour - 0.5) then
		return "day"
	elseif (gameHour >= WtC.sunsetHour - 0.5) and (gameHour < WtC.sunsetHour + 1.5) then
		return "dusk"
	elseif (gameHour >= WtC.sunsetHour + 1.5) or (gameHour < WtC.sunriseHour - 0.3) then
		return "night"
	end
end

-- Appculling switch
function this.switchFog(bool, type)
	local vfxRoot = tes3.game.worldSceneGraphRoot.children[9]
	for _, node in pairs(vfxRoot.children) do
		if node and node.name == "tew_"..type then
			for _, fog in pairs(node.children) do
				if fog.name == "Mist Emitter" then
					if fog.appCulled ~= bool then
						fog.appCulled = bool
						fog:update()
						this.debugLog("Appculling switched to "..tostring(bool).." for "..type.." fog.")
					end
				end
			end
		end
	end
end

-- Apply colour changes in simulate
local function lerpFogColours(e)

	-- this.debugLog("Lerping fog colours. Time: "..lerp.time)

	local vfxRoot = tes3.game.worldSceneGraphRoot.children[9]
	
	for _, vfx in pairs(vfxRoot.children) do
		if not vfx then break end

		if string.startswith(vfx.name, "tew_") and not (vfx.name == "tew_interior") then

			local type = string.sub(vfx.name, 5)

			local particleSystem = vfx:getObjectByName("MistEffect")
			local controller = particleSystem.controller
			local colorModifier = controller.particleModifiers
		
			if lerp.speed then
				controller.speed = math.lerp(lerp.speed.from, lerp.speed.to, lerp.time)
			end

			if lerp.angle then
				controller.planarAngle = math.lerp(lerp.angle.from, lerp.angle.to, lerp.time)
			end

			local deltaR = math.lerp(lerp[type].colours.from.r, lerp[type].colours.to.r, lerp.time)
			local deltaG = math.lerp(lerp[type].colours.from.g, lerp[type].colours.to.g, lerp.time)
			local deltaB = math.lerp(lerp[type].colours.from.b, lerp[type].colours.to.b, lerp.time)

			for _, key in ipairs(colorModifier.colorData.keys) do
				key.color.r = deltaR
				key.color.g = deltaG
				key.color.b = deltaB
			end

			local materialProperty = particleSystem.materialProperty
			materialProperty.emissive = {deltaR, deltaG, deltaB}
			-- TODO: Check what gives us the white fog
			materialProperty.specular = {deltaR, deltaG, deltaB}
			materialProperty.diffuse = {deltaR, deltaG, deltaB}
			materialProperty.ambient = {deltaR, deltaG, deltaB}

			--this.debugLog("Current colours: "..materialProperty.emissive.r..", "..materialProperty.emissive.g..", "..materialProperty.emissive.b)

			particleSystem:updateNodeEffects()
		
		end
	end

	lerp.time = lerp.time + (data.lerpTime * math.round(e.delta, 1))

	if (lerp.time >= 1) then
		if simulateRegistered then
			event.unregister("simulate", lerpFogColours)
			simulateRegistered = false
			this.debugLog("Lerp finished.")
			for _, vfx in pairs(vfxRoot.children) do
				if string.startswith(vfx.name, "tew_") and not (vfx.name == "tew_interior") then
					local type = string.sub(vfx.name, 5)
					this.reColourImmediate(vfx, lerp[type].colours.to)
				end
			end
			lerp = nil
		end
	end

end

-- Calculate output colours per time and weather
function this.getOutputColours(time, weather, colours)

	this.debugLog("Getting output colours. Time: "..time.."; Weather: "..weather.index)

	local weatherColour

	if time == "dawn" then
		weatherColour = weather.fogSunriseColor
	elseif time == "day" then
		weatherColour = weather.fogDayColor
	elseif time == "dusk" then
		weatherColour = weather.fogSunsetColor
	elseif time == "night" then
		weatherColour = weather.fogNightColor
	end

	return {
		r = math.clamp(weatherColour.r + colours[time].r, 0.0, 0.9),
		g = math.clamp(weatherColour.g + colours[time].g, 0.0, 0.9),
		b = math.clamp(weatherColour.b + colours[time].b, 0.0, 0.9)
	}

end

function this.reColourImmediate(vfx, fogColour)
	this.debugLog("Recolouring "..vfx.name.." immediately. Fog colour: "..fogColour.r.." "..fogColour.g.." "..fogColour.b)

	local particleSystem = vfx:getObjectByName("MistEffect")
	local controller = particleSystem.controller
	local colorModifier = controller.particleModifiers

	for _, key in ipairs(colorModifier.colorData.keys) do
		key.color.r, key.color.g, key.color.b = table.unpack(fogColour)
	end

	local materialProperty = particleSystem.materialProperty
	materialProperty.emissive = fogColour
	materialProperty.specular = fogColour
	materialProperty.diffuse = fogColour
	materialProperty.ambient = fogColour

	if vfx.name == "tew_cloud" then
		local speed
		if WtC.nextWeather then
			speed = math.max(WtC.nextWeather.windSpeed * data.speedCoefficient, data.minimumSpeed)
		else
			speed = math.max(WtC.currentWeather.windSpeed * data.speedCoefficient, data.minimumSpeed)
		end
		local windVector = WtC.windVelocityCurrWeather:normalized()
		controller.planarAngle = windVector.y * math.pi * 2
		controller.speed = speed
	end

	particleSystem:updateNodeEffects()
	this.debugLog(vfx.name.." recoloured.")
end

-- Recolours fog nodes with slightly adjusted current fog colour by modifying colour keys in NiColorData and material property values
function this.reColour(options)
	if simulateRegistered then this.debugLog("Lerp in progress.") return end

	local fromTime = options.fromTime
	local toTime = options.toTime
	local colours = options.colours
	local type = options.type
	local fromWeather = options.fromWeather
	local toWeather = options.toWeather

	this.debugLog("Running colour change for "..type)

	if (fromTime == toTime) and (fromWeather == toWeather) then
		this.debugLog("Same conditions. Recolouring immediately.")
		local vfxRoot = tes3.game.worldSceneGraphRoot.children[9]
		for _, vfx in pairs(vfxRoot.children) do
			if not vfx then break end

			this.debugLog("Recolouring immediately: from weather: "..fromWeather.index..", to weather: "..toWeather.index)
	
			if vfx.name == "tew_"..type then
				local fogColour = this.getOutputColours(toTime, toWeather, colours)
				this.reColourImmediate(vfx, fogColour)
			end
		end
	else
		this.debugLog("Different conditions. Recolouring "..type.." over time.")

		-- TODO: nuke?
		this.debugLog("From time: "..fromTime)
		this.debugLog("To time: "..toTime)
		this.debugLog("From weather: "..fromWeather.index)
		this.debugLog("To weather: "..toWeather.index)

		local fromColour = this.getOutputColours(fromTime, fromWeather, colours)
		local toColour = this.getOutputColours(toTime, toWeather, colours)

		if WtC.nextWeather and WtC.transitionScalar then
			fromColour = {
				r = math.lerp(fromColour.r, toColour.r, WtC.transitionScalar),
				g = math.lerp(fromColour.g, toColour.g, WtC.transitionScalar),
				b = math.lerp(fromColour.b, toColour.b, WtC.transitionScalar)
			}
		end
		
		lerp = {}
		lerp.time = 0

		if type == "tew_cloud" then
			local toSpeed
			local fromSpeed = math.max(WtC.currentWeather.windSpeed * data.speedCoefficient, data.minimumSpeed)

			local windVector = WtC.windVelocityCurrWeather:normalized()
			local toAngle
			local fromAngle = windVector.y * math.pi * 2

			if WtC.nextWeather then
				local windVectorNext = WtC.windVelocityNextWeather:normalized()
				toAngle = windVectorNext.y * math.pi * 2
				toSpeed =  math.max(WtC.nextWeather.windSpeed * data.speedCoefficient, data.minimumSpeed)
			else
				toSpeed = fromSpeed
				toAngle = fromAngle
			end

			lerp.speed = {
				from = fromSpeed,
				to = toSpeed
			}
			
			lerp.angle = {
				from = fromAngle,
				to = toAngle
			}
		end

		for _, fogType in pairs(data.fogTypes) do
			lerp[fogType.name] = {}
			lerp[fogType.name].colours = {from = fromColour, to = toColour}
			lerp[fogType.name].name = fogType.name
			this.debugLog("Prepared lerp for type "..fogType.name..", from "..fromTime..", "..fromWeather.index..", to "..toTime..", "..toWeather.index..".")
			this.debugLog("From colour: "..fromColour.r..", "..fromColour.g..", "..fromColour.b)
			this.debugLog("To colour: "..toColour.r..", "..toColour.g..", "..toColour.b)
		end

		if not simulateRegistered then
			simulateRegistered = true
			event.register("simulate", lerpFogColours)
			this.debugLog("Lerp registered for "..type)
		end
	end

end

-- Adds fog to the cell
function this.addFog(options)

	local mesh = options.mesh
	local type = options.type
	local toTime = options.toTime
	local toWeather = options.toWeather
	local height = options.height
	local colours = options.colours

	local vfxRoot = tes3.game.worldSceneGraphRoot.children[9]

	this.debugLog("Checking if we can add fog: "..type)

	for _, activeCell in ipairs(tes3.getActiveCells()) do
		if (not (this.isCellFogged(activeCell, type)) and not (activeCell.isInterior)) then
			this.debugLog("Cell is not fogged. Adding "..type..".")

			local fogMesh = tes3.loadMesh(mesh):clone()

			fogMesh:clearTransforms()
			fogMesh.translation = tes3vector3.new(
				8192 * activeCell.gridX + 4096,
				8192 * activeCell.gridY + 4096,
				getFogPosition(activeCell, height)
			)

			vfxRoot:attachChild(fogMesh, true)

			for _, vfx in pairs(vfxRoot.children) do
				if not vfx then break end
				if vfx.name == "tew_"..options.type then
					local particleSystem = vfx:getObjectByName("MistEffect")
					local controller = particleSystem.controller
					controller.initialSize = table.choice(data.fogTypes[options.type].initialSize)

					if WtC.nextWeather then
						if vfx.name == "tew_cloud" then
							controller.speed = math.max(WtC.nextWeather.windSpeed * data.speedCoefficient, data.minimumSpeed)
							local windVectorNext = WtC.windVelocityNextWeather:normalized()
							controller.planarAngle = windVectorNext.y * math.pi * 2
						end
						this.reColour(options)
					else
						if vfx.name == "tew_cloud" then
							controller.speed = math.max(WtC.currentWeather.windSpeed * data.speedCoefficient, data.minimumSpeed)
							local windVector = WtC.windVelocityCurrWeather:normalized()
							controller.planarAngle = windVector.y * math.pi * 2
						end
						local fogColour = this.getOutputColours(toTime, toWeather, colours)
						this.reColourImmediate(vfx, fogColour)
					end
					

	
				end
			end

			fogMesh:update()
			fogMesh:updateProperties()
			fogMesh:updateNodeEffects()

			this.updateData(activeCell, type)
		else
			this.debugLog("Cell is already fogged. Showing fog.")
			this.switchFog(false, type)
		end
	end

end

-- Removes fog from view by appculling - with fade out
function this.removeFog(type)
    this.debugLog("Removing fog of type: "..type)
	this.switchFog(true, type)
	this.purgeFoggedCells(type)
end

-- Removes fog from view by detaching - without fade out
function this.removeFogImmediate(options)

    this.debugLog("Immediately removing fog of type: "..options.type)

	if this.isFogAppculled(options.type) then return end

	if lerp then lerp.time = 1 end

	local vfxRoot = tes3.game.worldSceneGraphRoot.children[9]

	for _, vfx in pairs(vfxRoot.children) do
		if not vfx then break end
		if vfx.name == "tew_"..options.type then
			local fogColour = this.getOutputColours(options.toTime, options.toWeather, options.colours)
			this.reColourImmediate(vfx, fogColour)
		end
	end

	for _, node in pairs(vfxRoot.children) do
		if node and node.name == "tew_"..options.type then
			vfxRoot:detachChild(node)
		end
	end

	this.purgeFoggedCells(options.type)
end

local function getInteriorColour(cell, colours)

	return {
		r = math.clamp(cell.ambientColor.r + colours.r, 0.2, 0.5),
		g = math.clamp(cell.ambientColor.g + colours.g, 0.26, 0.5),
		b = math.clamp(cell.ambientColor.b + colours.b, 0.3, 0.5)
	}

end

function this.addInteriorFog(options)

	this.debugLog("Adding interior fog.")

	local vfxRoot = tes3.game.worldSceneGraphRoot.children[9]

	local mesh = options.mesh
	local type = options.type
	local height = options.height
	local colours = options.colours
	local cell = options.cell

	if not (this.isCellFogged(cell, type)) then
		this.debugLog("Interior cell is not fogged. Adding "..type..".")

		local fogMesh = tes3.loadMesh(mesh):clone()

		local pos = getInteriorCellPosition(cell)

		fogMesh:clearTransforms()
		fogMesh.translation = tes3vector3.new(
			pos.x,
			pos.y,
			pos.z + height
		)

		vfxRoot:attachChild(fogMesh, true)

		for _, vfx in pairs(vfxRoot.children) do
			if not vfx then break end
			if vfx.name == "tew_"..type then
				local particleSystem = vfx:getObjectByName("MistEffect")
				local controller = particleSystem.controller
				controller.initialSize = table.choice(data.interiorFog.initialSize)
				local fogColour = getInteriorColour(cell, colours)
				this.reColourImmediate(vfx, fogColour)
			end
		end

		fogMesh:update()
		fogMesh:updateProperties()
		fogMesh:updateNodeEffects()

		this.updateData(cell, type)
	else
		this.debugLog("Cell is already fogged. Showing fog.")
		this.switchFog(false, type)
	end

end

function this.removeAll()

	local vfxRoot = tes3.game.worldSceneGraphRoot.children[9]

	for _, node in pairs(vfxRoot.children) do
		if not node then break end

		if string.startswith(node.name, "tew_") then

			local type = string.sub(node.name, 5)
			vfxRoot:detachChild(node)
			this.purgeFoggedCells(type)

		end
	end

end

return this