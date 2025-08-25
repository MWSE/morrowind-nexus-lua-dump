local world = require('openmw.world')
local types = require('openmw.types')
local core = require('openmw.core')

-- Mastrius Script attacher
local function attachScript(actor)
    local player = world.players[1]

    -- Define quests
    local quests = types.Player.quests(player)
    local quest1 = quests['nibs_mastrius']
    local quest2 = quests['nibs_spellbreaker']

    -- Require Quests
    if (quest1 and quest1.stage >= 1) or (quest2 and quest2.stage >= 1) then
        -- Apply Local script to Actor
        actor:addScript('scripts/nibswanderingshield/mastrius.lua')
    end
end

-- Mastrius Slain
local function mastriusJournalUpdate()
    local player = world.players[1]
    local quests = types.Player.quests(player)
    local quest1 = quests['nibs_mastrius']

    if (quest1 and quest1.stage >= 1) then
        -- Mastrius journal update
        quest1:addJournalEntry(80)
    end
end

return {
    engineHandlers = {
        onActorActive = function(actor)
            -- Define Actor name
            if actor.recordId == 'mastrius' then
                attachScript(actor)
            end
        end
    },
    eventHandlers = {
        MastriusJournalUpdate = mastriusJournalUpdate
    }
}