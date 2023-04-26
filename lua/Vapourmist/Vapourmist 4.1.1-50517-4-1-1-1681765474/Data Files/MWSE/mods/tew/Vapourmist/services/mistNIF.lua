-- Mist module
-->>>---------------------------------------------------------------------------------------------<<<--

-- Imports
local mistNIF = {}
local util = require("tew.Vapourmist.components.util")
local debugLog = util.debugLog
local config = require("tew.Vapourmist.config")

-->>>---------------------------------------------------------------------------------------------<<<--
-- Constants

local TIMER_DURATION = 0.3

local CELL_SIZE = 8192

local MIN_LIFESPAN = 15
local MAX_LIFESPAN = 30

local MIN_DEPTH = 200
local MAX_DEPTH = 500

local MIN_BIRTHRATE = 1.2
local MAX_BIRTHRATE = 1.8

local CUTOFF_COEFF = 4

local HEIGHTS = {1156, 1200, 1260, 1300}
local SIZES = {580, 650, 700, 800, 1100, 1200}

local wetWeathers = {
    ["Rain"] = true,
    ["Thunderstorm"] = true
}

local MESH = tes3.loadMesh("tew\\Vapourmist\\vapourmist.nif")
local NAME_MAIN = "tew_Mist"
local NAME_EMITTER = "tew_Mist_Emitter"
local NAME_PARTICLE_SYSTEMS = {
	"tew_Mist_ParticleSystem_1",
	"tew_Mist_ParticleSystem_2",
	"tew_Mist_ParticleSystem_3"
}

-->>>---------------------------------------------------------------------------------------------<<<--
-- Structures

local tracker, removeQueue, appCulledTracker = {}, {}, {}

local toWeather, recolourRegistered

local WtC = tes3.worldController.weatherController
local WorldC = tes3.worldController

-->>>---------------------------------------------------------------------------------------------<<<--
-- Functions


-- Helper logic

