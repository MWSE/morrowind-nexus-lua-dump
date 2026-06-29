local ok, content = pcall(require, 'openmw.content')
if not ok or not content then
	return {}
end

require('scripts.eveningstar.db.es_deities')

-- with more than one deity slot, name each pray power after its deity
local storage = require('openmw.storage')
local maxDeities = storage.playerSection("SettingsSunsDuskES_OWNLY"):get("MAX_DEITIES") or 1

-- pray
-- id = "es_pray_tt_vivec",
-- name = "Pray",
-- icon = "icons/eveningstar/tx_s_es_tt_vivec.dds",
-- description = "Worship Vivec, "..title.." .",
-- baseCost = 1,

for pantheonId, pantheon in pairs(ES.DB.pantheon) do
	if pantheon.deities then
		for deityId, deity in pairs(pantheon.deities) do
			if not deity.stub then
				local effectId = "es_"..pantheonId.."_"..deityId
				content.magicEffects.records[effectId] = {
					template = content.magicEffects.records["detectkey"],
					name = "Pray to "..deity.name,
					baseCost = 1,
					icon = "icons/eveningstar/tx_s_"..effectId..".dds",
					description = "Worship "..deity.name..", "..deity.title.." .",
					onSelf = true,
					hasMagnitude = false,
					hasDuration = false,
				}
				content.spells.records["es_pray_"..pantheonId.."_"..deityId] = {
					name = maxDeities > 1 and ("Pray to "..deity.name) or "Pray",
					type = content.spells.TYPE.Power,
					cost = 1,
					isAutocalc = false,
					effects = {
						{
							id = effectId,
							range = content.RANGE.Self,
							magnitudeMin = 1,
							magnitudeMax = 1,
							duration = 1,
						},
					},
				}
			end
		end
	end
end

-- single power that prays to every worshipped deity at once
content.magicEffects.records["es_pray_all"] = {
	template = content.magicEffects.records["detectkey"],
	name = "Pray",
	baseCost = 1,
	icon = "icons/eveningstar/tx_s_es_pray_all.dds",
	description = "Worship all of your deities at once.",
	onSelf = true,
	hasMagnitude = false,
	hasDuration = false,
}
content.spells.records["es_pray_all"] = {
	name = "Pray",
	type = content.spells.TYPE.Power,
	cost = 1,
	isAutocalc = false,
	effects = {
		{
			id = "es_pray_all",
			range = content.RANGE.Self,
			magnitudeMin = 1,
			magnitudeMax = 1,
			duration = 1,
		},
	},
}

-- ------------------------------ vivec gift 3: poet's charm ----------------


content.activators.records["es_tt_vivec_g3_orb"] = {
	model = "meshes/tr/l/tr_l_dae_ward_v_01.NIF",
	name = "Poet's Charm",
}

-- ------------------------------ almalexia gift 2: healer's gift -----------

content.spells.records["es_tt_almalexia_g2_low"] = {
	name = "Healer's Gift",
	type = content.spells.TYPE.Ability,
	isAutocalc = false,
	effects = {
		{
			id = "restorehealth",
			range = content.RANGE.Self,
			magnitudeMin = 1,
			magnitudeMax = 1,
			duration = 1,
		},
	},
}
content.spells.records["es_tt_almalexia_g2_high"] = {
	name = "Healer's Gift",
	type = content.spells.TYPE.Ability,
	isAutocalc = false,
	effects = {
		{
			id = "restorehealth",
			range = content.RANGE.Self,
			magnitudeMin = 2,
			magnitudeMax = 2,
			duration = 1,
		},
	},
}

-- ------------------------------ sotha sil gift 3: ponder --------------

content.spells.records["es_tt_sothasil_g3_reflect"] = {
	name = "Wizard's Pondering",
	type = content.spells.TYPE.Spell,
	cost = 0,
	isAutocalc = false,
	effects = {
		{
			id = "reflect",
			range = content.RANGE.Self,
			magnitudeMin = 100,
			magnitudeMax = 100,
			duration = 60,
		},
		{
			id = "restoremagicka",
			range = content.RANGE.Self,
			magnitudeMin = 150,
			magnitudeMax = 150,
			duration = 6,
		},		
	},
}
content.activators.records["es_tt_sothasil_g3_orb"] = {
	model = "meshes/w/magic_target_alt.NIF",
	name = "Ponder Orb",
}