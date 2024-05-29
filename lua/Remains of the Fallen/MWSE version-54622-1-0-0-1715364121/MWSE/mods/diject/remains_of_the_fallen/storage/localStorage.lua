
local this = {}

local storageName = "rotf_by_diject"

this.data = nil

function this.initPlayerStorage()
    local player = tes3.player
    if not player.data[storageName] then
        player.data[storageName] = {}
    end
    this.data = player.data[storageName]
end

function this.isReady()
    return this.data ~= nil
end

---@param reference tes3reference
function this.getStorage(reference)
    local data = reference.data[storageName]
    if not data then
        reference.data[storageName] = {}
        data = reference.data[storageName]
    end
    reference.modified = true
    return data
end

---@param reference tes3reference
function this.isExists(reference)
    return reference.data[storageName]
end

function this.reset()
    this.data = nil
end

return this