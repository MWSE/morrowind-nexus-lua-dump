local isOpenMW, I = pcall(require, "openmw.interfaces")

local _, util = pcall(require, "openmw.util")
local _, core = pcall(require, "openmw.core")
local _, types = pcall(require, "openmw.types")
local _, storage = pcall(require, "openmw.storage")
local _, world = pcall(require, "openmw.world")
local _, async = pcall(require, "openmw.async")
local constant
if isOpenMW then
    constant = require("mwse.mods.CoinFlip.constant")
    if core and core.API_REVISION < 55 then
        I.Settings.registerPage {
            key = "SettingsCoinFlip",
            l10n = "SettingsTLF",
            name = "The Lucky Fellow",
            description = "Your OpenMW version is out of date. Please download a version of 0.49 from April 2024 or newer."
        }
        return {}
    end
else
    constant = require("CoinFlip.constant")
end
local timeDelay = 0.01
local useMountMenu = true
local coinObj
local coinDistance = 0
local coinRot = 0
local coinAscent = true
local waitForPickup = false
local coinOriginZPos
local player
local data = {}
math.randomseed(os.time())


local function getPosition(x, y, z)
    if isOpenMW then
        return util.vector3(x, y, z)
    else
        return tes3vector3.new(x, y, z)
    end
end
local function getValue(id)
    if isOpenMW then
        return data[id]
    else
        if not tes3.player.data.coinFlip then
            tes3.player.data.coinFlip = {}
        end
        return tes3.player.data.coinFlip[id]
    end
end
local function setValue(id,value)
    if isOpenMW then
         data[id] = value
    else
        if not tes3.player.data.coinFlip then
            tes3.player.data.coinFlip = {}
        end
         tes3.player.data.coinFlip[id] = value
    end
end
local function getItemRecordId(obj)
    if isOpenMW then
        return obj.recordId
    else
        return obj.baseObject.id:lower()
    end
end
local function playSound(id)
    if isOpenMW then
        player:sendEvent("CF_PlaySound")
    else
        tes3.playSound({ sound = id })
    end
end
local function showPlayerMessage(msg)
    if isOpenMW then
        player:sendEvent("CF_ShowMessage", msg)
    else
        tes3.messageBox(msg)
    end
end
local function moveIntoInv(item)
    if isOpenMW then
        playSound("item misc up")
        item:moveInto(player)
    else
        local id = item.object.id

        item:delete()
        tes3.addItem({ reference = tes3.player, item = id, count = 1 })
    end
end
local function gameIsPaused()
    if isOpenMW then
    else
        return tes3.menuMode()
    end
end
local function addSpellEffects(id)
    if isOpenMW then
        --play sound
        types.Actor.activeSpells(player):add({ id = id, effects = { 0 }, ignoreResistances = true, ignoreSpellAbsorption = true, ignoreReflect = true, stackable = true, })
    else
        tes3.applyMagicSource { reference = tes3.player, source = id, bypassResistances = true }
    end
end
local function addUnluckyEffects(id)
    playSound("destruction hit")
    if isOpenMW then
        addSpellEffects(constant.unLuckySpellId)
    else
        local timescale = tes3.worldController.timescale.value
        tes3.applyMagicSource({
            reference = tes3.player,
            bypassResistances = true,
            name = constant.unluckySpellName,
            effects = {
                {
                    id = tes3.effect["drainAttribute"],
                    attribute = tes3.attribute.luck,
                    min = constant.luckModifier,
                    max = constant.luckModifier,
                    duration = (constant.hoursToApply / timescale) * 60 * 60,
                },
            },
        })
    end
end
local function addLuckyEffects(id)
    playSound("restoration hit")
    if isOpenMW then
        addSpellEffects(constant.luckySpellId)
    else
        local timescale = tes3.worldController.timescale.value
        tes3.applyMagicSource({
            reference = tes3.player,
            bypassResistances = true,
            name = constant.luckySpellName,
            effects = {
                {
                    id = tes3.effect["fortifyAttribute"],
                    attribute = tes3.attribute.luck,
                    min = constant.luckModifier,
                    max = constant.luckModifier,
                    duration = (constant.hoursToApply / timescale) * 60 * 60,
                },
            },
        })
    end
