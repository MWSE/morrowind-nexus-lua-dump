local function getVersion()
    local metadata = toml.loadMetadata("BardicInspiration")
    if metadata then
        return metadata.package.version
    else
        return "[metadata missing]"
    end
end

local function initialized()
    if tes3.isModActive("BardicInspiration.esp") then
        local common = require("mer.bardicInspiration.common")
        --Deals with replacing vanilla lutes with playable ones
        require("mer.bardicInspiration.controllers.luteController")
        --Deals with adding lutes to merchants around Vvardenfell
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
