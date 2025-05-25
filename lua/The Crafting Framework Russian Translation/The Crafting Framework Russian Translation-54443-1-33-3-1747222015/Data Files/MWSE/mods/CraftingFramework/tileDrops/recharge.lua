local Util = require("CraftingFramework.util.Util")
local logger = Util.createLogger("Recharge")
local TileDropper = require("CraftingFramework.components.TileDropper")

local function doRecharge(e)
    local item = e.target.item --[[@as tes3weapon]]
    local luck = tes3.mobilePlayer.luck.current
    local intelligence = tes3.mobilePlayer.intelligence.current
    local fatigue = tes3.mobilePlayer.fatigue.current
    local fatigueBase = tes3.mobilePlayer.fatigue.base
    local normalisedFatigue = fatigue / fatigueBase
    local fFatigueBase = tes3.findGMST(tes3.gmst.fFatigueBase).value
    local fFatigueMult = tes3.findGMST(tes3.gmst.fFatigueMult).value
    local pcEnchant = tes3.mobilePlayer.enchant.current

    local luckTerm = math.clamp(luck, 1, 100) * 0.1
    local intelligenceTerm = math.clamp(intelligence, 0, 100) * 0.2
    local fatigueTerm = fFatigueBase - fFatigueMult * (1 - normalisedFatigue)

    local x = (pcEnchant + intelligenceTerm + luckTerm) * fatigueTerm
    local roll = math.random(1, 100)

    logger:debug("Recharge roll: %s, x: %s", roll, x)
    if roll < x then
        --Add charge
        local charge = e.target.itemData.charge
        local maxCharge = item.enchantment.maxCharge
        local refill = e.held.itemData.soul.soul * math.clamp(roll / x, 0, 1)
        refill = math.clamp(refill, 0, maxCharge - charge)
        logger:debug("Refilling %s charge", refill)
        e.target.itemData.charge = charge + refill
        tes3.playSound{ sound = "enchant success"}
    else
        logger:debug("Recharge failed")
        tes3.playSound{ sound = "enchant fail"}
    end
    --Remove soul gem
    tes3.removeItem{
        reference = e.reference,
        item = e.held.item,
        itemData = e.held.itemData,
        playSound = false
    }
    tes3.messageBox(tes3.findGMST(tes3.gmst.sNotifyMessage51).value, e.held.item.name)
end

TileDropper.register{
    name = "SoulGemRecharge",
    --purple
    highlightColor = {0.5, 0, 0.5},
    isValidTarget = function(target)
        local item = target.item --[[@as tes3weapon]]

        return item
            and target.itemData
            and target.itemData.charge
            and item.enchantment
            and target.itemData.charge < item.enchantment.maxCharge
    end,
    canDrop = function(params)
        return params.held.itemData and params.held.itemData.soul ~= nil
    end,
    onDrop = function(e)
        tes3ui.showMessageMenu{
            message = string.format("Перезарядить %s?", e.target.item.name),
            buttons = {
                { text = "Перезарядить", callback = function()
                    doRecharge(e)
                end},
            },
            cancels = true
        }
    end
}