end
local function runWithDelay(delay, func)
    if isOpenMW then
        async:newUnsavableSimulationTimer(delay, func)
    else
        timer.start({ duration = delay, callback = func })
    end
end
local function getPlayerLuck()
    if isOpenMW then
        return types.Actor.stats.attributes.luck(player).modified
    else
        return tes3.mobilePlayer.luck.current
    end
end
local function coinFlipChance()
    local val = getValue("coinFlipChance")
    if not val then
         val = constant.startingChance
    end
    setValue("coinFlipChance", val - constant.chanceIncrement)
    print("chance is " .. tostring(val))
    return val --getPlayerLuck() * 0.01
end
local function getRotation(x, y, z)
    --TODO: account for z rotation so it faces the player still
    if isOpenMW then
        local rot = util.transform.rotateY(y)
        return rot
    else
        return tes3vector3.new(x, (y), z)
    end
end
local function teleportObject(object, cell, position, rotation)
    if isOpenMW then
        object:teleport(cell, position, rotation)
    else
        tes3.positionCell({ reference = object, cell = cell, position = position, orientation = rotation })
    end
end
local function randomBool()
    if math.random() < coinFlipChance() * 0.01 then
        return true
    else
        return false
    end
end

local function incrementAmount()
    local input = coinDistance
    local a = 1    -- Start value
    local b = 0.1  -- End value
    local min = 0  -- Minimum input value
    local max = 50 -- Maximum input value

    -- Ensure the input is within the expected range
    input = math.max(min, math.min(max, input))

    -- Adjusted interpolation formula
    local result = a + (b - a) * ((input - min) / (max - min))

    return result * 3
end
local function teleportCoin()
    local newZPos = coinOriginZPos + coinDistance

    local newRot = getRotation(0, math.rad(coinRot), 0)
    if coinDistance <= 0 and not coinAscent then
        newZPos = coinOriginZPos
        newRot = getRotation(0, math.rad(0), 0)
        if randomBool() then
            newRot = getRotation(0, math.rad(180), 0)
            --newZPos = coinOriginZPos + 0.1111
            --showPlayerMessage("Heads, you are lucky!")
            addLuckyEffects()
            waitForPickup = true
            runWithDelay(constant.pickUpDelay, function()
                if waitForPickup then
                moveIntoInv(coinObj)
                waitForPickup = false
                end
            end)
        else
            addUnluckyEffects()
            waitForPickup = true
            runWithDelay(constant.pickUpDelay, function()
                if waitForPickup then
                moveIntoInv(coinObj)
                waitForPickup = false
                end
            end)
        end
        --return
    end
    teleportObject(coinObj, coinObj.cell, getPosition(coinObj.position.x, coinObj.position.y, newZPos), newRot)
end
local function coinUpdate()
    if coinAscent then
        coinDistance = coinDistance + incrementAmount()
        if coinDistance > 50 then
            coinAscent = false
        end
    else
        coinDistance = coinDistance - incrementAmount()
    end
    coinRot = coinRot + 10
    teleportCoin()
    if coinDistance <= 0 and not coinAscent then
        return
    end
    runWithDelay(timeDelay, function()
        coinUpdate()
    end)
end
local function activateCoin(coin, player)
    if gameIsPaused() then
        return
    end
    if getItemRecordId(coin) == constant.coinId then
        if waitForPickup then
            waitForPickup = false
        end
        coinOriginZPos = coin.position.z
        coinDistance = 0
        coinRot = 0
        coinAscent = true
        coinObj = coin
        runWithDelay(timeDelay, function()
            coinUpdate()
        end)
        return false
    end
end
local function activateMWSE(e)
    return activateCoin(e.target)
end
if isOpenMW then
    I.Activation.addHandlerForType(types.Miscellaneous, activateCoin)
else
    event.register(tes3.event.activate, activateMWSE)
    return {
    }
end
return {
    engineHandlers = {
        onPlayerAdded = function(p)
            player = p
        end,
        onSave = function ()
            return {data = data}
        end,
        onLoad = function (data)
            if data then
                data = data.data
            end
        end
    },
    eventHandlers = {
        CF_SetPlayer = function(plr)
            player = plr
        end,
    }
}