local function getMistPosition(cell)
	local average = 0
	local denom = 0

	for stat in cell:iterateReferences() do
		average = average + stat.position.z
		denom = denom + 1
	end

	math.randomseed(os.time())
	local height = HEIGHTS[math.random(#HEIGHTS)]

	if average == 0 or denom == 0 then
		return height
	else
		return (average / denom) + height
	end
end

local function isAvailable(weather, gameHour)
    local weatherName = weather.name

    if config.blockedMist[weatherName] then return false end

    return
    ((
        (gameHour > WtC.sunriseHour - 1 and gameHour < WtC.sunriseHour + 1.5)
    or
        (gameHour >= WtC.sunsetHour - 0.4 and gameHour < WtC.sunsetHour + 2))
    and not
        wetWeathers[weatherName])
    or
    (
        config.mistyWeathers[weatherName]
    )
end

local function getParticleSystemSize(drawDistance)
	return (CELL_SIZE * drawDistance)
end

local function getCutoffDistance(drawDistance)
	return getParticleSystemSize(drawDistance) / CUTOFF_COEFF
end

local function isPlayerClouded(mistMesh)
	debugLog("Checking if player is clouded.")
	local mp = tes3.mobilePlayer
	local playerPos = mp.position:copy()
	local drawDistance = mge.distantLandRenderConfig.drawDistance
	return playerPos:distance(mistMesh.translation:copy()) < (getCutoffDistance(drawDistance))
end


-- Table logic

local function removeFromTable(tab, val)
	local pos = table.find(tab, val)
	if pos then
		table.remove(tab, pos)
	else
		tab = {}
	end
end

local function addToTracker(mist)
	table.insert(tracker, mist)
	debugLog("Mist added to tracker.")
end

local function removeFromTracker(mist)
	removeFromTable(tracker, mist)
	debugLog("Mist removed from tracker.")
end

local function addToRemoveQueue(mist)
	table.insert(removeQueue, mist)
	debugLog("Mist added to removal queue.")
end

local function removeFromRemoveQueue(mist)
	removeFromTable(removeQueue, mist)
	debugLog("Mist removed from removal queue.")
end

local function addToAppCulledTracker(mist)
	table.insert(appCulledTracker, mist)
	debugLog("Mist added to appCulled tracker.")
end

local function removeFromAppCulledTracker(mist)
	removeFromTable(appCulledTracker, mist)
	debugLog("Mist removed from appCulled tracker.")
end

-- Hide/show logic

local function detach(vfxRoot, node)
	removeFromAppCulledTracker(node)
	vfxRoot:detachChild(node)
	debugLog("Mist detached.")
	removeFromRemoveQueue(node)
	removeFromTracker(node)
end

function mistNIF.detachAll()
	debugLog("Detaching all mist.")
	local vfxRoot = tes3.game.worldSceneGraphRoot.children[9]
	for _, node in pairs(vfxRoot.children) do
		if node and node.name == NAME_MAIN then
			detach(vfxRoot, node)
		end
	end
	tracker = {}
end

local function switchAppCull(node, bool)
	local emitter = node:getObjectByName(NAME_EMITTER)
	if (emitter.appCulled ~= bool) then
		emitter.appCulled = bool
		emitter:update()
	end
end

function mistNIF.hideAll()
	local vfxRoot = tes3.game.worldSceneGraphRoot.children[9]
	for _, node in pairs(vfxRoot.children) do
		if node and node.name == NAME_MAIN then
			switchAppCull(node, true)
		end
	end
end

function mistNIF.unhideAll()
	local vfxRoot = tes3.game.worldSceneGraphRoot.children[9]
	for _, node in pairs(vfxRoot.children) do
		if node and node.name == NAME_MAIN then
			-- local emitter = node:getObjectByName(NAME_EMITTER)
			switchAppCull(node, false)
		end
	end
end

local function appCull(node)
	local emitter = node:getObjectByName(NAME_EMITTER)
	if not (emitter.appCulled) then
		switchAppCull(node, true)
		timer.start{
			type = timer.simulate,
			duration = MAX_LIFESPAN,
			iterations = 1,
			persistent = false,
			callback = function() addToRemoveQueue(node) end
		}
		debugLog("Mist appculled.")
		addToAppCulledTracker(node)
		removeFromTracker(node)
	else
		debugLog("Mist already appculled. Skipping.")
	end
end

local function appCullAll()
	debugLog("Appculling all mist.")
	local vfxRoot = tes3.game.worldSceneGraphRoot.children[9]
	for _, node in pairs(vfxRoot.children) do
		if node and node.name == NAME_MAIN then
			appCull(node)
		end
	end
end

-- Colour logic

local function getMistColourMix(fogComp, skyComp)
	return math.lerp(fogComp, skyComp, 0.08)
end

local function getModifiedColour(comp)
	return math.clamp(math.lerp(comp, 1.0, 0.01), 0.03, 0.88)
end

-- Calculate output colours from current fog colour --
local function getOutputValues()
	local currentFogColor = WtC.currentFogColor:copy()
	local currentSkyColor = WtC.currentSkyColor:copy()
	local weatherColour = {
		r = getMistColourMix(currentFogColor.r, currentSkyColor.r),
		g = getMistColourMix(currentFogColor.g, currentSkyColor.g),
		b = getMistColourMix(currentFogColor.b, currentSkyColor.b)
	}
	return {
		colours = {
			r = getModifiedColour(weatherColour.r),
			g = getModifiedColour(weatherColour.g),
			b = getModifiedColour(weatherColour.b)
		}
	}
end

local function reColourTable(tab, mistColour)
	if not tab then return end
	if table.empty(tab) then return end
	for _, mist in ipairs(tab) do
		for _, name in ipairs(NAME_PARTICLE_SYSTEMS) do
			local particleSystem = mist:getObjectByName(name)

			local controller = particleSystem.controller
			local colorModifier = controller.particleModifiers

			for _, key in pairs(colorModifier.colorData.keys) do
				key.color.r = mistColour.r
				key.color.g = mistColour.g
				key.color.b = mistColour.b
			end

			local materialProperty = particleSystem.materialProperty
			materialProperty.emissive = mistColour
			materialProperty.specular = mistColour
			materialProperty.diffuse = mistColour
			materialProperty.ambient = mistColour

			particleSystem:update()
			particleSystem:updateProperties()
			particleSystem:updateEffects()
			mist:update()
			mist:updateProperties()
			mist:updateEffects()
		end
	end
end

local function reColour()

	local output = getOutputValues()
	local mistColour = output.colours

	reColourTable(tracker, mistColour)
	reColourTable(appCulledTracker, mistColour)
end

-- NIF values logic

local function deployEmitter(particleSystem)
	math.randomseed(os.time())
	local drawDistance = mge.distantLandRenderConfig.drawDistance

	local controller = particleSystem.controller

	local birthRate = math.random(MIN_BIRTHRATE, MAX_BIRTHRATE) * drawDistance
	controller.birthRate = birthRate
	controller.useBirthRate = true

	local lifespan = math.random(MIN_LIFESPAN, MAX_LIFESPAN)
	controller.lifespan = lifespan
	controller.emitStopTime = lifespan * lifespan

	local effectSize = getParticleSystemSize(drawDistance)

	controller.emitterWidth = effectSize
	controller.emitterHeight = effectSize
	controller.emitterDepth = math.random(MIN_DEPTH, MAX_DEPTH)

	controller.initialSize = SIZES[math.random(#SIZES)]

	particleSystem:update()
	particleSystem:updateProperties()
	particleSystem:updateEffects()
	debugLog("Emitter deployed.")
end

local function addMist()
	debugLog("Adding mist.")
	local vfxRoot = tes3.game.worldSceneGraphRoot.children[9]
	local cell = tes3.getPlayerCell()

	local mp = tes3.mobilePlayer
	if not mp or not mp.position then return end

	local playerPos = mp.position:copy()

	local mistPosition = tes3vector3.new(
		playerPos.x,
		playerPos.y,
		getMistPosition(cell)
	)

	local mistMesh = MESH:clone()
	mistMesh:clearTransforms()
	mistMesh.translation = mistPosition

	vfxRoot:attachChild(mistMesh)

	local mistNode
	for _, node in pairs(vfxRoot.children) do
		if node then
			if node.name == NAME_MAIN then
				if not table.find(removeQueue, node) then
					mistNode = node
				end
			end
		end
	end
	if not mistNode then return end

	addToTracker(mistNode)

	for _, name in ipairs(NAME_PARTICLE_SYSTEMS) do
		local particleSystem = mistNode:getObjectByName(name)
		if particleSystem then
			deployEmitter(particleSystem)
		end
	end

	mistMesh.appCulled = false
	mistMesh:update()
	mistMesh:updateProperties()
	mistMesh:updateEffects()
	debugLog("Mist added.")
end

-- Conditions logic

local function waitingCheck()
	debugLog("Starting waiting check.")
	local mp = tes3.mobilePlayer
	local gameHour = WorldC.hour.value

	if (not mp) or (mp and (mp.waiting or mp.traveling)) then
		toWeather = WtC.nextWeather or WtC.currentWeather
		if not (isAvailable(toWeather, gameHour)) then
			debugLog("Player waiting or travelling and mist not available.")
			mistNIF.detachAll()
		end
	end
	mistNIF.conditionCheck()
end

function mistNIF.onWaitMenu(e)
	local element = e.element
	element:registerAfter(tes3.uiEvent.destroy, function()
		waitingCheck()
	end)
end

function mistNIF.onWeatherChanged(e)
	debugLog("Starting weather check.")
	local fromWeather = e.from
    toWeather = e.to
	local gameHour = WorldC.hour.value

	if not isAvailable(toWeather, gameHour) then
		appCullAll()
	end

	if wetWeathers[fromWeather.name] and config.blockedMist[toWeather.name] ~= true then
		debugLog("Setting timer for post-rain mist.")
		-- Slight offset so it makes sense --
		timer.start {
			type = timer.game,
			iterations = 1,
			duration = 0.15,
			callback = function()
				debugLog("Deploying post-rain mist.")
				addMist()
			end
		}
	end
end

function mistNIF.conditionCheck()
	local cell = tes3.getPlayerCell()
	if not cell.isOrBehavesAsExterior then return end
	local gameHour = WorldC.hour.value

	toWeather = WtC.nextWeather or WtC.currentWeather

	for _, node in ipairs(removeQueue) do
		local vfxRoot = tes3.game.worldSceneGraphRoot.children[9]
		detach(vfxRoot, node)
	end

	if not table.empty(tracker) then
		debugLog("Tracker not empty. Checking distance.")
		for _, node in ipairs(tracker) do
			if not isPlayerClouded(node) then
				debugLog("Found distant mist.")
				appCull(node)
			end
		end
	else
		if isAvailable(toWeather, gameHour) then
			debugLog("Tracker is empty. Adding mist.")
			addMist()
		end
	end
end

-- Time and event logic

local function startTimer()
	timer.start{
		duration = TIMER_DURATION,
		callback = mistNIF.conditionCheck,
		iterations = -1,
		type = timer.game,
		persist = false
	}
end


-- Register events, timers and reset values --
function mistNIF.onLoaded()
	debugLog("Game loaded.")
	if not recolourRegistered then
		event.register(tes3.event.enterFrame, reColour)
		recolourRegistered = true
	end
	startTimer()
	tracker, removeQueue = {}, {}
	mistNIF.detachAll()
	mistNIF.conditionCheck()
end

return mistNIF