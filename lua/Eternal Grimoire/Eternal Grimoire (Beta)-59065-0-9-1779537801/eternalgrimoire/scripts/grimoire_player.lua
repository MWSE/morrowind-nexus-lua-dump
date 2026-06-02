-- ============================================================
-- The Eternal Grimoire — PLAYER Script
-- ============================================================

local core    = require('openmw.core')
local self    = require('openmw.self')
local types   = require('openmw.types')
local ui      = require('openmw.ui')
local storage = require('openmw.storage')
local anim    = require('openmw.animation')

print('[EternalGrimoire][PLAYER] ========== FILE LOADED ==========')

local EG = storage.globalSection('EternalGrimoire')

-- ----------------------------------------------------------------
-- Constants
-- ----------------------------------------------------------------
local GRIMOIRE_ID    = 'eternal_grimoire'
local POLL_INTERVAL  = 1.0
local VFX_ID         = GRIMOIRE_ID

-- ----------------------------------------------------------------
-- State
-- ----------------------------------------------------------------
local pollAcc = 0
local hadGrim = false
local wasEquipped = false

-- ----------------------------------------------------------------
-- Inventory check
-- ----------------------------------------------------------------
local function hasGrimoireInInventory()
    local inv = types.Actor.inventory(self)
    if not inv then
        return false
    end
    
    local books = inv:getAll(types.Light)
    
    for _, book in ipairs(books) do
        local recordId = book.recordId or ''
        if recordId == GRIMOIRE_ID then
            return true
        end
    end
    
    return false
end

-- ----------------------------------------------------------------
-- Equipment check
-- ----------------------------------------------------------------
local function isGrimoireEquipped()
    if not types.Actor.activeSpells then
        if not types.Actor then
            print('[EternalGrimoire][PLAYER] Actor type not available')
            return false
        end
    end
    
    local success, equipment = pcall(function()
        return types.Actor.equipment(self)
    end)
    
    if not success or not equipment then
        print('[EternalGrimoire][PLAYER] Could not access equipment')
        return false
    end
    
    local leftHand = equipment[types.Actor.EQUIPMENT_SLOT.CarriedLeft]
    
    if leftHand and leftHand.recordId == GRIMOIRE_ID then
        return true
    end
    
    return false
end

-- ----------------------------------------------------------------
-- VFX Management (WITH DEBUG LOGS)
-- ----------------------------------------------------------------
local function addGrimoireVfx()
    print('[EternalGrimoire][PLAYER] ========== ADDING VFX - START ==========')
    
    -- Check if anim module is available
    if not anim then
        print('[EternalGrimoire][PLAYER] ERROR: anim module is nil!')
        return
    end
    print('[EternalGrimoire][PLAYER] anim module available: ' .. tostring(anim))
    
    -- Check if addVfx function exists
    if not anim.addVfx then
        print('[EternalGrimoire][PLAYER] ERROR: anim.addVfx is nil!')
        return
    end
    print('[EternalGrimoire][PLAYER] anim.addVfx function available')
    
    -- Check if self is valid
    if not self then
        print('[EternalGrimoire][PLAYER] ERROR: self is nil!')
        return
    end
    print('[EternalGrimoire][PLAYER] self is valid')
    
    -- Check Light records
    if not types.Light then
        print('[EternalGrimoire][PLAYER] ERROR: types.Light is nil!')
        return
    end
    print('[EternalGrimoire][PLAYER] types.Light available')
    
    if not types.Light.records then
        print('[EternalGrimoire][PLAYER] ERROR: types.Light.records is nil!')
        return
    end
    print('[EternalGrimoire][PLAYER] types.Light.records available')
    
    -- Get the grimoire record
    local lightRecord = types.Light.records[GRIMOIRE_ID]
    if not lightRecord then
        print('[EternalGrimoire][PLAYER] ERROR: Could not find light record for ID: ' .. GRIMOIRE_ID)
        print('[EternalGrimoire][PLAYER] Available records:')
        for id, _ in pairs(types.Light.records) do
            print('[EternalGrimoire][PLAYER]   - ' .. tostring(id))
        end
        return
    end
    print('[EternalGrimoire][PLAYER] Light record found: ' .. tostring(lightRecord))
    
    -- Check if model exists
    if not lightRecord.model then
        print('[EternalGrimoire][PLAYER] ERROR: lightRecord.model is nil!')
        return
    end
    
    local meshPath = lightRecord.model
    print('[EternalGrimoire][PLAYER] Mesh path: ' .. tostring(meshPath))
    
    -- Try to add VFX with detailed error catching
    local success, err = pcall(function()
        print('[EternalGrimoire][PLAYER] Calling anim.addVfx with:')
        print('[EternalGrimoire][PLAYER]   - self: ' .. tostring(self))
        print('[EternalGrimoire][PLAYER]   - meshPath: ' .. tostring(meshPath))
        print('[EternalGrimoire][PLAYER]   - vfxId: ' .. tostring(VFX_ID))
        print('[EternalGrimoire][PLAYER]   - boneName: Bip01 L Hand')
        
        anim.addVfx(self, meshPath, {
            loop = true,
            boneName = "Bip01 L Hand",
            particle = ""
        })
    end)
    
    if success then
        print('[EternalGrimoire][PLAYER] ✅ VFX ADDED SUCCESSFULLY')
    else
        print('[EternalGrimoire][PLAYER] ❌ VFX ADD FAILED WITH ERROR:')
        print('[EternalGrimoire][PLAYER] ' .. tostring(err))
    end
    
    print('[EternalGrimoire][PLAYER] ========== ADDING VFX - END ==========')
