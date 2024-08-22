local mcm = require("JosephMcKean.teaMerchants.mcm")
local function initialized()
    -- the lua code won't work without the Tea Merchants.esp 
    if tes3.isModActive("Tea Merchants.esp") then
        if tes3.isModActive("Ashfall.esp") then
            require("JosephMcKean.teaMerchants.teaMerchant")
            require("JosephMcKean.teaMerchants.addTea")
            require("JosephMcKean.teaMerchants.newBottles")
            mwse.log("[%s %s] Initialized", mcm.mod, mcm.version)
        else
            -- show a messagebox upon entering the main menu
            tes3.messageBox(
                "Tea Merchants требует Ashfall. Пожалуйста, установите Ashfall, чтобы использовать этот мод.")
        end
    end
end
event.register("initialized", initialized)
require("JosephMcKean.teaMerchants.mcm")
