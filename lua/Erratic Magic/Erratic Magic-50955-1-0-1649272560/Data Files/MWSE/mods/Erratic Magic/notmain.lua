local money = 0

local function simulate()
    money = tes3.getPlayerGold()
end


local function giftTax()
    local updatedMoney = tes3.getPlayerGold()
    if updatedMoney > money then
        tes3.removeItem({reference = tes3.player, item = "gold_001", count = ((updatedMoney-money)/2)})
        money = updatedMoney
    end
end

local function initialized()
    event.register("simulate", simulate)
    event.register("menuExit", giftTax)
end

event.register("initialized", initialized)