

local types = require("openmw.types")
local ranActors = {}
local registeredSpells = {}
local prefix = "LMM"
local function onActorActive(actor)
    if not ranActors[actor.id] and actor.type == types.NPC then
        local function hasSpell(spellName, actor)
            return types.Actor.spells(actor)[spellName] ~= nil
        end
        local function string_to_seed(str)
            local hash = 0
            for i = 1, #str do hash = (hash * 31 + string.byte(str, i)) % 2 ^ 32 end
            return hash
        end
        local function random_from_string(str, max)
            local seed = string_to_seed(str)
            seed = (1103515245 * seed + 12345) % 2 ^ 31
            return (seed % max) + 1
        end
        for spellId, data in pairs(registeredSpells) do
            local eligible = true
            if data.spellRequired then
                if not hasSpell(data.spellRequired, actor) then
                    eligible = false
                end
            end
            if data.chance < 100 then
                local random = random_from_string(actor.recordId .. spellId,100)
                  if random  > data.chance then
                   eligible = false
                end
            end
            if eligible and not hasSpell(spellId, actor) then
                 types.Actor.spells(actor):add(spellId)
            end
        end
            ranActors[actor.id] = true
    end
end
local function registerSpellEvent(data)
    registeredSpells[data.spellId] = data
end
return {
    engineHandlers = {
        onActorActive = onActorActive,
        onSave = function()
            return {

                ranActors = ranActors,
            }
        end,
        onLoad = function(data)
            if data then
                ranActors = data.ranActors
            end
        end
    },
    eventHandlers = {
        [prefix .. "_" .. "registerSpell"] = registerSpellEvent
    }
}