end

local function removeGrimoireVfx()
    print('[EternalGrimoire][PLAYER] ========== REMOVING VFX ==========')
    local success, err = pcall(function()
        anim.removeVfx(self, VFX_ID)
    end)
    
    if success then
        print('[EternalGrimoire][PLAYER] ✅ VFX REMOVED SUCCESSFULLY')
    else
        print('[EternalGrimoire][PLAYER] ❌ VFX REMOVE FAILED: ' .. tostring(err))
    end
end

-- ----------------------------------------------------------------
-- Display
-- ----------------------------------------------------------------
local function showSpellList(spells)
    if not spells or #spells == 0 then
        return
    end
    
    ui.showMessage('The Eternal Grimoire rewrites itself:')
    for i = 1, math.min(#spells, 10) do
        ui.showMessage(string.format('  %d. %s', i, spells[i]))
    end
end

-- ----------------------------------------------------------------
-- Engine handlers
-- ----------------------------------------------------------------
local function onUpdate(dt)
    pollAcc = pollAcc + dt
    if pollAcc < POLL_INTERVAL then return end
    pollAcc = 0
    
    local hasNow = hasGrimoireInInventory()
    local isEquipped = isGrimoireEquipped()
    
    print('[EternalGrimoire][PLAYER] Poll tick: hasNow=' .. tostring(hasNow) .. ', hadGrim=' .. tostring(hadGrim) .. ', isEquipped=' .. tostring(isEquipped))
    
    -- Check for equipped state changes
    if isEquipped and not wasEquipped then
        print('[EternalGrimoire][PLAYER] >>> GRIMOIRE EQUIPPED <<<')
        addGrimoireVfx()
    elseif not isEquipped and wasEquipped then
        print('[EternalGrimoire][PLAYER] >>> GRIMOIRE UNEQUIPPED <<<')
        removeGrimoireVfx()
    end
    
    wasEquipped = isEquipped
    
    -- Only log on state change (pickup or drop)
    if hasNow and not hadGrim then
        print('[EternalGrimoire][PLAYER] >>> GRIMOIRE PICKED UP <<<')
        ui.showMessage('You feel the Grimoire pulse with power...')
        core.sendGlobalEvent('EG_GrimoirePickedUp', {})
    elseif not hasNow and hadGrim then
        print('[EternalGrimoire][PLAYER] >>> GRIMOIRE DROPPED <<<')
        ui.showMessage('The Grimoire slips from your grasp...')
        removeGrimoireVfx()
        core.sendGlobalEvent('EG_GrimoireDropped', {})
    end
    
    hadGrim = hasNow
end

local function onSave()
    return { 
        hadGrim = hadGrim,
        wasEquipped = wasEquipped
    }
end

local function onLoad(data)
    print('[EternalGrimoire][PLAYER] onLoad called')
    if data then
        hadGrim = data.hadGrim or false
        wasEquipped = data.wasEquipped or false
        
        if wasEquipped then
            addGrimoireVfx()
        end
    else
        hadGrim = false
        wasEquipped = false
    end
    print('[EternalGrimoire][PLAYER] Loaded state: hadGrim=' .. tostring(hadGrim) .. ', wasEquipped=' .. tostring(wasEquipped))
end

-- ----------------------------------------------------------------
-- Event handlers
-- ----------------------------------------------------------------
local function onEvent(name, data)
    if name == 'EG_GrimoireActiveConfirm' then
        ui.showMessage('The Grimoire floods your mind. New power surges through you.')
        
    elseif name == 'EG_PendingRestNotify' then
        ui.showMessage('As the Grimoire leaves your grasp, your spells scatter. Wait 24 hours.')
        
    elseif name == 'EG_SpellsRestored' then
        ui.showMessage('Your memories crystallize. Your spells return.')
        
    elseif name == 'EG_SpellsRefreshed' then
        showSpellList(data and data.spells or {})
    end
end

-- ----------------------------------------------------------------
-- Export
-- ----------------------------------------------------------------
print('[EternalGrimoire][PLAYER] ========== REGISTERING HANDLERS ==========')

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onSave   = onSave,
        onLoad   = onLoad,
    },
    eventHandlers = {
        EG_GrimoireActiveConfirm = onEvent,
        EG_PendingRestNotify     = onEvent,
        EG_SpellsRestored        = onEvent,
        EG_SpellsRefreshed       = onEvent,
    },
}