local common = require("blight.common")

event.register("spellResist", function(e)
    -- only interested in cure blight effect
    if e.effect.id ~= tes3.effect.cureBlightDisease then
        return
    end

    common.debug("'%s' has had their blight disease cured!", e.target)

    -- clear progression tracking data
    if (e.target == tes3.player) and e.target.data.blight then
        e.target.data.blight.blightProgession = {}
    end

    -- trigger decal removal / etc
    event.trigger("blight:RemovedBlight", { reference = e.target })
end)

local function onLoaded()
    timer.start({
        duration = 10,
        iterations = -1,
        callback = function()
            tes3.player.data.blight = tes3.player.data.blight or {}
            tes3.player.data.blight.blightProgession = tes3.player.data.blight.blightProgession or {}
            local progressions = tes3.player.data.blight.blightProgession

            for spell in common.iterBlightDiseases(tes3.player) do
                if not progressions[spell.id] then
                    progressions[spell.id] = {
                        progression = 0,
                        lastDay = tes3.worldController.daysPassed.value,
                        days = 0,
                        nextProgession = math.random(2,3)
                    }

                    common.debug("Registered progression for '%s'.", spell.name)
                else
                    common.debug("Processing progression for '%s'.", spell.name)

                    local progression = progressions[spell.id]
                    progression.days = progression.days + tes3.worldController.daysPassed.value - progression.lastDay
                    progression.lastDay = tes3.worldController.daysPassed.value

                    if (progression.days >= progression.nextProgession) then
                        progression.progression = progression.progression + 1
                        progression.nextProgession = math.random(2, 8)
                        progression.days = 0

                        local progressionSpellId = "TB_" .. spell.id .. "_P"
                        local progressionSpell = tes3.getObject(progressionSpellId) or tes3spell.create(progressionSpellId, "Infectious " .. spell.name)

                        progressionSpell.name = "Infectious " .. spell.name

                        for i=1, #spell.effects do
                            local effect = progressionSpell.effects[i]
                            local newEffect = spell.effects[i]

                            effect.id = newEffect.id
                            effect.rangeType = newEffect.range
                            effect.min = 10 * progression.progression
                            effect.max = 20 * progression.progression
                            effect.duration = newEffect.duration
                            effect.radius = newEffect.radius
                            effect.skill = newEffect.skill
                            effect.attribute = newEffect.attribute
                        end

                        progressionSpell.castType = tes3.spellType.blight

                        mwscript.addSpell({
                            reference = tes3.player,
                            spell = progressionSpell
                        })

                        tes3.messageBox("Your %s worsens.", spell.name)
                    end
                end
            end
        end
    })
end
event.register("loaded", onLoaded)
