local config = require("TES6Stats.config")

local function breakshit()

if config.enabled == false then return end
local chargen = tes3.findGlobal("CharGenState").value
if chargen ~= -1 then return end
local Mcurrent = tes3.mobilePlayer.magicka.current
local Hcurrent = tes3.mobilePlayer.health.current
local Fcurrent = tes3.mobilePlayer.fatigue.current
local Mbase = tes3.mobilePlayer.magicka.base
local Hbase = tes3.mobilePlayer.health.base
local Fbase = tes3.mobilePlayer.fatigue.base

local newCurrent = ((Mcurrent + Hcurrent + Fcurrent) / 3)
local newBase = ((Mbase + Hbase + Fbase) / 3)

tes3.setStatistic{ reference = tes3.player, name = "magicka", current = newCurrent }
tes3.setStatistic{ reference = tes3.player, name = "health", current = newCurrent }
tes3.setStatistic{ reference = tes3.player, name = "fatigue", current = newCurrent }
tes3.setStatistic{ reference = tes3.player, name = "magicka", base = newBase }
tes3.setStatistic{ reference = tes3.player, name = "health", base = newBase }
tes3.setStatistic{ reference = tes3.player, name = "fatigue", base = newBase }

end

local function onLoaded()
	event.register("simulate", breakshit)
end

event.register("loaded", onLoaded)

local function registerModConfig()
	require("TES6Stats.mcm")
end
event.register("modConfigReady", registerModConfig)