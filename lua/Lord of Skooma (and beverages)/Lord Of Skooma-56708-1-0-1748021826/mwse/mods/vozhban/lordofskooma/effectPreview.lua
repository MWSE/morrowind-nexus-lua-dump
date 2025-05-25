local recipes       = require("vozhban.lordofskooma.recipes")
local apparatusState= require("vozhban.lordofskooma.apparatusState")
local values        = require("vozhban.lordofskooma.values")

---@param ref tes3reference
---@return table preview
local function calculate(ref)
    local state  = apparatusState.get(ref)
    local preview = {guaranteed = 0, potential = 0, effects = {}}

    -- Compose a unique key for an effect including attr/skill variant
    local function effKey(id, attr, skill)
        if attr and attr ~= -1 then return ("%d@A%d"):format(id, attr) end
        if skill and skill ~= -1 then return ("%d@S%d"):format(id, skill) end
        return tostring(id)
    end

    if not state.mainIngredId or state.mainIngredId == "" then return preview end

    local guaranteedMap = {}   -- quick look-up for (id+sub) → true

    local function addEffect(id, g, p, attr, skill, isG)
        ------------------------------------------------------------
        -- 0. Retort stub skips all look-ups
        ------------------------------------------------------------
        if id == "retort_fake" then
            local key = "retort_fake"
            if not preview.effects[key] then
                preview.effects[key] = {
                    id = "retort_fake", name = "Retort Amplification",
                    g = 0, p = 0, potentialOnly = false
                }
            end
            local fx = preview.effects[key]
            fx.g = fx.g + (g or 0)
            fx.p = fx.p + (p or 0)
            guaranteedMap[key] = true
            return
        end

        ------------------------------------------------------------
        -- 1.  Sanitize attr / skill against the effect definition
        ------------------------------------------------------------
        local me          = tes3.getMagicEffect(id)
        if not me then return end
        local usesAttr    = me.targetsAttributes
        local usesSkill   = me.targetsSkills

        if not usesAttr  then attr  = nil end
        if not usesSkill then skill = nil end
        if attr  == -1   then attr  = nil end
        if skill == -1   then skill = nil end

        ------------------------------------------------------------
        -- 2.  Build unique key (id with sub-index only if relevant)
        ------------------------------------------------------------
        local key = effKey(id, attr, skill)

        ------------------------------------------------------------
        -- 3.  Create entry if missing
        ------------------------------------------------------------
        if not preview.effects[key] then
            local name = me.name
            if usesAttr  and attr  then
                name = ("%s (%s)"):format(name, tes3.getAttributeName(attr))
            elseif usesSkill and skill then
                name = ("%s (%s)"):format(name, tes3.getSkillName(skill))
            end
            preview.effects[key] = {
                id = id, name = name,
                g = 0, p = 0,
                attr = attr, skill = skill,
                potentialOnly = not isG
            }
        end

        ------------------------------------------------------------
        -- 4.  Update powers & guarantee map
        ------------------------------------------------------------
        local fx = preview.effects[key]
        fx.g = fx.g + (g or 0)
        fx.p = fx.p + (p or 0)

        if isG or (g or 0) > 0 then
            fx.potentialOnly = false
            guaranteedMap[key] = true
        end
    end

    local function commitEmpower(g, p)
        preview.guaranteed = preview.guaranteed + (g or 0)
        preview.potential  = preview.potential  + (p or 0)
    end

    ------------------------------------------------------------
    -- 1.   base product
    local recipe   = recipes.recipeList[state.mainIngredId]
    local product  = recipe and tes3.getObject(recipe.result)
    if not product or product.objectType ~= tes3.objectType.alchemy then return preview end

    local baseMag  = (product.effects[1].max + product.effects[1].min) / 2 or 1
    local baseDur  = product.effects[1].duration or 1
    local baseEffectCount = product:getActiveEffectCount()

    preview.baseMag, preview.baseDur = baseMag, baseDur

    for idx, e in ipairs(product.effects) do
        if e.id ~= -1 then
            addEffect(e.id, 0, 0, e.attribute, e.skill, true)
        end
    end
    --commitEmpower(0, 0)

    ------------------------------------------------------------
    -- 2-4. apparatus / secondary loops  (order-sensitive)
    local sec      = state.secondaryIngreds or {}
    local upg      = state.upgrades or {}

    -- pass 1 – mortars ---------------
    for i = 1, values.maxUpgradeSlots do
        local up = upg[i]
        if up then
            local item = tes3.getObject(up)
            if item and item.type == tes3.apparatusType.mortarAndPestle then
                local id1, id2 = sec[(i-1)*2+1], sec[(i-1)*2+2]
                if id1 and id2 then
                    local ing1, ing2 = tes3.getObject(id1), tes3.getObject(id2)
                    for j, e1 in ipairs(ing1.effects) do
                        if e1 ~= -1 then
                            for k, e2 in ipairs(ing2.effects) do
                                if e1 == e2 then
                                    local me = tes3.getMagicEffect(e1)

                                    local function sameSubIndex(list1, idx1, list2, idx2)
                                        return list1 and list2 and list1[idx1] ~= nil
                                            and list1[idx1] == list2[idx2]
                                    end

                                    local match = false
                                    if me and me.targetsAttributes then
                                        match = sameSubIndex(ing1.effectAttributeIds, j,
                                                            ing2.effectAttributeIds, k)
                                    elseif me and me.targetsSkills then
                                        match = sameSubIndex(ing1.effectSkillIds, j,
                                                            ing2.effectSkillIds, k)
                                    else
                                        match = true      -- effect has no sub-index
                                    end

                                    if match then
                                        local key = effKey(e1, ing1.effectAttributeIds[j], ing1.effectSkillIds[j])
                                        if preview.effects[key] then
                                            addEffect(e1, item.quality, item.quality,
                                            ing1.effectAttributeIds and ing1.effectAttributeIds[j] or nil,
                                            ing1.effectSkillIds     and ing1.effectSkillIds[j]     or nil,
                                            true)
                                            commitEmpower(item.quality, item.quality)
                                        else
                                            addEffect(e1, 0, 0,
                                            ing1.effectAttributeIds and ing1.effectAttributeIds[j] or nil,
                                            ing1.effectSkillIds     and ing1.effectSkillIds[j]     or nil,
                                            true)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- pass 2 – calcinators ---------------------
    for i = 1, values.maxUpgradeSlots do
        local up = upg[i]
        if up then
            local item = tes3.getObject(up)
            if item and item.type == tes3.apparatusType.calcinator then
                local ingId = sec[(i-1)*2+1]      -- one slot
                if ingId then
                    local ing  = tes3.getObject(ingId)
                    local q    = item.quality
                    local full = math.floor(q)
                    local frac = q - full

                    ----------------------------------------------------
                    -- 1.  FULL part
                    for idx, id in ipairs(ing.effects) do
                        if id ~= -1 then
                            local attr  = ing.effectAttributeIds and ing.effectAttributeIds[idx] or nil
                            local skill = ing.effectSkillIds     and ing.effectSkillIds[idx] or nil
                            local key   = effKey(id, attr, skill)
                            if guaranteedMap[key] then
                                -- already guaranteed → whole FULL as potential
                                addEffect(id, 0, full, attr, skill, false)
                                commitEmpower(0, full)
                            else
                                -- not yet present or only baseline
                                if preview.effects[key] then
                                    -- present baseline → FULL becomes potential
                                    addEffect(id, 0, full, attr, skill, false)
                                    commitEmpower(0, full)
                                else
                                    -- first appearance = baseline (0 power)
                                    addEffect(id, 0, 0, attr, skill, false)
                                    if full > 1 then
                                        addEffect(id, 0, full-1, attr, skill, false)
                                        commitEmpower(0, full-1)
                                    end
                                end
                            end
                        end
                    end

                    ----------------------------------------------------
                    -- 2.  FRACTION part – may become guaranteed
                    if frac > 0 then
                        local upgraded = false
                        for idx, id in ipairs(ing.effects) do
                            if id ~= -1 then
                                local attr  = ing.effectAttributeIds and ing.effectAttributeIds[idx] or nil
                                local skill = ing.effectSkillIds     and ing.effectSkillIds[idx]     or nil
                                local key   = effKey(id, attr, skill)

                                if guaranteedMap[key] then
                                    -- matches an already-guaranteed variant
                                    addEffect(id, frac, frac, attr, skill, true)
                                    commitEmpower(frac, frac)
                                    upgraded = true
                                    break
                                end
                            end
                        end

                        if not upgraded then
                            -- stays POTENTIAL on every own effect
                            local proc = false
                            for idx, id in ipairs(ing.effects) do
                                if id ~= -1 then
                                    local attr  = ing.effectAttributeIds and ing.effectAttributeIds[idx] or nil
                                    local skill = ing.effectSkillIds     and ing.effectSkillIds[idx] or nil
                                    local key   = effKey(id, attr, skill)
                                    local fx    = preview.effects[key]
                                    if fx and fx.p > 0 then      -- “own potential effects” already present
                                        addEffect(id, 0, frac, attr, skill, false)
                                        proc = true
                                    end
                                end
                            end
                            if proc then commitEmpower(0, frac) end
                        end
                    end
                end
            end
        end
    end

    -- pass 3 – alembics (accept ingredients OR potions) --------------------------
    local function eachEffect(obj, fn)
        if not obj then return end
        if obj.objectType == tes3.objectType.ingredient then
            for idx, id in ipairs(obj.effects) do
                if id ~= -1 then
                    fn(id,
                    obj.effectAttributeIds and obj.effectAttributeIds[idx] or nil,
                    obj.effectSkillIds     and obj.effectSkillIds[idx]     or nil)
                end
            end
        elseif obj.objectType == tes3.objectType.alchemy then
            for _, e in ipairs(obj.effects) do
                if e.id ~= -1 then fn(e.id, e.attribute or e.attributeId, e.skill or e.skillId) end
            end
        end
    end

    for i = 1, values.maxUpgradeSlots do
        local up = upg[i]
        if up then
            local app = tes3.getObject(up)
            if app and app.type == tes3.apparatusType.alembic then
                local srcId = sec[(i-1)*2+1]          -- single slot
                if srcId then
                    local srcObj = tes3.getObject(srcId)
                    eachEffect(tes3.getObject(srcId), function(id, attr, skill)
                        local key = effKey(id, attr, skill)
                        local fx  = preview.effects[key]
                        if fx then
                            if guaranteedMap[key] then
                                addEffect(id, app.quality, app.quality, attr, skill, false)
                                commitEmpower(app.quality, app.quality)
                            else
                                addEffect(id, 0, app.quality, attr, skill, false)
                                commitEmpower(0, app.quality)
                            end
                        end
                    end)
                end
            end
        end
    end

    -- pass 4 – retorts
    local retortPoolValue = 0
    for i = 1, values.maxUpgradeSlots do
        local up = upg[i]
        if up then
            local item = tes3.getObject(up)
            if item and item.type == tes3.apparatusType.retort then
                addEffect("retort_fake", item.quality, item.quality) --actually passes waterBreathing which is 0
                retortPoolValue = retortPoolValue + (sec[(i-1)*2+1] and tes3.getObject(sec[(i-1)*2+1]).value or 0) * item.quality
                commitEmpower(item.quality, item.quality)
            end
        end
    end

    ------------------------------------------------------------
    -- 5-7. totals

    local gCount, allCount = 0, 0
    for _, fx in pairs(preview.effects) do
        if fx.id ~= "retort_fake" then
            allCount = allCount + 1
            if not fx.potentialOnly then gCount = gCount + 1 end
        end
    end
    local extraG  = math.min(math.max(0, gCount  - baseEffectCount), 8 - baseEffectCount)
    local extraP  = math.min(math.max(0, allCount - baseEffectCount), 8 - baseEffectCount)

    if values.fractionScaling then
        -- classic fractional scaling (old behaviour)
        preview.mag    = baseMag * (1 + preview.guaranteed)
        preview.magMax = baseMag * (1 + preview.potential)

        preview.dur    = baseDur * (1 + preview.guaranteed)
        preview.durMax = baseDur * (1 + preview.potential)
    else
        -- NEW additive scaling
        preview.mag    = baseMag + preview.guaranteed * values.magnitudeScaling
        preview.magMax = baseMag + preview.potential  * values.magnitudeScaling

        preview.dur    = baseDur + preview.guaranteed * values.durationScaling
        preview.durMax = baseDur + preview.potential  * values.durationScaling
    end

    local baseVal   = product.value or 1
    preview.value   = baseVal * (1 + 0.1*(preview.guaranteed + extraG)) + retortPoolValue
    preview.valueMax= baseVal * (1 + 0.1*(preview.potential + extraP)) + retortPoolValue

    -- split list
    local retList, gList, pList = {}, {}, {}

    for _, fx in pairs(preview.effects) do
        if fx.id == "retort_fake" then
            table.insert(retList, fx)    -- fake retort effect
        elseif fx.potentialOnly then
            table.insert(pList, fx)      -- possible effects
        else
            table.insert(gList, fx)      -- guaranteed
        end
    end

    table.sort(gList, function(a,b) return a.name < b.name end)
    table.sort(pList, function(a,b) return a.name < b.name end)

    preview.effects = {}
    for _, e in ipairs(retList) do table.insert(preview.effects, e) end
    for _, e in ipairs(gList)   do table.insert(preview.effects, e) end
    for _, e in ipairs(pList)   do table.insert(preview.effects, e) end
    return preview
end

return {calculate = calculate}
