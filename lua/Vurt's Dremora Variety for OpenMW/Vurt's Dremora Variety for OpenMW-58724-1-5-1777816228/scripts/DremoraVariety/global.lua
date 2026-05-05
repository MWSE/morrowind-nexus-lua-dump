local world = require("openmw.world")
local types = require("openmw.types")

local ogModel = "meshes/r/dremora.nif"
local modelVariants = {
    "meshes/v_drem/1.nif",
    "meshes/v_drem/2.nif",
    "meshes/v_drem/3.nif",
    "meshes/v_drem/4.nif",
    "meshes/v_drem/5.nif",
    "meshes/v_drem/6.nif",
    "meshes/v_drem/7.nif",
    "meshes/v_drem/8.nif",
}
local blacklist = {
    -- Community Traits Ported (Merlord's Backgrounds)
    -- https://www.nexusmods.com/morrowind/mods/58704
    ["mer_bg_drem_1"] = true,
    ["mer_bg_drem_2"] = true,
    ["mer_bg_drem_3"] = true,
    -- Summoned by the player character
    ["dremora_summon"] = true,
}

local changedDremoras = {
    -- actor.id = true
}
local dremoraVariants = {
    -- dremora-like record id = {
    --     variant 1
    -- }
}

local function randomizeDremora(actor)
    if not dremoraVariants[actor.recordId] or changedDremoras[actor.id] then
        return
    end

    local currVariants = dremoraVariants[actor.recordId]
    local variant = currVariants[math.random(#currVariants + 1)]
    -- landed on og model
    if not variant then
        changedDremoras[actor.id] = true
        return
    end

    local newDremora = world.createObject(variant.id)
    newDremora:teleport(actor.cell, actor.position, actor.rotation)
    actor:remove()
end

local function onSave()
    return {
        changedDremora = changedDremoras,
        dremoraVariants = dremoraVariants,
    }
end

local function onLoad(data)
    changedDremoras = data and data.changedDremora or changedDremoras
    dremoraVariants = data and data.dremoraVariants or dremoraVariants

    local newRecordCount = 0
    for _, record in ipairs(types.Creature.records) do
        if record.model == ogModel
            and not dremoraVariants[record.id]
            and not record.id:find("^Generated:")
            and not blacklist[record.id]
            and not record.mwscript
        then
            dremoraVariants[record.id] = {}
            for _, model in ipairs(modelVariants) do
                ---@diagnostic disable-next-line: undefined-field
                local newRecordDraft = types.Creature.createRecordDraft {
                    template = record,
                    model = model,
                }
                local newRecord = world.createRecord(newRecordDraft)
                table.insert(dremoraVariants[record.id], newRecord)
                newRecordCount = newRecordCount + 1
            end
        end
    end

    for recordId, _ in pairs(dremoraVariants) do
        if blacklist[recordId] then
            dremoraVariants[recordId] = nil
        end
    end

    if newRecordCount ~= 0 then
        print("[Dremora Variants] Generated", newRecordCount, "new dremora records.")
    end
end

return {
    engineHandlers = {
        onActorActive = randomizeDremora,
        onSave = onSave,
        onLoad = onLoad,
    }
}
