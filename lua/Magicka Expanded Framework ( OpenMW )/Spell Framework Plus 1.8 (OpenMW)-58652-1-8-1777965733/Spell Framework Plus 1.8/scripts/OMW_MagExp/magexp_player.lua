-- ============================================================
-- OMW_MagExp: Magic Expansion Framework for OpenMW
-- magexp_player.lua (PLAYER script)
-- ============================================================

local self    = require('openmw.self')
local core    = require('openmw.core')
local types   = require('openmw.types')
local anim    = require('openmw.animation')
local input   = require('openmw.input')
local storage = require('openmw.storage')
local ui      = require('openmw.ui')
local camera  = require('openmw.camera')
local util    = require('openmw.util')
local debug   = require('openmw.debug')
local I       = require('openmw.interfaces')

-- ---- State Management ----
local busyUntil        = 0
local hasQueuedLaunch  = false
local pendingLaunches  = {}

-- ---- [FEATURE 5] Charged Spell State ----
local currentChargeData = nil  -- { animGroup, chargeKey, priority, blendMask, isCharging }

-- ---- [CHARGE-AS-CAST] Tracks a chargeKey that was passed alongside the cast request.
-- If the key is still held when the 'start' text key fires, the cast enters charge loop
-- instead of proceeding directly to 'release'.
local pendingChargeKey = nil

-- ============================================================
-- [OSSC DETECTION] Optional OSSC integration
-- ============================================================
local IS_OSSC_LOADED = false
pcall(function()
    local s = storage.playerSection('SettingsOSSC_General')
    IS_OSSC_LOADED = (s ~= nil and s:get('DebugMode') ~= nil)
end)

local function debugLog(msg)
    if not IS_OSSC_LOADED then return end
    local section = storage.playerSection('SettingsOSSC_General')
    if section and section:get('DebugMode') then
        print("[MagExp-Player] " .. tostring(msg))
    end
end

-- ============================================================
-- [HELPERS] Launch Parameter Calculation
-- ============================================================
local function calculateLaunchPayload(spell, item)
    local cameraMode = camera.getMode()
    local startPos, direction

    if cameraMode == camera.MODE.FirstPerson then
        startPos  = camera.getPosition()
        direction = camera.getViewDirection()
        startPos = startPos + camera.getUp() * -10 + camera.getLeft() * 15
    else
        startPos  = self.position + util.vector3(0, 0, 120)
        direction = camera.getViewDirection()
        startPos = startPos + camera.getLeft() * 25
    end

    return {
        attacker   = self,
        spellId    = spell.id,
        itemObject = item,
        startPos   = startPos,
        direction  = direction,
        isGodMode  = debug.isGodMode()
    }
end

-- ============================================================
-- [INTERNAL] Charge key held check helper.
-- Safely calls the registered predicate for a given keyId.
-- Returns true only if the key is registered AND currently held.
-- ============================================================
local function isChargeKeyCurrentlyHeld(keyId)
    if not keyId then return false end
    local result = false
    pcall(function()
        local fn = I.MagExp
                   and I.MagExp._chargeKeyRegistry
                   and I.MagExp._chargeKeyRegistry[keyId]
        if fn then result = fn() end
    end)
    return result
end

-- ============================================================
-- [CORE] Animation Sync & Lifecycle
-- ============================================================
local function onTextKey(groupname, key)
    if not hasQueuedLaunch then return end

    local k = tostring(key):lower()

    -- --------------------------------------------------------
    -- "start" key: end of the initial cast wind-up phase.
    -- If a chargeKey was registered for this cast AND the key
    -- is still held at this point, enter the charge loop
    -- instead of letting the animation proceed to "release".
    -- --------------------------------------------------------
    if k == "start" then
        if pendingChargeKey and isChargeKeyCurrentlyHeld(pendingChargeKey) then
            debugLog("Charge key held at 'start' — entering charge loop for: " .. tostring(pendingChargeKey))

            -- Register charge state so onUpdate can poll the key each frame
            currentChargeData = {
                animGroup  = "spellcast",
                chargeKey  = pendingChargeKey,
                priority   = 1,
                blendMask  = 15,
                isCharging = true,
            }

            -- Re-play spellcast with loop = true so it stays in the charge phase.
            -- OpenMW will cycle at the loop start/stop markers in the NIF/KF.
            -- onUpdate will detect key release and call anim.play with loop = false
            -- to proceed forward through to 'release' naturally.
            pcall(function()
                anim.play(self, "spellcast", 1, 15, true, 1.0)
            end)
            -- Do NOT clear pendingChargeKey here — onUpdate needs it.
        end
        -- If key is NOT held (or no chargeKey registered), do nothing:
        -- the animation continues playing normally toward 'release'.
        return
    end

    -- --------------------------------------------------------
    -- "release" key: spell fires here (standard path AND after
    -- charge loop completes).
    -- --------------------------------------------------------
    if k == "release" then
        debugLog("Animation Release Key Detected: " .. k)
        for spellId, item in pairs(pendingLaunches) do
            local spell = core.magic.spells.records[spellId] or core.magic.enchantments.records[spellId]
            if spell then
                local payload = calculateLaunchPayload(spell, item)
                core.sendGlobalEvent('MagExp_CastRequest', payload)
            end
        end
        pendingLaunches  = {}
        hasQueuedLaunch  = false
        -- Clear charge state once the spell has fired
        if currentChargeData then
            currentChargeData.isCharging = false
        end
        return
    end

    -- --------------------------------------------------------
    -- "stop" key: animation fully finished, clean everything up.
    -- --------------------------------------------------------
    if k == "stop" then
        hasQueuedLaunch  = false
        pendingLaunches  = {}
        currentChargeData = nil
        pendingChargeKey  = nil   -- always clear on full animation end
        return
    end
