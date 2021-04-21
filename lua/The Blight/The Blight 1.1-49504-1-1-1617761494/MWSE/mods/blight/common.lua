local common = {}

common.config = require("blight.config")
common.getBlightLevel = require("blight.modules.get-blight-level")

function common.debug(str, ...)
    if common.config.debugMode then
        local info = debug.getinfo(2, "Sl")
        local module = info.short_src:match("^.+\\(.+).lua$")
        local prepend = ("[blight.%s:%s]:"):format(module, info.currentline)
        local aligned = ("%-36s"):format(prepend)
        mwse.log(aligned .. str, ...)
    end
end

function common.traverse(roots)
    local function iter(nodes)
        for i, node in ipairs(nodes or roots) do
            if node then
                coroutine.yield(node)
                if node.children then
                    iter(node.children)
                end
            end
        end
    end
    return coroutine.wrap(iter)
end

function common.getKeyFromValueFunc(tbl, func)
    for key, value in pairs(tbl) do
        if (func(value) == true) then return key end
    end
    return nil
end

function common.calculateChanceResult(chance)
    local roll = math.random(0, 100)
    return roll <= chance, roll
end

function common.iterBlightDiseases(reference)
    return coroutine.wrap(function()
        -- special handling for containers
        if reference.object.organic then
            if reference.data.blight and reference.data.blight.diseases then
                for spell in pairs(reference.data.blight.diseases) do
                    coroutine.yield(tes3.getObject(spell))
                end
            end
            return
        end
        -- alternative handling for actors
        for _, spell in pairs(reference.object.spells.iterator) do
            if common.diseases[spell.id] then
                coroutine.yield(spell)
            end
        end
    end)
end

function common.isBlightProgressionDisease(spell)
    return spell.id:find("^TB_.*_P$") ~= nil
end

function common.getTransmittableBlightDiseases(source, target)
    local spells={}
    for spell in common.iterBlightDiseases(source) do
        if not common.isBlightProgressionDisease(spell) and not common.hasBlight(target, spell) then
            table.insert(spells, spell)
        end
    end
    return spells, #spells > 0
end

function common.calculateBlightChance(reference)
    local chance = common.config.baseBlightTransmissionChance --Base Chance

    -- It's a plant!
    if (reference.object.organic == true) then
        return chance
    end

    -- It's not a plant! Proceed normally.

    -- Dead people can't get blight.
    if (reference.mobile.isDead == true) then
        return 0
    end

    -- Modify based on helmet
    for _, stack in pairs(reference.object.equipment) do
        local object = stack.object
        if object.objectType == tes3.objectType.armor then
            local parts = 0
            if object.slot == tes3.armorSlot.helmet then
                for _, part in pairs(object.parts) do
                    if (part.type == tes3.activeBodyPart.hair) then
                        common.debug("'%s' hair coverage found.", reference)
                        parts = parts + 1
                    elseif (part.type == tes3.activeBodyPart.head) then
                        common.debug("'%s' head coverage found.", reference)
                        parts = parts + 3
                    elseif (part.type == tes3.activeBodyPart.neck) then
                        common.debug("'%s' neck coverage found.", reference)
                        parts = parts + 1
                    end
                end
            end

            chance = chance - parts
        end
    end

    return chance
end

function common.hasBlight(reference, searchSpell)
    for spell in common.iterBlightDiseases(reference) do
        if not searchSpell or searchSpell.id == spell.id then
            return true, spell
        end
    end
    return false
end

function common.addBlight(reference, spellId)
    if reference.object.organic then
        reference.data.blight = reference.data.blight or {}
        reference.data.blight.diseases = reference.data.blight.diseases or {}
        reference.data.blight.diseases[spellId] = true
    else
        mwscript.addSpell({ reference = reference, spell = spellId })
    end

    event.trigger("blight:AddedBlight", {
        reference = reference,
        diseaseId = spellId,
    })
end

function common.removeBlight(reference, spellId)
    if reference.object.organic then
        reference.data.blight = reference.data.blight or {}
        reference.data.blight.diseases = reference.data.blight.diseases or {}
        reference.data.blight.diseases[spellId] = nil
    else
        mwscript.removeSpell({
            reference = reference,
            spell = spellId
        })
    end

    event.trigger("blight:RemovedBlight", {
        reference = reference,
        diseaseId = spellId,
    })
end

common.diseases = {
    --Empty, loaded at runtime.
}

return common
