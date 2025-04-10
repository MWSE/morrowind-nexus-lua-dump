local config = require("DremoraModelRandomizer.config")
local log = require("DremoraModelRandomizer.log")

local dremoraIDs = {
    ["dremora"] = true,
    ["dremora_lord"] = true, 
    ["dremora_kynreeve"] = true,
    ["dremora_kynmarcher"] = true,
    ["dremora_summon"] = true,
    ["dremora_mage"] = true,
    ["dremora_warrior"] = true,
    ["dremora_gothren_guard1"] = true,
    ["dremora_gothren_guard2"] = true,
    ["dremora_lord_khash_uni"] = true,
    ["dremora_special_fyr"] = true,
    ["dremora_ttmg"] = true,
    ["dremora_ttpc"] = true
}

local dremoraVariants = {
    "\\v_drem\\1.nif",
    "\\v_drem\\2.nif",
    "\\v_drem\\3.nif",
    "\\v_drem\\4.nif",
    "\\v_drem\\5.nif",
    "\\v_drem\\6.nif",
    "\\v_drem\\7.nif",
    "\\v_drem\\8.nif"
}

local function randomizeDremoraModel(e)
    if not config.enabled then return end

    local object = e.reference.baseObject

    if object.objectType ~= tes3.objectType.creature then
        return
    end

    if object.mesh:lower() ~= "r\\dremora.nif"
        and not dremoraIDs[object.id:lower()]
    then
        log:trace("Skip: '%s' - '%s'", object.id, object.mesh)
        return
    end

    -- Note: `playAnimation` triggers `mobileActivated`
    -- A temp var is used here as an awkward workaround to avoid the infinite loop.
    local temp = e.reference.tempData
    if temp.vurt_dremoraRandomized then
        temp.vurt_dremoraRandomized = nil
        return
    end

    local data = e.reference.data

    data.vurt_dremoraVariant = data.vurt_dremoraVariant or table.choice(dremoraVariants)
    temp.vurt_dremoraRandomized = true

    log:debug("Assigning mesh '%s' to '%s'", data.vurt_dremoraVariant, e.reference)
    tes3.playAnimation({ reference = e.reference, mesh = data.vurt_dremoraVariant })
end
event.register("mobileActivated", randomizeDremoraModel)

event.register("DremoraModelRandomizer:Refresh", function(e)
    e.reference.data.vurt_dremoraVariant = nil
    randomizeDremoraModel(e)
end)

event.register("modConfigReady", function()
    dofile("DremoraModelRandomizer.MCM")
end)
