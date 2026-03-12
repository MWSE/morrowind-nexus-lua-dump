local core    = require("openmw.core")
local self    = require("openmw.self")
local types   = require("openmw.types")
local nearby  = require("openmw.nearby")
local util    = require("openmw.util")
local ui      = require("openmw.ui")
local storage = require("openmw.storage")
local async   = require("openmw.async")

local shared          = require("scripts.gshared")
local EXEMPT_CLASSES  = shared.EXEMPT_CLASSES
local EXEMPT_NPCS     = shared.EXEMPT_NPCS
local KHAJIIT_RACE    = shared.KHAJIIT_RACE
local EXEMPT_FACTIONS = shared.EXEMPT_FACTIONS
local NARCOTIC        = shared.NARCOTIC
local CONTRABAND      = shared.CONTRABAND
local GOLD_IDS        = shared.GOLD_IDS
local DEFAULTS        = shared.DEFAULTS
local EXEMPT_CELLS    = shared.EXEMPT_CELLS
local EXEMPT_NPCS_FULL = shared.EXEMPT_NPCS_FULL

local section       = storage.playerSection("SettingsGreedyNPCs")
local sectionValues = storage.playerSection("SettingsGreedyNPCsValues")

local VEC_FORWARD  = util.vector3(0, 1, 0)
local HEAD_OFFSET  = util.vector3(0, 0, 95)
local CHEST_OFFSET = util.vector3(0, 0, 60)
local COS_FOV      = math.cos(math.rad(80))

local snapA = {}
local snapB = {}
local currentSnap  = snapA
local prevSnap     = snapB

local loadCooldown     = 0
local playerIsSneaking = false
local settingsDirty    = false
local cachedCellName   = nil
local cachedCellExempt = false

local function get(key)
    local val = section:get(key)
    if val ~= nil then return val end
    val = sectionValues:get(key)
    if val ~= nil then return val end
    return DEFAULTS[key]
end

local cachedSettings = {
    PICKUP_RADIUS       = get("PICKUP_RADIUS"),
    CONTRABAND_RADIUS   = get("CONTRABAND_RADIUS"),
    PICKUP_DELAY        = get("PICKUP_DELAY"),
    PICKUP_ENABLED      = get("PICKUP_ENABLED"),
    CRIME_ENABLED       = get("CRIME_ENABLED"),
    CHAMELEON_THRESHOLD = get("CHAMELEON_THRESHOLD"),
    SNEAK_THRESHOLD     = get("SNEAK_THRESHOLD"),
    MIN_APPARATUS       = get("MIN_APPARATUS"),
    MIN_BOOK            = get("MIN_BOOK"),
    MIN_CLOTHING        = get("MIN_CLOTHING"),
    MIN_ARMOR           = get("MIN_ARMOR"),
    MIN_WEAPON          = get("MIN_WEAPON"),
    MIN_INGREDIENT      = get("MIN_INGREDIENT"),
    MIN_POTION          = get("MIN_POTION"),
    MIN_LOCKPICK        = get("MIN_LOCKPICK"),
    MIN_PROBE           = get("MIN_PROBE"),
    MIN_REPAIR          = get("MIN_REPAIR"),
    MIN_MISC            = get("MIN_MISC"),
    RANK_EXEMPT_ENABLED = get("RANK_EXEMPT_ENABLED"),
    RANK_EXEMPT_DIFF    = get("RANK_EXEMPT_DIFF"),
}

local function broadcastSettings()
    core.sendGlobalEvent("GreedyNPCs_SettingsUpdated", {
        PICKUP_RADIUS   = cachedSettings.PICKUP_RADIUS,
        PICKUP_DELAY    = cachedSettings.PICKUP_DELAY,
        PICKUP_ENABLED  = cachedSettings.PICKUP_ENABLED,
        MIN_APPARATUS   = cachedSettings.MIN_APPARATUS,
        MIN_BOOK        = cachedSettings.MIN_BOOK,
        MIN_CLOTHING    = cachedSettings.MIN_CLOTHING,
        MIN_ARMOR       = cachedSettings.MIN_ARMOR,
        MIN_WEAPON      = cachedSettings.MIN_WEAPON,
        MIN_INGREDIENT  = cachedSettings.MIN_INGREDIENT,
        MIN_POTION      = cachedSettings.MIN_POTION,
        MIN_LOCKPICK    = cachedSettings.MIN_LOCKPICK,
        MIN_PROBE       = cachedSettings.MIN_PROBE,
        MIN_REPAIR      = cachedSettings.MIN_REPAIR,
        MIN_MISC        = cachedSettings.MIN_MISC,
        RANK_EXEMPT_ENABLED = cachedSettings.RANK_EXEMPT_ENABLED,
        RANK_EXEMPT_DIFF    = cachedSettings.RANK_EXEMPT_DIFF,
    })
