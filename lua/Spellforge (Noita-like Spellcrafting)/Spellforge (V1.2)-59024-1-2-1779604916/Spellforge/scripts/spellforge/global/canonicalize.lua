local util = require("openmw.util")

local canonicalize = {}

local FNV_OFFSET_32 = 2166136261
local FNV_PRIME_32 = 16777619

local function sortedKeys(tbl)
    local keys = {}
    if type(tbl) ~= "table" then
        return keys
    end
    for k in pairs(tbl) do
        keys[#keys + 1] = k
    end
    table.sort(keys)
    return keys
end

local function serializeNode(node)
    local parts = { tostring(node.opcode or "<nil>") }

    if node.base_spell_id then
        parts[#parts + 1] = "base=" .. tostring(node.base_spell_id)
    end

    if node.params then
        for _, key in ipairs(sortedKeys(node.params)) do
            parts[#parts + 1] = string.format("%s=%s", key, tostring(node.params[key]))
        end
    end

    if node.payload then
        local payload_parts = {}
        for i, child in ipairs(node.payload) do
            payload_parts[i] = serializeNode(child)
        end
        parts[#parts + 1] = "payload[" .. table.concat(payload_parts, ";") .. "]"
    end

    return "{" .. table.concat(parts, "|") .. "}"
end

local function serializeRecipe(recipe)
    local nodes = {}
    for i, node in ipairs(recipe.nodes or {}) do
        nodes[i] = serializeNode(node)
    end
    return table.concat(nodes, "->")
end

local function fnv1a32(input)
    local hash = FNV_OFFSET_32
    for i = 1, #input do
        hash = util.bitXor(hash, string.byte(input, i))
        hash = util.bitAnd(hash * FNV_PRIME_32, 0xFFFFFFFF)
    end
    return string.format("%08x", hash)
end

function canonicalize.run(recipe)
    -- Transitional note:
    -- Current canonicalization hashes prototype node tables from 2.2b scaffolding.
    -- TODO(2.2c): canonicalize the ordered effect list including effect IDs, ranges,
    -- magnitudes, area, duration, operator IDs, operator params, and compiler version.
    local canonical = serializeRecipe(recipe)
    return {
        canonical = canonical,
        recipe_id = fnv1a32(canonical),
    }
end

return canonicalize
