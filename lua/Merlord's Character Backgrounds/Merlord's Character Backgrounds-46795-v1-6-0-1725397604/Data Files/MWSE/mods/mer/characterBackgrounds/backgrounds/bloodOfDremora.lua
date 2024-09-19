local interop = require('mer.characterBackgrounds.interop')

local INTERRUPT_CHANCE = 0.5
local MAGIC_SKILLS = {
    tes3.skill.alchemy,
    tes3.skill.alteration,
    tes3.skill.conjuration,
    tes3.skill.destruction,
    tes3.skill.enchant,
    tes3.skill.illusion,
    tes3.skill.mysticism,
    tes3.skill.restoration,
}

local background = interop.addBackground{
    id = "dremoraBlood",
    name = "Blood of the Dremora",
    description = (
        "Long ago, you performed a dark ritual to infuse your blood with that of a dremora. " ..
        "While it did increase your magical affinity, it also angered the him a great deal. " ..
        "Every once in a while, the daedra will summon himself to Nirn and hunt you down. " ..
        "Whenever he is defeated, you absorb his blood, causing all your magic skills to increase by 1."
    ),
    defaultData = {
        dremoraKilled = 0
    },
}
if not background then return end

--replace interrupt creature with dremora
local function onRestInterrupt(e)
    event.unregister("restInterrupt", onRestInterrupt)
    if not background:isActive() then return end

    e.creature = tes3.getObject("mer_bg_dremList")
    do --show message
        local introPhrases = {
            '"Give me back my blood, mortal!"',
            "\"This is the end, {pcName}!\"",
            "\"Your soul belongs to me, {pcName}!\"",
            "\"You'll rue the day you took my blood, mortal!\"",
            "\"Curse you, {pcName}!\" I will kill you next time!",
        }
        local selectedPhrase = table.choice(introPhrases) --[[@as string]]
        selectedPhrase = selectedPhrase:gsub("{pcName}", tes3.player.object.name)
        tes3.messageBox(selectedPhrase)
    end

    tes3.playSound({
        sound = "dremora scream"
    })
end


--calculate whether to replace interrupt creature with dremora
event.register("calcRestInterrupt", function(e)
    if not background:isActive() then return end
    --One dremora killed every two levels, starting at lvl 2
    local readyForDremora = tes3.player.object.level >= 2 + (background.data.dremoraKilled * 2)
    if readyForDremora then
        if math.random() < INTERRUPT_CHANCE then
            event.register("restInterrupt", onRestInterrupt)
            e.count = 1
            e.hour = math.random(1, 3)
        end
    end
end)

--When dremora is dead, increase all magic skills by +1
event.register("death", function(e)
    if not background:isActive() then return end
    if string.find(e.reference.baseObject.id, "mer_bg_drem") then
        tes3.playSound({ sound = "dremora moan"})
        e.reference:delete()
        background.data.dremoraKilled = background.data.dremoraKilled + 1
        for _, skill in ipairs(MAGIC_SKILLS) do
            tes3.modStatistic({
                reference = tes3.player,
                skill = skill,
                value = 1
            })
        end
        tes3.messageBox({
            message = "Dremora blood courses through your veins. Your magic skills have increased!",
            buttons = { "Okay" }
        })
    end
end)

--Prevent looting dremora
event.register("activate", function(e)
    if not background:isActive() then return end
    if e.target and string.find(e.target.baseObject.id, "mer_bg_drem") then
        return false
    end
end)