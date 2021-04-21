--[[
    Looking at the code is cheating!
]]
local configPath = "ModJamTrophyHunt"
local trophyId = "modjam_trophy"

local KM = {
    RID = "u",
    CID = "i",
    XP = "q",
    YP = "w",
    ZP = "e",
    XR = "r",
    YR = "t",
    ZR = "y",
    HNT = "h",
    FND = "____o",
}

local function gnrtid(hnt) 
    local id = 0
    for i = 1, #hnt do
        local c = hnt:sub(i,i)
        id = id + string.byte(c)
    end
    return id
end

local function dcd(enc)
    local dcdd = ""
    for ch in string.gmatch(enc, "%d+") do
        dcdd = dcdd .. string.char(ch)
    end
    return dcdd
end


local trs = mwse.loadConfig(configPath, {})
local function plcTrs()
    if not tes3.player.data.trophiesPlaced then
        for _, d in ipairs(trs) do
            local CID = dcd(d[KM.CID])
            local ref = tes3.createReference{
                object = trophyId, 
                cell = CID, 
                position = {
                    d[KM.XP],
                    d[KM.YP],
                    d[KM.ZP],
                },
                orientation = {
                    d[KM.XR],
                    d[KM.YR],
                    d[KM.ZR],
                }
            }
            ref.data.treasureID = d[KM.HNT]
        end
        tes3.player.data.trophiesPlaced = true
    end
end
event.register("loaded", plcTrs)


local function pickT(e)
    if e.activator == tes3.player then
        local total = 0
        local numFND = 0
        local isN
        for _, data in ipairs(trs) do
            total = total + 1
            if e.target.data and e.target.data.treasureID == data[KM.HNT] then
                if not data[KM.FND] then
                    isN = true
                    data[KM.FND] = gnrtid(data[KM.HNT]) 
                    mwse.saveConfig(configPath, trs)
                    event.trigger("MCM:refresh")
                    event.trigger("MCM:refresh")
                end
            end
            if data[KM.FND] ~= nil then
                numFND = numFND + 1
            end
        end
        if isN then
            tes3.messageBox{
                message = string.format("Congratulations! You have found %d out of %d trophies so far.", numFND, total),
                buttons = { "Okay"}
            }
        end
    end
end
event.register("activate", pickT)

local function registerModConfig()
    local template = mwse.mcm.createTemplate{ name = "Modjam Trophy Hunt"}
    
    local sidebarPage = template:createSideBarPage{
        description = [[
Welcome to the 2021 Modjam Trophy Hunt Competition!

Fifteen trophies have been hidden around Vvarndenfell. The first person to find all of them, or the person who found the most trophies by 10th April, wins a Steam game key!

To enter the competition, find as many trophies as you can, then send the config file to Merlord#0980 on Discord. The config file is located here:
    Data Files/MWSE/config/ModJamTrophyHunt.json

It is recommended you play this mod on an install without a lot of mods that edit a lot of cells, to ensure correct placement of the trophies. 
]]
    }

    local category = sidebarPage:createCategory("Hints:")
    for i, data in ipairs(trs) do
        category:createInfo{
            text = "",
            postCreate = function(self)
                local list = ""
                list = list .. string.format("%G: %s%s\n",
                    i,
                    dcd(data[KM.HNT]),
                    data[KM.FND] ~= nil and " (Found)" or ""
                )
                self.elements.info.text = list
                if data[KM.FND] ~= nil then
                    self.elements.info.color = tes3ui.getPalette("negative_color")
                end
            end
        }
    end
    template:register()
end

event.register("modConfigReady", registerModConfig)