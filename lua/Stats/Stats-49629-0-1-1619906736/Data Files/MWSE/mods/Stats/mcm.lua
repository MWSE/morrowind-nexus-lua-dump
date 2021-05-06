local defaultConfig ={
    characters = {}
}
local config = mwse.loadConfig("Stats", defaultConfig)

local template = mwse.mcm.createTemplate("Stats")
template:saveOnClose("Stats", config)
--[[
function disp_time(time)
    if(time == nil) then
        return "no data"
    end
    local days = math.floor(time/86400)
    local hours = math.floor(math.fmod(time, 86400)/3600)
    local minutes = math.floor(math.fmod(time,3600)/60)
    local seconds = math.floor(math.fmod(time,60))
    return string.format("%d:%02d:%02d:%02d",days,hours,minutes,seconds)
end
]]
local savePage = template:createSidebarPage({
    label = "This Save",
    description = "Stats for what has happened in the history of this save file."
})
--[[
if (tes3.player) then
    local saveTimePlayed = tes3.player.data.JaceyS.Stats.time
end
local saveTimePlayedDisplay = savePage:createCategory({
    label = "Time Played: ",
    description = disp_time(saveTimePlayed)
})
]]
local characterPage = template:createSidebarPage({
    label = "This Character",
    description = "Stats for what has happened to this character, over any number of branching timelines."
})

local globalPage = template:createSidebarPage({
    label = "Global Stats",
    description = "Stats across all tracked characters."
})



mwse.mcm.register(template)