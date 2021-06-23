local function initialized()
    if tes3.isModActive("BardicInspiration.esp") then
        --Deals with replacing vanilla lutes with playable ones
        require("mer.bardicInspiration.controllers.luteController")
        --Checks when the player readies a lute and triggers performances
        require("mer.bardicInspiration.controllers.lutePlayController")
        --Manage performance skill
        require("mer.bardicInspiration.controllers.skillController")
        require("mer.bardicInspiration.controllers.experienceController")
        --Manage Dialog entries
        require("mer.bardicInspiration.dialog.performanceDialog")
        require("mer.bardicInspiration.dialog.learnMusicDialog")
    end
end
event.register("initialized", initialized)

--MCM
require("mer.bardicInspiration.mcm")
