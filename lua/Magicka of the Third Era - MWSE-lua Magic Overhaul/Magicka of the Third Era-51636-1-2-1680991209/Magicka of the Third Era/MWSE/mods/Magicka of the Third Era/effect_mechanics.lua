
local level_based_illusion_effects = {49, 50, 51, 52, 53, 54, 55, 56}

local function on_effect(e)
    local target = e.target
    local target_mobile = target.mobile
    
    if not target_mobile then return end
    if e.sourceInstance.sourceType == 3 then return end

    local target_level = e.target.object.level
    local spell = e.source
    local index
    for i, effect_id in ipairs(level_based_illusion_effects) do
        index = spell:getFirstIndexOfEffect(effect_id) + 1
        if index > 0 then
            if spell.effects[index].min < 9999 then
                local mag_min = spell.effects[index].min
                local mag_max = spell.effects[index].max
                local duration = spell.effects[index].duration
                local target_fight = target_mobile.fight
                local calm_mag = target_mobile.fight
                local frenzy_mag = math.min(100 - target_mobile.fight, 0)
                if math.random(mag_min, mag_max) > target_level then
                    if effect_id >= 53 and effect_id <= 56 then
                        tes3.applyMagicSource{
                        reference = target,
                        name = "Illusion",
                        effects = {{id = effect_id, duration = duration, min = 100, max = 100}}
                        }
                    end
                    if (effect_id == 51 and target_mobile.actorType == 1) or (effect_id == 52 and target_mobile.actorType == 0) then
                        for _, cell in pairs(tes3.getActiveCells()) do
                            for actor in tes3.iterate(cell.actors) do
                                if actor.mobile and not actor.disabled then
                                    if not actor.mobile.isDead and actor ~= target and target.position:distance(actor.position) < 900 then
                                        mwscript.startCombat{reference = target, target = actor}
                                    end
                                end
                            end
                        end
                        mwscript.startCombat{reference = target, target = e.caster}
                        tes3.applyMagicSource{
                            reference = target,
                            name = "Frenzy",
                            effects = {{id = effect_id, duration = duration, min = frenzy_mag, max = frenzy_mag}}
                            }
                    end
                    if (effect_id == 49 and target_mobile.actorType == 1) or (effect_id == 50 and target_mobile.actorType == 0) then
                        mwscript.stopCombat{reference = target, target = e.caster}
                        tes3.applyMagicSource{
                            reference = target,
                            name = "Calm",
                            effects = {{id = effect_id, duration = duration, min = calm_mag, max = calm_mag}}
                            }
                    end
                else
                    e.resistedPercent = 100
                end
            end
        end
    end

end

local function initialized()
    event.register("spellResist", on_effect)
end

event.register("initialized", initialized)