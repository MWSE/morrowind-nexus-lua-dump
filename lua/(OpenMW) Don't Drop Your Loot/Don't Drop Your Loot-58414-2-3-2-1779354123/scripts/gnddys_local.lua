local self    = require("openmw.self")
local types   = require("openmw.types")
local core    = require("openmw.core")
local async   = require("openmw.async")
local nearby  = require("openmw.nearby")
local anim    = require("openmw.animation")
local I       = require("openmw.interfaces")

local shared       = require("scripts.gshared")
local DEFAULTS     = shared.DEFAULTS
local KHAJIIT_RACE = shared.KHAJIIT_RACE
local GOLD_IDS     = shared.GOLD_IDS

local messages = require("scripts.gnddys_messages")

-- AI packages that block all greedy behavior
local BUSY_PACKAGES = {
    Combat = true,
    Pursue = true,
}

-- AI packages that block greedy behavior only when ESCORT_FOLLOW_BUSY is on
local CUST_PACKAGES = {
    Escort = true,
    Follow = true,
}

local LURE_ITEM_DIST       = 60
local LURE_HOME_DIST       = 5
local LURE_TICK            = 0.3
local PICKUP_ANIM_DURATION = 2
local PICKUP_LOW_THRESHOLD = 0.2

local STUCK_DISPLACEMENT    = 6
local STUCK_TICKS_THRESHOLD = 2    -- ~0.6s of no movement before reacting
local JUMP_ATTEMPTS         = 2    -- number of jumps before giving up
local JUMP_RETRY_DELAY      = 1    -- seconds between retries


-- These are the keys broadcast to NPCs by the player script
local NPC_SETTING_KEYS = {
    "PICKUP_ENABLED",
    "CRIME_ENABLED",
    "EQUIP_ARMOR",
    "LURE_PICKUP_DELAY",
    "LURE_RETURN_DELAY",
    "LURE_LINGER_DELAY",
    "SHOW_PICKUP_MESSAGES",
    "SHOW_HEAVY_MESSAGES",
    "ESCORT_FOLLOW_BUSY",
    "JUMP_WHEN_STUCK",
}

local cfg = {}
for _, k in ipairs(NPC_SETTING_KEYS) do
    cfg[k] = DEFAULTS[k]
end


-- lure: nil | { item, itemPos, homePos, savedWander, phase }
-- phase: 'walking' | 'pickup_wait' | 'picked_up' | 'linger_wait' | 'returning'
local lure            = nil
local lureTickRunning = false

local startLureTick
local playPickupAnimation
local lureTick

local function isKhajiit()
    local record = types.NPC.record(self.object)
    return (record and record.race and KHAJIIT_RACE[record.race:lower()]) or false
end

local function npcName()
    local record = types.NPC.record(self.object)
    return record and record.name or "Someone"
end

local function findPlayer()
    for _, a in ipairs(nearby.players) do return a end
    return nil
end

