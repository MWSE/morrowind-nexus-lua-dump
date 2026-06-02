-- Declarations --
local nearby = require("openmw.nearby")
local types = require("openmw.types")
local self = require("openmw.self")
local core = require("openmw.core")
local util = require("openmw_aux.util")
local I = require("openmw.interfaces")

local infectedCritters = {}

-- Animal Handling skill
local l10n = core.l10n('CurableCritters')
local skillID = 'CurableCritters_animal_handling'
local useTypes = {
    FeedCreature = 1,
    CalmCreature = 2,
    CureCreature = 3,
}

-- register skill to player
I.SkillFramework.registerSkill(skillID, {
    name = l10n('Skill_Animal_Handling'),
    description = l10n('Skill_Animal_Handling_Desc'),
    icon = { fgr = 'icons/SkillFramework/animal_handling_option_1.dds' },
    attribute = 'Willpower',
    skillGain = {
        [useTypes.FeedCreature] = 1,
        [useTypes.CalmCreature] = 4,
        [useTypes.CureCreature] = 10,
    },
    modIntegration = {
        statsWindow = {
            subsection = I.SkillFramework.STATS_WINDOW_SUBSECTIONS.Nature
        }
    }
}
)

local function onUpdate()
    -- find all nearby actors sorted by distance
    local critters = util.mapFilterSort(
        nearby.actors,
        function(actor)
            return actor.type == types.Creature and (self.position - actor.position):length()
        end
    )

    infectedCritters = {}
    for _, critter in ipairs(critters) do
        -- filter creatures and check if creature is infected
        if critter and critter.type == types.Creature and string.find(critter.recordId, 'diseased') ~= nil then
            table.insert(infectedCritters, critter)
        end
    end
    core.sendGlobalEvent('infectCritters', infectedCritters)
end

return {
    engineHandlers = {
        onUpdate = onUpdate
    }
}
