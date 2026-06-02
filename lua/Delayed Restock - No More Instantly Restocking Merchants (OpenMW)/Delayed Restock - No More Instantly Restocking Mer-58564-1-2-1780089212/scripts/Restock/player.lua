local core = require("openmw.core")
local I = require("openmw.interfaces")
local ui = require("openmw.ui")

I.Settings.registerPage({
    key = "Restock",
    l10n = "Restock",
    name = "Restock",
    description = "Makes it so merchants no longer restock immediately. Note: This mod is not safe to uninstall, if you want merchants to instantly restock again just set the restock delay to 0.",
})

local function showMessage(message)
    ui.showMessage(tostring(message), { showInDialogue = true })
end

local function onUiModeChanged(data)
    if type(data) ~= "table" then
        return
    end

    -- Fire on both transitions: entering Barter and leaving it.
    -- This lets global logic refresh stock without requiring full dialogue reopen.
    if data.newMode == I.UI.MODE.Barter or data.oldMode == I.UI.MODE.Barter then
        core.sendGlobalEvent("RestockReimpl_OnUiModeChanged", {
            oldMode = data.oldMode,
            newMode = data.newMode,
            merchant = data.arg,
        })
    end
end

return {
    eventHandlers = {
        RestockReimpl_ShowMessage = showMessage,
        UiModeChanged = onUiModeChanged,
    },
}
