local common = require("mer.sigilStones.common")
local logger = common.createLogger("environment")
local SigilStone = require("mer.sigilStones.components.SigilStone")

local function giveStone()
    local sigilStone = SigilStone:create{
        baseObjectId = "mer_sigilStone_01",
    }
    if not sigilStone then
        return
    end
    sigilStone:addToInventory()
    tes3.messageBox("%s has been added to your inventory", sigilStone.object.name)
end

event.register("UIEXP:sandboxConsole", function(e)
    e.sandbox.sigilStones = {
        giveStone = giveStone
    }
    logger:info("Sandboxed Sigil Stones Environment")
end)