local distillation = {}

local recipes = require("vozhban.lordofskooma.recipes")
local apparatusState = require("vozhban.lordofskooma.apparatusState")
local values = require("vozhban.lordofskooma.values")
local effectPreview = require("vozhban.lordofskooma.effectPreview")

local function diminish(value)
    local output = 0
    local i = 1
    while value > 100 do
        value = value - 100
        output = output + math.floor(100/i)
        i = i + 1
    end
    output = output + math.floor(value/i)
    return output
end

function distillation.getProwess()
    local alchemy = diminish(tes3.mobilePlayer.alchemy.current)
    local intelligence = diminish(tes3.mobilePlayer.intelligence.current)
    local luck = diminish(tes3.mobilePlayer.luck.current)
    return alchemy + intelligence / 5 + luck / 10
end

function distillation.getMainIngredConsumption(apparatus, recipeId)
    local base = recipes.recipeList[recipeId].required
    local bonus = math.floor(apparatusState.getCalcinatorBonus(apparatusState.getTotals(apparatusState.get(apparatus))))
    local prowess = math.floor(distillation.getProwess() * 0.01)
    return math.max(1, base - bonus - prowess)
end

function distillation.getMainIngredConsumptionFinal(apparatus, recipeId, prowess)
    local base = recipes.recipeList[recipeId].required
    local bonus = math.floor(apparatusState.getCalcinatorBonus(apparatusState.getTotals(apparatusState.get(apparatus))))
    prowess = math.floor(prowess * 0.01)
    return math.max(1, base - bonus - prowess)
end

function distillation.getRecipeDifficulty(apparatus, recipeId)
    local base = recipes.recipeList[recipeId].difficulty
    local bonus  = apparatusState.getMortarBonus(apparatusState.getTotals(apparatusState.get(apparatus)))
    return math.max(0, base - bonus)
end

function distillation.getDistillationTime(apparatus)
    local prowess = distillation.getProwess() * 0.001
    local mult = 1 - apparatusState.getAlembicBonus(apparatusState.getTotals(apparatusState.get(apparatus))) - prowess
    return math.max(values.distillationTime * mult, 0.01)
end

function distillation.getDistillationTimeMult(apparatus)
    local prowess = distillation.getProwess() * 0.001
    return math.max((1 - apparatusState.getAlembicBonus(apparatusState.getTotals(apparatusState.get(apparatus))) - prowess) * 100, 1)
end

function distillation.getSuccessChance(apparatus, recipeId)
    return distillation.getProwess() - distillation.getRecipeDifficulty(apparatus, recipeId)
end

local function addProduct(state, id, count)
    state.storage[id] = (state.storage[id] or 0) + count
end

local function consumeIngred(state, ingredId, count)
    state.storage[ingredId] = math.max(0, (state.storage[ingredId] or 0) - count)
    if state.storage[ingredId] == 0 then
        state.storage[ingredId] = nil
    end
end

function distillation.updateAll()
    for apparatus in tes3.player.cell:iterateReferences(tes3.objectType.miscItem, false) do
        if apparatus.id == "apparatus_skooma" then
            local state = apparatusState.get(apparatus)
            
            local samples = state.prowessSamples or {}
            local sampleTimeStamp = state.startTime or 0
            if #samples < 10 and state.isRunning and sampleTimeStamp and tes3.getSimulationTimestamp() - sampleTimeStamp >= distillation.getDistillationTime(apparatus) / 10 then
                table.insert(samples, distillation.getProwess())
                apparatusState.setValue(apparatus, "prowessSamples", samples)
                sampleTimeStamp = tes3.getSimulationTimestamp()
                --mwse.log("Prowess Sample = %d", distillation.getProwess())
            end

            if state.isRunning and state.startTime and tes3.getSimulationTimestamp() - state.startTime >= distillation.getDistillationTime(apparatus) then
                apparatusState.setValue(apparatus, "isRunning", false)
                apparatusState.setValue(apparatus, "startTime", nil)

                distillation.run(apparatus)

                if state.mode == 0 and (state.storage[state.mainIngredId] or 0) >= distillation.getMainIngredConsumption(apparatus, state.mainIngredId) then
                    apparatusState.setValue(apparatus, "isRunning", true)
                    apparatusState.setValue(apparatus, "startTime", tes3.getSimulationTimestamp())
                    apparatusState.setValue(apparatus, "prowessSamples", {})
                    tes3.createVisualEffect{
                        position = apparatus.position:copy(),
                        object = "Light_Fire",
                        lifespan = distillation.getDistillationTime(apparatus)*120,
                        scale = 0.1,
                        verticalOffset = 0
                    }
                end
            end
        end
    end
