local core = require('openmw.core')
local markup = require('openmw.markup')
local vfs = require('openmw.vfs')
local types = require('openmw.types')
local I = require('openmw.interfaces')
local world = require('openmw.world')

require('scripts.niftyspellpack.settings.global')

local effectHandlers = {}
for path in vfs.pathsWithPrefix('scripts/niftyspellpack/effects/') do
    if path:match('global%.lua$') then
        local effectId = path:match('scripts/niftyspellpack/effects/(.-)/global%.lua$')
        if effectId then
            effectHandlers['nsp_' .. effectId] = require('scripts.niftyspellpack.effects.' .. effectId .. '.global')
        end
    end
end

local data = markup.loadYaml('scripts/niftyspellpack/spellInfo.yaml')
local npcSpellMap = {}
local npcConditions = {}
for _, spellData in ipairs(data.spells) do
    if spellData.npcs then
        for _, npcId in ipairs(spellData.npcs) do
            npcSpellMap[npcId:lower()] = npcSpellMap[npcId:lower()] or {}
            table.insert(npcSpellMap[npcId:lower()], spellData.id)
        end
    end
    if spellData.npcConditions then
        npcConditions[spellData.id] = spellData.npcConditions
    end
end

local function createCtx(target, data)
    local ctx = {
        target = target,
    }
    data = data or {}
    for k, v in pairs(data) do
        ctx[k] = v
    end
    return ctx
end

local function checkConditions(target, conditions)
    for _, condition in ipairs(conditions) do
        if condition.type == 'skillMin' then
            if target.type.stats.skills[condition.skill](target).base < condition.value then
                return false
            end
        elseif condition.type == 'skillMax' then
            if target.type.stats.skills[condition.skill](target).base > condition.value then
                return false
            end
        elseif condition.type == 'sellsAny' then
            local any = false
            for _, spell in ipairs(target.type.spells(target)) do
                if spell.type == core.magic.SPELL_TYPE.Spell then
                    for _, effect in ipairs(spell.effects) do
                        if effect.effect.school == condition.school then
                            any = true
                            break
                        end
                    end
                end
            end
            if not any then return false end
        end
    end
    return true
end

local function assignSpells(npc)
    local record = npc.type.record(npc)
    if not record.servicesOffered.Spells then
        return
    end

    local spellsToAdd = npcSpellMap[npc.recordId:lower()]
    local seen = {}
    if spellsToAdd then
        for _, spellId in ipairs(spellsToAdd) do
            npc.type.spells(npc):add(core.magic.spells.records[spellId])
            seen[spellId] = true
        end
    end
    for spellId, conditions in pairs(npcConditions) do
        if not seen[spellId] and checkConditions(npc, conditions) then
            npc.type.spells(npc):add(core.magic.spells.records[spellId])
        end
    end
end

I.Activation.addHandlerForType(types.NPC, function(npc)
    assignSpells(npc)
end)

local tomeDefs = {
	{
		tomeId = "spelltome_nsp_conj",
		message = "You have learned a Conjuration spell from this tome.",
		spells = {
			"nsp_pocket",
		},
	},
	{
		tomeId = "spelltome_nsp_myst",
		message = "You have learned several Mysticism spells from this tome.",
		spells = {
			"nsp_contingency",
			"nsp_projection",
			"nsp_greaterprojection",
			"nsp_wildintervention",
		},
	},
	{
		tomeId = "spelltome_nsp_alt",
		message = "You have learned an Alteration spell from this tome.",
		spells = {
			"nsp_alacrity",
		},
	},
}

local function giveStartingTomes(data) -- spell tomes
	local player = data.player
	if not player or not player:isValid() then
		player = world.players[1]
	end
	if not player or not player:isValid() then return end
	
	local inv = types.Actor.inventory(player)
	for _, def in ipairs(tomeDefs) do
		if not inv:find(def.tomeId) then
			local tome = world.createObject(def.tomeId, 1)
			tome:moveInto(inv)
		end
	end
end

return {
    engineHandlers = {
        onLoad = function(save)
            if save then
                if save.effectData then
                    for effectId, data in pairs(save.effectData) do
                        local handlers = effectHandlers[effectId]
                        if handlers and handlers.onLoad then
                            handlers.onLoad(data)
                        end
                    end
                end
            end
        end,
        onSave = function()
            local effectData = {}
            for effectId, handlers in pairs(effectHandlers) do
                if handlers.onSave then
                    local data = handlers.onSave()
                    if data then
                        effectData[effectId] = data
                    end
                end
            end

            return {
                effectData = effectData,
            }
        end  
    },
    eventHandlers = {
        NSP_EffectEvent = function(data)
            local effectHandler = effectHandlers[data.effectId]
            if effectHandler and effectHandler[data.type] then
                effectHandler[data.type](createCtx(data.target, data.ctx))
            end
        end,
        NSP_Teleport = function(data)
            data.target:teleport(data.cell or '', data.position, data.options)
        end,
		NSP_GiveStartingTomes = giveStartingTomes,
    },
}