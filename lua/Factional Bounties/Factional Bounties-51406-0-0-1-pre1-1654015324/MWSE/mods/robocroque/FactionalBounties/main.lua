local config = require 'robocroque.factionalbounties.config'
local debug = require 'robocroque.factionalbounties.debug'
local bounties = require 'robocroque.factionalbounties.bounties'

if config.debugMode then
    require 'robocroque.factionalbounties.debugMenu'
end

-- HELPERS

local factions = {}

local lastReportedCrime = {
    time = nil,
    victimFaction = nil,
    crimeType = nil
}

local function getBountyForCrime(crimeType, crimeValue)
    local bounties = {
        ["attack"]     = function() return tes3.findGMST(tes3.gmst.iCrimeAttack).value                end,
        ["killing"]    = function() return tes3.findGMST(tes3.gmst.iCrimeKilling).value               end,
        ["pickpocket"] = function() return tes3.findGMST(tes3.gmst.iCrimePickPocket).value            end,
        ["trespass"]   = function() return tes3.findGMST(tes3.gmst.iCrimeTresspass).value             end,
        ["stealing"]   = function() return tes3.findGMST(tes3.gmst.fCrimeStealing).value * crimeValue end,
        ["theft"]      = function() return tes3.findGMST(tes3.gmst.fCrimeStealing).value * crimeValue end
    }

    return bounties[crimeType]()
end

local function crimeHasBeenReported(time, victimFaction, crimeType)
    return (lastReportedCrime.time == time and lastReportedCrime.victimFaction == victimFaction and lastReportedCrime.crimeType == crimeType)
end

local function translateToAffiliated(factionName)
    if (factions[factionName] ~= nil and factions[factionName].affiliatedFaction ~= nil) then
        debug('Faction %s is affiliated with %s, using the latter', factionName, factions[factionName].affiliatedFaction)
        return factions[factionName].affiliatedFaction
    end

    return faction
end

local function factionsAreAffiliated(factionA, factionB)
    debug('Checking affiliation for %s , %s', factionA, factionB)

    if (factionA == nil or factionB == nil) then
        return false
    end

    local a = translateToAffiliated(factionA.name)
    local b = translateToAffiliated(factionB.name)

    return (a == b)
end

local function factionTracksTheirOwnCrimes(factionName)
    if (factions[factionName] ~= nil and factions[factionName].tracksOwnCrimes ~= nil) then
        return factions[factionName].tracksOwnCrimes
    end

    return false
end

local function witnessFeelsResponsible(witnessMobile, crimeType)
    return witnessMobile.alarm >= config.minimumAlarmToReportCrime[crimeType]
end

local function witnessCaresAboutTheCrime(witnessMobile, witnessFaction, victimFaction, crimeType)
    -- TODO: If you're also in the same faction but have a higher rank than the witness, we might want to overlook some crimes...
    return (
        witnessFeelsResponsible(witnessMobile, crimeType) and
        factionsAreAffiliated(witnessFaction, victimFaction) and
        factionTracksTheirOwnCrimes(victimFaction.name)
    )
end

local function reportCrime(crimeType, victimFaction, value, time, position)
    -- Location seems to be the location of the witness, not where you committed the crime. As far as I can tell we could only go by
    -- victim faction, crime type, and time then.
    if (crimeHasBeenReported(time, victimFaction, crimeType)) then
        debug('Crime %s at %s on faction %s has already been reported, doing nothing', crimeType, time, victimFaction)
        return
    end

    lastReportedCrime.time = time
    lastReportedCrime.victimFaction = victimFaction
    lastReportedCrime.crimeType = crimeType


    local bounty = getBountyForCrime(crimeType, value)

    bounties.addBounty(victimFaction.name, bounty)
    debug('Crime %s, %s, %s reported, raised bounty with faction %s by %s (Total %s)', time, position, crimeType, victimFaction.name, bounty, bounties.getBounty(victimFaction.name))
end

-- INITIALIZATION

local function onInitialized()
    factions = require 'robocroque.factionalbounties.factions'
    require 'robocroque.factionalbounties.interop'
    require 'robocroque.factionalbounties.dialogue'
end
event.register(tes3.event.initialized, onInitialized)

local function onLoaded()
    -- for _, faction in ipairs(tes3.dataHandler.nonDynamicData.factions) do
    --     local factionInfo = factions[faction.name]
    --     debug('Faction %s', faction.name)
    --     if factionInfo ~= nil then
    --         debug('Got rules for faction %s:', faction.name)
    --         if factionInfo.tracksOwnCrimes ~= nil then
    --             debug('  tracksOwnCrimes: %s', factionInfo.tracksOwnCrimes)
    --         end
    --         if factionInfo.affiliatedFaction ~= nil then
    --             debug('  affiliatedFaction: %s', factionInfo.affiliatedFaction)
    --         end
    --     end
    -- end

    if tes3.player.data.factionBounties == nil then
        tes3.player.data.factionBounties = {}
    end
end
event.register(tes3.event.loaded, onLoaded)

-- EVENT HANDLERS

local function onCrimeWitnessed(e)
    debug('Crime witnessed!')
    debug('  Crime: %s', e.type)
    debug('  Victim: %s, Faction: %s', e.victim, e.victimFaction)
    debug('  Witness: %s, Faction: %s', e.witness, e.witness.object.faction)

    if e.witnessMobile.actorType ~= tes3.actorType.npc then
        debug('  But since the witness is no NPC they do not give a shit')
        debug('  witnessMobile actorType: %s', e.witnessMobile.actorType)
        return
    end

    if (e.type == 'werewolf') then
        -- That's not really a crime against a faction, more against nature
        return
    end

    if witnessCaresAboutTheCrime(e.witnessMobile, e.witness.object.faction, e.victimFaction, e.type) then
        reportCrime(e.type, e.victimFaction, e.value, e.realTimestamp, e.position)
        -- e.witnessMobile:kill()
    end
end
event.register(tes3.event.crimeWitnessed, onCrimeWitnessed)
