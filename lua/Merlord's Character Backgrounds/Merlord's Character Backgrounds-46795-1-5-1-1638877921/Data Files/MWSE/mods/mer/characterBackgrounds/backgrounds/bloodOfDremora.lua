local dremoraBloodDoOnce
local dremoraInterruptChance = 0.30
local dremoraDoAttack

local getData = function()
    local data = tes3.player.data.merBackgrounds or {}
    data.dremoraBlood = data.dremoraBlood or {
        dremoraKilled = 0
    }
    return data
end

return {
    id = "dremoraBlood",
    name = "Blood of the Dremora",
    description = (
        "Long ago, you performed a dark ritual to infuse your blood with that of a dremora. " ..
        "While it did increase your magical affinity, it also angered the him a great deal. " ..
        "Every once in a while, the daedra will summon himself to Nirn and hunt you down. " ..
        "Whenever he is defeated, you absorb his blood, causing all your magic skills to increase by 1."
    ),
    callback = function()


        --calculate whether to replace interrupt creature with dremora
        local function calcRestInterrupt(e)
            local data = getData()
            if data.currentBackground == "dremoraBlood" then
                --One dremora killed every two levels, starting at lvl 2
                local readyForDremora = (
                    (tes3.player.object.level - 2) >= (  data.dremoraBlood.dremoraKilled * 2 )
                )
                if readyForDremora then
                    local rand = math.random()
                    if rand < dremoraInterruptChance then
                        dremoraDoAttack = true
                        e.count = 1
                        e.hour = math.random(1, 3)
                    end
                end
            end
        end

        --replace interrupt creature with dremora
        local function restInterrupt(e)
            local data = getData()
            if data.currentBackground == "dremoraBlood" then
                if dremoraDoAttack then
                    dremoraDoAttack = false
                    e.creature = tes3.getObject("mer_bg_dremList")
                    local pcName = tes3.player.object.name
                    local introPhrases = {
                        '"Give me back my blood, mortal!"',
                        string.format("\"This is the end, %s!\"", pcName),
                        string.format("\"Your soul belongs to me, %s!\"",  pcName),
                        "\"You'll rue the day you took my blood, mortal!\"",
                        string.format("\"Curse you, %s!\" I will kill you next time!", pcName)
                    }
                    tes3.playSound({
                        sound = "dremora scream"
                    })
                    tes3.messageBox( introPhrases[ math.random(#introPhrases)] )

                end
            end
        end

        --When dremora is dead, increase all magic skills by +1
        local function onDeath(e)
            local data = getData()
            if data.currentBackground == "dremoraBlood" then
                if string.find(e.reference.baseObject.id, "mer_bg_drem") then
                    local deathPhrases = {

                    }
                    tes3.messageBox( deathPhrases[math.random(#deathPhrases)] )

                    tes3.playSound({ sound = "dremora moan"})
                    mwscript.disable({ reference = e.mobile})

                    data.dremoraBlood.dremoraKilled = data.dremoraBlood.dremoraKilled + 1
                    local magicSkills = {
                        "illusion",
                        "alchemy",
                        "alteration",
                        "conjuration",
                        "destruction",
                        "enchant",
                        "mysticism",
                        "restoration"
                    }
                    for _, skill in ipairs(magicSkills) do
                        tes3.modStatistic({
                            reference = tes3.player,
                            skill = tes3.skill[skill],
                            value = 1
                        })
                    end
                    tes3.messageBox({
                        message = "Dremora blood courses through your veins. Your magic skills have increased!",
                        buttons = { "Okay" }
                    })
                end
            end
        end

        --Prevent looting dremora
        local function onActivate(e)
            if e.target and string.find(e.target.baseObject.id, "mer_bg_drem") then
                return false
            end
        end

        if dremoraBloodDoOnce then return end
        dremoraBloodDoOnce = true

        event.register("calcRestInterrupt", calcRestInterrupt)
        event.register("restInterrupt", restInterrupt)
        event.register("death", onDeath)
        event.register("activate", onActivate)
    end
}