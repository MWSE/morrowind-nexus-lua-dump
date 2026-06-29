-- world/clutterItems.lua
---@omw-context none
-- Shared lightweight furniture-surface clutter classification.

local M = {}

function M.objectEnabled(obj)
    if not obj then return false end
    local ok, enabled = pcall(function() return obj.enabled end)
    if ok and enabled == false then return false end
    return true
end

local function itemText(env, item)
    local profiles = env and env.profiles
    local recordId = item and item.recordId or ""
    local model = profiles and profiles.objectModelPath and profiles.objectModelPath(item) or ""
    local name = ""
    local ok, rec = pcall(function()
        if item and item.type and item.type.record then return item.type.record(item) end
        return nil
    end)
    if ok and rec and rec.name then name = rec.name end
    return (tostring(recordId) .. " " .. tostring(model) .. " " .. tostring(name)):lower()
end

local function isFlatPaperLike(text)
    return text:find("bk_", 1, true) ~= nil
        or text:find("book_", 1, true) ~= nil
        or text:find("text_", 1, true) ~= nil
        or text:find("paper", 1, true) ~= nil
        or text:find("parchment", 1, true) ~= nil
        or text:find("scroll", 1, true) ~= nil
        or text:find("note", 1, true) ~= nil
        or text:find("letter", 1, true) ~= nil
end

local function isSoftFloorCovering(text)
    return text:find("rug", 1, true) ~= nil
        or text:find("carpet", 1, true) ~= nil
        or text:find("bearskin", 1, true) ~= nil
        or text:find("pelt", 1, true) ~= nil
        or text:find("hide", 1, true) ~= nil
        or text:find("floorcloth", 1, true) ~= nil
end

local function hasWord(text, word)
    return tostring(text or ""):find("%f[%w]" .. tostring(word or "") .. "%f[%W]") ~= nil
end

local drinkWords = {
    "cup", "goblet", "flask", "pitcher", "jug", "mug", "liquor",
    "mazte", "matze", "sujamma", "shein", "greef", "flin", "brandy", "comberry",
}

local function isDrinkOrTableware(text)
    if text:find("drink", 1, true)
        or text:find("bottle", 1, true)
        or text:find("beer", 1, true)
        or text:find("wine", 1, true)
        or text:find("ale", 1, true)
        or text:find("comestible", 1, true) then
        return true
    end
    for _, word in ipairs(drinkWords) do
        if hasWord(text, word) then return true end
    end
    return false
end

function M.isFurnitureLike(env, item)
    local text = itemText(env, item)
    return text:find("stool", 1, true) ~= nil
        or text:find("chair", 1, true) ~= nil
        or text:find("bench", 1, true) ~= nil
        or text:find("bed", 1, true) ~= nil
end

function M.kind(env, item)
    local text = itemText(env, item)
    if text:find("cushion", 1, true) ~= nil or text:find("pillow", 1, true) ~= nil then
        return "soft_surface"
    end
    if isSoftFloorCovering(text) then
        return "soft_surface"
    end
    if isFlatPaperLike(text) then
        return "paper_item"
    end
    if text:find("stool", 1, true) ~= nil
        or text:find("chair", 1, true) ~= nil
        or text:find("bench", 1, true) ~= nil then
        return "hard_blocker"
    end
    local softItem = text:find("armor", 1, true) ~= nil
        or text:find("armour", 1, true) ~= nil
        or text:find("cuirass", 1, true) ~= nil
        or text:find("pauldron", 1, true) ~= nil
        or text:find("gauntlet", 1, true) ~= nil
        or text:find("greave", 1, true) ~= nil
        or text:find("boot", 1, true) ~= nil
        or text:find("helm", 1, true) ~= nil
        or text:find("shield", 1, true) ~= nil
        or text:find("weapon", 1, true) ~= nil
        or text:find("sword", 1, true) ~= nil
        or text:find("axe", 1, true) ~= nil
        or text:find("dagger", 1, true) ~= nil
        or text:find("mace", 1, true) ~= nil
        or text:find("spear", 1, true) ~= nil
        or text:find("bow", 1, true) ~= nil
        or text:find("potion", 1, true) ~= nil
        or text:find("food", 1, true) ~= nil
        or isDrinkOrTableware(text)
    if softItem then return "soft_item_blocker" end
    local hard = text:find("lantern", 1, true) ~= nil
        or text:find("candlestick", 1, true) ~= nil
        or text:find("candle", 1, true) ~= nil
        or text:find("drum", 1, true) ~= nil
        or text:find("planter", 1, true) ~= nil
        or text:find("potted", 1, true) ~= nil
        or text:find("flowerpot", 1, true) ~= nil
        or text:find("plant", 1, true) ~= nil
        or text:find("flora", 1, true) ~= nil
    return hard and "hard_blocker" or nil
end

return M
