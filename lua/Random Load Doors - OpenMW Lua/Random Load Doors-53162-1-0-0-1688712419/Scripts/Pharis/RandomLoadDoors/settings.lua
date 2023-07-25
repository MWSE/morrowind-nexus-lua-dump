--[[

Mod: Random Load Doors
Author: Pharis

--]]

local I = require("openmw.interfaces")

local modInfo = require("Scripts.Pharis.RandomLoadDoors.modinfo")

local pageDescription = "By Pharis\nv" .. modInfo.version .. "\n\nLoad doors of the random variety. :)"

I.Settings.registerPage {
	key = modInfo.name,
	l10n = modInfo.name,
	name = "Random Load Doors",
	description = pageDescription
}

print("[" .. modInfo.name .. "] Initialized v" .. modInfo.version)
