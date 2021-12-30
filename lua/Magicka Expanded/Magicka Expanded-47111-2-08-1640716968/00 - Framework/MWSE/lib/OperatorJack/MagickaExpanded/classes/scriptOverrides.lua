local tomes = require("OperatorJack.MagickaExpanded.classes.tomes")
local grimoires = require("OperatorJack.MagickaExpanded.classes.grimoires")

local function initialized()
    mwse.overrideScript("OJ_ME_Test", function(e)
        tomes.addTomesToPlayer()
        grimoires.addGrimoiresToPlayer()
    
        print("[Magicka Expanded: INFO] Executed Lua Script Override OJ_ME_Test")
        mwscript.stopScript{script="OJ_ME_Test"}
    end)
    
    print("[Magicka Expanded: INFO] Registered Script Overrides")
end

event.register("initialized", initialized)