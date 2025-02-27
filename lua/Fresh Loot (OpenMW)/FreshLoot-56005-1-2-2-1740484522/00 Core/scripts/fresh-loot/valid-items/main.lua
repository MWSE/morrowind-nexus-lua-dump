local mHelpers = require("scripts.fresh-loot.util.helpers")
local log = require("scripts.fresh-loot.util.log")

local itemIds = {}
for _, plugin in ipairs({ "base" }) do
    local ids = require("scripts.fresh-loot.valid-items.ids-" .. plugin)
    mHelpers.addAllToHashset(itemIds, ids)
    log(string.format("Found %d item ids in the \"%s\" plugin", #ids, plugin))
end

return itemIds