local types = require("openmw.types")
local storage = require("openmw.storage")

require("scripts.ShelfControl.utils.openmw_utils")

local sectionMisc = storage.globalSection("SettingsShelfControl_misc")

--- Represents a book owner and provides helper methods.
--- @class Owner
--- @field recordId string|nil     The NPC's record ID (if the book has a direct owner).
--- @field factionId string|nil    The owning faction's ID (if faction-owned).
--- @diagnostic disable-next-line: undefined-doc-name
--- @field book types.Book         Book object
--- @diagnostic disable-next-line: undefined-doc-name
--- @field self types.Actor|nil    The active actor reference in the current cell (nil if not loaded).
--- @field isDead boolean          Whether the owner is dead (or not in the same cell → treated as dead).
--- @field disposition integer     Disposition of the owner towards the player (-1 if unavailable).
--- @field sellsBooks boolean      Whether the owner offers books as a service.
--- @field record table|nil        The NPC record (if applicable).
local Owner = {}
Owner.__index = Owner

--- Constructor: create a new Owner instance for a given book and player.
--- @param book any   The book being inspected.
--- @param player any The player actor reference.
--- @return Owner
function Owner.new(book, player)
    local self = setmetatable({}, Owner)

    self.recordId    = book.owner and book.owner.recordId or nil
    self.factionId   = book.owner and book.owner.factionId or nil
    self.book        = book
    self.disposition = -1
    self.record      = nil
    self.self        = nil
    self.sellsBooks  = false
    self.isDead      = false

    self:_collectData(book, player)
    self:_printDebugInfo()

    return self
end

--- Internal: collect all relevant data about this owner.
--- @param book any
--- @param player any
function Owner:_collectData(book, player)
    -- Try to find active actor reference
    if self.recordId then
        self.self = GetActiveActorByRecordId(self.recordId)
    end

    -- Dead or missing owner handling
    if self.self then
        self.isDead = types.Actor.isDead(self.self)
        self.disposition = types.NPC.getDisposition(self.self, player)
    else
        self.isDead = true
    end

    -- Service offering (sellsBooks)
    if self.recordId and not self.factionId then
        self.record = types.NPC.record(self.recordId)
        self.sellsBooks = self.record.servicesOffered["Books"] or false
    end
end

--- Debug print for owner info, if enabled in config.
function Owner:_printDebugInfo()
    if not sectionMisc:get("enableDebug") then return end
    print("\nCurrent book owner info" ..
        "\nrecordId ->      " .. tostring(self.recordId) ..
        "\nfactionId ->     " .. tostring(self.factionId) ..
        "\nrecord ->        " .. tostring(self.record) ..
        "\nsellsBooks ->    " .. tostring(self.sellsBooks) ..
        "\nself ->          " .. tostring(self.self) ..
        "\nisDead ->        " .. tostring(self.isDead) ..
        "\ndisposition ->   " .. tostring(self.disposition)
    )
end

return Owner
