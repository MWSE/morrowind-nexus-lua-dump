local seph = require("seph")

local mod = seph.Mod()

mod.id = "seph.npcSoulTrapping"
mod.name = "Захват душ NPC"
mod.description = [[
Этот мод позволяет вам ловить души NPC. При желании он также добавляет в игру черные камни душ.
По умолчанию стоимость души NPC в 10 раз превышает его уровень. Этот параметр можно настроить.
Черные камни душ могут появиться вместо великих камней душ в случайных контейнерах.
Этот мод также исправляет ошибку ванильного Морровинда, связанную с использованием ловушки душ на NPC.
]]
mod.author = "Sephumbra"
mod.hyperlink = "https://www.nexusmods.com/morrowind/mods/50744"
mod.version = {major = 2, minor = 4, patch = 1}
mod.requiredMwseBuildDate = 20220404
mod.requiredModules = {
	"blackSoulGem",
	"npcSoulTrap",
	"creatureSoulTrap",
	"interop"
}

return mod