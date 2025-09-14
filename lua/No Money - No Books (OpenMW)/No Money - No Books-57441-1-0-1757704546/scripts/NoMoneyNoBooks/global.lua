local storage = require("openmw.storage")
local I = require("openmw.interfaces")
local types = require("openmw.types")
local world = require("openmw.world")
local core = require("openmw.core")

local sectionSettings = storage.globalSection("NoMoneyNoBooks_settings")
local l10n = core.l10n("NoMoneyNoBooks")

local function isOwned(book, actor)
    if not types.Player.objectIsInstance(actor) then return false end
    -- checking only owner record might backfire me in the ass
    -- yolo
    if book.owner.recordId then
        return true
    end
end

local function isBuyable(book, actor)
    if not types.Player.objectIsInstance(actor) then return false end
    if not isOwned(book, actor) then
        return false
    end

    local ownerRecordId = book.owner.recordId
    local ownerRecord = types.NPC.record(ownerRecordId)
    local ownerSellsBooks = ownerRecord.servicesOffered["Books"]

    for _, activeActor in ipairs(world.activeActors) do
        if activeActor.recordId == ownerRecordId then
            return ownerSellsBooks
        end
    end

    return not ownerSellsBooks
end

local modes = {
    ["None"] = function(...)
        return true
    end,

    ["Only buyable"] = function(book, actor)
        local bookAvailable = not isBuyable(book, actor)
        if not bookAvailable and sectionSettings:get("showMessages") then
            actor:sendEvent("ShowMessage", { message = l10n("message_bookBuyable") })
        end
        return bookAvailable
    end,

    ["Any owned"] = function(book, actor)
        local bookAvailable = not isOwned(book, actor)
        if not bookAvailable and sectionSettings:get("showMessages") then
            actor:sendEvent("ShowMessage", { message = l10n("message_bookOwned") })
        end
        return bookAvailable
    end,
}

I.Activation.addHandlerForType(types.Book, function(book, actor)
    local mode = modes[sectionSettings:get("mode")]
    return mode(book, actor)
end)
