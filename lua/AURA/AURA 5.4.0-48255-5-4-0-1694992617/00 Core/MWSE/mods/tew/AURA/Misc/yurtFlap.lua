local config = require("tew.AURA.config")
local metadata = toml.loadMetadata("AURA")
local version = metadata.package.version
local common = require("tew.AURA.common")

local vol = config.volumes.misc.yurtVol / 100

local yurtDoors = {
    "in_ashl_door_01",
    "in_ashl_door_02",
    "in_ashl_door_02_sha",
    "ex_ashl_door_01",
    "ex_ashl_door_02",
    "_In_Drs_Tnt_01_Door",
    "_In_Drs_Tnt_03_Door",
    "_Ex_Drs_Tnt_01_Door",
    "_Ex_Drs_Tnt_03_Door",
}
local bearSkins = {
    "BM_IC_door_pelt",
    "BM_IC_door_pelt_dark",
    "BM_IC_door_pelt_wolf",
}

local debugLog = common.debugLog

-- Fabric sorta sound on entering yurts and those weird BM dwellings --
local function yurtFlap(e)
    if not (e.target.object.objectType == tes3.objectType.door) then return end
    for _, door in pairs(yurtDoors) do
        if e.target.object.id == door then
            tes3.playSound { sound = "tew_yurt", volume = 0.9 * vol, pitch = 0.8 }
            debugLog("Playing yurt flap sound.")
            return
        end
    end
    for _, door in pairs(bearSkins) do
        if e.target.object.id == door then
            tes3.playSound { sound = "tew_yurt", volume = 0.9 * vol, pitch = 0.5 }
            debugLog("Playing bear skin sound.")
            return
        end
    end
end

event.register("activate", yurtFlap)
