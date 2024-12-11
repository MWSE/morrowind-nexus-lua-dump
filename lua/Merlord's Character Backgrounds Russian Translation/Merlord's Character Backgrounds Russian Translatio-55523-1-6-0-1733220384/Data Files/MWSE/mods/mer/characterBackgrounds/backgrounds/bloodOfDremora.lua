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
    name = "Кровь дреморы",
    description = (
        "Давным-давно в ходе темного ритуала вы смешали свою кровь с кровью дреморы. " ..
        "Это не только усилило ваш магический дар, но и изрядно разозлило даэдра. " ..
        "Время от времени дремора будет являться в Нирн и устраивать охоту за вами. " ..
        "Каждый раз, одержав над ним победу, вы впитываете его кровь, благодаря чему все ваши магические навыки увеличиваются на 1."
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
            '"Верни мне мою кровь, смертный!"',
            "\"\"Это конец, {pcName}!\"",
            "\"\"Твоя душа принадлежит мне, {pcName}!\"",
            "\"Ты пожалеешь о том дне, когда моя кровь смешалась с твоей, смертный!\"",
            "\"Будь ты проклят, {pcName}!\"В следующий раз я тебя убью!",
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
            message = "Кровь дреморы течет по вашим жилам. Ваши магические навыки повысились!",
            buttons = { "Готово" }
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