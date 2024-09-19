--get game and config
local game = tes3.getGame()
local config = require("DFPSO.config")

--default whitelist
local defaultWhiteList = {
    cells = {
        "Old Ebonheart",
        "Old Ebonheart, Docks"
    }
}
--whitelist JSON path
local whitelistPath = "whitelist"
local whitelist = mwse.loadConfig(whitelistPath, defaultWhiteList)
--internal values for frametime comparison and aggression modifier
local lastframe = 0.016
local modagro = 0
--internal value for current view distance converted to menu value equivalent
local vdnum = 10
--bool for whether or not to dynamically alter
local run = true

local newRenderDistance = 7168
local smoothdelta = 1

local function onTimerComplete()
--main function, does comparisons and VD changes
if run then
	--if delta option is enabled, prepare values based on frame comparison
	if config.delta then
		--modagro is modifier to number of VD changes
		modagro = math.abs(tes3.worldController.deltaTime - lastframe)
		modagro = modagro * 100
		modagro = math.floor(modagro)
	else
		--if delta option is disabled, reset to zero to make sure no ghost values remain
		modagro = 0
	end
	--main comparison with target frametime multiplied with threshold
	if tes3.worldController.deltaTime < ((1/config.target) * ((100 - config.threshold)/100)) then
		--apply mod agro here together with normal agro
		for i=1, (config.agro + modagro) do
		mge.macros.increaseViewRange()
		end
	elseif tes3.worldController.deltaTime > ((1/config.target) * ((100 + config.threshold)/100)) then
		for i=1, (config.agro + modagro) do
		mge.macros.decreaseViewRange()
		end
	else
		--prediction, extra VD decrease if frametime increases over threshold within normal threshold bounds
		if config.prediction then
			if (tes3.worldController.deltaTime - lastframe) > ((1/config.target) * ((config.threshold / 100) * (config.predrange / 100))) then
				--mge.macros.decreaseViewRange()
			end
		end
	end
	
end
	
	--record last frametime for comparison in prediction and delta functions
	lastframe = tes3.worldController.deltaTime
end

local function changePerFrame()

	--determine magnitude of delta
	smoothdelta = math.abs(tes3.worldController.deltaTime - (1/config.target))
	smoothdelta = smoothdelta * 1000 * config.smoothagro

	if tes3.worldController.deltaTime < ((1/config.target) * ((100 - config.threshold)/100)) then
		newRenderDistance = math.min(7168, newRenderDistance + (10 * smoothdelta))
		mgeCameraConfig.nearRenderDistance = newRenderDistance
	elseif tes3.worldController.deltaTime > ((1/config.target) * ((100 + config.threshold)/100)) then
		newRenderDistance = math.max(2500, newRenderDistance - (10 * smoothdelta))
		mgeCameraConfig.nearRenderDistance = newRenderDistance
	else
		
	end


	local timer = timer.delayOneFrame(changePerFrame)

end


local function isReducedDrawDistanceCell(cell)
    --Check if cell.name is whitelisted
    for _, cellName in ipairs(whitelist.cells) do
        if cellName == cell.name then
            return true
        end
    end
end

local function returnToDefVD()
	--function that returns VD to user defaults to prevent ghost values from dynamic changes in cells
	vdnum = math.floor((game.renderDistance - 2500) / 512)

	if config.nwlvalue - vdnum > 0 then
		for i=1, math.abs(config.nwlvalue - vdnum) do
		mge.macros.increaseViewRange()
		end
	elseif config.nwlvalue - vdnum < 0 then
		for i=1, math.abs(config.nwlvalue - vdnum) do
		mge.macros.decreaseViewRange()
		end
	end

end

local function changeToStaticVD()
	--function that changes VD to static target
	vdnum = math.floor((game.renderDistance - 2500) / 512)

	if config.staticvd - vdnum > 0 then
		for i=1, math.abs(config.staticvd - vdnum) do
		mge.macros.increaseViewRange()
		end
	elseif config.staticvd - vdnum < 0 then
		for i=1, math.abs(config.staticvd - vdnum) do
		mge.macros.decreaseViewRange()
		end
	end

end

local function onCellChanged(e)
	
	if config.usewl then
	
		if isReducedDrawDistanceCell(tes3.player.cell) then
		
			if config.static then
				run = false
				changeToStaticVD()
			else
				run = true
			end
	
		else
			run = false
			returnToDefVD()
		end

	else 
		run = true
	end
end

local function onGameLoaded(e)

	if config.smooth then
	local frametimer = timer.delayOneFrame(changePerFrame)
	end
	--list whitelisted to log
	for _, cellName in ipairs(whitelist.cells) do
        mwse.log("[FOE] Whitelisted cell: %s", cellName)
    end
	--check if whitelisting is active
	if config.usewl then
		--check if loadin cell is whitelisted
		if isReducedDrawDistanceCell(tes3.player.cell) then
			if config.static then
				run = false
				changeToStaticVD()				
			else
				run = true
			end
		else
			run = false
		end
		
	else
		run = true
	end
--global timer to execute dynamic adjustment
if not config.smooth then
local FPScheck = timer.start({ duration = (1/config.changerate), callback = onTimerComplete, iterations = -1 })
end
end

event.register(tes3.event.cellChanged, onCellChanged)
event.register(tes3.event.loaded, onGameLoaded)

require("DFPSO.mcm")