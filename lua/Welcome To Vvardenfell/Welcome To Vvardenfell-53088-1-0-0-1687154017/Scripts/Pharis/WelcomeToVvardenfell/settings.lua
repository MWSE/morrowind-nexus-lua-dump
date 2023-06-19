--[[

Mod: Welcome To Vvardenfell
Author: Pharis

--]]

local I = require("openmw.interfaces")

-- Mod info
local modInfo = require("Scripts.Pharis.WelcomeToVvardenfell.modinfo")
local modName = modInfo.modName
local modVersion = modInfo.modVersion

-- Page description(s)
local pageDescription = "By Pharis\nv" .. modVersion .. "\n\nHappy Crashing! :)"

I.Settings.registerPage {
	key = modName,
	l10n = modName,
	name = "Welcome To Vvardenfell",
	description = pageDescription
}

print("[" .. modName .. "] Initialized v" .. modVersion)
