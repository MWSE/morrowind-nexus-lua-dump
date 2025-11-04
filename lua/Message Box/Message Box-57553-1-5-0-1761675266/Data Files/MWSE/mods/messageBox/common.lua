local log = mwse.Logger.new()

local this = {}



--Player Mod Data
function this.getModDataP()
    log:trace("Checking player's saved Mod Data.")

    if not tes3.player.data.messageBox then
        log:info("Player Mod Data not found, setting to base Mod Data values.")
        tes3.player.data.messageBox = { ["lastMsg"] = "", ["visible"] = true }
        tes3.player.modified = true
    else
        log:trace("Saved Mod Data found.")
    end

    return tes3.player.data.messageBox
end

--Translations
this.i18n = mwse.loadTranslations("messageBox")

return this