end

local function refreshCache()
    for k in pairs(cachedSettings) do
        cachedSettings[k] = get(k)
    end
    broadcastSettings()
end

section:subscribe(async:callback(function()
    settingsDirty = true
end))

sectionValues:subscribe(async:callback(function()
    settingsDirty = true
end))

local function fillSnapshot(t)
    for k in pairs(t) do t[k] = nil end
    local inv = types.Actor.inventory(self)
    if not inv then return end
    for _, item in ipairs(inv:getAll()) do
        t[item.recordId] = (t[item.recordId] or 0) + item.count
    end
end

local function swapAndFill()
    if currentSnap == snapA then
        currentSnap = snapB
        prevSnap    = snapA
    else
        currentSnap = snapA
        prevSnap    = snapB
    end
    fillSnapshot(currentSnap)
end

local function isOutrankedByPlayer(actor)
    if not cachedSettings.RANK_EXEMPT_ENABLED then return false end
    local playerObj = self.object
    for _, factionId in pairs(types.NPC.getFactions(actor)) do
        local npcRank    = types.NPC.getFactionRank(actor, factionId)
        local playerRank = types.NPC.getFactionRank(playerObj, factionId)
        if playerRank > 0 and npcRank > 0 then
            if playerRank >= 9 or (playerRank - npcRank) >= cachedSettings.RANK_EXEMPT_DIFF then
                return true
            end
        end
    end
    return false
end

local function isInCombat(actor)
    local stance = types.Actor.getStance(actor)
    return stance == 1 or stance == 2
end

local function isPlayerHidden()
    local player = self.object
    local eff    = types.Actor.activeEffects(player)
    local cham   = eff and eff:getEffect("chameleon")
    local sneak  = types.NPC.stats.skills.sneak(player).modified
    if (cham and cham.magnitude and cham.magnitude >= cachedSettings.CHAMELEON_THRESHOLD) or
       (playerIsSneaking and sneak >= cachedSettings.SNEAK_THRESHOLD) then
        return true
    end
    return false
end

local function canSeePlayer(npc, radius)
    local toPlayer = self.position - npc.position
    local len = toPlayer:length()
    if len == 0 then return true end
    if len > radius then return false end
    local npcForward = npc.rotation:apply(VEC_FORWARD)
    if npcForward:dot(toPlayer / len) < COS_FOV then return false end
    local result = nearby.castRay(
        npc.position + HEAD_OFFSET,
        self.position + CHEST_OFFSET,
        { collisionType = 3, ignore = { npc } }
    )
    return not result.hit
end

local function isExemptFromCrime(actor)
    local stance = types.Actor.getStance(actor)
    if stance == 1 or stance == 2 then return true end
    local record = types.NPC.record(actor)
    if not record then return true end
    local recordId = actor.recordId:lower()
    if EXEMPT_NPCS_FULL[recordId] then return true end
    if EXEMPT_NPCS[recordId] then return true end
    if isOutrankedByPlayer(actor) then return true end
    if record.class and EXEMPT_CLASSES[record.class:lower()] then return true end
    for _, factionId in pairs(types.NPC.getFactions(actor)) do
        if EXEMPT_FACTIONS[factionId:lower()] then return true end
    end
    return false
end

local function wantsItem(actor, narcotic, contraband, pauperContraband)
    if isInCombat(actor) then return false end
    local record = types.NPC.record(actor)
    if not record then return false end
    if EXEMPT_NPCS_FULL[actor.recordId:lower()] then return false end
    if isOutrankedByPlayer(actor) then return false end
    local isPauper  = record.class and EXEMPT_CLASSES[record.class:lower()]
    local isKhajiit = record.race  and KHAJIIT_RACE[record.race:lower()]
    if isPauper then
        if contraband then return pauperContraband end
        return true
    end
    if isKhajiit then
        return not contraband
    end
    if narcotic or contraband then return false end
    return true
