
local level_based_illusion_effects = {49, 50, 51, 52, 53, 54, 55, 56}

---@param e spellResistEventData
local function on_effect(e)
    local target = e.target
    local target_mobile = target.mobile
    if not target_mobile then return end
    ---@cast target_mobile tes3mobilePlayer|tes3mobileNPC|tes3mobileCreature
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
                local calm_mag = target_mobile.fight
                local frenzy_mag = math.max(100 - target_mobile.fight, 0)
                if math.random(mag_min, mag_max) >= target_level then
                    if effect_id >= 53 and effect_id <= 56 then
                        tes3.applyMagicSource{
                        reference = target,
                        name = "Illusion",
                        effects = {{id = effect_id, duration = duration, min = 100, max = 100}}
                        }
                    end
                    if (effect_id == 51 and target_mobile.actorType == 1) or (effect_id == 52 and target_mobile.actorType == 0) then
                        for _, cell in pairs(tes3.getActiveCells()) do
                            for actor in cell.actors do
                                local actor_mobile = actor.mobile
                                ---@cast actor_mobile tes3mobilePlayer|tes3mobileNPC|tes3mobileCreature
                                if actor_mobile and not actor.disabled then
                                    if not actor_mobile.isDead and actor ~= target and target.position:distance(actor.position) < 900 then
                                        target_mobile:startCombat(actor_mobile)
                                    end
                                end
                            end
                        end
                        local caster_mobile = e.caster.mobile
                        ---@cast caster_mobile tes3mobilePlayer|tes3mobileNPC|tes3mobileCreature
                        target_mobile:startCombat(caster_mobile)
                        tes3.applyMagicSource{
                            reference = target,
                            name = "Frenzy",
                            effects = {{id = effect_id, duration = duration, min = frenzy_mag, max = frenzy_mag}}
                            }
                    end
                    if (effect_id == 49 and target_mobile.actorType == 1) or (effect_id == 50 and target_mobile.actorType == 0) then
                        target_mobile:stopCombat(false)
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