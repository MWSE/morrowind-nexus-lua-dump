local common = require("scripts.advanced_world_map.common")

local storageName = common.localDataName

local this = {}

this.data = nil

function this.initPlayerStorage(data)
    this.data = data and (data[storageName] or {}) or {}
end

function this.isPlayerStorageReady()
    return this.data ~= nil
end

function this.reset()
    this.data = nil
end

function this.save(data)
    data[storageName] = this.data
end

return this