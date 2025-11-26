local storage = require("openmw.storage")
local I = require("openmw.interfaces")
local types = require("openmw.types")

local Owner = require("scripts.ShelfControl.model.owner")
require("scripts.ShelfControl.checkers.books")
require("scripts.ShelfControl.checkers.cells")
require("scripts.ShelfControl.utils.openmw_utils")
require("scripts.ShelfControl.messages.messageManager")

local sectionBuyable = storage.globalSection("SSettingshelfControl_buyable")
local sectionOwned = storage.globalSection("SettingsShelfControl_owned")
local sectionMisc = storage.globalSection("SettingsShelfControl_misc")

local function checkOwnership(section, ownershipChecker, ctx)
    if section:get("supress")
        and ownershipChecker(ctx.owner)
        and section:get("minDisposition") > ctx.owner.disposition
        and not LocationIsWhitelisted(ctx)
    then
        ShowMessage(ctx)
        return true
    end
    return false
end

-- true = allow activation, false = block activation
local function onBookActivation(book, actor)
    if not sectionMisc:get("modEnabled") then return true end
    -- if not player
    if not types.Player.objectIsInstance(actor) then return true end
    -- if book has an mwscript attached
    local bookRecord = GetRecord(book)
    if sectionMisc:get("ignoreBooksWithMWScripts") and bookRecord.mwscript then return true end
    -- if book is a scroll
    if sectionMisc:get("ignoreScrolls") and bookRecord.isScroll then return true end

    local ctx = {
        book = book,
        owner = Owner.new(book, actor),
        player = actor,
    }
    -- check buyable and owned conditions
    if checkOwnership(sectionBuyable, IsBuyable, ctx)
        or checkOwnership(sectionOwned, IsNpcOwned, ctx)
        or checkOwnership(sectionOwned, IsFactionOwned, ctx)
    then
        return false
    end

    return true
end

I.Activation.addHandlerForType(types.Book, onBookActivation)
