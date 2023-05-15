--[[

Mod: Pharis' Magicka Regeneration
Author: Pharis

--]]

local I = require("openmw.interfaces")

-- Mod info
local modInfo = require("Scripts.Pharis.PharisMagickaRegeneration.modInfo")
local modName = modInfo.modName
local modVersion = modInfo.modVersion

-- Page description(s)
local pageDescription = "By Pharis\nv" .. modVersion .. "\n\nMagicka regeneration for players, NPCs, and creatures."

I.Settings.registerPage {
	key = modName,
	l10n = modName,
	name = "Pharis' Magicka Regeneration",
	description = pageDescription
}
