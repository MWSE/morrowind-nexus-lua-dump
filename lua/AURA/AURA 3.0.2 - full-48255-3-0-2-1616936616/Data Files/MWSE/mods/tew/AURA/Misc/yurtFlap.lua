local modversion = require("tew\\AURA\\version")
local version = modversion.version
local config=require("tew\\AURA\\config")
local debugLogOn=config.debugLogOn

local vol=config.yurtVol/200

local yurtDoors={
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
local bearSkins={
    "BM_IC_door_pelt",
    "BM_IC_door_pelt_dark",
    "BM_IC_door_pelt_wolf",
}

local function debugLog(string)
    if debugLogOn then
       mwse.log("[AURA "..version.."] Misc (Others): "..string)
    end
end

local function yurtFlap(e)
    if not e.target.object.objectType == tes3.objectType.door then return end
    for _, door in pairs(yurtDoors) do
        if e.target.object.id==door then
            tes3.playSound({soundPath="tew\\AURA\\Misc\\yurtflap.wav", volume=0.9*vol, pitch=0.8, reference=tes3.player})
            debugLog("Playing yurt flap sound.")
            return
        end
    end
    for _, door in pairs(bearSkins) do
        if e.target.object.id==door then
            tes3.playSound({soundPath="tew\\AURA\\Misc\\yurtflap.wav", volume=0.9*vol, pitch=0.5, reference=tes3.player})
            debugLog("Playing bear skin sound.")
            return
        end
    end
end

print("[AURA "..version.."] Yurt flap sound initialised.")
event.register("activate", yurtFlap)