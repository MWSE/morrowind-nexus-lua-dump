local config = require("mer.characterBackgrounds.config")
local common = require("mer.characterBackgrounds.common")
local logger = common.createLogger("Background")

---@alias CharacterBackgrounds.BackgroundConfig.createMcm fun(self: CharacterBackgrounds.Background, template: table)

---A Background configuration
---@class CharacterBackgrounds.BackgroundConfig
---@field id string id of the background
---@field name string The name of the background
---@field description string|fun():string A description of the background
---@field checkDisabled? fun():boolean  *(Optional)* Returns true if this background is disabled
---@field doOnce? fun(self: CharacterBackgrounds.Background) *(Optional)* Called once when background is selected.
---@field onLoad? fun(self: CharacterBackgrounds.Background) *(Optional)* Called on load and when background is selected.
---@field defaultData? table *(Optional)* A collection of default values for the data table
---@field createMcm? CharacterBackgrounds.BackgroundConfig.createMcm *(Optional)* A function for adding a page to the MCM

---@class CharacterBackgrounds.Background : CharacterBackgrounds.BackgroundConfig
---@field data table A collection of values for the background
---@field getName fun(self: CharacterBackgrounds.Background):string Returns the name of the background
---@field getDescription fun(self: CharacterBackgrounds.Background):string Returns the description of the background
local Background = {
    ---@type { background: CharacterBackgrounds.Background, callback: CharacterBackgrounds.BackgroundConfig.createMcm }[]
    mcms = {},

    ---@type table<string, CharacterBackgrounds.Background>
    registeredBackgrounds = {}
}
Background.__index = Background


function Background.getCurrentBackground()
    return Background.registeredBackgrounds[config.persistent.currentBackground]
end

local function getMeta(id)
    return {
        __index = function(_tbl, key)
            if not tes3.player then return end
            local data = tes3.player.data.merBackgrounds
            if data and data[id] then
                return data[id][key]
            end
        end,
        __newindex = function(_tbl, key, value)
            if not tes3.player then return end
            local data = tes3.player.data.merBackgrounds
            if not data then
                data = {}
                tes3.player.data.merBackgrounds = data
            end
            data[id] = data[id] or {}
            data[id][key] = value
        end
    }
end

---@param data CharacterBackgrounds.Config.persistent
---@deprecated
function Background.callback(data) end

function Background.get(id)
    return config.persistent[id]
end

---@param template mwseMCMTemplate
function Background.registerMcmPages(template)
    logger:info("Registering MCM mod pages")
    --sort mcms by id
    table.sort(Background.mcms, function(a, b)
        return a.background.id < b.background.id
    end)
    for _, mcm in ipairs(Background.mcms) do
        if mcm.background.createMcm then
            logger:info("- %s", mcm.background.name)
            mcm.background:createMcm(template)
        end
    end
end


---@param data CharacterBackgrounds.BackgroundConfig
---@return CharacterBackgrounds.Background
function Background:new(data)
    logger:assert(
        data.id ~= nil,
        "Background must have an id")
    logger:assert(
        data.name ~= nil,
        string.format("Background '%s' must have a name.", data.id)
    )
    logger:assert(
        data.description ~= nil,
        string.format("Background '%s' must have a description.", data.id)
    )
    ---@type CharacterBackgrounds.Background
    local background = table.copy(data)
    setmetatable(background, self)

    background.data = setmetatable({}, getMeta(data.id))

    if background.createMcm then
        table.insert(Background.mcms, {background = background, callback = background.createMcm})
    end

    return background
end


function Background:getName()
    return self.name
end

function Background:getDescription()
    if type(self.description) == "function" then
        return self.description()
    else
        return self.description
    end
end

function Background:isActive()
    return config.persistent.chargenFinished == true
        and config.persistent.currentBackground == self.id
end




return Background