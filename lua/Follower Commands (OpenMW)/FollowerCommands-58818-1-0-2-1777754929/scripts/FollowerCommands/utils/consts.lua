local C = {}

C.commandTriggerKey = "FollowerCommands_command"

C.scribs = {
    -- vanilla
    ["scrib"]              = true,
    ["scrib diseased"]     = true,
    ["scrib_vaba-amus"]    = true,
    ["scrib blighted"]     = true,
    ["scrib_rerlas"]       = true,

    -- ice scrib
    -- https://www.nexusmods.com/morrowind/mods/51338
    ["icescrib"]           = true,

    -- Creatures and Critters
    -- https://www.nexusmods.com/morrowind/mods/54518
    ["aa_cr_horned_scrib"] = true,

    -- Diverse Scribs
    -- https://www.nexusmods.com/morrowind/mods/56176
    ["scrib_2"]            = true,
    ["scrib diseased_2"]   = true,
    ["ttooth_scrib_2"]     = true,

    -- TriangleTooth's Ecology Mod
    -- https://www.nexusmods.com/morrowind/mods/47061
    ["ttooth_scrib"]       = true,

    -- Utility Spells
    -- https://www.nexusmods.com/morrowind/mods/58288
    ["scrib_summon"]       = true,
}

C.actions = {
    kill          = "kill",
    travel        = "travel",
    lockpick      = "lockpick",
    untrap        = "untrap",
    forceUntrap   = "forceUntrap",
    lootContainer = "lootContainer",
    lootItem      = "lootItem",
}

C.customScripts = {
    [C.actions.lockpick]      = "scripts/FollowerCommands/customScripts/pickprobe.lua",
    [C.actions.untrap]        = "scripts/FollowerCommands/customScripts/pickprobe.lua",
    [C.actions.forceUntrap]   = "scripts/FollowerCommands/customScripts/forceUntrap.lua",
    [C.actions.lootContainer] = "scripts/FollowerCommands/customScripts/loot.lua",
    [C.actions.lootItem]      = "scripts/FollowerCommands/customScripts/loot.lua",
}

C.headHeight = .9
C.footHeight = .2

C.messageTypes = {
    unlockFail         = "unlockFail",
    unlockSuccess      = "unlockSuccess",
    lockTooComplex     = "lockTooComplex",
    lockpickConfirm    = "lockpickConfirm",
    noLockpicks        = "noLockpicks",

    untrapFail         = "untrapFail",
    untrapSuccess      = "untrapSuccess",
    untrapConfirm      = "untrapConfirm",
    noProbes           = "noProbes",

    forceUntrapRefuse  = "forceUntrapRefuse",
    forceUntrapConfirm = "forceUntrapConfirm",
    noForceUntrap      = "noForceUntrap",

    cantReach          = "cantReach",
    lootConfirm        = "lootConfirm",
    noFreeSpace        = "noFreeSpace",
    notEnoughFreeSpace = "notEnoughFreeSpace",

    illegal            = "illegal",
}

return C