end

-- ============================================================
-- [UPDATE] Charge Key Polling
-- Polls the registered charge key each frame while in charge mode.
-- When the key is released, resumes the animation without looping
-- so it naturally proceeds to the 'release' text key → spell fires.
-- ============================================================
local function onUpdate(dt)
    if currentChargeData and currentChargeData.isCharging then
        local chargeKey = currentChargeData.chargeKey
        local isHeld    = isChargeKeyCurrentlyHeld(chargeKey)

        if not isHeld then
            -- Key released: switch from looping to single-play so the animation
            -- proceeds forward through 'release' → spell fires → 'stop'.
            debugLog("Charge key released — proceeding to release key")
            currentChargeData.isCharging = false
            pendingChargeKey = nil
            pcall(function()
                anim.play(self, currentChargeData.animGroup,
                    currentChargeData.priority or 7,
                    currentChargeData.blendMask or 15,
                    false,   -- no loop → will reach 'release' naturally
                    1.0)
            end)
        end
    end
end

-- ============================================================
-- [EVENT] MagExp_StartQuickCast
--
-- Accepts an optional 'chargeKey' field (string).
-- If provided, the cast key doubles as the charge key:
--   - If held through the 'start' animation text key → charge loop.
--   - If released before 'start' → normal instant cast to 'release'.
--
-- Usage example (from a player/local script):
--   self:sendEvent('MagExp_StartQuickCast', {
--       spellId   = "fireball",
--       chargeKey = "MyMod_CastKey",  -- the key registered via I.MagExp.registerChargeKey
--   })
-- ============================================================
local function startQuickCast(data)
    local spellId = data.spellId
    local spell = core.magic.spells.records[spellId] or core.magic.enchantments.records[spellId]
    if not spell then return end

    debugLog("Initiating Quick Cast sequence for: " .. spellId)

    -- Store which chargeKey (if any) was passed alongside this cast.
    -- onTextKey 'start' will read this to decide whether to enter charge loop.
    pendingChargeKey = data.chargeKey or nil

    core.sendGlobalEvent('MagExp_ProcessCast', {
        actor     = self,
        spellId   = spellId,
        item      = data.item,
        isFree    = data.isFree,
        isGodMode = debug.isGodMode()
    })
end

local function handleCastResult(data)
    if data.success then
        debugLog("Cast Authorization: SUCCESS")
        hasQueuedLaunch = true
        pendingLaunches[data.spellId] = data.item

        -- Trigger casting animation. The 'start' text key handler will decide
        -- whether to continue normally or enter the charge loop.
        anim.playBlended(self, "spellcast", { priority = 1, blend = 0.2 })
    else
        debugLog("Cast Authorization: FAILED (Roll/Magicka)")
        ui.showMessage("You failed casting the spell.")
        -- Reset charge key on failure so it doesn't leak into the next cast.
        pendingChargeKey = nil
    end
end

if I.AnimationController then
    I.AnimationController.addTextKeyHandler('', onTextKey)
end

