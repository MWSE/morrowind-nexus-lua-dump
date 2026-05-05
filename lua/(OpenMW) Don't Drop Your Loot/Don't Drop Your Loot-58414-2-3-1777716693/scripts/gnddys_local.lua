local self  = require("openmw.self")
local types = require("openmw.types")
local core  = require("openmw.core")
local async = require("openmw.async")
local I     = require("openmw.interfaces")
local nearby = require("openmw.nearby")
local anim  = require("openmw.animation")

local shared       = require("scripts.gshared")
local DEFAULTS     = shared.DEFAULTS
local KHAJIIT_RACE = shared.KHAJIIT_RACE
local GOLD_IDS = shared.GOLD_IDS

local messages = require("scripts.gnddys_messages")


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
    local msg = pool[math.random(#pool)]
    player:sendEvent("NpcPickupMessage", {
        message = npcName() .. ": \"" .. msg .. "\""
    })
end

-- no picking up or reporting
local BUSY_PACKAGES = {
    Combat  = true,
    Pursue  = true,
}
 
-- configurable via settings
local CUST_PACKAGES = {
    Escort  = true,
    Follow  = true,
}

local cachedSettings = {
    PICKUP_ENABLED       = DEFAULTS.PICKUP_ENABLED,
    CRIME_ENABLED        = DEFAULTS.CRIME_ENABLED,
    EQUIP_ARMOR          = DEFAULTS.EQUIP_ARMOR,
    LURE_PICKUP_DELAY    = DEFAULTS.LURE_PICKUP_DELAY,
    LURE_RETURN_DELAY    = DEFAULTS.LURE_RETURN_DELAY,
    LURE_LINGER_DELAY    = DEFAULTS.LURE_LINGER_DELAY,
    SHOW_PICKUP_MESSAGES = DEFAULTS.SHOW_PICKUP_MESSAGES,
    SHOW_HEAVY_MESSAGES  = DEFAULTS.SHOW_HEAVY_MESSAGES,
    ESCORT_FOLLOW_BUSY   = DEFAULTS.ESCORT_FOLLOW_BUSY,
}

local LURE_ITEM_DIST = 60
local LURE_HOME_DIST = 5
local LURE_TICK = 0.3

local lure = nil
local lureTickRunning = false

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

-- Restore saved Wander packages onto the AI stack
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

-- Remove all Wander packages so Travel starts immediately
local function removeWander()
    I.AI.filterPackages(function(p)
        return p.type ~= "Wander"
    end)
end

local function lureCleanup()
    if not lure then return end
    local saved = lure.savedWander
    I.AI.removePackages("Travel")
    restoreWander(saved)
    lure = nil
    lureTickRunning = false
end

-- forward declaration, assigned after startLureTick is defined, used to get rid of onupdate
local startLureTick

-- forward declaration, assigned later
local playPickupAnimation
local PICKUP_ANIM_DURATION = 2

local function lureReturn()
    if not lure then return end
    I.AI.startPackage({
        type         = "Travel",
        destPosition = lure.homePos,
        cancelOther  = false,
    })
    lure.phase = "returning"
    startLureTick()
end

local function canCarryItem(item)
    local itemWeight = 0

    if types.Weapon.objectIsInstance(item) then
        itemWeight = types.Weapon.record(item).weight or 0
    elseif types.Armor.objectIsInstance(item) then
        itemWeight = types.Armor.record(item).weight or 0
    elseif types.Clothing.objectIsInstance(item) then
        itemWeight = types.Clothing.record(item).weight or 0
    elseif types.Book.objectIsInstance(item) then
        itemWeight = types.Book.record(item).weight or 0
    elseif types.Ingredient.objectIsInstance(item) then
        itemWeight = types.Ingredient.record(item).weight or 0
    elseif types.Potion.objectIsInstance(item) then
        itemWeight = types.Potion.record(item).weight or 0
    elseif types.Apparatus.objectIsInstance(item) then
        itemWeight = types.Apparatus.record(item).weight or 0
    elseif types.Lockpick.objectIsInstance(item) then
        itemWeight = types.Lockpick.record(item).weight or 0
    elseif types.Probe.objectIsInstance(item) then
        itemWeight = types.Probe.record(item).weight or 0
    elseif types.Repair.objectIsInstance(item) then
        itemWeight = types.Repair.record(item).weight or 0
    elseif types.Miscellaneous.objectIsInstance(item) then
        itemWeight = types.Miscellaneous.record(item).weight or 0
    end

    local count = item.count or 1
    local stackWeight = itemWeight * count

    if stackWeight <= 0 then
        return true, count
    end

    local actor       = self.object
    local capacity    = types.Actor.getCapacity (actor)
    local encumbrance = types.Actor.getEncumbrance(actor)
    local freeSpace   = capacity - encumbrance

    if freeSpace <= 0 then
        return false, 0
    end

    local canFit = math.floor(freeSpace / itemWeight)
    if canFit >= count then
        return true, count
    end

    return false, canFit
end

local function lureDoPickup()
    if not lure then return end
    local item = lure.item
    if item and item:isValid() and item.count > 0 and item.cell then
        local canAll, maxCount = canCarryItem(item)
        if maxCount <= 0 then
            -- NPC arrived but can't carry even one
            lure.phase = "linger_wait"
            if cachedSettings.SHOW_HEAVY_MESSAGES then
                showNpcMessage(
                    messages.TOO_HEAVY_MESSAGES,
                    messages.KHAJIIT_TOO_HEAVY_MESSAGES
                )
            end
            async:newUnsavableSimulationTimer(cachedSettings.LURE_LINGER_DELAY, function()
                if not lure or lure.phase ~= "linger_wait" then return end
                lureReturn()
            end)
            return
        end
        lure.phase = "picked_up"
        playPickupAnimation(item, not canAll and maxCount or nil)
        -- Wait for the animation to finish before walking back, then linger LURE_RETURN_DELAY.
        local returnDelay = math.max(PICKUP_ANIM_DURATION, cachedSettings.LURE_RETURN_DELAY)
        async:newUnsavableSimulationTimer(returnDelay, function()
            if not lure or lure.phase ~= "picked_up" then return end
            lureReturn()
        end)
    else
        lure.phase = "linger_wait"
        if cachedSettings.SHOW_PICKUP_MESSAGES then
            showNpcMessage(
                messages.LURE_MISS_MESSAGES,
                messages.KHAJIIT_LURE_MISS_MESSAGES
            )
        end
        async:newUnsavableSimulationTimer(cachedSettings.LURE_LINGER_DELAY, function()
            if not lure or lure.phase ~= "linger_wait" then return end
            lureReturn()
        end)
    end
end


local function isBusy()
    local pkg = I.AI.getActivePackage(self.object)
    local pkgType = pkg and pkg.type or "none"
    if BUSY_PACKAGES[pkgType] then return true end
    if cachedSettings.ESCORT_FOLLOW_BUSY and CUST_PACKAGES[pkgType] then return true end
    return false
end


-- forward declaration
local lureTick

lureTick = function()
    if not lure then
        lureTickRunning = false
        return
    end

    if types.Actor.isDead(self.object) or isBusy() then
        lureCleanup()
        lureTickRunning = false
        return
    end

    if lure.phase == "walking" then
        local pkg = I.AI.getActivePackage(self.object)
        local travelDone = not pkg or pkg.type ~= "Travel"

        local dist = (self.position - lure.itemPos):length()
        if dist > LURE_ITEM_DIST and not travelDone then
            -- still walking, schedule next tick
            async:newUnsavableSimulationTimer(LURE_TICK, lureTick)
            return
        end

        I.AI.removePackages("Travel")

        local item = lure.item
        if item and item:isValid() and item.count > 0 and item.cell then
            lure.phase = "pickup_wait"
            async:newUnsavableSimulationTimer(cachedSettings.LURE_PICKUP_DELAY, function()
                if not lure or lure.phase ~= "pickup_wait" then return end
                lureDoPickup()
            end)
        else
            lure.phase = "linger_wait"
            if cachedSettings.SHOW_PICKUP_MESSAGES then
                showNpcMessage(
                    messages.LURE_MISS_MESSAGES,
                    messages.KHAJIIT_LURE_MISS_MESSAGES
                )
            end
            async:newUnsavableSimulationTimer(cachedSettings.LURE_LINGER_DELAY, function()
                if not lure or lure.phase ~= "linger_wait" then return end
                lureReturn()
            end)
        end
        -- phases after walking are timer-driven, let the tick loop sleep.
        -- lureReturn() will call startLureTick() to resume for "returning".
        lureTickRunning = false
        return

    elseif lure.phase == "returning" then
        local pkg = I.AI.getActivePackage(self.object)
        local travelDone = not pkg or pkg.type ~= "Travel"

        local dist = (self.position - lure.homePos):length()
        if dist <= LURE_HOME_DIST or travelDone then
            if not travelDone then
                I.AI.removePackages("Travel")
            end
            -- restore saved Wander packages
            restoreWander(lure.savedWander)
            lure = nil
            lureTickRunning = false
            return
        end

        -- still returning, schedule next tick
        async:newUnsavableSimulationTimer(LURE_TICK, lureTick)
        return
    end

    lureTickRunning = false
end

startLureTick = function()
    if lureTickRunning then return end
    lureTickRunning = true
    async:newUnsavableSimulationTimer(LURE_TICK, lureTick)
end

-- armour part

local ARMOR_TYPE_SLOT = {
    [types.Armor.TYPE.Helmet]        = types.Actor.EQUIPMENT_SLOT.Helmet,
    [types.Armor.TYPE.Cuirass]       = types.Actor.EQUIPMENT_SLOT.Cuirass,
    [types.Armor.TYPE.LPauldron]     = types.Actor.EQUIPMENT_SLOT.LeftPauldron,
    [types.Armor.TYPE.RPauldron]     = types.Actor.EQUIPMENT_SLOT.RightPauldron,
    [types.Armor.TYPE.Greaves]       = types.Actor.EQUIPMENT_SLOT.Greaves,
    [types.Armor.TYPE.Boots]         = types.Actor.EQUIPMENT_SLOT.Boots,
    [types.Armor.TYPE.LGauntlet]     = types.Actor.EQUIPMENT_SLOT.LeftGauntlet,
    [types.Armor.TYPE.RGauntlet]     = types.Actor.EQUIPMENT_SLOT.RightGauntlet,
    [types.Armor.TYPE.Shield]        = types.Actor.EQUIPMENT_SLOT.CarriedLeft,
    [types.Armor.TYPE.LBracer]       = types.Actor.EQUIPMENT_SLOT.LeftGauntlet,
    [types.Armor.TYPE.RBracer]       = types.Actor.EQUIPMENT_SLOT.RightGauntlet,
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
    if not rec then return end
    local slot = ARMOR_TYPE_SLOT[rec.type]
    if not slot then return end
    if armorSkillId(item) == nil then return end

    local pickedRating = effectiveArmorRating(item, self.object)

    local unarmoredSkill = types.NPC.stats.skills.unarmored(self.object).modified
    local unarmoredRating = (unarmoredSkill * unarmoredSkill) * 0.0065
    if pickedRating <= unarmoredRating then 
        return 
    end

    local eq = types.Actor.getEquipment(self.object)
    local current = eq and eq[slot]
    if current and current:isValid() and types.Armor.objectIsInstance(current) then
        local currentRating = effectiveArmorRating(current, self.object)
        if pickedRating <= currentRating then return end
    end

    -- picked armour is better or slot is empty, equip it
    eq[slot] = item
    types.Actor.setEquipment(self, eq)
end

playPickupAnimation = function(item, maxCount, onComplete)
    if not item or not item:isValid() then
        if onComplete then onComplete() end
        return
    end
    if types.Actor.isDead(self.object) then
        if onComplete then onComplete() end
        return
    end

    self:enableAI(false)
    local fired = false

    I.AnimationController.addTextKeyHandler("loot02", function(groupname, key)
        if key == "attach" and not fired then
            fired = true
            core.sendGlobalEvent("GNPCs_FinalizePickup", {
                npc      = self.object,
                item     = item,
                maxCount = maxCount,
            })
        end
    end)

    I.AnimationController.playBlendedAnimation("loot02", {
        startKey = "start",
        stopKey  = "stop",
        priority = anim.PRIORITY.Scripted,
        speed    = 1.5,
    })

    async:newUnsavableSimulationTimer(PICKUP_ANIM_DURATION, function()
        if self:isActive() and not types.Actor.isDead(self.object) then
            self:enableAI(true)
        end
        if not fired then
            fired = true
            core.sendGlobalEvent("GNPCs_FinalizePickup", {
                npc      = self.object,
                item     = item,
                maxCount = maxCount,
            })
        end
        if onComplete then onComplete() end
    end)
end


return {
    engineHandlers = {
        onActive = function()
            I.Combat.addOnHitHandler(function()
                if not lure then return end
                lureCleanup()
            end)
        end,

        onInactive = function()
            lureCleanup()
            lureTickRunning = false
            core.sendGlobalEvent("GNPCs_RequestRemoval", self.object)
        end,
    },

    eventHandlers = {
        GreedyNPCs_SettingsUpdated = function(data)
            cachedSettings.PICKUP_ENABLED       = data.PICKUP_ENABLED
            cachedSettings.CRIME_ENABLED        = data.CRIME_ENABLED
            cachedSettings.EQUIP_ARMOR          = data.EQUIP_ARMOR
            cachedSettings.LURE_PICKUP_DELAY    = data.LURE_PICKUP_DELAY or DEFAULTS.LURE_PICKUP_DELAY
            cachedSettings.LURE_RETURN_DELAY    = data.LURE_RETURN_DELAY or DEFAULTS.LURE_RETURN_DELAY
            cachedSettings.LURE_LINGER_DELAY    = data.LURE_LINGER_DELAY or DEFAULTS.LURE_LINGER_DELAY
            cachedSettings.SHOW_PICKUP_MESSAGES = data.SHOW_PICKUP_MESSAGES
            cachedSettings.SHOW_HEAVY_MESSAGES  = data.SHOW_HEAVY_MESSAGES
            cachedSettings.ESCORT_FOLLOW_BUSY   = data.ESCORT_FOLLOW_BUSY
            if cachedSettings.SHOW_PICKUP_MESSAGES == nil then cachedSettings.SHOW_PICKUP_MESSAGES = DEFAULTS.SHOW_PICKUP_MESSAGES end
            if cachedSettings.SHOW_HEAVY_MESSAGES  == nil then cachedSettings.SHOW_HEAVY_MESSAGES  = DEFAULTS.SHOW_HEAVY_MESSAGES  end
            if cachedSettings.ESCORT_FOLLOW_BUSY   == nil then cachedSettings.ESCORT_FOLLOW_BUSY   = DEFAULTS.ESCORT_FOLLOW_BUSY  end
        end,

        GNPCs_QueryPickup = function(data)
            if not cachedSettings.PICKUP_ENABLED then return end
            if not data or not data.item or not data.item:isValid() then return end
            if types.Actor.isDead(self.object) then return end
            if isBusy() then return end
            if lure then return end
            local recordId = data.item.recordId:lower()
            local isGold = GOLD_IDS[recordId]
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
        end,

        GNPCs_LureToItem = function(data)
            if not cachedSettings.PICKUP_ENABLED then return end
            if not data or not data.item or not data.item:isValid() then return end
            if types.Actor.isDead(self.object) then return end
            if isBusy() then return end
            if lure and lure.phase ~= "returning" and lure.phase ~= "linger_wait" and lure.phase ~= "picked_up" then return end
            -- height check
            if math.abs(self.position.z - data.itemPos.z) > 100 then return end

            -- save home position; keep original if re-lured mid-sequence
            local homePos = (lure and lure.homePos) or self.position
            -- save Wander packages before first lure only
            local savedWander = (lure and lure.savedWander) or saveWander()

            -- clear previous Travel and Wander so new Travel starts immediately
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

            if cachedSettings.SHOW_PICKUP_MESSAGES then
                showNpcMessage(
                    messages.LURE_INVESTIGATE_MESSAGES,
                    messages.KHAJIIT_LURE_INVESTIGATE_MESSAGES
                )
            end

            startLureTick()
        end,

        GNPCs_QueryCrime = function(data)
            if not cachedSettings.CRIME_ENABLED then return end
            if not data or not data.player then return end
            if types.Actor.isDead(self.object) then return end
            if isBusy() then return end
            core.sendGlobalEvent("ContrabandCrime", { player = data.player })
        end,

        GNPCs_TryEquipArmor = function(data)
            if not cachedSettings.EQUIP_ARMOR then return end
            if not data or not data.item or not data.item:isValid() then return end
            tryEquipArmor(data.item)
        end,

        GNPCs_StartPickupAnimation = function(data)
            if not data or not data.item or not data.item:isValid() then return end
            if types.Actor.isDead(self.object) then return end
            if isBusy() then return end
            if lure then return end
            if data.item.cell == nil then return end

            local item     = data.item
            local maxCount = data.maxCount

            -- start a short Travel so the engine rotates the NPC toward the item
            I.AI.startPackage({
                type         = "Travel",
                destPosition = item.position,
                cancelOther  = false,
            })

            async:newUnsavableSimulationTimer(0.5, function()
                if not self:isActive() then return end
                if types.Actor.isDead(self.object) then return end
                I.AI.removePackages("Travel")

                if not item:isValid() or item.cell == nil or item.count <= 0 then return end

                playPickupAnimation(item, maxCount)
            end)
        end,
    },
}