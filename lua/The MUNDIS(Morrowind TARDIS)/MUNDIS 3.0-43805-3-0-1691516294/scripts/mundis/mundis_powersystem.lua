local util = require("openmw.util")
local world = require("openmw.world")
local types = require("openmw.types")
local core = require("openmw.core")
local storage = require("openmw.storage")
local interfaces = require("openmw.interfaces")
local myModData = storage.globalSection('MundisData')
local LocIndex = 0

local powerData = { soulBank = 0, chargeSize = 100 }

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
local function onLoad(data)
    if data then
        powerData = data.powerData
    end
    setMundisPowerState(powerData.soulBank > 0)
end
local function onPlayerAdded(player)
    setMundisPowerState(powerData.soulBank > 0)
end
local function onSave()
    return { powerData = powerData }
end
local function depositSouls()
    if core.API_REVISION == 29 then return end
    local soulsDeposit = 0
    local addedSoulValue = 0
    for index, item in ipairs(types.Actor.inventory(world.players[1]):getAll(types.Miscellaneous)) do
        local soul = types.Miscellaneous.getSoul(item)

        if soul and soul ~= "" then
            local soulSize = types.Creature.record(soul).soulValue * item.count
            soulsDeposit = soulsDeposit + item.count
            if soulSize > 0 then
                addedSoulValue = addedSoulValue + soulSize
            end
            if item.recordId ~= "misc_soulgem_azura" then
                item:remove()
            else
                world.createObject(item.recordId, item.count):moveInto(types.Actor.inventory(world.players[1]))
                item:remove()
            end
        end
    end
    if addedSoulValue > 0 then
        world.players[1]:sendEvent("showMessageMundis",
            string.format("You deposit %d souls, worth %d charges", soulsDeposit,
                math.floor(addedSoulValue / powerData.chargeSize)))
    else
        world.players[1]:sendEvent("showMessageMundis", string.format("You are carrying no usable soul gems."))
    end
    powerData.soulBank = powerData.soulBank + addedSoulValue

    setMundisPowerState(powerData.soulBank > 0)
end
local function getChargeCount()
    
if core.API_REVISION == 29 then 
    return 10
    end
    return math.floor(powerData.soulBank / powerData.chargeSize)
end
local function incrementChargeCount(count)
    powerData.soulBank = powerData.soulBank + (count * powerData.chargeSize)
    setMundisPowerState(powerData.soulBank > 0)
end
local function onActivate(object, actor)
    if object.recordId == "mundis_power_inquire" then
        if core.API_REVISION == 29 then
            world.players[1]:sendEvent("showMessageMundis",
                string.format("The MUNDIS currently has unlimited charges remaining."))
            return
        end
        world.players[1]:sendEvent("showMessageMundis",
            string.format("The MUNDIS currently has %d charges remaining.",
                math.floor(powerData.soulBank / powerData.chargeSize)))
    elseif object.recordId == "mundis_power_deposit" then
        depositSouls()
    elseif object.recordId == "mundis_summonscroll" and core.API_REVISION > 29 then
        types.Actor.spells(world.players[1]):add("aa_summonspell")
      --  world.players[1]:sendEvent("showMessageMundis",
     --       string.format("You read the scroll, and learn the spell to summon the MUNDIS."))
    end
end
return {
    interfaceName = "MundisPowerSystem",
    interface = {
        version = 1,
        getLocIndex = getLocIndex,
        setCheatState = setCheatState,
        depositSouls = depositSouls,
        getChargeCount = getChargeCount,
        incrementChargeCount = incrementChargeCount
    },
    eventHandlers = {
        teleportMundis = teleportMundis,
        setNextDest = setNextDest,
        exitMundisFunc = exitMundisFunc,
        checkButtonText = checkButtonText,
        MUNDISInit = MUNDISInit,
        startTPTimer = startTPTimer,
    },
    engineHandlers = {
        onSave = onSave,
        onLoad = onLoad,
        onInit = onPlayerAdded,
        onObjectActive = onObjectActive,
        onActivate = onActivate,
        onPlayerAdded = onPlayerAdded,
    }
}
