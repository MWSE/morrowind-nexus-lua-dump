
local common = require("mer.darkShard.common")
local logger = common.createLogger("environment")
local DarkShard = require("mer.darkShard")
local Nirn = require("mer.darkShard.components.Nirn")
local Comet = require("mer.darkShard.components.Comet")

event.register("UIEXP:sandboxConsole", function(e)
    logger:debug("Sandboxing Dark Shard Environment")
    e.sandbox.DarkShard = DarkShard
    e.sandbox.darkShard = {
        cometEffect = DarkShard.CometEffect,
        mainQuest = DarkShard.Quest.quests.afq_main,
        aurora = DarkShard.shaders.aurora,
        telescope = DarkShard.shaders.telescope,
        cometTest = function(questIndex)
            --set quest stage
            DarkShard.Quest.quests.afq_main:setIndex(questIndex or 99)
            --set nighttime
            tes3.findGlobal("GameHour").value = 1
            --set clear weather
            tes3.worldController.weatherController:switchImmediate(tes3.weather.clear)
        end,
        telescopeTest = function()
            DarkShard.shaders.telescope.enabled = true
        end,
        calibrate = function(number)
            local shader = DarkShard.shaders.telescope
            shader.RedOffset = number
            shader.GreenOffset = number
            shader.BlueOffset = number
        end,
        enableNirn = function()
            Nirn.enable()
        end,
        enableComet = function()
            Comet.enable()
        end
    }
    logger:info("Sandboxed Dark Shard Environment")
end)
