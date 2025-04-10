local GuarCompanion = require("mer.theGuarWhisperer.GuarCompanion")

event.register("UIEXP:sandboxConsole", function(e)
    e.sandbox.guarWhisperer = {
        GuarCompanion = GuarCompanion,
        getCurrent = function()
            return GuarCompanion.get(e.sandbox.currentRef)
        end
    }
end)