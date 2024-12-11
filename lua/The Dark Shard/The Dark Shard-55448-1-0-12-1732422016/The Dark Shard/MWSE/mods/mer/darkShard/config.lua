---@class DarkShard.Config
local config = {}

config.metadata = toml.loadMetadata("DarkShard") --[[@as MWSE.Metadata]]

---@class DarkShard.Config.static
config.static = {
    resonator_misc_id = "afq_dwe_powerbox_misc",
    vanilla_telescope_id = "in_dwrv_telescope",
    vanilla_observatory_id = "in_dwrv_obsrv10",
    observatory_hatch_id = "afq_obsrv_hatch_01",
    resonator_mesh = "afq\\afq_resonator.nif",
}

---@class DarkShard.Config.MCM
local mcmDefault = {
    logLevel = "INFO",
    modEnabled = true,
    zoomUsingPageKeys = false,
}

---@class DarkShard.Config.tempData
local tempDataDefault = {
    ---@type number?
    previousWaveHeight = nil,
    ---@type boolean?
    telescopeActive = nil,
    ---@type tes3vector3?
    activateTelescope_previousPosition = nil,
    ---@type tes3vector3?
    activateTelescope_previousOrientation = nil,
    ---@type tes3vector3?
    activateTelescope_previousTelescopeOrientation = nil,
    ---@type 'telescope' | 'observatory' | nil
    activeTelescopeType = nil,
    ---@type boolean?
    telescopeCometViewed = nil,
    ---@type boolean?
    previousZoomEnable = nil,
    ---@type number?
    previousZoom = nil,
    ---@type table<niNode, { timePassed: number, duration: number, targetPhase: number, startingPhase?: number }>
    resonatorAnimatingNodes = {},
    ---@type boolean?
    lookingAtComet = nil,
}

---@class DarkShard.Config.persistent
local persistentDefault = {
    ---@type number? How long until the dialog unlocks
    phenomenonDialogUnlockTime = nil,
    ---@type number? The number of different telescopes the comet has been viewed through
    cometsSeen = 0,
    ---@type boolean Whether the note has been added to the player's inventory
    noteAdded = false,
    ---@type boolean Whether an assassination attempt has been made
    assassinationAttempted = false,
}

---@type DarkShard.Config.MCM
config.mcm = mwse.loadConfig(config.metadata.package.name, mcmDefault)

config.save = function()
    mwse.saveConfig(config.metadata.package.name, config.mcm)
end

---@type DarkShard.Config.tempData
config.tempData = setmetatable({}, {
    __index = function(_, key)
        if not tes3.player then return end
        tes3.player.tempData.darkShard = tes3.player.tempData.darkShard or {}
        table.copymissing(tes3.player.tempData.darkShard, table.deepcopy(tempDataDefault))
        return tes3.player.tempData.darkShard[key]
    end,
    __newindex = function(_, key, value)
        if not tes3.player then return end
        tes3.player.tempData.darkShard = tes3.player.tempData.darkShard or {}
        table.copymissing(tes3.player.tempData.darkShard, table.deepcopy(tempDataDefault))
        tes3.player.tempData.darkShard[key] = value
    end
})

---@type DarkShard.Config.persistent
config.persistent = setmetatable({}, {
    __index = function(_, key)
        if not tes3.player then return end
        tes3.player.data.darkShard = tes3.player.data.darkShard or {}
        table.copymissing(tes3.player.data.darkShard, table.deepcopy(persistentDefault))
        return tes3.player.data.darkShard[key]
    end,
    __newindex = function(_, key, value)
        if not tes3.player then return end
        tes3.player.data.darkShard = tes3.player.data.darkShard or {}
        table.copymissing(tes3.player.data.darkShard, table.deepcopy(persistentDefault))
        tes3.player.data.darkShard[key] = value
    end
})


return config