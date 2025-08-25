-- BarterMod_ClassDemand.lua
-- Maps each NPC class to at least four inventory objectTypes, lore-based

local this = {}

this.classDemandMap = {
    -- Vanilla NPC classes
    ["alchemist"]        = {
        tes3.objectType.alchemy,
        tes3.objectType.apparatus,
        tes3.objectType.ingredient,
        tes3.objectType.miscItem,
    },
    ["apothecary"]       = {
        tes3.objectType.alchemy,
        tes3.objectType.ingredient,
        tes3.objectType.book,
        tes3.objectType.miscItem,
    },
    ["bookseller"]       = {
        tes3.objectType.book,
        tes3.objectType.scroll,
        tes3.objectType.miscItem,
        tes3.objectType.tool,
    },
    ["buoyant armiger"]  = {
        tes3.objectType.armor,
        tes3.objectType.weapon,
        tes3.objectType.clothing,
        tes3.objectType.miscItem,
    },
    ["caretaker"]        = {
        tes3.objectType.clothing,
        tes3.objectType.miscItem,
        tes3.objectType.repairItem,
        tes3.objectType.book,
    },
    ["champion"]         = {
        tes3.objectType.weapon,
        tes3.objectType.armor,
        tes3.objectType.miscItem,
        tes3.objectType.repairItem,
    },
    ["clothier"]         = {
        tes3.objectType.clothing,
        tes3.objectType.miscItem,
        tes3.objectType.book,
        tes3.objectType.alchemy,
    },
    ["commoner"]         = {
        tes3.objectType.miscItem,
        tes3.objectType.clothing,
        tes3.objectType.ingredient,
        tes3.objectType.book,
    },
    ["dreamer"]          = {
        tes3.objectType.book,
        tes3.objectType.scroll,
        tes3.objectType.alchemy,
        tes3.objectType.miscItem,
    },
    ["enchanter"]        = {
        tes3.objectType.spell,
        tes3.objectType.scroll,
        tes3.objectType.book,
        tes3.objectType.miscItem,
    },
    ["enforcer"]         = {
        tes3.objectType.weapon,
        tes3.objectType.armor,
        tes3.objectType.ammo,
        tes3.objectType.miscItem,
    },
    ["farmer"]           = {
        tes3.objectType.ingredient,
        tes3.objectType.tool,
        tes3.objectType.miscItem,
        tes3.objectType.book,
    },
    ["gardener"]         = {
        tes3.objectType.ingredient,
        tes3.objectType.alchemy,
        tes3.objectType.tool,
        tes3.objectType.miscItem,
    },
    ["gondolier"]        = {
        tes3.objectType.miscItem,
        tes3.objectType.light,
        tes3.objectType.clothing,
        tes3.objectType.book,
    },
    ["guard"]            = {
        tes3.objectType.weapon,
        tes3.objectType.armor,
        tes3.objectType.ammo,
        tes3.objectType.repairItem,
    },
    ["guild guide"]      = {
        tes3.objectType.book,
        tes3.objectType.scroll,
        tes3.objectType.miscItem,
        tes3.objectType.alchemy,
    },
    ["healer"]           = {
        tes3.objectType.alchemy,
        tes3.objectType.ingredient,
        tes3.objectType.book,
        tes3.objectType.apparatus,
    },
    ["herder"]           = {
        tes3.objectType.ingredient,
        tes3.objectType.miscItem,
        tes3.objectType.tool,
        tes3.objectType.book,
    },
    ["hunter"]           = {
        tes3.objectType.weapon,
        tes3.objectType.ammo,
        tes3.objectType.clothing,
        tes3.objectType.ingredient,
    },
    ["journalist"]       = {
        tes3.objectType.book,
        tes3.objectType.scroll,
        tes3.objectType.tool,
        tes3.objectType.miscItem,
    },
    ["king"]             = {
        tes3.objectType.clothing,
        tes3.objectType.book,
        tes3.objectType.miscItem,
        tes3.objectType.armor,
    },
    ["mabrigash"]        = {
        tes3.objectType.ingredient,
        tes3.objectType.alchemy,
        tes3.objectType.miscItem,
        tes3.objectType.scroll,
    },
    ["merchant"]         = {
        tes3.objectType.miscItem,
        tes3.objectType.book,
        tes3.objectType.clothing,
        tes3.objectType.armor,
    },
    ["miner"]            = {
        tes3.objectType.tool,
        tes3.objectType.miscItem,
        tes3.objectType.ingredient,
        tes3.objectType.armor,
    },
    ["necromancer"]      = {
        tes3.objectType.scroll,
        tes3.objectType.spell,
        tes3.objectType.book,
        tes3.objectType.miscItem,
    },
    ["noble"]            = {
        tes3.objectType.clothing,
        tes3.objectType.book,
        tes3.objectType.alchemy,
        tes3.objectType.miscItem,
    },
    ["ordinator"]        = {
        tes3.objectType.weapon,
        tes3.objectType.armor,
        tes3.objectType.book,
        tes3.objectType.repairItem,
    },
    ["pauper"]           = {
        tes3.objectType.miscItem,
        tes3.objectType.clothing,
        tes3.objectType.ingredient,
        tes3.objectType.book,
    },
    ["pawnbroker"]       = {
        tes3.objectType.miscItem,
        tes3.objectType.book,
        tes3.objectType.scroll,
        tes3.objectType.alchemy,
    },
    ["priest"]           = {
        tes3.objectType.book,
        tes3.objectType.scroll,
        tes3.objectType.alchemy,
        tes3.objectType.miscItem,
    },
    ["publican"]         = {
        tes3.objectType.miscItem,
        tes3.objectType.ingredient,
        tes3.objectType.alchemy,
        tes3.objectType.book,
    },
    ["queen mother"]     = {
        tes3.objectType.clothing,
        tes3.objectType.book,
        tes3.objectType.miscItem,
        tes3.objectType.armor,
    },
    ["savant"]           = {
        tes3.objectType.book,
        tes3.objectType.scroll,
        tes3.objectType.miscItem,
        tes3.objectType.alchemy,
    },
    ["shaman"]           = {
        tes3.objectType.scroll,
        tes3.objectType.ingredient,
        tes3.objectType.spell,
        tes3.objectType.alchemy,
    },
    ["sharpshooter"]     = {
        tes3.objectType.weapon,
        tes3.objectType.ammo,
        tes3.objectType.armor,
        tes3.objectType.miscItem,
    },
    ["shipmaster"]       = {
        tes3.objectType.miscItem,
        tes3.objectType.tool,
        tes3.objectType.light,
        tes3.objectType.book,
    },
    ["slave"]            = {
        tes3.objectType.miscItem,
        tes3.objectType.clothing,
        tes3.objectType.tool,
        tes3.objectType.ingredient,
    },
    ["smith"]            = {
        tes3.objectType.tool,
        tes3.objectType.weapon,
        tes3.objectType.armor,
        tes3.objectType.repairItem,
    },
    ["smuggler"]         = {
        tes3.objectType.miscItem,
        tes3.objectType.weapon,
        tes3.objectType.ammo,
        tes3.objectType.scroll,
    },
    ["trader"]           = {
        tes3.objectType.miscItem,
        tes3.objectType.book,
        tes3.objectType.scroll,
        tes3.objectType.armor,
    },
    ["warlock"]          = {
        tes3.objectType.spell,
        tes3.objectType.scroll,
        tes3.objectType.alchemy,
        tes3.objectType.miscItem,
    },
    ["wise woman"]       = {
        tes3.objectType.ingredient,
        tes3.objectType.alchemy,
        tes3.objectType.scroll,
        tes3.objectType.book,
    },
    ["witch"]            = {
        tes3.objectType.alchemy,
        tes3.objectType.ingredient,
        tes3.objectType.spell,
        tes3.objectType.miscItem,
    },

    -- Tamriel_Data classes
    ["baker"]            = {
        tes3.objectType.ingredient,
        tes3.objectType.miscItem,
        tes3.objectType.book,
        tes3.objectType.alchemy,
    },
    ["banker"]           = {
        tes3.objectType.miscItem,
        tes3.objectType.book,
        tes3.objectType.lockpick,
        tes3.objectType.scroll,
    },
    ["barrister"]        = {
        tes3.objectType.book,
        tes3.objectType.scroll,
        tes3.objectType.miscItem,
        tes3.objectType.alchemy,
    },
    ["cat-catcher"]      = {
        tes3.objectType.tool,
        tes3.objectType.miscItem,
        tes3.objectType.scroll,
        tes3.objectType.armor,
    },
    ["courtesan"]        = {
        tes3.objectType.clothing,
        tes3.objectType.miscItem,
        tes3.objectType.alchemy,
        tes3.objectType.book,
    },
    ["dockworker"]       = {
        tes3.objectType.tool,
        tes3.objectType.miscItem,
        tes3.objectType.clothing,
        tes3.objectType.armor,
    },
    ["fisherman"]        = {
        tes3.objectType.ingredient,
        tes3.objectType.tool,
        tes3.objectType.miscItem,
        tes3.objectType.book,
    },
    ["jarl"]             = {
        tes3.objectType.armor,
        tes3.objectType.weapon,
        tes3.objectType.clothing,
        tes3.objectType.book,
    },
    ["lamp knight"]      = {
        tes3.objectType.light,
        tes3.objectType.weapon,
        tes3.objectType.armor,
        tes3.objectType.miscItem,
    },
    ["ore miner"]        = {
        tes3.objectType.tool,
        tes3.objectType.armor,
        tes3.objectType.miscItem,
        tes3.objectType.ingredient,
    },
    ["sailor"]           = {
        tes3.objectType.miscItem,
        tes3.objectType.light,
        tes3.objectType.tool,
        tes3.objectType.book,
    },
    ["scribe"]           = {
        tes3.objectType.book,
        tes3.objectType.scroll,
        tes3.objectType.miscItem,
        tes3.objectType.alchemy,
    },
    ["therionaut"]       = {
        tes3.objectType.scroll,
        tes3.objectType.spell,
        tes3.objectType.book,
        tes3.objectType.miscItem,
    },
    ["clever-man"]       = {
        tes3.objectType.scroll,
        tes3.objectType.book,
        tes3.objectType.alchemy,
        tes3.objectType.miscItem,
    },

    -- Fallback
    ["default"]          = {
        tes3.objectType.miscItem,
        tes3.objectType.ingredient,
        tes3.objectType.book,
        tes3.objectType.weapon,
    },
}

--- Returns an array of at least four inventory objectTypes for a given classID.
-- @param classID string from ref.object.class.id
-- @return array of tes3.objectType constants
function this.getDemandTypes(classID)
    if not classID or classID == "" then
        return this.classDemandMap.default
    end
    local key = string.lower(classID)
    return this.classDemandMap[key] or this.classDemandMap.default
end

return this
