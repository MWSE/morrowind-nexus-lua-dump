local storage = require('openmw.storage')
local core = require('openmw.core')

require("scripts.morrowind_world_randomizer.generator.items")
require("scripts.morrowind_world_randomizer.generator.statics")
require("scripts.morrowind_world_randomizer.generator.containers")
require("scripts.morrowind_world_randomizer.generator.creatures")
require("scripts.morrowind_world_randomizer.generator.spells")
require("scripts.morrowind_world_randomizer.generator.lights")

local tableLib = require("scripts.morrowind_world_randomizer.utils.table")

local this = {}

this.storageName = "MWR_By_Diject"

this.version = 4

---@class mwr.globalStorageData
---@field version number
---@field itemsData mwr.itemsData
---@field treesData mwr.staticsData
---@field floraData mwr.staticsData
---@field rocksData mwr.staticsData
---@field herbsData mwr.containersData
---@field creaturesData mwr.creaturesData
---@field spellsData mwr.spellsData
---@field lightsData mwr.lightsData

this.storage = nil
---@type mwr.globalStorageData
this.data = nil

---@return boolean #have the game files been modified
function this.init()
    this.storage = storage.globalSection(this.storageName)
    this.data = this.storage:asTable()
    if not this.data or this.version ~= this.data.version then
        return true
    end
    local gameFiles = this.data.gameFiles
    if gameFiles then
        local fileTable = {}
        for _, file in pairs(gameFiles) do
            if not core.contentFiles.has(file) then
                return true
            end
            fileTable[file] = true
        end
        for _, file in pairs(core.contentFiles.list) do
            if not fileTable[file] then
                return true
            end
        end
        return false
    end
    return true
end

function this.saveGameFilesDataToStorage()
    this.data.gameFiles = tableLib.copy(core.contentFiles.list)
    this.storage:set("gameFiles", this.data.gameFiles)
end

---@param data table|nil
function this.save(data)
    if data then
        this.data = data
    end
    this.storage:reset(this.data)
end

return this