end

local function checkCrime(narcotic)
    if isPlayerHidden() then return end
    for _, actor in ipairs(nearby.actors) do
        if actor.type == types.NPC
           and not types.Actor.isDead(actor)
           and not isExemptFromCrime(actor)
           and canSeePlayer(actor, cachedSettings.CONTRABAND_RADIUS) then
            local record    = types.NPC.record(actor)
            local isKhajiit = record and record.race and KHAJIIT_RACE[record.race:lower()]
            if not (narcotic and isKhajiit) then
                core.sendGlobalEvent("ContrabandCrime", { player = self.object })
                return
            end
        end
    end
end

local function findPickupNPC(itemPos, narcotic, contraband, pauperContraband)
    local best     = nil
    local bestDist = math.huge
    for _, actor in ipairs(nearby.actors) do
        if actor ~= self.object
           and types.NPC.objectIsInstance(actor)
           and not types.Actor.isDead(actor)
           and wantsItem(actor, narcotic, contraband, pauperContraband)
           and canSeePlayer(actor, cachedSettings.PICKUP_RADIUS) then
            local dist = (actor.position - itemPos):length()
            if dist <= cachedSettings.PICKUP_RADIUS and dist < bestDist then
                bestDist = dist
                best     = actor
            end
        end
    end
    return best
end

local function updateCellCache()
    local cell = self.cell
    if not cell then
        cachedCellExempt = false
        return
    end
    local name = cell.name
    if name ~= cachedCellName then
        cachedCellName   = name
        cachedCellExempt = EXEMPT_CELLS[name:lower()] == true
    end
end

return {
    engineHandlers = {
        onInit = function()
            fillSnapshot(currentSnap)
            updateCellCache()
            loadCooldown = 3
            broadcastSettings()
        end,

        onLoad = function()
            fillSnapshot(currentSnap)
            updateCellCache()
            loadCooldown = 3
            broadcastSettings()
        end,

        onFrame = function(dt)
    
            if settingsDirty then
                settingsDirty = false
                refreshCache()
            end

            updateCellCache()
            if cachedCellExempt then return end

            if loadCooldown > 0 then
                loadCooldown = loadCooldown - 1
                fillSnapshot(currentSnap)
                return
            end

            swapAndFill()

            for id, prevCount in pairs(prevSnap) do
                local newCount = currentSnap[id] or 0
                if newCount < prevCount then
                    if cachedSettings.PICKUP_ENABLED then
                        if GOLD_IDS[id] then
                            core.sendGlobalEvent("NpcPickupRegisterBatch", { ids = GOLD_IDS })
                        else
                            core.sendGlobalEvent("NpcPickupRegister", { recordId = id })
                        end
                    end
                    if cachedSettings.CRIME_ENABLED then
                        if CONTRABAND[id] or NARCOTIC[id] then
                            checkCrime(NARCOTIC[id] or false)
                        end
                    end
                end
            end
        end,
    },

    eventHandlers = {
        NpcPickupCheck = function(data)
            if cachedCellExempt then return end
            if not cachedSettings.PICKUP_ENABLED then return end
            local item             = data.item
            local narcotic         = data.narcotic         or false
            local contraband       = data.contraband       or false
            local pauperContraband = data.pauperContraband or false
            if not item or not item:isValid() then return end
            if (item.position - self.position):length() > cachedSettings.PICKUP_RADIUS then return end
            if isPlayerHidden() then return end
            if isInCombat(self) then return end
            local npc = findPickupNPC(item.position, narcotic, contraband, pauperContraband)
            if not npc then return end
            core.sendGlobalEvent("NpcPickupItem", { item = item, npc = npc })
        end,

        NpcPickupMessage = function(data)
            if data and data.message then
                ui.showMessage(data.message)
            end
        end,

        PlayerSneakChanged = function(data)
            playerIsSneaking = data.sneaking
        end,
    },
}