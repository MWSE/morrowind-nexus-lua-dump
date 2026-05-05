local async = require("openmw.async")
local storage = require("openmw.storage")
local MOD_NAME = "ActionCameraSwap"
local L = require("openmw.core").l10n(MOD_NAME)
local I = require("openmw.interfaces")
local settingsSection = "SettingsPlayer" .. MOD_NAME
local modSettings = storage.playerSection(settingsSection)
local scriptVersion = 1.11

I.Settings.registerPage {
    key = MOD_NAME,
    l10n = MOD_NAME,
    name = "Action Camera Swap",
    description = L("modDescription", { version = scriptVersion })
}

I.Settings.registerGroup {
    key = settingsSection,
    l10n = MOD_NAME,
    name = "Action Camera Swap",
    page = MOD_NAME,
    description = L("settingsDescription"),
    permanentStorage = false,
    settings = {
        {
            key = "modEnabled",
            name = L("modEnabled_name"),
            description = L("modEnabled_desc"),
            default = true,
            renderer = "checkbox"
        },
        {
            key = "always1stIndoors",
            name = L("alwaysFirstIndoors_name"),
            description = L("alwaysFirstIndoors_desc"),
            default = true,
            renderer = "checkbox"
        },
        {
            key = "dofOn",
            name = L("dofOn_name"),
            description = L("dofOn_desc"),
            default = true,
            renderer = "checkbox"
        },
        {
            key = "dofSwap",
            name = L("dofSwap_name"),
            description = L("dofSwap_desc"),
            default = true,
            renderer = "checkbox"
        },
        {
            key = "dofChainNum",
            name = L("dofChainNum_name"),
            description = L("dofChainNum_desc"),
            default = 0,
            min = 0,
            renderer = "number"
        },
        {
            key = "dofBaseBlurRadius",
            name = L("dofBaseBlurRadius_name"),
            description = L("dofBaseBlurRadius_desc"),
            default = 0.275,
            max = 1,
            min = 0,
            renderer = "number"
        },
        {
            key = "dofBlurFalloff",
            name = L("dofBlurFalloff_name"),
            description = L("dofBlurFalloff_desc"),
            default = 2,
            max = 10,
            min = 0.1,
            renderer = "number"
        },
        {
            key = "dofMaxBlurRadius",
            name = L("dofMaxBlurRadius_name"),
            description = L("dofMaxBlurRadius_desc"),
            default = 6,
            max = 10,
            min = 1,
            renderer = "number"
        },
        {
            key = "showMessages",
            name = L("showMsgs_name"),
            description = L("showMsgs_desc"),
            default = false,
            renderer = "checkbox"
        }
    }
}

local modEnabled = modSettings:get("modEnabled")
local always1stIndoors = modSettings:get("always1stIndoors")
local dofOn = modSettings:get("dofOn")
local dofSwap = modSettings:get("dofSwap")
local dofChainNum = modSettings:get("dofChainNum")
local dofBaseBlurRadius = modSettings:get("dofBaseBlurRadius")
local dofBlurFalloff = modSettings:get("dofBlurFalloff")
local dofMaxBlurRadius = modSettings:get("dofMaxBlurRadius")
local showMessages = modSettings:get("showMessages")

local function updateSettings(_, key)
    if key == "modEnabled" then
        modEnabled = modSettings:get("modEnabled")
    elseif key == "always1stIndoors" then
        always1stIndoors = modSettings:get("always1stIndoors")
    elseif key == "dofOn" then
        dofOn = modSettings:get("dofOn")
    elseif key == "dofSwap" then
        dofSwap = modSettings:get("dofSwap")
    elseif key == "dofChainNum" then
        dofChainNum = modSettings:get("dofChainNum")
    elseif key == "dofBaseBlurRadius" then
        dofBaseBlurRadius = modSettings:get("dofBaseBlurRadius")
    elseif key == "dofBlurFalloff" then
        dofBlurFalloff = modSettings:get("dofBlurFalloff")
    elseif key == "dofMaxBlurRadius" then
        dofMaxBlurRadius = modSettings:get("dofMaxBlurRadius")
    elseif key == "showMessages" then
        showMessages = modSettings:get("showMessages")
    end
end
modSettings:subscribe(async:callback(updateSettings))

return {
    MOD_NAME = MOD_NAME,
    scriptVersion = scriptVersion,
    modEnabled = function() return modEnabled end,
    always1stIndoors = function() return always1stIndoors end,
    dofOn = function() return dofOn end,
    dofSwap = function() return dofSwap end,
    dofChainNum = function() return dofChainNum end,
    dofBaseBlurRadius = function() return dofBaseBlurRadius end,
    dofBlurFalloff = function() return dofBlurFalloff end,
    dofMaxBlurRadius = function() return dofMaxBlurRadius end,
    showMessages = function() return showMessages end,
}
