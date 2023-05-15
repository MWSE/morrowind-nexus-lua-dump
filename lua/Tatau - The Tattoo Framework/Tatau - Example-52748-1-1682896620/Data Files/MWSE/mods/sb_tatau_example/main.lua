local interop = require("sb_tatau.interop")

local tattoos = {
    {
        id     = "face_t",
        slot   = interop.slots.head,
        mPaths = { [""] = "sb_tatau\\sb_todd.tga" },
        fPaths = {}
    },
    {
        id     = "face_l",
        slot   = interop.slots.head,
        mPaths = { [""] = "sb_tatau\\sb_todd_l.tga" },
        fPaths = {}
    },
    {
        id     = "face_r",
        slot   = interop.slots.head,
        mPaths = { [""] = "sb_tatau\\sb_todd_r.tga" },
        fPaths = {}
    },
    {
        id     = "arm_ul",
        slot   = interop.slots.upArmL,
        mPaths = { [""] = "sb_tatau\\sb_dragon_ul.tga" },
        fPaths = {}
    },
    {
        id     = "arm_ll",
        slot   = interop.slots.lowArmL,
        mPaths = { [""] = "sb_tatau\\sb_dragon_ll.tga" },
        fPaths = {}
    },
    -- {
    --     id     = "chest",
    --     slot   = interop.slots.torso,
    --     mPaths = { [""] = "sb_tatau\\sb_heart.tga" },
    --     fPaths = {}
    -- },
    -- {
    --     id     = "back",
    --     slot   = interop.slots.torso,
    --     mPaths = { [""] = "sb_tatau\\sb_dojima.tga" },
    --     fPaths = {}
    -- }
    -- {
    --     id     = "back",
    --     slot   = interop.slots.torso,
    --     mPaths = { [""] = "sb_tatau\\sb_drag_red.tga" },
    --     fPaths = {}
    -- }
    -- {
    --     id     = "back",
    --     slot   = interop.slots.torso,
    --     mPaths = { [""] = "sb_tatau\\sb_drag_blk.tga" },
    --     fPaths = {}
    -- }
    {
        id     = "back",
        slot   = interop.slots.torso,
        mPaths = { [""] = "sb_tatau\\sb_drag_wing.tga" },
        fPaths = { [""] = "sb_tatau\\sb_drag_wing_f.tga" }
    }
}

local function onInitialized()
    for _, tattoo in ipairs(tattoos) do
        interop:register(tattoo)
    end
    interop:registerAll()
end
event.register("initialized", onInitialized)

--- @param e bodyPartsUpdatedEventData
local function bodyPartsUpdatedCallback(e)
    if (e.reference == tes3.player) then
        interop:prepare(tes3.player)
        for _, tattoo in ipairs(tattoos) do
            interop:applyTattoo(tes3.player, tattoo.id)
        end
    end
end
event.register(tes3.event.bodyPartsUpdated, bodyPartsUpdatedCallback)

--- @param e referenceDeactivatedEventData
local function referenceDeactivatedCallback(e)
    if (e.reference == tes3.player) then
        for _, tattoo in ipairs(tattoos) do
            interop:removeTattoo(tes3.player, tattoo.id)
        end
    end
end
event.register(tes3.event.referenceDeactivated, referenceDeactivatedCallback)
