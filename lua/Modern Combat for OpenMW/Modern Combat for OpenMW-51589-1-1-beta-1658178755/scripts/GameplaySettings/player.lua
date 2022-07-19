local ui = require("openmw.ui");

return {
    engineHandlers = {
        onUpdate = function()
            ui.showMessage(
                "ModernCombat v1.0: Please uninstall previous mod verions first. Check instruction on nexus for more info")
        end
    }
}
