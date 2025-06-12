local common = require("mer.chargenScenarios.common")
local Clutter = require("mer.chargenScenarios.component.Clutter")
local Validator = require("mer.chargenScenarios.util.validator")

---@class ChargenScenariosClutterList
---@field clutters table<number, ChargenScenariosClutter> @the list of clutter to add to the world
local ClutterList = {
    registeredClutterLists = {},
}

---Register a clutter list that can be used in multiple scenarios
---@param id string
---@param clutters ChargenScenariosClutterInput[]
---@return ChargenScenariosClutterList
function ClutterList.register(id, clutters)
    local clutterList = ClutterList:new(clutters)
    ClutterList.registeredClutterLists[id] = clutterList
    return clutterList
end

function ClutterList.get(id)
    return ClutterList.registeredClutterLists[id]
end

--Constructor
---@param clutters ChargenScenariosClutterInput[]
---@return ChargenScenariosClutterList
function ClutterList:new(clutters)
    local clutterList = {}
    ---Build
    clutterList.clutters = common.convertListTypes(clutters, Clutter)
    setmetatable(clutterList, self)
    self.__index = self
    return clutterList
end



---@return tes3reference[]|nil
function ClutterList:doClutter()
    if self.clutters and table.size(self.clutters) > 0 then
        local placedClutterReferences = {}
        for _, clutter in ipairs(self.clutters) do
            if clutter:checkRequirements() then
                local item = clutter:place()
                if item then
                    table.insert(placedClutterReferences, item)
                end
            end
        end
        return placedClutterReferences
    end
end

return ClutterList
