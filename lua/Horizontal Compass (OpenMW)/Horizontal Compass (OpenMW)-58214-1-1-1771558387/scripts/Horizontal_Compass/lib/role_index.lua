-- role_index.lua
local types = require("openmw.types")

local ROLE_PATH = "textures/Horizontal_Compass/roles/"

-- =====================
-- ICON DEFINITIONS
-- =====================
local ICONS = {
    warrior   = ROLE_PATH .. "warrior.png",
    guard     = ROLE_PATH .. "guard.png",
    mage      = ROLE_PATH .. "mage.png",
    monk      = ROLE_PATH .. "monk.png",
    thief     = ROLE_PATH .. "thief.png",
    stealth   = ROLE_PATH .. "stealth.png",
    shop      = ROLE_PATH .. "shop.png",
    civil     = ROLE_PATH .. "commoner.png",
    noble     = ROLE_PATH .. "noble.png",
    bard      = ROLE_PATH .. "bard.png",
    bed       = ROLE_PATH .. "bar.png",
    master    = ROLE_PATH .. "master.png",
    herder    = ROLE_PATH .. "herder.png",
    savant    = ROLE_PATH .. "savant.png",
    smith     = ROLE_PATH .. "smith.png",
    pauper    = ROLE_PATH .. "pauper.png",
    wise      = ROLE_PATH .. "wise.png",
    slave     = ROLE_PATH .. "slave.png",
    dreamer   = ROLE_PATH .. "dreamer.png",
    smuggler  = ROLE_PATH .. "smuggler.png",
    travel    = ROLE_PATH .. "travel.png",
    farmer    = ROLE_PATH .. "farmer.png",
    werewolf  = ROLE_PATH .. "werewolf.png",
    vampire   = ROLE_PATH .. "vampire.png",
    undead    = ROLE_PATH .. "undead.png",
    daedra    = ROLE_PATH .. "daedra.png",
    beast     = ROLE_PATH .. "beast.png",
    dwemer    = ROLE_PATH .. "centurion.png",
    sick      = ROLE_PATH .. "corprus.png",
    unknown   = ROLE_PATH .. "unknown.png",
    miner     = ROLE_PATH .. "miner.png",
    pilgrim   = ROLE_PATH .. "pilgrim.png",
    publican  = ROLE_PATH .. "publican.png",
}

-- =====================
-- ROLE RESOLUTION
-- =====================
local function resolveRole(actor)
    if actor.type == types.Creature then
        local t = types.Creature.record(actor).type
        if t == 2 then return "undead"
        elseif t == 1 then return "daedra"
        else return "beast" end
    end

    local rec = types.NPC.record(actor)
    if not rec or not rec.class then return "civil" end

    local id = rec.class:lower()

    if id:find("guard") or id:find("ordin") or id:find("buoyant armiger") then return "guard"
    elseif id:find("merchant") or id:find("trader") or id:find("service") or id:find("broker") or id:find("seller") or id:find("clothier") or id:find("gondolier") then return "shop"
    elseif id:find("warrior") or id:find("knight") or id:find("barbarian") or id:find("crusader") then return "warrior"
    elseif id:find("mage") or id:find("wizard") or id:find("sorcerer") or id:find("spell") then return "mage"
    elseif id:find("monk") or id:find("priest") or id:find("healer") then return "monk"
    elseif id:find("thief") or id:find("assassin") or id:find("rogue") or id:find("nightblade") or id:find("scout") or id:find("agent") then return "thief"
    elseif id:find("archer") or id:find("hunter") or id:find("marksman") or id:find("shooter") then return "stealth"
    elseif id:find("shipmaster") or id:find("caravaner") or id:find("guide") then return "travel"
    elseif id:find("acrobat") or id:find("pilgrim") then return "pilgrim"
    elseif id:find("bard") then return "bard"
    elseif id:find("noble") then return "noble"
    elseif id:find("publican") then return "publican"
    elseif id:find("slave") then return "slave"
    elseif id:find("herder") then return "herder"
    elseif id:find("savant") then return "savant"
    elseif id:find("smith") then return "smith"
    elseif id:find("pauper") then return "pauper"
    elseif id:find("wise") then return "wise"
    elseif id:find("dreamer") then return "dreamer"
    elseif id:find("smuggler") then return "smuggler"
    elseif id:find("centurion") then return "dwemer" -- Fixed to match ICONS table key
    elseif id:find("corprus") then return "sick"    -- Fixed to match ICONS table key
    elseif id:find("farmer") then return "farmer"
    elseif id:find("werewolf") then return "werewolf"
    elseif id:find("vampire") then return "vampire"
    elseif id:find("miner") then return "miner"
    elseif id:find("-at-") then return "master"
    end

    return "civil"
end

-- =====================
-- PUBLIC API
-- =====================
return {
    getVisualProfile = function(actor)
        local role = resolveRole(actor)
        return {
            role = role,
            icon = ICONS[role] or ICONS.civil,
        }
    end
}