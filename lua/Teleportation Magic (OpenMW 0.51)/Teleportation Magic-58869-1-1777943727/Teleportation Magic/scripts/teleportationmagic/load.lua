MODNAME = "TeleportationMagic"
content = require('openmw.content')
util = require('openmw.util')

local db = require('scripts.teleportationmagic.tpDatabase')

content.activators.records.pr_purpleportal = {
	name = "Portal",
	model = "meshes\\teleportationmagic\\purplePortal.nif",
}

content.statics.records["TPM_emptyStatic"] = {model = "meshes/teleportationmagic/none.nif"}

for effId, entry in pairs(db) do
	content.magicEffects.records[effId] = {
		template = content.magicEffects.records["detectkey"],
		name = entry.name,
		baseCost =  entry.cost or 45,
		icon = "icons/RFD/RFD_teleport.dds",
		description = "This effect teleports subject to "..entry.name:sub(13).." .",
		onTarget = true,
	--	hitStatic = "VFX_MysticismHit", --> "meshes/e/magic_hit_myst.nif"
	--	bolt = "VFX_MysticismBolt", 
		areaStatic = "TPM_emptyStatic", --> meshes/e/magic_reflect.nif
		color = util.color.hex("9725f5"),
	--	speed = 1.5,
	--	particle = "reflect", --> "meshes/e/magic_reflect.nif"
	--	hitStatic = "meshes/w/magic_target_myst.nif", 
	}
	content.spells.records[entry.spell] = {
		name = entry.name,
		type = content.spells.TYPE.Spell,
		cost = entry.cost or 45,
		isAutocalc = false,
		effects = {
			{
				id = effId,
				range = content.RANGE.Target,
				magnitudeMin = 1,
				magnitudeMax = 1,
				duration = 1,
			},
		},
	}
end

local TOME_TEMPLATE = "<DIV ALIGN=\"CENTER\">\r\n<IMG SRC=\"RFD/RFD_tome_01.dds\" WIDTH=\"250\" HEIGHT=\"325\"><BR>\r\n<BR>\r\n<IMG SRC=\"RFD/RFD_tome_02.dds\" WIDTH=\"250\" HEIGHT=\"325\">"

for _, entry in pairs(db) do
	local cost = entry.cost or 45
	local text = TOME_TEMPLATE .. "<#spellbook|" .. entry.spell .. "|" .. cost .. "+|mys|2>"
	content.books.records["spelltome_" .. entry.spell] = {
		name = "Spell Tome: " .. entry.name,
		model = "meshes/spelltomes/teleportation_1.nif",
		icon = "icons/spelltomes/teleportation_1.dds",
		weight = 1,
		value = 100,
		isScroll = false,
		text = text,
	}
end