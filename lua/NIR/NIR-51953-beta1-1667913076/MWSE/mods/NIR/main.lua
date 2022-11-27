local config = require("NIR.config")

--  save leveled list object IDs to local strings for no real reason
local aiSpawn = "0s_restSpawn_ai"  --Ascadian Isles Region
local alSpawn = "0s_restSpawn_al"  --Ashlands Region
local acSpawn = "0s_restSpawn_ac"  --Azura's Coast Region
local bcSpawn = "0s_restSpawn_bc"  --Bitter Coast Region
local bgSpawn = "0s_restSpawn_bg"  --Brodir Grove Region
local fcSpawn = "0s_restSpawn_fc"  --Felsaad Coast Region
local glSpawn = "0s_restSpawn_gl"  --Grazelands Region
local hfSpawn = "0s_restSpawn_hf"  --Hirstaang Forest Region
local ipSpawn = "0s_restSpawn_ip"  --Isinfier Plains Region
local mmSpawn = "0s_restSpawn_mm"  --Moesring Mountains Region
local maSpawn = "0s_restSpawn_ma"  --Molag Amur Region
local rmSpawn = "0s_restSpawn_rm"  --Red Mountain Region
local sgSpawn = "0s_restSpawn_sg"  --Sheogorad
local wgSpawn = "0s_restSpawn_wg"  --West Gash Region

local function restInterruptCallback(e)

	if e.waiting then
		return
	end

	local playerCell = tes3.getPlayerCell()
	local inside = playerCell.isInterior
	if inside then
		return
	end
	local rng = math.random(100)
	local region = tes3.getRegion()
	if region.id == "Ascadian Isles Region" then
		if rng > config.aiChance then
			return
		end
		e.creature = tes3.getObject(aiSpawn)

	elseif region.id == "Ashlands Region" then
		if rng > config.alChance then
			return
		end
		e.creature = tes3.getObject(alSpawn)

	elseif region.id == "Azura's Coast Region" then
		if rng > config.acChance then
			return
		end
		e.creature = tes3.getObject(acSpawn)

	elseif region.id == "Bitter Coast Region" then
		if rng > config.bcChance then
			return
		end
		e.creature = tes3.getObject(bcSpawn)

	elseif region.id == "Brodir Grove Region" then
		if rng > config.bgChance then
			return
		end
		e.creature = tes3.getObject(bgSpawn)

	elseif region.id == "Felsaad Coast Region" then
		if rng > config.fcChance then
			return
		end
	e.creature = tes3.getObject(fcSpawn)

	elseif region.id == "Grazelands Region" then
		if rng > config.glChance then
			return
		end
	e.creature = tes3.getObject(glSpawn)

	elseif region.id == "Hirstaang Forest Region" then
		if rng > config.hfChance then
			return
		end
	e.creature = tes3.getObject(hfSpawn)

	elseif region.id == "Isinfier Plains Region" then
		if rng > config.ipChance then
			return
		end
	e.creature = tes3.getObject(ipSpawn)

	elseif region.id == "Moesring Mountains Region" then
		if rng > config.mmChance then
			return
		end
	e.creature = tes3.getObject(mmSpawn)

	elseif region.id == "Molag Amur Region" then
		if rng > config.maChance then
			return
		end
	e.creature = tes3.getObject(maSpawn)

	elseif region.id == "Red Mountain Region" then
		if rng > config.rmChance then
			return
		end
	e.creature = tes3.getObject(rmSpawn)

	elseif region.id == "Sheogorad" then
		if rng > config.sgChance then
			return
		end
	e.creature = tes3.getObject(sgSpawn)

	elseif region.id == "West Gash Region" then
		if rng > config.wgChance then
			return
		end
	e.creature = tes3.getObject(wgSpawn)

	end
end

local function calcRestInterruptCallback(e)
	if config.testmode then
		e.hour = (tes3.mobilePlayer.restHoursRemaining)
		e.count = 1
	end
end

local function initialized()
  if tes3.isModActive("NIR.esp") then
    event.register("restInterrupt", restInterruptCallback)
	event.register("calcRestInterrupt", calcRestInterruptCallback)
  else
    mwse.log("NIR.esp not found")
  end
end
event.register("initialized", initialized)

local function registerModConfig()
	require("NIR.mcm")
end
event.register("modConfigReady", registerModConfig)