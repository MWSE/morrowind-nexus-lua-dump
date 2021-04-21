local mod = "Enchanted Library"
local version = "1.0"

local data = require("EnLib.data")

local function onInitialized()

    -- Go through each book in the data table, one at a time.
    for _, dataBook in ipairs(data.books) do

        -- Get the game object with the same ID as the current book in the table.
        local book = tes3.getObject(dataBook.id)

        -- Make sure the current book is in the game's data, then change the icon and mesh.
        if book then
            book.icon = dataBook.icon
            book.mesh = dataBook.mesh
        end
    end

    mwse.log("[" .. mod .. " " .. version .. "] Initialized.")
end

event.register("initialized", onInitialized)