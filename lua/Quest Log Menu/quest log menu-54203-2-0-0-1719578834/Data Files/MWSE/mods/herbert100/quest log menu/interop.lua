---@class herbert.QLM.interop
---@field get_quest_icon_path fun(quest: tes3quest): string? function that fetches the icon path of a given `tes3quest`
local interop = {}

--- Gets the icon path for a given `tes3quest`. You can alter this function if you want
-- to add more icons to this mod, or if you want to alter the icons that are used.
---@param quest tes3quest
---@return string? icon_path (if it exists)
function interop.get_quest_icon_path(quest)
end

-- make `interop.get_quest_icon_path` default to getting the ssqn icon path
do 
    local hlib = require('herbert100')
    local common = hlib.import("common") ---@type herbert.QLM.common
    if common.ssqn_interop then
        interop.get_quest_icon_path = common.ssqn_interop.get_quest_icon_path
    end
end

return interop