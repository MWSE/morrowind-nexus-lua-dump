-- Unit tests for module.addToSortedTable
-- Run with: lua "test_addToSortedTable.lua"
-- From folder: "00 Core/scripts/skill-evolution/tests"

-- ── Mock for openmw.util (not used by addToSortedTable) ───────────────────────
package.preload['openmw.util'] = function()
    return {
        color = { rgb = function(r, g, b) return { r = r, g = g, b = b } end },
        vector2 = function(x, y) return { x = x, y = y } end,
    }
end

-- Add parent path for require
package.path = package.path .. ";../util/?.lua"

local helpers = require('helpers')
local addToSortedTable = helpers.addToSortedTable

-- ── Minimal test harness ──────────────────────────────────────────────────────
local passed, failed = 0, 0

local function check(name, condition, detail)
    if condition then
        passed = passed + 1
        print(string.format("  [PASS] %s", name))
    else
        failed = failed + 1
        print(string.format("  [FAIL] %s%s", name, detail and (" — " .. detail) or ""))
    end
end

local function isSortedDesc(list, getter)
    for i = 1, #list - 1 do
        if getter(list[i]) < getter(list[i + 1]) then
            return false, string.format("list[%d]=%s < list[%d]=%s", i, getter(list[i]), i + 1, getter(list[i + 1]))
        end
    end
    return true
end

local function hasDuplicate(list, getId)
    local seen = {}
    for i = 1, #list do
        local id = getId(list[i])
        if id and seen[id] then return true, id end
        seen[id] = true
    end
    return false
end

local function contains(list, item)
    for i = 1, #list do
        if list[i] == item then return true end
    end
    return false
end

local function newItem(id, score)
    return { id = id, score = score }
end

local getter = function(item) return item.score end
local getId = function(item) return item.id end
local noId = function(_) return nil end

-- ── Group 1: descending order ─────────────────────────────────────────────────
print("\n[Group 1] Descending order")
do
    local list = {}
    addToSortedTable(newItem("a", 10), getter, noId, list, 5)
    addToSortedTable(newItem("b", 30), getter, noId, list, 5)
    addToSortedTable(newItem("c", 20), getter, noId, list, 5)
    local ok, detail = isSortedDesc(list, getter)
    check("3 inserts remain sorted desc", ok, detail)
end
do
    local list = {}
    local scores = { 5, 3, 8, 1, 9, 2, 7 }
    for i = 1, #scores do
        local s = scores[i]
        addToSortedTable(newItem(tostring(s), s), getter, noId, list, 10)
    end
    local ok, detail = isSortedDesc(list, getter)
    check("7 unordered inserts remain sorted desc", ok, detail)
end

-- ── Group 2: maximum size ─────────────────────────────────────────────────────
print("\n[Group 2] Maximum size (size)")
do
    local list = {}
    local size = 3
    for i = 1, 6 do
        addToSortedTable(newItem(tostring(i), i), getter, noId, list, size)
    end
    check("list does not exceed size=3", #list <= size, "length=" .. #list)
end
do
    local list = {}
    local size = 1
    addToSortedTable(newItem("a", 5), getter, noId, list, size)
    addToSortedTable(newItem("b", 10), getter, noId, list, size)
    addToSortedTable(newItem("c", 3), getter, noId, list, size)
    check("list does not exceed size=1", #list <= size, "length=" .. #list)
end
do
    -- A full list must not grow even with a weaker item
    local list = {}
    local size = 2
    addToSortedTable(newItem("a", 10), getter, noId, list, size)
    addToSortedTable(newItem("b", 8), getter, noId, list, size)
    addToSortedTable(newItem("c", 1), getter, noId, list, size) -- too weak
    check("too-weak item does not grow a full list", #list == size, "length=" .. #list)
end

-- ── Group 3: no duplicates by getId ──────────────────────────────────────────
print("\n[Group 3] Uniqueness by getId")
do
    local list = {}
    addToSortedTable(newItem("x", 5), getter, getId, list, 5)
    addToSortedTable(newItem("x", 10), getter, getId, list, 5)
    local dup, id = hasDuplicate(list, getId)
    check("duplicate replaced by better score", not dup, "duplicated id=" .. tostring(id))
    check("best score is kept", #list == 1 and list[1].score == 10, "score=" .. (list[1] and list[1].score or "nil"))
end
do
    local list = {}
    addToSortedTable(newItem("x", 10), getter, getId, list, 5)
    addToSortedTable(newItem("x", 5), getter, getId, list, 5) -- worse, must be ignored
    local dup, id = hasDuplicate(list, getId)
    check("worse duplicate ignored", not dup, "duplicated id=" .. tostring(id))
    check("best score kept over worse duplicate", list[1].score == 10, "score=" .. (list[1] and list[1].score or "nil"))
end
do
    local list = {}
    addToSortedTable(newItem("a", 9), getter, getId, list, 5)
    addToSortedTable(newItem("b", 7), getter, getId, list, 5)
    addToSortedTable(newItem("a", 8), getter, getId, list, 5) -- duplicate "a", worse
    addToSortedTable(newItem("b", 6), getter, getId, list, 5) -- duplicate "b", worse
    local dup, id = hasDuplicate(list, getId)
    check("no duplicate with multiple ids", not dup, "duplicated id=" .. tostring(id))
    check("correct length after ignored duplicates", #list == 2, "length=" .. #list)
end
do
    -- getId returns nil: no deduplication, duplicates allowed
    local list = {}
    addToSortedTable(newItem(nil, 5), getter, noId, list, 5)
    addToSortedTable(newItem(nil, 5), getter, noId, list, 5)
    check("getId=nil: duplicates allowed", #list == 2, "length=" .. #list)
end

-- ── Group 4: insufficient item excluded ───────────────────────────────────────
print("\n[Group 4] Insufficient item excluded")
do
    local list = {}
    local size = 3
    addToSortedTable(newItem("a", 10), getter, getId, list, size)
    addToSortedTable(newItem("b", 8), getter, getId, list, size)
    addToSortedTable(newItem("c", 6), getter, getId, list, size)
    local weak = newItem("d", 2)
    addToSortedTable(weak, getter, getId, list, size)
    check("weak item absent from full list", not contains(list, weak))
    local ok, detail = isSortedDesc(list, getter)
    check("list remains sorted after rejecting weak item", ok, detail)
end
do
    local list = {}
    local size = 3
    addToSortedTable(newItem("a", 10), getter, getId, list, size)
    addToSortedTable(newItem("b", 8), getter, getId, list, size)
    local medium = newItem("c", 5)
    addToSortedTable(medium, getter, getId, list, size) -- list not full: should be inserted
    check("medium item accepted when list is not full", contains(list, medium))
end
do
    -- Duplicate with lower score: must not appear twice
    local list = {}
    local size = 5
    addToSortedTable(newItem("a", 10), getter, getId, list, size)
    local worse = newItem("a", 3)
    addToSortedTable(worse, getter, getId, list, size)
    check("worse duplicate absent from list", not contains(list, worse))
end

-- ── Summary ───────────────────────────────────────────────────────────────────
print(string.format("\n%d tests passed, %d failures.", passed, failed))
if failed > 0 then os.exit(1) end

