
local powerData = { soulBank = 0, chargeSize = 100,buttonCost = 1,summonCost = 4 }
local lightSystem = require("mundis.lightsystem")
local function updateCellLights()
    local cell = tes3.player.cell
    local cellName = cell.name:lower()
    if string.sub(cellName, 1, 6) == "mundis" then
        if not tes3.player.data.Mundis then
            tes3.player.data.Mundis = {}
            tes3.player.data.Mundis.powerData =powerData
        elseif not tes3.player.data.Mundis.powerData then
            tes3.player.data.Mundis.powerData = powerData

        end
        for ref in cell:iterateReferences() do
            local id = ref.baseObject.id
            if  ref.object.objectType == tes3.objectType.light then
                if tes3.player.data.Mundis.powerData.soulBank == 0 then
                    lightSystem.removeLight(ref)
                else
                    lightSystem.onLight(ref)

                end
            end
        end
    end
end
local function setMundisPowerState(state)
    myModData:set("MUNDISPowered", powerData.soulBank > 0)
    for key, cell in pairs(interfaces.MundisGlobalData.getMundisCells()) do
        for index, value in ipairs(cell:getAll(types.Light)) do
         --   if value.recordId == "aa_light_velothi_brazier_177" then
                value.enabled = powerData.soulBank > 0
         --   end
        end
        for index, value in ipairs(cell:getAll(types.Activator)) do
            if value.recordId == "zhac_brazier_off" then
                value.enabled = powerData.soulBank <= 0
            end
        end
    end
end
local function onPlayerAdded(player)
    setMundisPowerState(powerData.soulBank > 0)


end
local function depositSouls()
    local soulsDeposit = 0
    local addedSoulValue = 0
    for _, stack in pairs(tes3.player.object.inventory) do
        if stack.variables  then
        local soul =stack.variables[1].soul
        

        if soul  then
            local soulSize = soul.soul * stack.count
            soulsDeposit = soulsDeposit + stack.count
            if soulSize > 0 then
                addedSoulValue = addedSoulValue + soulSize
            end
            print(stack.object.id)
            if stack.object.id and  stack.object.id:lower() ~= "misc_soulgem_azura" then
                for index, var in ipairs(stack.variables) do
                    
                tes3.removeItem({reference = tes3.player,item = stack.object,count = stack.count,itemData = var,playSound = false})
                end
            elseif  stack.object.id:lower() == "misc_soulgem_azura" then
                local count = stack.count
                tes3.removeItem({reference = tes3.player,item = stack.object,count = stack.count,itemData = stack.variables[1],playSound = false})
                tes3.addItem({reference = tes3.player,item = "misc_soulgem_azura",count = count,playSound = false,itemData  = nil,soul = nil})
                --      item:remove()
            end
        end
    end
    end
    if addedSoulValue > 0 then
        tes3.messageBox(
            string.format("You deposit %d souls, worth %d charges", soulsDeposit,
                math.floor(addedSoulValue / powerData.chargeSize)))
    else
        tes3.messageBox( string.format("You are carrying no usable soul gems."))
    end
    tes3.player.data.Mundis.powerData.soulBank =  tes3.player.data.Mundis.powerData.soulBank + addedSoulValue

end
local function getChargeCount()
    if not tes3.player.data.Mundis.powerData then
        tes3.player.data.Mundis.powerData = powerData
    end
    if not tes3.player.data.Mundis.powerData.summonCost then
        tes3.player.data.Mundis.powerData.summonCost = powerData.summonCost
        tes3.player.data.Mundis.powerData.buttonCost = powerData.buttonCost
    end
    return math.floor(tes3.player.data.Mundis.powerData.soulBank / tes3.player.data.Mundis.powerData.chargeSize)
end
local function incrementChargeCount(count)
    tes3.player.data.Mundis.powerData.soulBank = tes3.player.data.Mundis.powerData.soulBank + (count * tes3.player.data.Mundis.powerData.chargeSize)
    updateCellLights()
    --setMundisPowerState(powerData.soulBank > 0)
end
local function onActivate(e)
    local id = e.target.object.id:lower()
    if id == "mundis_power_inquire" then
        if not tes3.player.data.Mundis then
            tes3.player.data.Mundis = {}
            tes3.player.data.Mundis.powerData =powerData
        elseif not tes3.player.data.Mundis.powerData then
            tes3.player.data.Mundis.powerData = powerData

        end
        tes3.messageBox(
            string.format("The MUNDIS currently has %d charges remaining.",
                math.floor(tes3.player.data.Mundis.powerData.soulBank / tes3.player.data.Mundis.powerData.chargeSize)))
    elseif id == "mundis_power_deposit" then
        if not tes3.player.data.Mundis then
            tes3.player.data.Mundis = {}
            tes3.player.data.Mundis.powerData =powerData
        elseif not tes3.player.data.Mundis.powerData then
            tes3.player.data.Mundis.powerData = powerData

        end
        depositSouls()
        updateCellLights()
    elseif id == "mundis_summonscroll" then
       tes3.addSpell({spell = "aa_summonspell",reference = tes3.mobilePlayer})
        tes3.messageBox(
            string.format("You read the scroll, and learn the spell to summon the MUNDIS."))
    end
end
local function cellChanged(e)
   updateCellLights()
end

event.register(tes3.event.cellChanged, cellChanged)

event.register(tes3.event.activate,onActivate)
return {getChargeCount = getChargeCount,incrementChargeCount = incrementChargeCount}