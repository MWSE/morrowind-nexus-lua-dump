local storage = require("openmw.storage")
local self = require("openmw.self")
local core = require("openmw.core")
local ui = require("openmw.ui")

local l10n = core.l10n("LuaPoweredArtifacts")
local sectionRazor = storage.globalSection("SettingsLuaPoweredArtifacts_razor")
local sectionScourge = storage.globalSection("SettingsLuaPoweredArtifacts_scourge")
local banishSFX = "sound/LuaPoweredArtifacts/banish.mp3"

local function razorInstakill()
    if sectionRazor:get("razorPlaySFX") then
        ---@diagnostic disable-next-line: missing-parameter
        ui.showMessage(l10n("messageDaedricBanishing"))
    end
    if sectionRazor:get("razorShowMessage") then
        core.sound.playSoundFile3d(banishSFX, self, {
            volume = 2,
        })
    end
end

local function scourgeInstakill()
    if sectionScourge:get("scourgePlaySFX") then
        core.sound.playSoundFile3d(banishSFX, self, {
            volume = 2,
        })
    end
end

return {
    eventHandlers = {
        RazorInstakill = razorInstakill,
        ScourgeInstakill = scourgeInstakill,
    }
}
