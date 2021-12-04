local function getVersion()
    local versionFile = io.open("Data Files/MWSE/mods/mer/bardicInspiration/version.txt", "r")
    local version = ""
    for line in versionFile:lines() do -- Loops over all the lines in an open text file
        version = line
    end
    return version
end

local function initialized()
    if tes3.isModActive("BardicInspiration.esp") then
        local common = require("mer.bardicInspiration.common")
        --Deals with replacing vanilla lutes with playable ones
        require("mer.bardicInspiration.controllers.luteController")
        --Deals with adding lutes to merchants around Vvardenfel
        require("mer.bardicInspiration.controllers.merchantController")
        --Checks when the player readies a lute and triggers performances
        require("mer.bardicInspiration.controllers.lutePlayController")
        --Manage performance skill
        require("mer.bardicInspiration.controllers.skillController")
        require("mer.bardicInspiration.controllers.experienceController")
        --Manage Dialog entries
        require("mer.bardicInspiration.dialog.performanceDialog")
        require("mer.bardicInspiration.dialog.learnMusicDialog")


        common.log:info("%s Initialised", getVersion())
    end
end
event.register("initialized", initialized)

--MCM
require("mer.bardicInspiration.mcm")
