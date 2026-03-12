local util = require("openmw.util")
local core = require("openmw.core")
local types = require("openmw.types")
local world = require("openmw.world")

local cachedSettings = {
    MOD_ENABLED   = true,
    DEBUG_ENABLED = false,
}

local function isModEnabled()
    return cachedSettings.MOD_ENABLED
end

local function debugPrint(...)
    if cachedSettings.DEBUG_ENABLED then
        print(...)
    end
end

local lastBounty = -1
local crimeData = {}
local crimeId = 0
local apiver = core.API_REVISION
local fixedScript = false
local messageDelay = 0
local messageToDelay = nil
local deathDelay = 1.8

local function getPlayer()
    if apiver == 29 then
        for index, value in ipairs(world.activeActors) do
            if value.type == types.Player then
                return value
            end
        end
    end
    return world.players[1]
end

local function getCrimeLevel()
    if apiver == 29 then
        local npc = world.getCellByName("ZHAC_BountyCancel_Holding"):getAll(types.NPC)[1]
        return types.Actor.stats.attributes.agility(npc).base
    else
        if not fixedScript then
            local script = world.mwscript.getGlobalScript("ZHAC_CrimeCancel_GlobalScr")
            script.variables.monitorcrime = 1
            fixedScript = true
        end
        return types.Player.getCrimeLevel(getPlayer())
    end
end

local function getCrimeId()
    crimeId = crimeId + 1
    return crimeId
end

local function setCrimeLevel(number)
    if number < 0 then
        debugPrint("Attempted to set crime to " .. tostring(number))
        number = 0
    end

    if apiver == 29 then
        local crimeSetterObs = world.getCellByName("ZHAC_BountyCancel_Holding"):getAll(types.Activator)
        for index, value in ipairs(crimeSetterObs) do
            if value.recordId:lower() == "zhac_bountycancel_bridge_set" then
                local player = getPlayer()
                value:teleport(player.cell.name, util.vector3(player.position.x, player.position.y, number))
                return
            end
        end
    end
    local script = world.mwscript.getGlobalScript("ZHAC_CrimeCancel_GlobalScr")
    script.variables.crimeAmount = number
end

local function addCrimeLevel(number)
    if number < 0 then
        debugPrint("Attempted to add negative crime: " .. tostring(number))
        number = 0
    end
    setCrimeLevel(getCrimeLevel() + number)
end

local function getActorEnabled(actor)
    if apiver == 29 then
        return true
    else
        return actor.enabled
    end
end

local function getObjectID(obj)
    if apiver == 29 then
        return obj.recordId
    else
        return obj.id
    end
end

local function revokeCrime(crime)
end

local function reportCrime(amount, cell)
    local newCrimeData = {
        amount = amount,
        cell = cell.name,
        crimeId = getCrimeId(),
        witnesses = {},
        pendingWitnesses = 0,
        crimeTime = core.getGameTime()
    }
    for index, actor in ipairs(world.activeActors) do
        if actor.type ~= types.Player
            and actor.type ~= types.Creature
            and types.Actor.stats.dynamic.health(actor).current > 0
            and getActorEnabled(actor) == true
        then
            actor:sendEvent("checkCrimeWitness", newCrimeData.crimeId)
            table.insert(newCrimeData.witnesses, getObjectID(actor))
            newCrimeData.pendingWitnesses = newCrimeData.pendingWitnesses + 1
        end
    end
    if newCrimeData.pendingWitnesses == 0 then
        setCrimeLevel(getCrimeLevel() - amount)
        messageDelay = deathDelay
        messageToDelay = "Last witness killed. " .. tostring(amount) .. " bounty removed."
    else
        table.insert(crimeData, newCrimeData)
    end
end

local function NPCReportReturn(data)
    local npcId = data.npcId
    local isWitness = data.isWitness
    local crimeId = data.crimeId
    for index, value in ipairs(crimeData) do
        if value.crimeId == crimeId then
            value.pendingWitnesses = value.pendingWitnesses - 1
            if not isWitness then
                for indexx, wit in ipairs(value.witnesses) do
                    if wit == npcId then
                        table.remove(value.witnesses, indexx)
                        break
                    end
                end
            end
            if value.pendingWitnesses == 0 then
                debugPrint("All witnesses reported in for crime "
                    .. tostring(value.crimeId)
                    .. " that is worth " .. tostring(value.amount))
            end
        end
    end
end

local function WitnessDeath(id)
    local removeCrimes = {}
    local crimeRefund = 0
    for crimeIndex, crime in ipairs(crimeData) do
        for index, wit in ipairs(crime.witnesses) do
            if wit == id then
                table.remove(crime.witnesses, index)
                break
            end
        end
        if #crime.witnesses == 0 then
            revokeCrime(crime)
            crimeRefund = crimeRefund + crime.amount
            table.insert(removeCrimes, crimeIndex)
        end
    end

    local crimeCancelled = #removeCrimes > 0
    for index = #removeCrimes, 1, -1 do
        table.remove(crimeData, removeCrimes[index])
    end

    if crimeCancelled then
        debugPrint("All witnesses killed, refunding " .. tostring(crimeRefund))
        setCrimeLevel(getCrimeLevel() - crimeRefund)
        messageDelay = deathDelay
        messageToDelay = "Last witness killed. " .. tostring(crimeRefund) .. " bounty removed."
    end
end

local function onUpdate(dt)
    if not isModEnabled() then return end

    local currentBounty = getCrimeLevel()
    if lastBounty == -1 then
        lastBounty = currentBounty
        return
    end

    local removeCrimes = {}
    local playerCell = getPlayer().cell.name
    for index, value in ipairs(crimeData) do
        if value.cell ~= playerCell then
            table.insert(removeCrimes, index)
        end
    end
    for index = #removeCrimes, 1, -1 do
        table.remove(crimeData, removeCrimes[index])
    end

    if currentBounty > lastBounty and currentBounty > 0 then
        reportCrime(currentBounty - lastBounty, getPlayer().cell)
    end

    if messageToDelay then
        messageDelay = messageDelay - dt
        if messageDelay <= 0 then
            messageDelay = 0
            getPlayer():sendEvent("BC_ShowMessage", messageToDelay)
            messageToDelay = nil
        end
    end

    lastBounty = currentBounty
end

local function onLoad(data)
    if data then
        crimeData = data.crimeData
        crimeId = data.crimeId
        fixedScript = data.fixedScript
    end
end

local function onPlayerAdded(plr)
    lastBounty = getCrimeLevel()
end

local function onSave()
    return { crimeData = crimeData, crimeId = crimeId, fixedScript = fixedScript }
end

return {
    eventHandlers = {
        NPCReportReturn = NPCReportReturn,
        WitnessDeath = WitnessDeath,
        setCrimeLevel = setCrimeLevel,
        addCrimeLevel = addCrimeLevel,
        NWNB_SettingsUpdated = function(data)
            cachedSettings = data
        end,
    },
    engineHandlers = {
        onPlayerAdded = onPlayerAdded,
        onUpdate = onUpdate,
        onLoad = onLoad,
        onSave = onSave,
    }
}