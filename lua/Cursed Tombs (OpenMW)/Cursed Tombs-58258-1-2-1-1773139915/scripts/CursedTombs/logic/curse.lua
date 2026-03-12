local world = require("openmw.world")
local storage = require("openmw.storage")
local util = require("openmw.util")
local core = require("openmw.core")

require("scripts.CursedTombs.utils.messages")

local sectionRevenants = storage.globalSection("SettingsCursedTombs_revenants")
local sectionOther = storage.globalSection("SettingsCursedTombs_other")

local function spawnRevenant(revenantList, actor, spawnPos)
    local id = revenantList[math.random(#revenantList)]
    local revenant = world.createObject(id, 1)
    revenant:teleport(actor.cell, spawnPos, {
        rotation = actor.rotation,
        onGround = true,
    })
end

local function doFeedback(actor)
    if sectionOther:get("enableMessages") then
        local msgs = CollectAllMessagesByPrefix("msg_remnantSpawned", core.l10n("CursedTombs"))
        print("Collected messages: " .. #msgs)
        actor:sendEvent("ShowMessage", { message = msgs[math.random(#msgs)] })
    end
    if sectionOther:get("enableSfx") then
        actor:sendEvent("PlaySound3d", { sound = "bonelord scream" })
    end
end

function TriggerCurse(revenants, actor, spawnPos)
    local revenantList = sectionRevenants:get("useLeveledLists")
        and revenants.leveled or revenants.static
    local revenantCount = math.random(
        sectionRevenants:get("minRevenantCount"),
        sectionRevenants:get("maxRevenantCount")
    )

    for _ = 1, revenantCount do
        spawnRevenant(revenantList, actor, spawnPos)
    end

    doFeedback(actor)
end
