local common = require("Revered Dead.common")
local config = require("Revered Dead.config")

common.log:debug("Successfully called stolen item flagging code.")
if tes3.mobilePlayer.bounty < config.graveRobberBounty then
    tes3.mobilePlayer.bounty = tes3.mobilePlayer.bounty + (config.graveRobberBounty)
end
for _, stack in pairs(tes3.player.object.inventory) do
    if stack.object.supportsLuaData == true and stack.variables then
        for _, vars in pairs(stack.variables) do
            if vars.data and vars.data.reveredDead and vars.data.reveredDead.isGraveGoods then
                tes3.setItemIsStolen({ item = stack.object, from = "RevDead_Ancestors", stolen = true })
            end
        end
    end
end
