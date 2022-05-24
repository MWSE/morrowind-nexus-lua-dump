local defaultConfig = ({chaosMode = false})
local config = mwse.loadConfig ("RelentlessDarkBrotherhood", defaultConfig)

local RNG
local spawnDist
local restSpawn = "db_assassins"
local assList = {
	"db_assassin1c",
	"db_assassin1a",
	"db_assassin2a",
	"db_assassin3a",
	"db_assassin4a"
}

local function spawnAss()
	local assassin = table.choice(assList)
	local dir = (math.random(4) - 1)
	mwscript.placeAtPC {object = assassin, distance = spawnDist, direction = dir}
end

local function restInterruptCallback(e)

	local dbAttack = tes3.getJournalIndex({ id = "TR_DBAttack" })
	local dbHunt = tes3.getJournalIndex({ id = "TR_DBHunt" })
	if dbAttack >= 10 and dbHunt < 100 then

		e.creature = tes3.getObject(restSpawn)
	end
end

local function calcRestInterruptCallback(e)

	local dbAttack = tes3.getJournalIndex({ id = "TR_DBAttack" })
	local dbHunt = tes3.getJournalIndex({ id = "TR_DBHunt" })
	if dbAttack >= 10 and dbHunt < 100 then

		if config.chaosMode then
			RNG = math.random(10)
		elseif config.chaosMode == false then
			RNG = math.random(2)
		end

		if RNG > 1 then
			e.hour = (tes3.mobilePlayer.restHoursRemaining)
			e.count = 1
		end
	end
end

local function onCellChanged(e)

	local dbAttack = tes3.getJournalIndex({ id = "TR_DBAttack" })
	local dbHunt = tes3.getJournalIndex({ id = "TR_DBHunt" })
	if dbAttack >= 10 and dbHunt < 100 then

		if (e.previousCell == nil) then
			return
		end

		--if going outside from interior

		if e.previousCell.isInterior then
			if e.cell.isInterior == false then
				if config.chaosMode then
					RNG = math.random(2)
				elseif config.chaosMode == false then
					RNG = math.random(10)
				end

				if RNG == 1 then
					spawnDist = 512
					spawnAss()
					return
				end
			end
		end

		--any other cell change

		if config.chaosMode then
			RNG = math.random(4)
		elseif config.chaosMode == false then
			RNG = math.random(20)
		end
		if RNG == 1 then
			spawnDist = 2048
			spawnAss()
		end
	end
end

event.register("restInterrupt", restInterruptCallback, { priority = -111 })
event.register("calcRestInterrupt", calcRestInterruptCallback, { priority = -10 })
event.register("cellChanged", onCellChanged)

--MCM

local function registerModConfig()

	local template = mwse.mcm.createTemplate("RelentlessDarkBrotherhood")
	template:saveOnClose("RelentlessDarkBrotherhood", config)
	local page = template:createPage()
	local category = page:createCategory("Settings")
	category:createOnOffButton({
	label = "Chaos Mode",
	variable = mwse.mcm:createTableVariable{id = "chaosMode", table = config}
	})
	mwse.mcm.register(template)

end

event.register("modConfigReady", registerModConfig)