local content = require('openmw.content')
local core = require('openmw.core')
local markup = require('openmw.markup')

local l10n = core.l10n('NiftySpellPack')

local mgef = content.magicEffects.records
local spell = content.spells.records

local data = markup.loadYaml('scripts/NiftySpellPack/spellInfo.yaml')

for _, e in ipairs(data.effects) do
    local id = e.id
    local record = e.record

    record.name = l10n('effect_' .. id)
    record.description = l10n('effect_' .. id .. '_d')
    if not e.inheritIcon then
        record.icon = 'icons/niftyspellpack/s/' .. id .. '.dds'
    end
    if record.template then
        record.template = mgef[record.template]
    end
    mgef[id] = record
end

for _, s in ipairs(data.spells) do
    local id = s.id
    local record = s.record

    record.name = l10n('spell_' .. id)
    if record.template then
        record.template = spell[record.template]
    end
    if record.type then
        record.type = content.spells.TYPE[record.type]
    end
    for _, effect in ipairs(record.effects) do
        if effect.range then
            effect.range = content.RANGE[effect.range]
        end
    end
    spell[id] = record
end

-- spell tomes
local tomeAssets = {
	alt = {
		icon = "icons/niftyspellpack/st_alteration.dds",
		mesh = "meshes/niftyspellpack/alteration_1.nif",
	},
	conj = {
		icon = "icons/niftyspellpack/st_conjuration.dds",
		mesh = "meshes/niftyspellpack/conjuration_1.nif",
	},
	myst = {
		icon = "icons/niftyspellpack/st_mysticism.dds",
		mesh = "meshes/niftyspellpack/mysticism_1.nif",
	},
}

local function defineTome(id, name, school)
	local assets = tomeAssets[school]
	if not assets then return end
	content.books.records[id] = {
		name = name,
		model = assets.mesh,
		icon = assets.icon,
		weight = 0.2,
		value = 75,
		isScroll = false,
		text = "",
	}
end

defineTome("spelltome_nsp_conj", "Spell Tome: Nifty Conjuration", "conj")
defineTome("spelltome_nsp_myst", "Spell Tome: Nifty Mysticism", "myst")
defineTome("spelltome_nsp_alt", "Spell Tome: Nifty Alteration", "alt")