end

function distillation.run(apparatus)
    local state = apparatusState.get(apparatus)
    local recipeId = state.mainIngredId
    local recipe = recipes.recipeList[recipeId]
    --mwse.log("Starting distillation of %s", recipes.recipeList[recipeId].name)
    if not recipe then
        tes3.messageBox("Invalid recipe " .. recipeId)
        return
    end

    local vanillaMode = apparatusState.getForceVanilla(apparatus)
    if not vanillaMode then
        -- No secondary ingreds AND no non-retort upgrades - vanilla anyway
        local hasSec  = next(state.secondaryIngreds or {}) ~= nil
        local hasRealUpgrade = false
        for i = 1, values.maxUpgradeSlots do
            local up = state.upgrades and state.upgrades[i]
            if up then
                local t = tes3.getObject(up).type
                if t == tes3.apparatusType.retort then hasRealUpgrade = true break end
            end
        end
        vanillaMode = (not hasSec) and (not hasRealUpgrade)
        --mwse.log("Set to vanilla mode: %s", tostring(vanillaMode))
    end

    local player = tes3.mobilePlayer
    local prowess = math.huge
    for _, v in ipairs(state.prowessSamples or {}) do
        prowess = math.min(prowess, v)
    end

    local required = distillation.getMainIngredConsumptionFinal(apparatus, recipeId, prowess)
    local difficulty = distillation.getRecipeDifficulty(apparatus, recipeId)
    --local available = state.storage[state.mainIngredId]

    local checklist = { { id = state.mainIngredId } }           -- main is always checked
    if not vanillaMode then
        for slot = 1, values.maxUpgradeSlots * 2 do        -- only slotted secondaries
            local sid = state.secondaryIngreds and state.secondaryIngreds[slot]
            if sid then
                table.insert(checklist, { id = sid })
            end
        end
    end

    local availMap = {}            -- id → pieces in storage
    local minAvail = math.huge
    for _, entry in ipairs(checklist) do
        local n = state.storage[entry.id] or 0
        availMap[entry.id] = n
        if n < minAvail then minAvail = n end
    end

    local function attemptDistill()

        local tempProwess = prowess - difficulty
        local guaranteed = math.floor(tempProwess / 100)
        local chance = tempProwess % 100
        local roll = math.random(0, 99)
        local totalProduced = guaranteed + (roll < chance and 1 or 0)

        if required < totalProduced then
            if minAvail >= totalProduced then
                required = totalProduced
            else
                totalProduced = minAvail
                required = minAvail
            end
        end

        for _, entry in ipairs(checklist) do
            if availMap[entry.id] < required then
                --mwse.log("[Distill] Skipping batch: not enough %s (%d < %d)", entry.id, availMap[entry.id], required)
                tes3.messageBox("Not enough %s (%d/%d) to run the next batch", tes3.getObject(entry.id).name, required, availMap[entry.id])
                state.mode = 1
                return
            end
        end

        if totalProduced > 0 then
            local fracSuccess = math.clamp(roll / chance, 0, 1) - 0.5
            if guaranteed > 0 then fracSuccess = -0.95 end

            --Imprtant: Retort bonus output can exceed 1:1 consumption limit.
            --Which also means that at really high skill values when consumption is increased
            --to accomodate large batches it effectively takes away instances of retort application.
                                                                --And I will do nothing about it.
            local bonusCount = 0
            for i = 1, values.maxUpgradeSlots do
                local upgrade = state.upgrades and state.upgrades[i]
                if upgrade then
                    local item = tes3.getObject(upgrade)
                    if item and item.type == tes3.apparatusType.retort then
                        local bonusOutputChance = apparatusState.getRetortBonus(apparatusState.getTotals(state)) * item.quality
                        local bonusRoll = math.random(0, 99)
                        if bonusRoll < bonusOutputChance then
                            totalProduced = totalProduced + 1
                            bonusCount = bonusCount + 1
                        end
                    end
                end
            end

            local ingredCount = 0
            for _, entry in ipairs(checklist) do
                consumeIngred(state, entry.id, required)
                ingredCount = ingredCount + required
            end

            local productId
            if vanillaMode then
                productId = recipe.result
                --mwse.log("Vanilla mode distillation")
            else
                local baseObj   = tes3.getObject(recipe.result)
                local baseEffectCount = baseObj:getActiveEffectCount()
                --mwse.log("Craft mode distillation")

                ----------------------------------------------------------------
                -- helpers ------------------------------------------------------
                ----------------------------------------------------------------
                local function effKey(id, attr, skill)
                    if attr  then return ("%dA%d"):format(id, attr) end   -- attribute variant
                    if skill then return ("%dS%d"):format(id, skill) end  -- skill variant
                    return tostring(id)                                   -- plain effect
                end

                local effects   = {}        -- key → { id, attr, skill, power }
                local function addEffect(id, attr, skill, pwrAdd)
                    local key = effKey(id, attr, skill)
                    local e   = effects[key]
                    if not e then
                        e = { id = id, attr = attr, skill = skill, power = 0 }
                        effects[key] = e
                    end
                    e.power = e.power + (pwrAdd or 0)
                end

                local function eachEffect(obj, fn)
                    if obj.objectType == tes3.objectType.ingredient then
                        for idx, id in ipairs(obj.effects) do
                            if id ~= -1 then
                                local me    = tes3.getMagicEffect(id)
                                if not me then return end
                                local attr  = (me.targetsAttributes and obj.effectAttributeIds and obj.effectAttributeIds[idx]) or nil
                                local skill = (me.targetsSkills     and obj.effectSkillIds     and obj.effectSkillIds[idx])     or nil
                                fn(id, attr, skill)
                            end
                        end
                    elseif obj.objectType == tes3.objectType.alchemy then
                        for _, e in ipairs(obj.effects) do
                            if e.id ~= -1 then
                                local me    = tes3.getMagicEffect(e.id)
                                if not me then return end
                                local attr  = (me.targetsAttributes and (e.attribute or e.attributeId)) or nil
                                local skill = (me.targetsSkills     and (e.skill     or e.skillId))     or nil
                                fn(e.id, attr, skill)
                            end
                        end
                    end
                end

                ----------------------------------------------------------------
                -- 1.  baseline (base potion effects, 0 power) -----------------
                ----------------------------------------------------------------
                local baseMag   = (baseObj.effects[1].max + baseObj.effects[1].min) / 2 or 1
                local baseDur   = baseObj.effects[1].duration or 1
                local baseVal   = baseObj.value or 1

                for _, eff in ipairs(baseObj.effects) do
                    if eff.id ~= -1 then
                        addEffect(eff.id, eff.attribute, eff.skill, 0)
                    end
                end

                local totalPower     = 0
                local retortValBonus = 0

                ----------------------------------------------------------------
                -- 2.  apparatuses in slot order --------------------------------
                ----------------------------------------------------------------
                for slot = 1, values.maxUpgradeSlots do
                    local upId = state.upgrades and state.upgrades[slot]
                    if upId then
                        local app   = tes3.getObject(upId)
                        local q     = app.quality
                        local t     = app.type

                        --------------------------------------------------------
                        -- MORTAR (needs two ingreds)
                        --------------------------------------------------------
                        if t == tes3.apparatusType.mortarAndPestle then
                            local sid1 = state.secondaryIngreds[(slot-1)*2+1]
                            local sid2 = state.secondaryIngreds[(slot-1)*2+2]
                            if sid1 and sid2 then
                                local ing1, ing2 = tes3.getObject(sid1), tes3.getObject(sid2)

                                eachEffect(ing1, function(id1, attr, skill)
                                    eachEffect(ing2, function(id2, attr2, skill2)
                                        if id1 == id2 and attr == attr2 and skill == skill2 then
                                            local key = effKey(id1, attr, skill)
                                            if effects[key] then
                                                addEffect(id1, attr, skill, q)              -- boost
                                                totalPower = totalPower + q
                                                --mwse.log("[mortar] added existing effect %s", tes3.effect.id1)
                                            else
                                                addEffect(id1, attr, skill, 0)              -- first time
                                                --mwse.log("[mortar] added new effect %s", tes3.effect.id1)
                                            end
                                        end
                                    end)
                                end)
                            end

                        --------------------------------------------------------
                        -- CALCINATOR (one ingred, random full rolls + fraction)
                        --------------------------------------------------------
                        elseif t == tes3.apparatusType.calcinator then
                            local sid = state.secondaryIngreds[(slot-1)*2+1]
                            if sid then
                                local ing = tes3.getObject(sid)
                                local full = math.floor(q)
                                local frac = q - full

                                -- full rolls
                                for _ = 1, full do
                                    local idx   = math.random(#ing.effects)
                                    local id    = ing.effects[idx]
                                    if id ~= -1 then
                                        local me    = tes3.getMagicEffect(id)
                                        local attr  = (me and me.targetsAttributes and ing.effectAttributeIds and ing.effectAttributeIds[idx]) or nil
                                        local skill = (me and me.targetsSkills     and ing.effectSkillIds     and ing.effectSkillIds[idx])     or nil

                                        local key   = effKey(id, attr, skill)
                                        if effects[key] then
                                            addEffect(id, attr, skill, q)  -- boost
                                            totalPower = totalPower + q
                                            --mwse.log("[calcinator] added existing effect %s", tes3.effect.id)
                                        else
                                            addEffect(id, attr, skill, 0)  -- first time
                                            --mwse.log("[calcinator] added new effect %s", tes3.effect.id)
                                        end
                                    end
                                end

                                -- fraction part
                                if frac > 0 then
                                    local matched = false
                                    eachEffect(ing, function(id, attr, skill)
                                        local key = effKey(id, attr, skill)
                                        if not matched and effects[key] and effects[key].power > 0 then
                                            addEffect(id, attr, skill, frac)
                                            --mwse.log("[calcinator] added fraction for %s", tes3.effect.id)
                                            totalPower = totalPower + frac
                                            matched = true
                                        end
                                    end)
                                end
                            end

                        --------------------------------------------------------
                        -- ALEMBIC  (ingredient OR potion, boosts only)
                        --------------------------------------------------------
                        elseif t == tes3.apparatusType.alembic then
                            local sid = state.secondaryIngreds[(slot-1)*2+1]
                            if sid then
                                local obj = tes3.getObject(sid)
                                eachEffect(obj, function(id, attr, skill)
                                    if attr  == -1 then attr  = nil end
                                    if skill == -1 then skill = nil end
                                    local key = effKey(id, attr, skill)
                                    --mwse.log("[alembic distill] Key: "..key)
                                    if effects[key] and effects[key].power >= 0 then
                                        addEffect(id, attr, skill, q)
                                        totalPower = totalPower + q
                                        --mwse.log("[alembic] added existing effect %s", tes3.effect.id)
                                    end
                                end)
                            end

                        --------------------------------------------------------
                        -- RETORT  (flat power + value bonus, ignores effects)
                        --------------------------------------------------------
                        elseif t == tes3.apparatusType.retort then
                            totalPower     = totalPower + q
                            --mwse.log("[retort] added power %s", tostring(q))
                            local sid      = state.secondaryIngreds[(slot-1)*2+1]
                            if sid then
                                retortValBonus = retortValBonus
                                                + tes3.getObject(sid).value * q
                            end
                        end
                    end
                end

                ----------------------------------------------------------------
                -- 3.  final stats ---------------------------------------------
                ----------------------------------------------------------------
                local allCount = 0
                for _ in pairs(effects) do allCount = allCount + 1 end
                local extraEffects = math.min(math.max(0, allCount - baseEffectCount), 8 - baseEffectCount)

                local finalMag, finalDur
                if values.fractionScaling then
                    finalMag = baseMag * (1 + totalPower)
                    finalDur = baseDur * (1 + totalPower)
                else
                    finalMag = baseMag + totalPower * values.magnitudeScaling
                    finalDur = baseDur + totalPower * values.durationScaling
                end

                local finalVal = math.floor(baseVal * (1 + 0.1 * (totalPower + extraEffects)) + retortValBonus)

                ----------------------------------------------------------------
                -- 4.  create / fetch potion object ----------------------------
                ----------------------------------------------------------------
                -- deterministic ID so identical combos stack
                local keys  = {}
                for k in pairs(effects) do keys[#keys+1] = k end
                table.sort(keys)
                local sig   = table.concat(keys, "") .. "_" ..string.format("%.2f", totalPower) .. "_" .. finalVal


                local function shortHash(str)
                    local hash = 0x811C9DC5
                    for i = 1, #str do
                        hash = bit.bxor(hash, str:byte(i))
                        hash = bit.tobit(hash * 0x01000193)
                    end
                    -- ensure unsigned & return 8-digit hex
                    return ("%08X"):format(bit.tobit(hash))
                end

                local hash  = shortHash(sig)
                local prefixMax = 30 - 5 - 8        -- 5 for _los_ 8 for hash
                local base  = baseObj.name:gsub("%s+", "_"):sub(1, prefixMax)

                local newId = string.format("%s_los_%s", base, hash)

                if not tes3.getObject(newId) then
                    local pot = tes3.createObject{
                        objectType = tes3.objectType.alchemy,
                        id         = newId,
                        name       = baseObj.name .. " (Craft)",
                        icon       = baseObj.icon,
                        mesh       = baseObj.mesh,
                        weight     = baseObj.weight,
                        value      = finalVal,
                    }

                    local slot = 1
                    for _, k in ipairs(keys) do
                        local e = effects[k]
                        pot.effects[slot].id        = e.id
                        pot.effects[slot].min       = math.floor(finalMag)
                        pot.effects[slot].max       = math.floor(finalMag)
                        pot.effects[slot].duration  = math.floor(finalDur)
                        pot.effects[slot].rangeType = tes3.effectRange.self
                        pot.effects[slot].attribute = e.attr  or nil
                        pot.effects[slot].skill     = e.skill or nil
                        slot = slot + 1
                        if slot > 8 then break end       -- hard cap
                    end
                end

                productId = newId
            end


            addProduct(state, productId, totalProduced)

            tes3.playSound{reference = tes3.player, sound = "potion success"}
            tes3.createVisualEffect{
                position = apparatus.position:copy(),
                object = "VFX_PoisonHit",
                lifespan = 1.0,
                scale = 1.2,
                verticalOffset = -90
            }
            if bonusCount > 0 then
                tes3.messageBox("You produced %d(+%d) %s using %d ingredients", totalProduced, bonusCount, recipe.name, ingredCount)
            else
                tes3.messageBox("You produced %d %s using %d ingredients", totalProduced, recipe.name, ingredCount)
            end

            player:exerciseSkill(tes3.skill.alchemy, 2 * (1 + fracSuccess))
            --mwse.log("[Lord of Skooma] %s: %d used; %d gained", recipeId, required, totalProduced or 0)
        else
            local fail = roll - chance
            local maxFail = 100 - chance -- at 100 chance fail should not be possible. probably. hopefully.
            local fracLoss = math.clamp(fail / maxFail, 0, 1)
            local minLoss = 0.5
            local maxLoss = math.max(minLoss, fracLoss)

            local totalLost = 0

            for _, entry in ipairs(checklist) do
                local loss  = math.random() * (maxLoss - minLoss) + minLoss
                local lossCount = math.ceil(required * loss)
                lossCount       = math.min(lossCount, required)

                if lossCount > 0 then
                    consumeIngred(state, entry.id, lossCount)
                    totalLost = totalLost + lossCount
                end
            end

            tes3.playSound{reference = tes3.player, sound = "potion fail"}
            tes3.createVisualEffect{
                position = apparatus.position:copy(),
                object = "VFX_DestructHit",
                lifespan = 1.0,
                scale = 1.2,
                verticalOffset = -90
            }
            tes3.messageBox("You failed to produce any %s and lost %d ingredients", recipe.name, totalLost)
            player:exerciseSkill(tes3.skill.alchemy, math.max(0, 0.5 - fracLoss))
            --mwse.log("[Lord of Skooma] %s: %d → %d used; %d gained", recipeId, required, totalLost or 0, totalProduced or 0)
        end
    end

    attemptDistill()

end

return distillation
