local hunger = 0
local tired = 0
local tiredstate = 0
local hungerstate = 0
local hungerHour = 0
local hungerDay = 0
local tiredDay = 0
local sleepHour = 0
local eatHour = 0
local travel = false
local t = nil

local food = require("KetsTired&Hungry.foodlist").theFood

local hungerPenalty = {
	"ket_pc_hungry1",
	"ket_pc_hungry2",
	"ket_pc_hungry3",
	"ket_pc_hungry4",
	"ket_pc_hungry5",
	"ket_pc_hungry6",
	"ket_pc_hungry7",
	"ket_pc_hungry8",
	"ket_pc_hungry9",
	"ket_pc_hungry10",
}

local tiredPenalty = {
	"ket_pc_tired1",
	"ket_pc_tired2",
	"ket_pc_tired3",
	"ket_pc_tired4",
	"ket_pc_tired5",
	"ket_pc_tired6",
	"ket_pc_tired7",
	"ket_pc_tired8",
	"ket_pc_tired9",
	"ket_pc_tired10",
}

--~ local function reportStats()
--~= 	tes3.messageBox("hunger="..hunger..", tired="..tired..", hungerstate="..hungerstate..", tiredstate="..tiredstate)
--~ end

local config = mwse.loadConfig("Ket's Tired and Hungry")
config = config or {}
config.minFood = config.minFood or 3
config.minSleep = config.minSleep or 8
config.noVagrancy = config.noVagrancy or true
config.travel = config.travel or false


local function updateTiredness(increase)
	local previousTiredstate = tiredstate
	local i

	i = 1


	repeat
		if (tired < (tiredDay * i)) then
			if i == 1 then
				if tired == 0 then
					tiredstate = 0
				end
				break
			elseif tiredstate < 12 then
				tiredstate = i-1
				break
			else
				tes3.getMobilePlayer():applyHealthDamage(10000)
				break
			end
		end
		i = i + 1
	until i > 12

	i = 1

	repeat
		if (tiredstate == i) then
			if (mwscript.getSpellEffects({reference = "player", spell = tiredPenalty[i]}) == false) then
				mwscript.addSpell({reference = "player", spell = tiredPenalty[i]})
			end
		end
		i = i+1
	until i > 10

	i = 1

	repeat
		if mwscript.getSpellEffects({reference = "player", spell = tiredPenalty[i]}) then
			if (tiredstate ~= i) then
				mwscript.removeSpell({reference = tes3.player, spell = tiredPenalty[i]})
			end
		end
		i = i + 1
	until i > 10

	if (tiredstate ~= previousTiredstate) then
		if (tiredstate < 1) then
			tes3.messageBox("You are well rested.")
		elseif (tiredstate < 3) then
			tes3.messageBox("You are tired.")
		elseif (tiredstate < 7) then
			tes3.messageBox("You are very tired.")
		elseif (tiredstate < 10) then
			tes3.messageBox("You are exhausted.")
		else
			tes3.messageBox("You'll exhaust to death very soon. You have to sleep.")
		end
	elseif increase and tiredstate > 0 then
		tes3.messageBox("You are less tired.")
	end
end

local function updateHunger(increase)
	local previousHungerstate = hungerstate
	local i = 0

	repeat
		if (hunger < (hungerHour*4.5)) then
			if hunger <= 0 then
				hunger = 0
				hungerstate = 0
				break
			end
		elseif ((i == 1) and (hunger < (hungerHour*9))) or ((i > 1) and (i < 7) and (hunger < (hungerDay * i/2))) or ((i > 7) and (i < 11) and (hunger < hungerDay*((i*2)-10))) then
			hungerstate = i
			break
		elseif (hunger > (hungerDay*14)) then
			tes3.getMobilePlayer():applyHealthDamage(10000)
		end
		i = i + 1
	until i > 12

	i = 1

	repeat
		if (hungerstate == i) then
			if (mwscript.getSpellEffects({reference = "player", spell = hungerPenalty[i]}) == false) then
				mwscript.addSpell({reference = "player", spell = hungerPenalty[i]})
			end
		end
		i = i+1
	until i > 10

	i = 1

	repeat
		if mwscript.getSpellEffects({reference = "player", spell = hungerPenalty[i]}) then
			if (hungerstate ~= i) then
				mwscript.removeSpell({reference = "player", spell = hungerPenalty[i]})
			end
		end
		i = i + 1
	until i > 10

	if (hungerstate ~= previousHungerstate) then
		if (hungerstate < 1) then
			tes3.messageBox("You aren't hungry anymore.")
		elseif (hungerstate < 3) then
			tes3.messageBox("You are hungry.")
		elseif (hungerstate < 7) then
			tes3.messageBox("You are very hungry.")
		elseif (hungerstate < 10) then
			tes3.messageBox("You are starving.")
		else
			tes3.messageBox("You'll starve to death very soon. You have to eat.")
		end
	elseif increase then
		tes3.messageBox("You are less hungry.")
	end
