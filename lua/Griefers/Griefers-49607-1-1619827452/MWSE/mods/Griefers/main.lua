local config = require("Griefers.config")

local function spawnSomething()
	if tes3.getPlayerCell().isInterior then return end
	local spawnPick = table.choice(config.spawnList)
	local spawnDir = (math.random(4) - 1)
	mwscript.placeAtPC {object = spawnPick, distance = config.spawnDist, direction = spawnDir}
end

local function spawnCheck()
	local spawnChance
	if config.leveledSpawn then
		local pc_level = tes3.player.object.level
		spawnChance = (config.baseChance + pc_level)
	else
		spawnChance = config.baseChance
	end
	local spawnRNG = math.random(100)
	if spawnRNG <= spawnChance then
		spawnSomething()
	end
end

local function startTimer()
	timer.start{type=timer.simulate, duration=config.spawnTimer, iterations=-1, callback=spawnCheck}
end

local function onLoaded()
	startTimer()
end

local function initialized()
	if tes3.isModActive("Griefers.esp") then
		event.register("loaded", onLoaded)
	else
		mwse.log("Griefers.esp not found")
	end
end
event.register("initialized", initialized)
local function registerModConfig()
	require("Griefers.mcm")
end
event.register("modConfigReady", registerModConfig)