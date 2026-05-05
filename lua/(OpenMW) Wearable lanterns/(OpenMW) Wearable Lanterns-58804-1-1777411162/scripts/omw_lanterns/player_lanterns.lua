local self    = require('openmw.self')
local types   = require('openmw.types')
local anim    = require('openmw.animation')
local ui      = require('openmw.ui')
local async   = require('openmw.async')
local camera  = require('openmw.camera')
local storage = require('openmw.storage')
local input   = require('openmw.input')
local I       = require('openmw.interfaces')

local Actor = types.Actor
local MD    = { first = camera.MODE.FirstPerson, third = camera.MODE.ThirdPerson }

local lanternsListIndex = storage.playerSection('Settings_tt_wearlanterns_cycle')
local waistBoneOwner   = storage.playerSection('Settings_tt_wearlanterns')
local lanternsState    = storage.playerSection('Settings_tt_wearlanterns_state')

local cam     = camera.getMode()
local devMode = false

local VFX_ID     = 'visibleLanterns'
local vfxLanterns = { loop = true, useAmbientLight = false, vfxId = VFX_ID }
local LIGHT_SPELL_ID = "fx_lanternlight"  

local showLanterns        = lanternsState:get('showLanterns') or false
local LanternsKeyWasDown  = false
local LvariantKeyWasDown = false
local debounceCounter    = 0

local counter   = math.random(3, 20)
local refresh   = true
local newEquip  = false
local useHelper = false
local lastSkins = nil

local function debug(m)
    if devMode then print(m); ui.showMessage(m) end
end

local function getLanternsIndex()  return lanternsListIndex:get('cycleIndex') or 1 end
local function setLanternsIndex(n) lanternsListIndex:set('cycleIndex', n) end

local function claimWaistBone() waistBoneOwner:set('owner', 'lanterns') end
local function waistIsOurs()
    local owner = waistBoneOwner:get('owner')
    return owner == nil or owner == 'lanterns'
end

local function buildStemMap()
    local stemMap = {}
    for _, item in ipairs(Actor.inventory(self):getAll()) do
        local ok, rec = pcall(function() return item.type.records[item.recordId] end)
        if ok and rec and rec.model then
            local path = rec.model:lower()
            path = path:gsub('_gnd%.nif$', ''):gsub('%.nif$', '')
            local folder = path:match('^(.*[/\\])') or ''
            local fname  = path:match('([^/\\]+)$') or path
            stemMap[fname] = folder .. fname .. '_skins.nif'
        end
    end
    return stemMap
end

local lanternsStemList = {
   'Light_Ashl_Lantern_01',
   'Light_Ashl_Lantern_02',
   'Light_Ashl_Lantern_03',
   'Light_Ashl_Lantern_04',
   'Light_Ashl_Lantern_05',
   'Light_Ashl_Lantern_06',
   'Light_Ashl_Lantern_07',
   'Light_Com_Lantern_01',
   'Light_Com_Lantern_02',
   'Light_De_Lantern_01',
   'Light_De_Lantern_02',
   'Light_De_Lantern_03',
   'Light_De_Lantern_04',
   'Light_De_Lantern_05',
   'Light_De_Lantern_06',
   'Light_De_Lantern_07',
   'Light_De_Lantern_08',
   'Light_De_Lantern_09',
   'Light_De_Lantern_10',
   'Light_De_Lantern_11',
   'Light_De_Lantern_12',
   'Light_De_Lantern_13',
   'Light_De_Lantern_14',
   'Light_MH_Rope_Lantern',
   'Light_paper_lantern_01',
   'Light_paper_lantern_02',
   'Light_paper_lantern_off'
}

