local core    = require("openmw.core")
local self    = require("openmw.self")
local types   = require("openmw.types")
local nearby  = require("openmw.nearby")
local util    = require("openmw.util")
local storage = require("openmw.storage")
local async   = require("openmw.async")
local ui      = require("openmw.ui")
local I       = require("openmw.interfaces")

local shared                = require("scripts.necro_shared")
local EXEMPT_FACTIONS       = shared.EXEMPT_FACTIONS
local EXEMPT_NPCS           = shared.EXEMPT_NPCS
local FACTION_EXEMPT_SUMMONS = shared.FACTION_EXEMPT_SUMMONS
local WITNESS_MESSAGES      = shared.WITNESS_MESSAGES
local DEFAULTS              = shared.DEFAULTS

local section = storage.playerSection("SettingsNecro")

local VEC_FORWARD  = util.vector3(0, 1, 0)
local HEAD_OFFSET  = util.vector3(0, 0, 95)
local CHEST_OFFSET = util.vector3(0, 0, 60)
local COS_FOV      = math.cos(math.rad(80))

local function get(key)
    local val = section:get(key)
    if val == nil then return DEFAULTS[key] end
    return val
end

local cachedSettings = {
    MOD_ENABLED            = get("MOD_ENABLED"),
    FACTION_EXEMPT_ENABLED = get("FACTION_EXEMPT_ENABLED"),
    SNEAK_THRESHOLD        = get("SNEAK_THRESHOLD"),
    CHAMELEON_THRESHOLD    = get("CHAMELEON_THRESHOLD"),
    WITNESS_RADIUS         = get("WITNESS_RADIUS"),
    SIGN_COMPAT            = get("SIGN_COMPAT"),
}

section:subscribe(async:callback(function(_, key)
    if key then
        cachedSettings[key] = get(key)
    else
        for k in pairs(cachedSettings) do
            cachedSettings[k] = get(k)
        end
    end
end))


local function resolveIsSneaking()
    if cachedSettings.SIGN_COMPAT then
        local signIface = I.SneakIsGoodNow
        if signIface and signIface.playerState then
            return signIface.playerState.isSneaking == true
        end
        return false
    end
    return self.controls.sneak
end


local function isPlayerHidden()
    local player = self.object
    local eff    = types.Actor.activeEffects(player)
    local cham   = eff and eff:getEffect("chameleon")
    if cham and cham.magnitude and cham.magnitude >= cachedSettings.CHAMELEON_THRESHOLD then
        return true
    end
    if resolveIsSneaking() then
        if cachedSettings.SIGN_COMPAT then
            return true
        end
        local sneak = types.NPC.stats.skills.sneak(player).modified
        if sneak >= cachedSettings.SNEAK_THRESHOLD then return true end
    end
    
    return false
end

local function isExempt(actor)
    if EXEMPT_NPCS[actor.recordId:lower()] then return true end
    local stance = types.Actor.getStance(actor)
    if stance == 1 or stance == 2 then return true end
    local record = types.NPC.record(actor)
    if not record then return true end
    for _, factionId in pairs(types.NPC.getFactions(actor)) do
        if EXEMPT_FACTIONS[factionId:lower()] then return true end
    end
    return false
end

local function canSeePlayer(npc)
    local toPlayer = self.position - npc.position
    if toPlayer:length() > cachedSettings.WITNESS_RADIUS then return false end
    local npcForward = npc.rotation:apply(VEC_FORWARD)
    if npcForward:dot(toPlayer:normalize()) < COS_FOV then return false end
    local result = nearby.castRay(
        npc.position + HEAD_OFFSET,
        self.position + CHEST_OFFSET,
        { collisionType = 3, ignore = { npc } }
    )
    return not result.hit
end

local function isSummonExemptForPlayer(summonId)
    for factionId, exemptSummons in pairs(FACTION_EXEMPT_SUMMONS) do
        if exemptSummons[summonId] then
            local rank = types.NPC.getFactionRank(self.object, factionId)
            if rank and rank > 0 then
                return true
            end
        end
    end
    return false
end

local function checkWitnesses()
    if isPlayerHidden() then return end
    for _, actor in ipairs(nearby.actors) do
        if actor.type == types.NPC
           and not types.Actor.isDead(actor)
           and not isExempt(actor)
           and canSeePlayer(actor) then
            core.sendGlobalEvent("NecroCommitCrime", { player = self.object })
            ui.showMessage(WITNESS_MESSAGES[math.random(#WITNESS_MESSAGES)])
            return
        end
    end
end

return {
    eventHandlers = {
        NecroCheckWitness = function(data)
            if not cachedSettings.MOD_ENABLED then return end
            if data.summonId
               and cachedSettings.FACTION_EXEMPT_ENABLED
               and isSummonExemptForPlayer(data.summonId) then
                return
            end
            checkWitnesses()
        end,
    },
}