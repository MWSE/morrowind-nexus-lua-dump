local stationID = "ek_rm_table_charge"

local hourlyRecharge = 100
local maxStationCharge = 5000

local function getNow()
    return ( tes3.worldController.daysPassed.value * 24 ) + tes3.worldController.hour.value
end

local function itemRechargeFilter(e)
    local isEnchanted = e.item.enchantment ~= nil
    if isEnchanted then
        local charge = e.itemData and e.itemData.charge or e.item.enchantment.maxCharge
        local maxCharge = e.item.enchantment.maxCharge

        if charge < maxCharge then
            return true
        end
        
    end                                             
    return false
end

local function getData()
    tes3.player.data.rethanmanor = tes3.player.data.rethanmanor or {
        stationCharge = maxStationCharge,
        lastChargeTime = getNow()
    }
    return tes3.player.data.rethanmanor
end


local function transferCharge(e, amount)
    getData().stationCharge = getData().stationCharge - amount
    e.itemData.charge = e.itemData.charge + amount
    tes3.playSound{ sound = "enchant success"}
    tes3.messageBox("Item recharged!")
end

local function activate(e)
    if e.target.object.id == stationID then
        local data = getData()
        if data.stationCharge > 1 then
            tes3ui.showInventorySelectMenu({
                title = string.format("%s (charge: %d)", e.target.object.name, getData().stationCharge ),
                noResultsText = "You have no items to recharge",
                filter = itemRechargeFilter,
                callback = function(e)
                    if e.item then
                        local drainedAmount = e.item.enchantment.maxCharge - e.itemData.charge
                        local refill = drainedAmount
                        refill = math.clamp( refill, 0, getData().stationCharge )
                        transferCharge(e, refill)
                    end
                end
            })
        else
            tes3.messageBox("The station needs to recharge")
        end
    end
end
event.register("activate", activate)


local function simulate(e)
    if not tes3.player then return end
    local now = getNow()
    local data = getData()
    if now > ( data.lastChargeTime + 1 ) then
        data.lastChargeTime = math.min((data.lastChargeTime + 1), now)
        data.stationCharge = math.min( (data.stationCharge + hourlyRecharge), maxStationCharge )
    end
end

event.register("enterFrame", simulate)

local function uiObjectTooltip(e)
    if e.object.id == stationID then
        local label = e.tooltip:findChild(tes3ui.registerID("HelpMenu_name"))
        label.text = label.text .. string.format(" (charge: %d)", getData().stationCharge)

    end
end


event.register("uiObjectTooltip", uiObjectTooltip)

mwse.log("rethan manor initialized")