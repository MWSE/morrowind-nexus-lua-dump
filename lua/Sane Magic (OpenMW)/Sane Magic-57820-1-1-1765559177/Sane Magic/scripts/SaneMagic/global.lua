local types = require('openmw.types')
local world = require('openmw.world')
local core = require('openmw.core')
local async = require('openmw.async')
local I = require('openmw.interfaces')
local crimes = require('openmw.interfaces').Crimes
local storage = require('openmw.storage')
local settings = storage.globalSection('SaneMagicSettingsGlobal')

local msg = core.l10n('SaneMagic', 'en')

local player = world.players[1]
local attributes = types.Actor.stats.attributes
local skills = types.NPC.stats.skills
local dynamic = types.Actor.stats.dynamic


local function isSummon(effectId)
    local summonEffects = {
        summonancestralghost = true,
        summonskeletalminion = true,
        summonbonewalker = true,
        summongreaterbonewalker = true,
        summonbonelord = true,
    }

    return summonEffects[effectId] or false
end

local summonPlaceTemple = {
    ["#3 -13"] = true, -- Vivec Temple
    ["#3 -14"] = true, -- Vivec Temple
    ["#4 -13"] = true, -- Vivec Temple
    ["#4 -14"] = true, -- Vivec Temple
    ["ald-ruhn, temple"] = true,
    ["balmora, temple"] = true,
    ["ghostgate, temple"] = true,
    ["gnisis, temple"] = true,
    ["molag mar, temple"] = true,
    ["suran, suran temple"] = true,
    ["vivec, hlaalu temple"] = true,
    ["vivec, st. olms temple"] = true,
    ["vivec, telvanni temple"] = true
}

local summonPlace = {
    ["ald-ruhn, guild of mages"] = true,
    ["balmora, guild of mages"] = true,
    ["caldera, guild of mages"] = true,
    ["vivec, guild of mages"] = true,
    ["sadrith mora, wolverine hall"] = true,
    ["#15 1"] = true, -- Tel Fyr
    ["tower of tel fyr, hall of fyr"] = true, -- Tel Fyr
    ["tower of tel fyr, onyx hall"] = true, -- Tel Fyr
    ["gnisis, arvs-drelen"] = true,
}


local summonPrefix = {
"Sadrith Mora",
"Tel Mora",
"Tel Vos",
"Tel Aruhn",
"Tel Uvirith",
"Tel Branora",
"Vivec, Telvanni",
}

local function startsWith(str, prefix)
    return string.sub(str, 1, #prefix) == prefix
end
local function isSummonLocation(data)
    for _, prefix in ipairs(summonPrefix) do
        if startsWith(data.cellName, prefix) then return true end
    end

    local tribunalTempleRange = types.NPC.getFactionRank(player, "temple")
    if summonPlaceTemple[data.cellId] and tribunalTempleRange > 3 then
        return true
    end
    if summonPlace[data.cellId] then
        return true
    end

    return false
end

local alredySummonCrime = false
local function checkNewSummon(data)
    alredySummonCrime = false
end

local function checkSummon(data)
    if world.isWorldPaused() then 
        return
    end

    local effects = types.Actor.activeEffects(data.actor)
    local hasSummon = false
    
    for effectId, effect in pairs(effects) do
        if isSummon(effect.id) then 
            hasSummon = true
            break
        end
    end

    if hasSummon then
        if not alredySummonCrime and not isSummonLocation(data) then
            local crimeLevel = types.Player.getCrimeLevel(player)
            crimes.commitCrime(data.actor, {
                --arg = 80,
                type = player.type.OFFENSE_TYPE.Assault,
            })
            if crimeLevel < types.Player.getCrimeLevel(player) then
                alredySummonCrime = true
            end
        end
    else
        alredySummonCrime = false
    end
end


local function loseDisposition(data)
    for _, npc in ipairs(data.list) do
        types.NPC.modifyBaseDisposition(npc, player, -data.value)
    end
    local callback = async:registerTimerCallback("restoreDisposition", function(data)
        for _, npc in ipairs(data.list) do
            types.NPC.modifyBaseDisposition(npc, player, data.value)
        end
    end)
    async:newGameTimer(data.duration, callback, data) --*core.getGameTimeScale()
end

local function punishFrenzy(data)
    crimes.commitCrime(player, {
        --arg = crimesCost,
        type = player.type.OFFENSE_TYPE.Assault,
        victim = data.victim,
        victimAware = true
    })
end
local function punishCharm(data)
    crimes.commitCrime(player, {
        arg = 50,
        type = player.type.OFFENSE_TYPE.Theft,
        victim = data.victim,
        victimAware = true
    })
end

return {

    eventHandlers = {
        punishFrenzy = punishFrenzy,
        punishCharm = punishCharm,
        checkSummon = checkSummon,
        checkNewSummon = checkNewSummon,
        loseDisposition=loseDisposition,

        SaneMagicSettings = function(data)
            settings:set("smCharm", data.smCharm)
            settings:set("smFrenzyCrime", data.smFrenzyCrime)
        end
    }

}
