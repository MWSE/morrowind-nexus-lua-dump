local moreConfigurableMagic = {}
moreConfigurableMagic.currentValues = {}
local config = require("KKB.More Configurable Magic.config")
local moreMagic = require("KKB.More Configurable Magic.moreMagic")
local function registerModConfig()
	mwse.mcm.registerMCM(require("KKB.More Configurable Magic.mcm"))
end
event.register("modConfigReady", registerModConfig)

local function onInit()
    moreMagic.mcpDur = tes3.hasCodePatchFeature(tes3.codePatchFeature.spellmakingMatchesEditor)
    mwse.log("Kukaibo's more configurable magic mod loaded")
end
event.register("initialized", onInit)