end

local function updateStats()
	local sleep = false
	local minFood = config.minFood
	local minSleep = config.minSleep
	if tes3.getGlobal("ket_pc_injail") == 0 then
		if config.travel then
			if travel then
				return
			end
		end
		if tes3.getMobilePlayer().sleeping then
			sleep = true
			hunger = hunger + hungerHour/3
			if (tes3.getPlayerCell().isInterior) or (not config.noVagrancy) then
				tired = tired - sleepHour
				if tired < 0 then
					tired = 0
				end
			end
		else
			tired = tired + 1
			sleepHour = tired/(minSleep+(tiredstate*0.4))
			if sleepHour < 2 then
				sleepHour = 2
			end
		end
		updateTiredness(sleep)
		hunger = hunger + hungerHour
		eatHour = hunger/(minFood+((hungerstate-1)*0.25))
		if (eatHour < 3) then
			eatHour = 3
		end
		updateHunger(false)
	end
end

local function onEquip(e)
	if e.reference == tes3.getPlayerRef() and food[e.item.id] then
		hunger = hunger - eatHour
		if hungerstate ~= 0 then
			updateHunger(true)
		else
			hunger = 0
		end
	elseif (e.item.id == "potion_skooma_01") or (e.item.id == "ingred_moon_sugar_01") then
		tired = tired - sleepHour*2
		updateTiredness(true)
	end
end

local function onSimulate()
	updateTiredness(false)
	updateHunger(false)
end

local function onMenuExit()
	if travel then
		travel = false
	end
end

local function onUiActivated()
	if tes3.getGlobal("ket_pc_injail") == 1 then
		tes3.setGlobal("ket_pc_injail", 0)
	end
end

local function onActivate(e)
	if e.activator ~= tes3.player then
		return
	end
	if (e.target.mobile.object.class.id == "Caravaner") or (e.target.mobile.object.class.id == "Shipmaster") then
		travel = true
	end
end

local function loadGlobals()
	t = timer.start({duration = 1, callback = updateStats, type = timer.game, iterations = -1})
	hunger = tes3.getGlobal("ket_pc_hunger")
	tired = tes3.getGlobal("ket_pc_tired")
	hungerstate = tes3.getGlobal("ket_pc_hungerstate")
	tiredstate = tes3.getGlobal("ket_pc_tiredstate")
	sleepHour = tes3.getGlobal("ket_sleephour")
	eatHour = tes3.getGlobal("ket_eathour")
	hungerHour = 3
	hungerDay = hungerHour*18.6
	tiredDay = 16
end

local function saveGlobals()
	tes3.setGlobal("ket_pc_hunger", hunger)
	tes3.setGlobal("ket_pc_tired", tired)
	tes3.setGlobal("ket_pc_hungerstate", hungerstate)
	tes3.setGlobal("ket_pc_tiredstate", tiredstate)
	tes3.setGlobal("ket_eathour", eatHour)
	tes3.setGlobal("ket_sleephour", sleepHour)
end

event.register("simulate", onSimulate)
event.register("equip", onEquip)
event.register("uiActivated", onUiActivated, {filter = "MenuTimePass"})
event.register("loaded", loadGlobals)
event.register("save", saveGlobals)
event.register("activate", onActivate)
event.register("menuExit", onMenuExit)

local modConfig = require("KetsTired&Hungry.mcm")
modConfig.config = config
local function registerModConfig()
	mwse.registerModConfig("Ket's Tired and Hungry", modConfig)
end
event.register("modConfigReady", registerModConfig)
