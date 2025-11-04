local world = require("openmw.world")

require("scripts.CanonicalGear.globalValues")
require("scripts.CanonicalGear.utils")
require("scripts.CanonicalGear.equipment.items")

local function isDorisaDarvel(actor)
    return actor.recordId == DorisaDarvel
end

local function alreadyRecievedBooks()
    return GearedNPCs.dorisaDarvel
end

function DorisaDarvelAddBooks(actor)
    if not isDorisaDarvel(actor) or alreadyRecievedBooks() then return end

    for _, bookId in ipairs(DorisaDarvelsBooks) do
        local book = world.createObject(bookId)
        book:moveInto(actor)
        Log("Given " .. bookId .. " to Dorisa Darvel.")
    end

    GearedNPCs.dorisaDarvel = true
end
