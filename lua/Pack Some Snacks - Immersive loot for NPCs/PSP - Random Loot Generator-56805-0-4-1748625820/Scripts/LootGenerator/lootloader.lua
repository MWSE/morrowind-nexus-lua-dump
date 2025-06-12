local core = require("openmw.core")

local PATCHES_PATH = "scripts.lootgenerator.lootlist."

-- List your potential patches / mods here
local AVAILABLE_PATCHES = {
    "morrowind.esm",
    "tribunal.esm",
	"bloodmoon.esm",
	"oaab_data.esm",
	"tamriel_data.esm",
	"Expanded Loot.esm"
}

local lootData = {
    food = {},
    drink = {},
    misc = {},
}

local function mergeLootData(newData)
    for category, items in pairs(newData) do
        if lootData[category] then
            for _, id in ipairs(items) do
                table.insert(lootData[category], id)
            end
        end
    end
end

local function loadLootPatches()
    for _, patch in ipairs(AVAILABLE_PATCHES) do
        if core.contentFiles.has(patch) then
            local fileName = patch:gsub("%.esm", ""):gsub("%.esp", ""):gsub("%.omwaddon", "")
            local success, patchData = pcall(require, PATCHES_PATH .. fileName)
            if success and patchData then
                mergeLootData(patchData)
            else
                print("Failed to load patch data for " .. fileName)
            end
        end
    end
end

return {
    loadLootPatches = loadLootPatches,
    getLootData = function() return lootData end,
}