local function getAvailableLanterns()
    local stemMap   = buildStemMap()
    local available = {}

    for _, stem in ipairs(lanternsStemList) do
        local skinsPath = stemMap[stem:lower()]
        if skinsPath then
            available[#available + 1] = { stem = stem, skins = skinsPath }
        end
    end
    return available
end

local function applyLanternBuff()
    Actor.spells(self):add(LIGHT_SPELL_ID)
    debug('Lantern buff applied: ' .. LIGHT_SPELL_ID)
end

local function removeLanternBuff()
    Actor.spells(self):remove(LIGHT_SPELL_ID)
    debug('Lantern buff removed: ' .. LIGHT_SPELL_ID)
end

local function setShowLanterns(val)
    local availLanterns = getAvailableLanterns()
    
    if val and #availLanterns == 0 then
        debug('Lanterns: no lanterns available in inventory')
        return
    end

    showLanterns = val
    lanternsState:set('showLanterns', val)

    if val then
        applyLanternBuff()  
    else
        removeLanternBuff()  
    end
end

local function scanInv(reset)
    newEquip = false
    refresh  = false


    local availLanterns = getAvailableLanterns()
    local lIdx         = getLanternsIndex()
    if lIdx > #availLanterns then lIdx = math.max(#availLanterns, 1) end
    local activeSkins  = availLanterns[lIdx] and availLanterns[lIdx].skins or nil

    local changed = (activeSkins ~= lastSkins) or reset
    if not changed then return end
    lastSkins = activeSkins

    debug('lanterns: remove vfx')
    anim.removeVfx(self, VFX_ID)

    local shouldShowVfx = showLanterns and activeSkins and cam ~= MD.first and waistIsOurs()
    if shouldShowVfx then
        debug('lanterns vfx: ' .. activeSkins)
        vfxLanterns.boneName = 'waist'
        anim.addVfx(self, activeSkins, vfxLanterns)
    end

    if showLanterns and #availLanterns > 0 and activeSkins then
        applyLanternBuff()
    else
        removeLanternBuff()
    end
end

local function onFrame(dt)
    if debounceCounter > 0 then
        debounceCounter = debounceCounter - 1
        return
    end

    local keyDown = input.getBooleanActionValue('wearlamp')  
    if keyDown and not LanternsKeyWasDown then
        setShowLanterns(not showLanterns)  
        if showLanterns then claimWaistBone() end
        counter = 1
        refresh = true
        debounceCounter = 0
        debug('Lanterns VFX: ' .. (showLanterns and 'ON' or 'OFF'))
    end
    LanternsKeyWasDown = keyDown

    local lVarKeyDown = input.getBooleanActionValue('changelamp')  
    if lVarKeyDown and not LvariantKeyWasDown then
        local availLanterns = getAvailableLanterns()
        if #availLanterns > 0 then
            setShowLanterns(true)
            claimWaistBone()
            local cur = getLanternsIndex()
            if cur > #availLanterns then cur = #availLanterns end
            local nxt = cur % #availLanterns + 1
            setLanternsIndex(nxt)
            counter = 1
            refresh = true
            debounceCounter = 15
            debug('Lanterns: ' .. availLanterns[nxt].stem .. ' (' .. nxt .. '/' .. #availLanterns .. ')')
        else
            debug('Lanterns: none available in inventory')
        end
    end
    LvariantKeyWasDown = lVarKeyDown

    if newEquip then scanInv(refresh) end
    counter = counter - 1
    if counter > 0 then return end
    counter = 20
    if refresh or not useHelper then scanInv(refresh) end
end


local function onUpdate(dt)
    if dt == 0 then return end

    local prevCam = cam
    cam = camera.getMode()

    if prevCam ~= cam then
        counter = 3
        refresh = true
    end
end

local function onActive()
    counter = 3
    refresh = true
end

return {
    engineHandlers = { onUpdate = onUpdate, onFrame = onFrame, onActive = onActive },
    eventHandlers  = {
        UiModeChanged = function(e)
            local uiModes = {
                [I.UI.MODE.Rest]     = true,
                [I.UI.MODE.Training] = true,
                [I.UI.MODE.Travel]   = true,
            }
            if uiModes[e.oldMode] then
                counter = 3
                refresh = true
            end
        end,
        olhInitialized = function()
            useHelper = true
            I.luaHelper.eventRegister('equipped',   function() newEquip = true end)
            I.luaHelper.eventRegister('unequipped', function() newEquip = true end)
        end,
        vfxRemoveAll = function()
            counter = math.random(11, 16)
            refresh = true
        end,
    },
}
