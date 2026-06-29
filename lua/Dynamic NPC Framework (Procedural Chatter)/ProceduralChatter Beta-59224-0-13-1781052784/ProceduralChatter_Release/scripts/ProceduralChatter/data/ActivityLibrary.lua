local types = require('openmw.types')
local JsonMergeLoader = require("scripts.ProceduralChatter.JsonMergeLoader")

local Activities = {}

local PREFIX = "scripts/proceduralchatter/data/activities/"

-- Condition registry: keyed by string name used in JSON "condition" fields.
local conditionRegistry = {}

-- Prayer / Temple faction condition
conditionRegistry["templePriest"] = function(npc)
    local rec = types.NPC.record(npc)
    if rec.factions then
        for factionId, _ in pairs(rec.factions) do
            local fl = string.lower(factionId)
            if fl:find("temple") or fl:find("tribunal") then return true end
        end
    end
    local nameL = string.lower(rec.name or "")
    local idL   = string.lower(npc.recordId or "")
    if nameL:find("priest") or nameL:find("ordinator") or idL:find("priest") or idL:find("ordinator") then
        return true
    end
    return false
end

-- Farmer / nearby ingredient condition
conditionRegistry["nearbyIngredient300"] = function(npc)
    local cell = npc.cell
    if not cell or not cell.isExterior then return false end
    local ok, ingredients = pcall(function() return cell:getAll(types.Ingredient) end)
    if not ok or not ingredients then return false end
    for _, ing in ipairs(ingredients) do
        local dist = (ing.position - npc.position):length()
        if dist < 300 then return true end
    end
    return false
end

local function tableSize(t)
    local c = 0
    for _ in pairs(t) do c = c + 1 end
    return c
end

local function mergeFile(data, path)
    for id, entry in pairs(data) do
        if type(entry) == "table" then
            Activities[id] = entry
            -- Attach condition function if specified by string key
            if type(entry.condition) == "string" and conditionRegistry[entry.condition] then
                entry.condition = conditionRegistry[entry.condition]
            elseif type(entry.condition) == "string" then
                print(string.format("[ActivityLibrary] WARNING: unknown condition '%s' in '%s'", entry.condition, path))
                entry.condition = nil
            end
        end
    end
end

local count = JsonMergeLoader.scan(PREFIX, mergeFile)
print(string.format("[ActivityLibrary] Loaded %d activity JSON file(s), %d entries.", count, tableSize(Activities)))

return Activities
