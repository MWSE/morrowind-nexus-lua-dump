local Util = require("CraftingFramework.util.Util")
local logger = Util.createLogger("RecoverMaterials")
local Craftable = require("CraftingFramework.components.Craftable")
--[[
    When the player equips a crafted tool which has no durability,
    give the option to deconstruct it for materials
]]
---@param e equipEventData
local function recoverBrokenToolMaterials(e)
    logger:debug("Recovering broken tool materials")
    local materialsUsed = e.itemData.data.materialsUsed
    local materialRecovery = e.itemData.data.materialRecovery
    local recoverMessage = Craftable:recoverMaterials(materialsUsed, materialRecovery)
    if recoverMessage then
        tes3.messageBox(recoverMessage)
    else
        tes3.messageBox("Вам не удалось извлечь материалы.")
    end
    logger:debug("removing %s from inventory", e.item.name)
    tes3.removeItem{
        reference = tes3.player,
        item = e.item,
        itemData = e.itemData,
        count = 1,
        playSound = false,
    }
    Craftable:playDeconstructionSound()
end

local function showRecoverMaterialsMessage(e)
    if not e.itemData then
        return
    end
    local isBroken = e.itemData.condition and e.itemData.condition <= 0
    local materialsUsed = e.itemData.data.materialsUsed

    if isBroken and materialsUsed then
        logger:debug("Item is broken, showing recover materials message")
        tes3ui.showMessageMenu{
            message = string.format("%s сломан", e.item.name),
            buttons = {
                {
                    text = "Извлечь материалы",
                    callback = function()
                        recoverBrokenToolMaterials(e)
                    end
                }
            },
            cancels = true,
        }
        return false
    end
end

event.register("equip", showRecoverMaterialsMessage, { priority = 500 })