local function showNpcMessage(msgs, khajiitMsgs)
    local player = findPlayer()
    if not player then return end
    local pool = isKhajiit() and khajiitMsgs or msgs
    local msg  = pool[math.random(#pool)]
    player:sendEvent("NpcPickupMessage", {
        message = npcName() .. ": \"" .. msg .. "\"",
    })
end


local function isBusy()
    local pkg     = I.AI.getActivePackage(self.object)
    local pkgType = pkg and pkg.type or "none"
    if BUSY_PACKAGES[pkgType] then return true end
    if cfg.ESCORT_FOLLOW_BUSY and CUST_PACKAGES[pkgType] then return true end
    return false
end


-- Save all Wander packages from the NPC's AI stack
local function saveWander()
    local saved = {}
    I.AI.forEachPackage(function(pkg)
        if pkg.type == "Wander" then
            saved[#saved + 1] = {
                type         = "Wander",
                distance     = pkg.distance,
                duration     = pkg.duration * 3600,
                idle         = pkg.idle,
                isRepeat     = pkg.isRepeat,
                destPosition = pkg.destPosition,
            }
        end
    end)
    if #saved == 0 then return nil end
    return saved
end

local function restoreWander(saved)
    if not saved then return end
    for _, pkg in ipairs(saved) do
        I.AI.startPackage({
            type         = "Wander",
            distance     = pkg.distance,
            duration     = pkg.duration,
            idle         = pkg.idle,
            isRepeat     = pkg.isRepeat,
            destPosition = pkg.destPosition,
            cancelOther  = false,
        })
    end
end

-- Remove all Wander packages so a new Travel starts immediately
local function removeWander()
    I.AI.filterPackages(function(p)
        return p.type ~= "Wander"
    end)
end

-- Map item types to their record accessors. Unlisted types report 0 weight
local WEIGHT_RECORD_FOR = {
    [types.Weapon]        = types.Weapon.record,
    [types.Armor]         = types.Armor.record,
    [types.Clothing]      = types.Clothing.record,
    [types.Book]          = types.Book.record,
    [types.Ingredient]    = types.Ingredient.record,
    [types.Potion]        = types.Potion.record,
    [types.Apparatus]     = types.Apparatus.record,
    [types.Lockpick]      = types.Lockpick.record,
    [types.Probe]         = types.Probe.record,
    [types.Repair]        = types.Repair.record,
    [types.Miscellaneous] = types.Miscellaneous.record,
}

local function getItemWeight(item)
    for itemType, recordFn in pairs(WEIGHT_RECORD_FOR) do
        if itemType.objectIsInstance(item) then
            local rec = recordFn(item)
            return rec and rec.weight or 0
        end
    end
    return 0
end

-- Returns (canCarryAll, maxThatFits)
local function canCarryItem(item)
    local itemWeight = getItemWeight(item)
    local count      = item.count or 1
    local stackWeight = itemWeight * count

    if stackWeight <= 0 then
        return true, count
    end

    local capacity    = types.Actor.getCapacity(self.object)
    local encumbrance = types.Actor.getEncumbrance(self.object)
    local freeSpace   = capacity - encumbrance

    if freeSpace <= 0 then
        return false, 0
    end

    local canFit = math.floor(freeSpace / itemWeight)
    if canFit >= count then return true, count end
    return false, canFit
end

local ARMOR_TYPE_SLOT = {
    [types.Armor.TYPE.Helmet]    = types.Actor.EQUIPMENT_SLOT.Helmet,
    [types.Armor.TYPE.Cuirass]   = types.Actor.EQUIPMENT_SLOT.Cuirass,
    [types.Armor.TYPE.LPauldron] = types.Actor.EQUIPMENT_SLOT.LeftPauldron,
    [types.Armor.TYPE.RPauldron] = types.Actor.EQUIPMENT_SLOT.RightPauldron,
    [types.Armor.TYPE.Greaves]   = types.Actor.EQUIPMENT_SLOT.Greaves,
    [types.Armor.TYPE.Boots]     = types.Actor.EQUIPMENT_SLOT.Boots,
    [types.Armor.TYPE.LGauntlet] = types.Actor.EQUIPMENT_SLOT.LeftGauntlet,
    [types.Armor.TYPE.RGauntlet] = types.Actor.EQUIPMENT_SLOT.RightGauntlet,
    [types.Armor.TYPE.Shield]    = types.Actor.EQUIPMENT_SLOT.CarriedLeft,
    [types.Armor.TYPE.LBracer]   = types.Actor.EQUIPMENT_SLOT.LeftGauntlet,
    [types.Armor.TYPE.RBracer]   = types.Actor.EQUIPMENT_SLOT.RightGauntlet,
}

local function armorSkillId(item)
    local skillId = I.Combat.getArmorSkill(item)
    if not skillId or skillId == "unarmored" then return nil end
    return skillId
end

local function armorConditionRatio(item)
    local rec = types.Armor.record(item)
    if not rec.health or rec.health <= 0 then return 1 end
    local data = types.Item.itemData(item)
    local cond = (data and data.condition) or rec.health
    return cond / rec.health
end

local function effectiveArmorRating(item, npcObj)
    local rec = types.Armor.record(item)
    if not rec then return 0 end
    local skillId = armorSkillId(item)
    if not skillId then return 0 end
    local skill = types.NPC.stats.skills[skillId](npcObj).modified
    return (rec.baseArmor or 0) * armorConditionRatio(item) * (skill / 30)
end

local function tryEquipArmor(item)
    if not types.Armor.objectIsInstance(item) then return end
    local rec = types.Armor.record(item)
    if not rec                                then return end
    local slot = ARMOR_TYPE_SLOT[rec.type]
    if not slot                               then return end
    if armorSkillId(item) == nil              then return end

    local pickedRating = effectiveArmorRating(item, self.object)

    -- skip if even the NPC's bare unarmored rating is better
    local unarmoredSkill  = types.NPC.stats.skills.unarmored(self.object).modified
    local unarmoredRating = (unarmoredSkill * unarmoredSkill) * 0.0065
    if pickedRating <= unarmoredRating then return end

    local eq      = types.Actor.getEquipment(self.object)
    local current = eq and eq[slot]
    if current and current:isValid() and types.Armor.objectIsInstance(current) then
        if pickedRating <= effectiveArmorRating(current, self.object) then return end
    end

    -- picked armor is better or slot is empty
    eq[slot] = item
    types.Actor.setEquipment(self, eq)
end

local function isItemHigh(pos)
    local bbox   = self.object:getBoundingBox()
    local center = bbox.center
    local half   = bbox.halfSize
    local t      = (pos.z - center.z + half.z) / (2 * half.z)
    return t > PICKUP_LOW_THRESHOLD
end

local function sendFinalizePickup(item, maxCount)
    core.sendGlobalEvent("GNPCs_FinalizePickup", {
        npc      = self.object,
        item     = item,
        maxCount = maxCount,
    })
end

playPickupAnimation = function(item, maxCount, onComplete)
    if not item or not item:isValid() or types.Actor.isDead(self.object) then
        if onComplete then onComplete() end
        return
    end

    self:enableAI(false)
    local fired = false

    local upperAnim = isItemHigh(item:getBoundingBox().center)
    local animName  = upperAnim and "loot01" or "loot02"

    -- Primary path: animation key triggers the transfer at the right frame
    I.AnimationController.addTextKeyHandler(animName, function(_, key)
        if key == "attach" and not fired then
            fired = true
            sendFinalizePickup(item, maxCount)
        end
    end)

    I.AnimationController.playBlendedAnimation(animName, {
        startKey = "start",
        stopKey  = "stop",
        priority = anim.PRIORITY.Scripted,
        speed    = upperAnim and 1.35 or 1.5,
    })

    -- Fallback path: if the key never fires (interrupted/missing key), force it
    async:newUnsavableSimulationTimer(PICKUP_ANIM_DURATION, function()
        if self:isActive() and not types.Actor.isDead(self.object) then
            self:enableAI(true)
        end
        if not fired then
            fired = true
            sendFinalizePickup(item, maxCount)
        end
        if onComplete then onComplete() end
    end)
end

local function lureCleanup()
    if not lure then return end
    I.AI.removePackages("Travel")
    restoreWander(lure.savedWander)
    lure = nil
    lureTickRunning = false
end

local function lureReturn()
    if not lure then return end
    I.AI.startPackage({
        type         = "Travel",
        destPosition = lure.homePos,
        cancelOther  = false,
    })
    lure.phase        = "returning"
    lure.lastPos      = nil
    lure.stuckTicks   = 0
    lure.unstuckTried = false
    startLureTick()
end

local function lureScheduleLinger(reason)
    lure.phase = "linger_wait"
    if reason == "miss" and cfg.SHOW_PICKUP_MESSAGES then
        showNpcMessage(messages.LURE_MISS_MESSAGES, messages.KHAJIIT_LURE_MISS_MESSAGES)
    elseif reason == "too_heavy" and cfg.SHOW_HEAVY_MESSAGES then
        showNpcMessage(messages.TOO_HEAVY_MESSAGES, messages.KHAJIIT_TOO_HEAVY_MESSAGES)
    end
    async:newUnsavableSimulationTimer(cfg.LURE_LINGER_DELAY, function()
        if not lure or lure.phase ~= "linger_wait" then return end
        lureReturn()
    end)
end

local function lureDoPickup()
    if not lure then return end
    local item = lure.item
    if not (item and item:isValid() and item.count > 0 and item.cell) then
        lureScheduleLinger("miss")
        return
    end

    local canAll, maxCount = canCarryItem(item)
    if maxCount <= 0 then
        -- NPC arrived but can't carry even one
        lureScheduleLinger("too_heavy")
        return
    end

    lure.phase = "picked_up"
    playPickupAnimation(item, (not canAll) and maxCount or nil)

    -- wait for the animation to finish, then walk back after LURE_RETURN_DELAY
    local returnDelay = math.max(PICKUP_ANIM_DURATION, cfg.LURE_RETURN_DELAY)
    async:newUnsavableSimulationTimer(returnDelay, function()
        if not lure or lure.phase ~= "picked_up" then return end
        lureReturn()
    end)
end

local function checkStuckAndJump()
    if not lure then return end

    local curPos = self.position
    if lure.lastPos then
        local moved = (curPos - lure.lastPos):length()
        if moved == 0 then
            -- perfectly still = not physically stuck
        elseif moved < STUCK_DISPLACEMENT then
            lure.stuckTicks = (lure.stuckTicks or 0) + 1
        else
            lure.stuckTicks = 0
            lure.unstuckTried = false
        end
    end
    lure.lastPos = curPos

    if (lure.stuckTicks or 0) < STUCK_TICKS_THRESHOLD then return end
    if lure.unstuckTried then return end
    if not cfg.JUMP_WHEN_STUCK then return end

    lure.unstuckTried = true
    lure.stuckTicks   = 0

    local function tryJump(remaining)
        if not lure then return end
        if types.Actor.isDead(self.object) then return end
        self.controls.jump = true
        if remaining > 1 then
            async:newUnsavableSimulationTimer(JUMP_RETRY_DELAY, function()
                tryJump(remaining - 1)
            end)
        end
    end
    tryJump(JUMP_ATTEMPTS)
end


local function lureTickWalking()
    local pkg        = I.AI.getActivePackage(self.object)
    local travelDone = not pkg or pkg.type ~= "Travel"
    local dist       = (self.position - lure.itemPos):length()

    if dist > LURE_ITEM_DIST and not travelDone then
        checkStuckAndJump()
        async:newUnsavableSimulationTimer(LURE_TICK, lureTick)
        return
    end

    I.AI.removePackages("Travel")

    local item = lure.item
    if item and item:isValid() and item.count > 0 and item.cell then
        lure.phase = "pickup_wait"
        async:newUnsavableSimulationTimer(cfg.LURE_PICKUP_DELAY, function()
            if not lure or lure.phase ~= "pickup_wait" then return end
            lureDoPickup()
        end)
    else
        lureScheduleLinger("miss")
    end
    -- phases after walking are timer-driven; lureReturn() will resume the tick
    lureTickRunning = false
end

local function lureTickReturning()
    local pkg        = I.AI.getActivePackage(self.object)
    local travelDone = not pkg or pkg.type ~= "Travel"
    local dist       = (self.position - lure.homePos):length()

    if dist <= LURE_HOME_DIST or travelDone then
        if not travelDone then
            I.AI.removePackages("Travel")
        end
        restoreWander(lure.savedWander)
        lure = nil
        lureTickRunning = false
        return
    end

    checkStuckAndJump()
    async:newUnsavableSimulationTimer(LURE_TICK, lureTick)
end

lureTick = function()
    if not lure then
        lureTickRunning = false
        return
    end
    if types.Actor.isDead(self.object) or isBusy() then
        lureCleanup()
        return
    end

    if lure.phase == "walking" then
        lureTickWalking()
    elseif lure.phase == "returning" then
        lureTickReturning()
    else
        lureTickRunning = false
    end
end

startLureTick = function()
    if lureTickRunning then return end
    lureTickRunning = true
    async:newUnsavableSimulationTimer(LURE_TICK, lureTick)
end

local function onActive()
    I.Combat.addOnHitHandler(function()
        if not lure then return end
        lureCleanup()
    end)
end

local function onInactive()
    lureCleanup()
    lureTickRunning = false
    core.sendGlobalEvent("GNPCs_RequestRemoval", self.object)
end

local function onSettingsUpdated(data)
    for _, k in ipairs(NPC_SETTING_KEYS) do
        local v = data[k]
        if v ~= nil then cfg[k] = v else cfg[k] = DEFAULTS[k] end
    end
end

local function onQueryPickup(data)
    if not cfg.PICKUP_ENABLED                                  then return end
    if not data or not data.item or not data.item:isValid()    then return end
    if types.Actor.isDead(self.object)                         then return end
    if isBusy()                                                then return end
    if lure                                                    then return end

    local recordId         = data.item.recordId:lower()
    local isGold           = GOLD_IDS[recordId]
    local canAll, maxCount = canCarryItem(data.item)

    if not isGold and maxCount <= 0 then
        core.sendGlobalEvent("NpcTooHeavyItem", {
            item = data.item,
            npc  = self.object,
        })
        return
    end

    core.sendGlobalEvent("NpcPickupItem", {
        item     = data.item,
        npc      = self.object,
        maxCount = (not isGold and not canAll) and maxCount or nil,
    })
end

local function onLureToItem(data)
    if not cfg.PICKUP_ENABLED                               then return end
    if not data or not data.item or not data.item:isValid() then return end
    if types.Actor.isDead(self.object)                      then return end
    if isBusy()                                             then return end

    -- already in a non-interruptible phase
    if lure
       and lure.phase ~= "returning"
       and lure.phase ~= "linger_wait"
       and lure.phase ~= "picked_up" then
        return
    end

    -- height check, don't lure across floors
    if math.abs(self.position.z - data.itemPos.z) > 100 then return end

    -- preserve home & saved wander across re-lures mid-sequence
    local homePos     = (lure and lure.homePos)     or self.position
    local savedWander = (lure and lure.savedWander) or saveWander()

    -- clear previous Travel and Wander so the new Travel starts immediately
    I.AI.removePackages("Travel")
    removeWander()

    lure = {
        item        = data.item,
        itemPos     = data.itemPos,
        homePos     = homePos,
        savedWander = savedWander,
        phase       = "walking",
    }

    I.AI.startPackage({
        type         = "Travel",
        destPosition = data.itemPos,
        cancelOther  = false,
    })

    if cfg.SHOW_PICKUP_MESSAGES then
        showNpcMessage(
            messages.LURE_INVESTIGATE_MESSAGES,
            messages.KHAJIIT_LURE_INVESTIGATE_MESSAGES
        )
    end

    startLureTick()
end

local function onQueryCrime(data)
    if not cfg.CRIME_ENABLED           then return end
    if not data or not data.player     then return end
    if types.Actor.isDead(self.object) then return end
    if isBusy()                        then return end
    core.sendGlobalEvent("ContrabandCrime", { player = data.player })
end

local function onTryEquipArmor(data)
    if not cfg.EQUIP_ARMOR                                  then return end
    if not data or not data.item or not data.item:isValid() then return end
    tryEquipArmor(data.item)
end

local function onStartPickupAnimation(data)
    if not data or not data.item or not data.item:isValid() then return end
    if types.Actor.isDead(self.object)                      then return end
    if isBusy()                                             then return end
    if lure                                                 then return end
    if data.item.cell == nil                                then return end

    local item     = data.item
    local maxCount = data.maxCount

    -- short Travel so the engine rotates the NPC toward the item
    I.AI.startPackage({
        type         = "Travel",
        destPosition = item.position,
        cancelOther  = false,
    })

    async:newUnsavableSimulationTimer(0.5, function()
        if not self:isActive()                       then return end
        if types.Actor.isDead(self.object)           then return end
        I.AI.removePackages("Travel")
        if not item:isValid() or item.cell == nil or item.count <= 0 then return end
        playPickupAnimation(item, maxCount)
    end)
end

return {
    engineHandlers = {
        onActive   = onActive,
        onInactive = onInactive,
    },
    eventHandlers = {
        GreedyNPCs_SettingsUpdated = onSettingsUpdated,
        GNPCs_QueryPickup          = onQueryPickup,
        GNPCs_LureToItem           = onLureToItem,
        GNPCs_QueryCrime           = onQueryCrime,
        GNPCs_TryEquipArmor        = onTryEquipArmor,
        GNPCs_StartPickupAnimation = onStartPickupAnimation,
    },
}