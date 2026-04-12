local types = require("openmw.types")
local Actor = types.Actor
local SLOT  = Actor.EQUIPMENT_SLOT

local SLOT_NAME = {
    [SLOT.Helmet]        = "helmet",
    [SLOT.Cuirass]       = "cuirass",
    [SLOT.Greaves]       = "greaves",
    [SLOT.Boots]         = "boots",
    [SLOT.LeftPauldron]  = "left_pauldron",
    [SLOT.RightPauldron] = "right_pauldron",
    [SLOT.LeftGauntlet]  = "left_gauntlet",
    [SLOT.RightGauntlet] = "right_gauntlet",
    [SLOT.CarriedLeft]   = "carried_left",
}

local SLOT_KEYS = {
    "helmet", "cuirass", "greaves", "boots",
    "left_pauldron", "right_pauldron",
    "left_gauntlet", "right_gauntlet",
    "carried_left",
}

local function makeSlotSpells(class, tier)
    local prefix = "areq_burden_" .. class .. "_"
    local suffix = "_t" .. tier
    local t = {}
    for _, name in ipairs(SLOT_KEYS) do
        t[name] = prefix .. name .. suffix
    end
    return t
end

local BURDEN_SPELLS = {
    HEAVY  = { [2] = makeSlotSpells("heavy",  2), [3] = makeSlotSpells("heavy",  3), [4] = makeSlotSpells("heavy",  4) },
    MEDIUM = { [2] = makeSlotSpells("medium", 2), [3] = makeSlotSpells("medium", 3), [4] = makeSlotSpells("medium", 4) },
    LIGHT  = { [2] = makeSlotSpells("light",  2), [3] = makeSlotSpells("light",  3), [4] = makeSlotSpells("light",  4) },
    BOUND  = {
        helmet         = "areq_burden_bound_helmet",
        cuirass        = "areq_burden_bound_cuirass",
        left_gauntlet  = "areq_burden_bound_left_gauntlet",
        right_gauntlet = "areq_burden_bound_right_gauntlet",
        boots          = "areq_burden_bound_boots",
        carried_left   = "areq_burden_bound_shield",
    },
}

local BOUND_EFFECT_SLOTS = {
    BoundHelm    = { SLOT.Helmet },
    BoundCuirass = { SLOT.Cuirass },
    BoundGloves  = { SLOT.LeftGauntlet, SLOT.RightGauntlet },
    BoundBoots   = { SLOT.Boots },
    BoundShield  = { SLOT.CarriedLeft },
}

return {
    SLOT_NAME          = SLOT_NAME,
    BURDEN_SPELLS      = BURDEN_SPELLS,
    BOUND_EFFECT_SLOTS = BOUND_EFFECT_SLOTS,
}