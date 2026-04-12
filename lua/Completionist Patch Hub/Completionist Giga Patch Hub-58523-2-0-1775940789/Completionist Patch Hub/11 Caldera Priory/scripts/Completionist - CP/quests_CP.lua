local self = require('openmw.self')
local quests = {
    {
        id = "SLF_CP_AHeartlessAffair",
        name = "A Heartless Affair",
        category = "Side Quest",
        subcategory = "Caldera Priory",
        master = "Caldera Priory",
        text = "I have been drawn into a strange matter in the Halls of the Damned and should see it through."
    },

    {
        id = "SLF_CP_TheSkeletonKing",
        name = "The Skeleton King",
        category = "Main Quest",
        subcategory = "Caldera Priory",
        master = "Caldera Priory",
        text = "I must descend beneath Caldera Priory, confront the evil behind its fall, and find a way to end the threat."
    },

    {
        id = "SLF_CP_ASmithingMatter",
        name = "A Smithing Matter",
        category = "Side Quest",
        subcategory = "Caldera Priory",
        master = "Caldera Priory",
        text = "Chalda has asked me to recover a missing smithing hammer from the depths below the priory."
    },

    {
        id = "SLF_CP_AGruesomeFate",
        name = "A Gruesome Fate",
        category = "Side Quest",
        subcategory = "Caldera Priory",
        master = "Caldera Priory",
        text = "I have agreed to investigate the ruin of Caldera Priory and put an end to the undead menace there."
    },

    {
        id = "SLF_CP_ABurningSoul",
        name = "A Burning Soul",
        category = "Side Quest",
        subcategory = "Caldera Priory",
        master = "Caldera Priory",
        text = "A restless voice bound to a burnt corpse has set me on a grim errand deep within the Halls of the Damned."
    },

    {
        id = "SLF_CP_AVowOfFealty",
        name = "A Vow of Fealty",
        category = "Side Quest",
        subcategory = "Caldera Priory",
        master = "Caldera Priory",
        text = "A peculiar skull has asked to be carried to the Chapel of Vows for an old rite."
    },

    {
        id = "SLF_CP_AKingsArmor",
        name = "A King's Armor",
        category = "Side Quest",
        subcategory = "Caldera Priory",
        master = "Caldera Priory",
        text = "The remains of the Skeleton King's armor may yet be restored into something of use."
    },

    {
        id = "SLF_CP_AGustOfWind",
        name = "A Gust of Wind",
        category = "Side Quest",
        subcategory = "Caldera Priory",
        master = "Caldera Priory",
        text = "A whisper in the Bowels of Hatred has pointed me toward a hidden prize."
    },

    {
        id = "SLF_CP_ALostPrior",
        name = "A Lost Prior",
        category = "Side Quest",
        subcategory = "Caldera Priory",
        master = "Caldera Priory",
        text = "I have been asked to search the depths below Caldera Priory for the missing prior, Demus Caelian."
    },

}

local hasSent = false
return {
    engineHandlers = {
        onUpdate = function(dt)
            if not hasSent then
                self:sendEvent("Completionist_RegisterPack", quests)
                hasSent = true
            end
        end
    }
}
-- Quest count: 9
