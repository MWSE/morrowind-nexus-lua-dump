local types = require('openmw.types')
local world = require('openmw.world')
local core = require('openmw.core')
local async = require('openmw.async')
local I = require('openmw.interfaces')
local crimes = require('openmw.interfaces').Crimes
local storage = require('openmw.storage')
local settings = storage.globalSection('SaneMagicSettingsGlobal')

local lctn = require('Scripts.SaneMagic.location')


local msg = core.l10n('SaneMagic', 'en')

local player = world.players[1]
local attributes = types.Actor.stats.attributes
local skills = types.NPC.stats.skills
local dynamic = types.Actor.stats.dynamic

local alredySummonCrime = false
local function checkNewSummon(data)
    alredySummonCrime = false
end
local function allowSummon(data)

    --mage 
    if lctn.isMage(data) then return true end

    --telvanni
    -- local telvanniRang = types.NPC.getFactionRank(player, "telvanni")
    -- if telvanniRang >= 1 and lctn.isTelvanni(data) then return true end
    if lctn.isTelvanni(data) then return true end

    --temple
    local tribunalTempleRang = types.NPC.getFactionRank(player, "temple")
    if lctn.isTemple(data) then 
        if tribunalTempleRang > 3 then 
            return true 
        else
            for _, npc in ipairs(data.npcs) do
                npc:sendEvent('StartAIPackage', {type='Combat', target=player})
            end    
        end
    end

    --final 

    return false
end
local function checkSummon(data)
    local summonEffects = {
        summonancestralghost = true,
        summonskeletalminion = true,
        summonbonewalker = true,
        summongreaterbonewalker = true,
        summonbonelord = true,
    }
    if world.isWorldPaused() then 
        return
    end

    local effects = types.Actor.activeEffects(player)
    local hasSummon = false
    for _, effect in pairs(effects) do
        if summonEffects[effect.id] then 
            hasSummon = true
            break
        end
    end

    if hasSummon then
        if not alredySummonCrime and not allowSummon(data) then
            local crimeLevel = types.Player.getCrimeLevel(player)
            crimes.commitCrime(player, {
                --arg = 400,
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
    for _ , npc in ipairs(data.list) do
        -- local bd = types.NPC.getBaseDisposition(npc, player)
        -- print(npc, bd, data.value)
        types.NPC.modifyBaseDisposition(npc, player, -data.value)
    end
    local callback = async:registerTimerCallback("restoreDisposition", function(data)
        for _, npc in ipairs(data.list) do
            types.NPC.modifyBaseDisposition(npc, player, data.value)
        end
    end)
    async:newSimulationTimer(data.duration, callback, data) --*core.getGameTimeScale()
end


local function punishSuspicious()
    crimes.commitCrime(player, {
        --arg = 200,
        type = player.type.OFFENSE_TYPE.Trespassing,
    })
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
        arg = 200,
        type = player.type.OFFENSE_TYPE.Theft,
        victim = data.victim,
        victimAware = true
    })
end

return {
    eventHandlers = {
        punishSuspicious = punishSuspicious,
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