local handlers = {
    engineHandlers = {
        onUpdate  = onUpdate,
    },
    eventHandlers = {
        MagExp_StartQuickCast = startQuickCast,
        MagExp_CastResult     = handleCastResult,

        -- [FEATURE 5] Custom animation override from launchSpellAnim()
        MagExp_PlaySpellAnim = function(data)
            if not data or not data.animGroup then return end
            local group    = data.animGroup
            local mask     = data.blendMask or 15
            local priority = data.priority  or 7

            debugLog("MagExp_PlaySpellAnim: " .. group .. " (priority=" .. priority .. " mask=" .. mask .. ")")

            anim.play(self, group, priority, mask, false, 1.0)

            if data.isCharged then
                currentChargeData = {
                    animGroup  = group,
                    chargeKey  = data.chargeKey,
                    priority   = priority,
                    blendMask  = mask,
                    isCharging = true,
                }
                debugLog("Charged spell started: " .. group .. " key=" .. tostring(data.chargeKey))
            end
        end,
        -- [FEATURE 5] Graceful release: resumes normal playback so the 'release'
        -- text key fires naturally → spell launches → 'stop' clears state.
        MagExp_ReleaseSpellAnim = function(data)
            if not data or not data.animGroup then return end
            debugLog("MagExp_ReleaseSpellAnim: " .. data.animGroup)
            pcall(function()
                anim.play(self, data.animGroup,
                    currentChargeData and currentChargeData.priority or 7,
                    currentChargeData and currentChargeData.blendMask or 15,
                    false, 1.0)
            end)
            if currentChargeData then
                currentChargeData.isCharging = false
            end
        end,

        -- VFX Utilities
        AddVfx = function(data)
            anim.addVfx(self, data.model, data.options)
        end,
        RemoveVfx = function(vfxId)
            anim.removeVfx(self, vfxId)
        end,
        RemoveVfxDirect = function(vfxId)
            anim.removeVfx(self, vfxId)
        end,

        -- UI Utilities
        Ui_ShowMessage = function(msg)
            if type(msg) == "string" then ui.showMessage(msg) end
        end,

        -- Resource consumption: magicka here; scroll/charge via global event (inventory mutations).
        MagExp_ConsumeResource = function(data)
            pcall(function()
                if data.magickaCost then
                    local magicka = types.Actor.stats.dynamic.magicka(self)
                    magicka.current = math.max(0, magicka.current - data.magickaCost)
                end
                -- Scroll / charge must run in global script (OpenMW restriction). Interface calls from
                -- player scripts are not guaranteed to execute with global permissions; use global event.
                if (data.itemCountCost and data.itemRecordId) or (data.itemChargeCost and data.itemRecordId) then
                    core.sendGlobalEvent('MagExp_ApplyInventoryConsume', {
                        attacker = self,
                        item = data.item,
                        itemCountCost = data.itemCountCost,
                        itemRecordId = data.itemRecordId,
                        itemChargeCost = data.itemChargeCost,
                    })
                end
            end)
        end,
    }
}

-- ============================================================
-- [PUBLIC LOCAL API] For other player scripts (like OSSC, Kinetic Forces)
-- ============================================================
local MagExp_PlayerInterface = {
    consumeSpellCost = function(spellId, itemObject)
        if debug.isGodMode() then return true end
        local spell = core.magic.spells.records[spellId]
        local isEnchantment = false
        if not spell then
            spell = core.magic.enchantments.records[spellId]
            isEnchantment = spell ~= nil
        end
        if not spell then return true end
        local cost = spell.cost or 0
        if cost <= 0 then return true end

        if isEnchantment and itemObject and type(itemObject) ~= "string" and itemObject:isValid() then
            if spell.type == core.magic.ENCHANTMENT_TYPE.CastOnce then
                if itemObject.count > 0 then
                    core.sendGlobalEvent('MagExp_ApplyInventoryConsume', {
                        attacker = self,
                        item = itemObject,
                        itemCountCost = 1,
                        itemRecordId = itemObject.recordId,
                    })
                    return true
                else
                    ui.showMessage("You do not have enough of that item.")
                    return false
                end
            else
                local skill = 0
                pcall(function() skill = types.Player.stats.skills.enchant(self).modified end)
                cost = math.max(1, math.floor(0.01 * (110 - skill) * cost))
                local currentCharge, haveCharge = 0, false
                pcall(function()
                    local itemData = types.Item.itemData(itemObject)
                    if itemData and itemData.enchantmentCharge ~= nil then
                        currentCharge = itemData.enchantmentCharge
                        haveCharge = true
                    end
                end)
                if not haveCharge then
                    currentCharge = spell.charge or 0
                end
                if currentCharge >= cost then
                    core.sendGlobalEvent('MagExp_ApplyInventoryConsume', {
                        attacker = self,
                        item = itemObject,
                        itemChargeCost = cost,
                        itemRecordId = itemObject.recordId,
                    })
                    return true
                else
                    ui.showMessage("You don't have enough charges in this item.")
                    return false
                end
            end
        else
            local magicka = types.Actor.stats.dynamic.magicka(self)
            if magicka.current >= cost then
                magicka.current = magicka.current - cost
                return true
            else
                ui.showMessage("You do not have enough Magicka to cast the spell.")
                return false
            end
        end
    end
}

return {
    interfaceName  = "MagExp_Player",
    interface      = MagExp_PlayerInterface,
    engineHandlers = handlers.engineHandlers,
    eventHandlers  = handlers.eventHandlers,
}