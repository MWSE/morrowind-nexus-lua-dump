-- Zerkish Hotkeys Improved - zhi_player.lua
-- main player script

-- openmw modules
local core  = require('openmw.core')
local I     = require('openmw.interfaces')
local ui    = require('openmw.ui')
local util  = require('openmw.util')
local Actor = require('openmw.types').Actor
local types = require('openmw.types')
local self  = require('openmw.self')
local async = require('openmw.async')
local input = require('openmw.input')
local animation = require('openmw.animation')
local ambient = require('openmw.ambient')
local storage = require('openmw.storage')

local auxUi = require('openmw_aux.ui')

-- ZHI modules
local ZHIUtil           = require('scripts.ZerkishHotkeysImproved.zhi_util')
local ZHIUI             = require('scripts.ZerkishHotkeysImproved.zhi_ui')
local ZHIUIMagic        = require('scripts.ZerkishHotkeysImproved.zhi_ui_magic')
local ZHIUIMain         = require('scripts.ZerkishHotkeysImproved.zhi_ui_main')
local ZHIUIInventory    = require('scripts.ZerkishHotkeysImproved.zhi_ui_inventory')
local ZHIHotbarData     = require('scripts.ZerkishHotkeysImproved.zhi_hotbardata')
local ZHIHotbarHUD      = require('scripts.ZerkishHotkeysImproved.zhi_hotbarhud')
local ZHITooltip        = require('scripts.ZerkishHotkeysImproved.zhi_tooltip')

local ZMUI = require('scripts.ZModUtils.UI')
local ZMUtility = require('scripts.ZModUtils.Utility')

local ZHI_SAVEDATA_VERSION = 1

local ZHI_VERSION = 'b1.64'

local ZHI_WINDOWS = {
    Main = 1,
    MagicSelection = 2,
    InventorySelection =  3,
    HotkeySelect = 4,
    FirstTimePopup = 5,
    QuickKeyMenuPopup = 6,
    Tooltip = 7,
}

local ZHI_MAXHOTBARS = 6
local BG_FADE_ALPHA = 0.60
local FG_FADE_ALPHA = 0.85
local TOOLTIP_OFFSET = util.vector2(10, 15)

local ZHI_MODIFIERS = {
    None = 1,
    LeftShift = 2,
    LeftAlt = 3,
    LeftCtrl = 4,
    Mouse3 = 5,
    Mouse4 = 6,
    Mouse5 = 7,
}

local zhiWindows = {}

local ZHISaveData_V1 = {
    version = 1,

    -- Handling interaction with the default quick keys menu
    shouldSuppressStandardQuickKeys = false,
    onCloseQuickKeyMenuFirstTimeFlag = false,

    --hotbars = nil,
}

local ZHISaveData = ZHISaveData_V1

ZHIL10n = core.l10n('ZerkishHotkeysImproved', 'en')

local firstTimeMessage = ZHIL10n('in_game_firsttime_notification')
-- [[Welcome to Zerkish Improved Hotkeys (ZHI)!

-- This message is shown since you have not opened the 'QuickKeys' Menu on this save since you installed ZHI.
-- Please open the QuickKeys Menu (Default: F1), and make sure all QuickKeys are removed, then save the game.

-- This is required for ZHI to work properly due to some OpenMW Script Limitations.

-- The next time you open the QuickKeys Menu it will be replaced by ZHI. 
-- You can tell ZHI to show the default menu again in the Script Settings.
-- (Disabled if Compatibility Mode is on).

-- You can permanently disable this notification for all saves in Script Settings.

-- NOTE: If you are having problems and you are running other UI Mods,
-- Please try enabling "Compatibility Mode" in settings/misc and reload.

-- Thanks for using ZHI! // Zerkish]]

local quickKeyPopupMessage = ZHIL10n('in_game_quickkey_popup')
-- [[ZHI will replace this window once it's been closed.
-- Please clear all quickkeys.]]

-- temporary settings variables
local sForceStandardUI = false
local sAutoStanceChange = true
local sDisableFirstTimeNotification = false
local sExtendedTooltipsEnabled = false
local sShowHotbarHUD = false
local sCompatibilityMode = false
local sStanceQueue = false
local sStanceQueueGracePeriod = 0.2
local sWindowAnchor = util.vector2(0.5, 0.5)
local sEnableItemConditionCheck = false

local showFirstTimeMessageAfterChargen = false

local hotbarSettings = { }
for i=1, ZHI_MAXHOTBARS do
    hotbarSettings[i] = {
        -- default is 1, 2, 3 enabled
        enabled = i < 4,
        modifier = nil
    }
end


local function loadDataV1(data)
    -- care needs to be given to not override values that aren't set.
    ZHISaveData.shouldSuppressStandardQuickKeys = data.shouldSuppressStandardQuickKeys ~= nil and data.shouldSuppressStandardQuickKeys or ZHISaveData.shouldSuppressStandardQuickKeys
    ZHISaveData.onCloseQuickKeyMenuFirstTimeFlag = data.onCloseQuickKeyMenuFirstTimeFlag ~= nil and data.onCloseQuickKeyMenuFirstTimeFlag or ZHISaveData.onCloseQuickKeyMenuFirstTimeFlag

    print('ZHI LOAD HOTBARS V1')
    ZHIHotbarData.loadHotbarData(data)
end

local function destroyWindow(ident)
    if zhiWindows[ident] then
        auxUi.deepDestroy(zhiWindows[ident])
        zhiWindows[ident] = nil
    end
end

local function isWindowOpen(ident)
    return zhiWindows[ident] ~= nil
end

local function isAnyWindowOpen()
    local value = false
    for i=1,#ZHI_WINDOWS do
        if zhiWindows[i] then
            print('ZHI isAnyWindowOpen open', i)
            value = true
        end
    end
    return value
end

local function openQuickKeyPopup()
    assert(not isWindowOpen(ZHI_WINDOWS.QuickKeyMenuPopup))

    local message = quickKeyPopupMessage
    if sForceStandardUI then
        message = ZHIL10n('in_game_quickkey_popup_notfirst')
    end

    zhiWindows[ZHI_WINDOWS.QuickKeyMenuPopup] = ZHIUI.createMessageBox(ZHIL10n('in_game_popup_header'), message, false, false)
    zhiWindows[ZHI_WINDOWS.QuickKeyMenuPopup].layout.props.relativePosition = util.vector2(0.5, 0.70)
    zhiWindows[ZHI_WINDOWS.QuickKeyMenuPopup]:update()
end

local function closeAllWindows()
    local hasClosedWindows = false
    for k, v in pairs(zhiWindows) do
        print('ZHI closeAllWindows - closing (' .. tostring(k) .. ')')
        if zhiWindows[k] then
            auxUi.deepDestroy(zhiWindows[k])
            --zhiWindows[k]:destroy()
            zhiWindows[k] = nil
            hasClosedWindows = true
        end
    end

    ZHITooltip.updateTooltip(nil, nil)

    -- In compatibility mode we try to behave like the other, sane, windows.
    if sCompatibilityMode and hasClosedWindows then
        I.UI.setMode()
    elseif hasClosedWindows then
        -- This prevents us from being in a broken UI state.
        -- for some reason, the ui can break while reloading lua code, doing this appears to fix the issue.
        I.UI.setMode('Interface', {})
        I.Controls.overrideUiControls(false)
        I.UI.setMode()
    end
end

local function openFirstTimePopup()
    assert(isWindowOpen(ZHI_WINDOWS.FirstTimePopup) == false)

    local resetUI = I.UI.getMode() == nil

    if resetUI then
        if not sCompatibilityMode then
            I.Controls.overrideUiControls(true)
        end
        I.UI.setMode('Interface', { windows = {}})
    end

    local callbacks = {
        okButton = closeAllWindows
    }
    
    zhiWindows[ZHI_WINDOWS.FirstTimePopup] = ZHIUI.createMessageBox(ZHIL10n('in_game_popup_header'), firstTimeMessage, true, false, callbacks)
end

local function findUIHotkey(hotbar, key)
    --print('findUIHotkey')
    if not isWindowOpen(ZHI_WINDOWS.Main)  then
        return nil
    end

    if (zhiWindows[ZHI_WINDOWS.Main].layout.content == nil) then
        return
    end

    local ident = ZHIUtil.getHotkeyIdentifier(hotbar, key)
    local hotkeyLayout = ZMUtility.findLayoutByNameRecursive(zhiWindows[ZHI_WINDOWS.Main].layout.content, ident)

    if not hotkeyLayout then
        print(string.format('findUIHotkey(%d, %d) = %s  (ident : %s)', hotbar, key, tostring(hotkeyLayout), ident))
    end
    return hotkeyLayout
end

local handToHandTexture = ui.texture({ path = 'icons/k/stealth_handtohand.dds' })

local function updateHotkeyUI(hotkeyLayout, hotkeyData)
    if not hotkeyLayout then
        return
    end

    -- check for the hardcoded hand to hand
    if hotkeyData.hotbar.hotbarNum == 1 and hotkeyData.hotbar.hotbarKey == 10 then
        ZHIUI.setHotkeyIcon(hotkeyLayout, handToHandTexture, nil)
        return
    end

    local data = hotkeyData.data
    if not data then
        return
    end

    local item = data.item
    local spell = data.spell

    if not data and (not (item or spell)) then
        ZHIUI.resetHotkeyUI(hotkeyLayout)
    else
        ZHIUI.setHotkeyFromData(hotkeyLayout, hotkeyData)
    end
end

local function updateHotbarsUI()
    ZHIHotbarData.foreachBarAndKey(function(hotbar, key, data)
        updateHotkeyUI(findUIHotkey(hotbar, key), data)
    end)
    I.ZHI.updateUI()
end

local function onReceiveMagicHotkeyResult(hotbar, key, result)
    I.ZHI.setMainWindowAlpha(FG_FADE_ALPHA)

    if result and result.resultType == ZHIUIMagic.RESULT_TYPE.PowerOrSpell then
        ZHIHotbarData.setSpellHotkey(hotbar, key, result.spell)
    elseif result and result.resultType == ZHIUIMagic.RESULT_TYPE.Item then
        ZHIHotbarData.setItemHotkey(hotbar, key, result.item, result.item.type.records[result.item.recordId].enchant)
    end

    updateHotbarsUI()
    if sShowHotbarHUD then
        ZHIHotbarHUD.updateHUD()
    end

    destroyWindow(ZHI_WINDOWS.MagicSelection)
    ZHITooltip.updateTooltip(nil, nil)
end

local function onReceiveInventoryResult(hotbar, key, item)
    I.ZHI.setMainWindowAlpha(FG_FADE_ALPHA)

    if item then
        ZHIHotbarData.setItemHotkey(hotbar, key, item)
        updateHotbarsUI()
        if sShowHotbarHUD then
            ZHIHotbarHUD.updateHUD()
        end
    end

    destroyWindow(ZHI_WINDOWS.InventorySelection)
    ZHITooltip.updateTooltip(nil, nil)
end

-- Open the Magic Selection Window
local function openMagicSelectWindow (hotbar, key)
    assert(not isWindowOpen(ZHI_WINDOWS.MagicSelection))

    local callbacks = {
        onSelectItem = ZMUtility.bindFunction(onReceiveMagicHotkeyResult, hotbar, key),
        onFocusLossItem = function(layout)
            ZHITooltip.updateTooltip(nil, nil)
            I.ZHI.updateUI()
        end,
        onMouseMove = function(mEvent, layout)
            local data = {}
            if layout.userData.resultType == ZHIUIMagic.RESULT_TYPE.PowerOrSpell then
                data.spell = layout.userData.spell
            elseif layout.userData.resultType == ZHIUIMagic.RESULT_TYPE.Item then
                data.item = {
                    itemId = layout.userData.item.id,
                    recordId = layout.userData.item.recordId,
                    itemType = layout.userData.item.type,
                }
            end

            if isWindowOpen(ZHI_WINDOWS.MagicSelection) then
                ZHITooltip.updateTooltip(mEvent.position + TOOLTIP_OFFSET, data)    
            else
                ZHITooltip.updateTooltip(nil, nil)
            end
        end,
    }

    zhiWindows[ZHI_WINDOWS.MagicSelection] = ZHIUIMagic.createMagicSelectionWindow(callbacks)
    I.ZHI.setMainWindowAlpha(FG_FADE_ALPHA)
end

local function openInventorySelectWindow(hotbar, key)
    assert(not isWindowOpen(ZHI_WINDOWS.InventorySelection))
    I.ZHI.setMainWindowAlpha(FG_FADE_ALPHA)
    local callbacks = {
        onSelectItem = ZMUtility.bindFunction(onReceiveInventoryResult, hotbar, key),
        onFocusLossItem = function(layout)
            --ZHIUIInventory.hideTooltip(zhiWindows[ZHI_WINDOWS.InventorySelection], layout)
            ZHITooltip.updateTooltip(nil, nil)
            I.ZHI.updateUI()
        end,
        onMouseMove = function(mEvent, layout)
            local data = {
                item = {
                    itemId = layout.userData.item.id,
                    recordId = layout.userData.item.recordId,
                    itemType = layout.userData.item.type,
                }
            }
            if isWindowOpen(ZHI_WINDOWS.InventorySelection) then
                ZHITooltip.updateTooltip(mEvent.position + TOOLTIP_OFFSET, data)
            else
                ZHITooltip.updateTooltip(nil, nil)
            end
        end,
    }
    zhiWindows[ZHI_WINDOWS.InventorySelection] = ZHIUIInventory.createInventorySelectionWindow(callbacks)
end

local function onHotkeySelectMenuChoice(hotbar, key, result)
    destroyWindow(ZHI_WINDOWS.HotkeySelect)

    if result == 'inventory' then
        print('ZHI opening inventory menu')
        openInventorySelectWindow(hotbar, key)
        I.ZHI.setMainWindowAlpha(BG_FADE_ALPHA)
    elseif result == 'magic' then
        print('ZHI opening magic menu')
        openMagicSelectWindow(hotbar, key)
        I.ZHI.setMainWindowAlpha(BG_FADE_ALPHA)
    elseif result == 'delete' then
        print('ZHI delete hotkey')
        local hkData = ZHIHotbarData.getHotkeyData(hotbar, key)
        ZHIHotbarData.resetHotkeyData(hkData)
        local hotkeyLayout = findUIHotkey(hotbar, key)
        updateHotkeyUI(hotkeyLayout, hkData)
        --updateHotbarsUI()
        I.ZHI.setMainWindowAlpha(FG_FADE_ALPHA)
        I.ZHI.updateUI()

        if sShowHotbarHUD then
            ZHIHotbarHUD.updateHUD()
        end
    else
        I.ZHI.setMainWindowAlpha(FG_FADE_ALPHA)
        -- cancel, do nothing
    end
end

local function shouldIgnoreHotkeyInput(hotbar, hotkey)
    if hotbar == 1 and hotkey == 10 then
        return true
    end

    if isWindowOpen(ZHI_WINDOWS.MagicSelection) or isWindowOpen(ZHI_WINDOWS.InventorySelection) or isWindowOpen(ZHI_WINDOWS.HotkeySelect) then
        return true
    end

    return not hotbarSettings[hotbar].enabled
end

local function onHotkeySelectPressed(mouseEvent, layout)
    assert(layout.userData ~= nil)
    if shouldIgnoreHotkeyInput(layout.userData.hotbar, layout.userData.hotkey) then
        return
    end
    I.ZHI.setMainWindowAlpha(BG_FADE_ALPHA)
    zhiWindows[ZHI_WINDOWS.HotkeySelect] = ZHIUIMain.createHotkeySelectionWindow(ZMUtility.bindFunction(onHotkeySelectMenuChoice, layout.userData.hotbar, layout.userData.hotkey))
    --I.ZHI.updateUI()
    ZHITooltip.updateTooltip(nil, nil)
end

local function onClearAllHotkeysPressed(mEvent, layout)
    ZHIHotbarData.foreachBarAndKey(function(hotbar, key, data) 
        ZHIHotbarData.resetHotkeyData(data)
    end)
    updateHotbarsUI()
    if sShowHotbarHUD then
        ZHIHotbarHUD.updateHUD()
    end
end

local function openMainWindow()
    assert(not isWindowOpen(ZHI_WINDOWS.Main))
    if isWindowOpen(ZHI_WINDOWS.Main) then
        print("ZHI mainWindow already open")
        return
    end

    if isAnyWindowOpen() then
        print("ZHI WARNING openMainWindow - has previously opened windows.")
    end

    local callbacks = {
        onHotkeyPressed = onHotkeySelectPressed,
        onClearAllPressed = onClearAllHotkeysPressed,
        onOkPressed = function (mEvent, layout) 
            closeAllWindows()
        end,
        onHotkeyFocusLoss = function(mEvent, layout)
            ZHIUIMain.hideTooltipForHotkey(zhiWindows[ZHI_WINDOWS.Main], layout)
        end,
        onHotkeyMouseMove = function(mEvent, layout)
            if shouldIgnoreHotkeyInput(layout.userData.hotbar, layout.userData.hotkey) then
                ZHITooltip.updateTooltip(nil, nil)
                return
            end
            ZHIUIMain.showTooltipForHotkey(layout, mEvent.position + TOOLTIP_OFFSET)
        end,
    }

    zhiWindows[ZHI_WINDOWS.Main] = ZHIUIMain.createMainWindow(callbacks)
    I.ZHI.setMainWindowAlpha(FG_FADE_ALPHA)
    updateHotbarsUI()

    -- Allow other mods to control the UI in compatibility mode.
    if not sCompatibilityMode then
        I.Controls.overrideUiControls(true)
        I.UI.setMode('Interface', {windows = {}})
    end
end

local function shouldSuppressDefaultQuickKeysMenu()
    --return false
    return ZHISaveData.shouldSuppressStandardQuickKeys and (not sForceStandardUI)
end

local function setOverrideDefaultQuickKeyMenu(value)
    ZHISaveData.shouldSuppressStandardQuickKeys = value
    local settings = storage.playerSection('SettingsZHIAAMain')
    settings:set('force_standard_ui', not value)
end

local function compatReplaceDefaultMenu()
    print('ZHI compat replace QuickKeys Menu')
    I.UI.registerWindow('QuickKeys', openMainWindow, closeAllWindows)
end

local function onQuickKeyMenuHandler()
    -- For compat mode we just ensure the mod state is consistent and rely on replacing the Window.
    if sCompatibilityMode then
        print('ZHI onQuickKeyMenuHandler - Compatibility')
        if ZHISaveData.onCloseQuickKeyMenuFirstTimeFlag == false then
            async:newUnsavableSimulationTimer(0.25, function()
                print("ZHI set firstTimeQuickKeysMenuFlag")
                setOverrideDefaultQuickKeyMenu(true)
                ZHISaveData.onCloseQuickKeyMenuFirstTimeFlag = true
                compatReplaceDefaultMenu()
                ui.showMessage('ZHI has now replaced QuickKeysMenu. Press QuickKeyMenu Key to Open ZHI.')
            end)
        end
        return true
    end

    -- -- This means the user OPENED the QuickKeys Menu
    local hasOpened = I.UI.getMode() == 'QuickKeysMenu'

    -- If the user opened the ui
    if hasOpened then
        -- and we should suppress the default menu
        if shouldSuppressDefaultQuickKeysMenu() then
            I.UI.setMode() -- clear all UI.
            openMainWindow()
        else
            openQuickKeyPopup()

            -- HACK because we can't rely on the user to close with the F1 menu.
            -- We will also run ONE update after before the game pauses, so we can't immediately check in onUpdate.
            async:newUnsavableSimulationTimer(0.01, function()
                print("ZHI set firstTimeQuickKeysMenuFlag")
                setOverrideDefaultQuickKeyMenu(true)
                destroyWindow(ZHI_WINDOWS.QuickKeyMenuPopup)
                ZHISaveData.onCloseQuickKeyMenuFirstTimeFlag = true
                ui.showMessage(ZHIL10n('in_game_message_replace_notification'))
            end)
        end
    elseif isWindowOpen(ZHI_WINDOWS.Main) then
        closeAllWindows()
    end
end

local function getHotbarFromCurrentModifier()
    for i=2, ZHI_MAXHOTBARS do
        --print('enabled', hotbarSettings[i].enabled)
        if hotbarSettings[i].enabled then
            --print('modifier', hotbarSettings[i].modifier)
            if hotbarSettings[i].modifier == ZHI_MODIFIERS.LeftShift then
                if input.isKeyPressed(input.KEY.LeftShift) then return i end
            elseif hotbarSettings[i].modifier == ZHI_MODIFIERS.LeftAlt then
                if input.isKeyPressed(input.KEY.LeftAlt) then return i end
            elseif hotbarSettings[i].modifier == ZHI_MODIFIERS.LeftCtrl then
                if input.isKeyPressed(input.KEY.LeftCtrl) then return i end
            elseif hotbarSettings[i].modifier == ZHI_MODIFIERS.Mouse3 then
                if input.isMouseButtonPressed(2) then return i end
            elseif hotbarSettings[i].modifier == ZHI_MODIFIERS.Mouse4 then
                if input.isMouseButtonPressed(4) then return i end
            elseif hotbarSettings[i].modifier == ZHI_MODIFIERS.Mouse5 then
                if input.isMouseButtonPressed(5) then return i end
            end
        end
    end

    return 1
end

local function getQuickKeyItem(recordId, itemId)
    local itemObject = I.ZHI.getSpecificInventoryItem(recordId, itemId)
    if itemObject and sEnableItemConditionCheck then
        local itemData = types.Item.itemData(itemObject)
        if itemData and itemData.condition and itemData.condition <= 1e-4 then
            itemObject = I.ZHI.getFirstInventoryItem(recordId, sEnableItemConditionCheck)
        end
    end

    if not itemObject then
        itemObject = I.ZHI.getFirstInventoryItem(recordId, sEnableItemConditionCheck) -- Actor.inventory(self):find(recordId)
    end
    
    return itemObject
end

local stanceStrings = {}
stanceStrings[Actor.STANCE.Weapon] = 'Weapon'
stanceStrings[Actor.STANCE.Nothing] = 'Nothing'
stanceStrings[Actor.STANCE.Spell] = 'Spell'

local function canPlayerChangeStance()
    local blacklist = {
        'weapononehand',
        'weapontwohand',
        'weapontwowide',
        'handtohand',
        'spellcast',
        'shortbladeonehand',
        'bluntonehand',
        'blunttwohand',
        'bowandarrow',
        'crossbow',
        'throwweapon',
    }

    local anim = animation.getActiveGroup(self, animation.BONE_GROUP.RightArm)

    for i=1,#blacklist do
        if anim == blacklist[i] then
            --print('Stance Rejected', anim)
            return false
        end
    end

    --print('Stance Allowed: ', anim)

    return true
end

local queuedStance = nil
local queuedStanceTimer = 0.0

-- How many frames after we should be able to switch that we have tried
local queuedStanceAttempts = 0
local queuedStanceAttemptsMax = 5

local function queueStanceChange(stance)
    print('Queuing stance change', stanceStrings[stance])
    queuedStance = stance
    queuedStanceTimer = 0.0
    queuedStanceAttempts = 0
end

local function sendZHIHotkeyEvent(spell, item, itemEnchant)
    if (not spell) and (not item) and (not itemEnchant) then return end

    local data = {}
    if spell then
        data.spell = {
            id = spell.id
        }
    elseif item then
        data.item = {
            id = item.id,
            recordId = item.recordId,
            typeName = tostring(item.type),
        }
    elseif itemEnchant then
        data.itemEnchant = {
            id = itemEnchant.id,
            recordId = itemEnchant.recordId,
            typeName = tostring(itemEnchant.type),
        }
    end
    
    self:sendEvent('ZHI_HotkeySelectEvent', data)
end

local function sendZHIHotkeyEquipEvent(item, equipmentSlot)
    if (not item) then return end

    local data = {
        item = {
            id = item.id,
            typeName = tostring(item.type),
        },
        equipmentSlot = equipmentSlot,
    }

    self:sendEvent('ZHI_HotkeyEquipEvent', data)
end

local function setSelectedSpell(actor, spell)
    if (not actor) or (not spell) then
        print('ZHI setSelectedSpell', actor, spell)
        return
    end

    -- Send event to let other mods react to quick keys.
    sendZHIHotkeyEvent(spell, nil, nil)

    local current = Actor.getSelectedSpell(self)
    if (not current) or (current.id ~= spell.id) then 
        Actor.setSelectedSpell(actor, spell)
    end

    if sAutoStanceChange then
        -- StanceQueue implicitly handles delayed actions for stance changes.
        if sStanceQueue then
            queueStanceChange(Actor.STANCE.Spell)
        else
            -- If we have nothing equipped at all it turns into a delayed action.
            if (current == nil) then
                async:newUnsavableGameTimer(0.01, function() Actor.setStance(self, Actor.STANCE.Spell) end)
            else
                Actor.setStance(self, Actor.STANCE.Spell)
            end
        end
    end
end

local function setSelectedEnchantedItem(actor, itemObject)
    if (not actor) or (not itemObject) then
        print('ZHI setSelectedEnchantedItem', actor, itemObject)
        return
    end

    -- send event to let other mods react
    sendZHIHotkeyEvent(nil, nil, itemObject)

    local current = Actor.getSelectedEnchantedItem(actor)
    if (not current) or (current.id ~= itemObject.id) then
        Actor.setSelectedEnchantedItem(self, itemObject)
    end

    if sAutoStanceChange then
        if sStanceQueue then
            queueStanceChange(Actor.STANCE.Spell)
        else
            async:newUnsavableGameTimer(0.01, function() Actor.setStance(self, Actor.STANCE.Spell) end)
        end
    end
end

local function equipItemForActor(actor, itemObject, equipment, slot, isEnchantment)
    if (not actor) or (not itemObject) or (not equipment) or (not slot) then
        print('ZHI equipItemForActor', actor, itemObject, equipment, slot)
        return false
    end
    
    local shouldChangeStance = (not isEnchantment) and sAutoStanceChange and (slot == Actor.EQUIPMENT_SLOT.CarriedRight)
    shouldChangeStance = shouldChangeStance and Actor.getStance(self) ~= Actor.STANCE.Weapon

    if (not isEnchantment) then
        sendZHIHotkeyEvent(nil, itemObject, nil)
    end

    -- If the item is already equipped we don't send events or change anything.
    local current = equipment[slot]
    if (not current) or (current.id ~= itemObject.id) then
        equipment[slot] = itemObject

        -- If we're doing a stance change we don't want to play the weapon sound, cause it'll be played twice.
        local sounds = ZMUtility.Items.getSoundsForItem(itemObject)
        if (not shouldChangeStance) and sounds and sounds.equip then
            ambient.playSound(sounds.equip)
        end

        -- Send event to let other mods react to it if they want.
        sendZHIHotkeyEquipEvent(itemObject, slot)

        Actor.setEquipment(actor, equipment)
    end

    -- If it's an enchanted item we handle it will be handled later on.
    if shouldChangeStance then
        if sStanceQueue then
            queueStanceChange(Actor.STANCE.Weapon)
        else
            Actor.setStance(self, Actor.STANCE.Weapon)
        end
    end

    return true
end

local function onQuickKeyPressed(keyNum)
    local hotbar = getHotbarFromCurrentModifier()
    local hotkey = ZHIHotbarData.getHotkeyData(hotbar, keyNum)

    if hotkey and hotkey.data.spell then
        local spell = core.magic.spells.records[hotkey.data.spell.spellId]
        if spell then
            setSelectedSpell(self, spell)
        end
    elseif hotkey and hotkey.data.item then
        local itemObject = getQuickKeyItem(hotkey.data.item.recordId, hotkey.data.id)

        if itemObject then
            -- Equip the item
            local equipment = Actor.getEquipment(self)
            local equipmentSlot = ZMUtility.Items.getEquipmentSlotForItem(itemObject, self)
            if equipmentSlot then
                equipItemForActor(self, itemObject, equipment, equipmentSlot, hotkey.data.item.enchantment ~= nil)
            end

            -- If it's an enchantment
            if hotkey.data.item.enchantment then
                setSelectedEnchantedItem(self, itemObject)
            end

            -- Attempt to use the item if it's not equippable and it isn't selected as an enchantment.
            if (not equipmentSlot) and (not hotkey.data.item.enchantment) then
                if itemObject.count > 0 then
                    sendZHIHotkeyEvent(nil, itemObject, nil)
                    core.sendGlobalEvent("UseItem", { object = itemObject, actor = self })
                end
            end
        end
    end
end

local function setQuickMenuToggleEnabled(value)
    I.Settings.updateRendererArgument('SettingsZHIAAMain', 'force_standard_ui', {
        disabled = not value
    })
    if value == false then sForceStandardUI = false end
end

local function settingsListener(section, key)
    local sectionData = storage.playerSection(section)

    if not sectionData then return end

    -- for some reason nil key means 'all keys'

    if section == "SettingsZHIAAMain" then
        if key == nil or key == "force_standard_ui" then
            sForceStandardUI = sectionData:get('force_standard_ui')
            print('ZHI.sForceStandardUI = ', sForceStandardUI)
        end
        if key == nil or key == "auto_stance_change" then
            sAutoStanceChange = sectionData:get('auto_stance_change')
            print('ZHI.sAutoStanceChange = ', sAutoStanceChange)
        end
        if key == nil or key == "enable_stance_queue" then
            sStanceQueue = sectionData:get('enable_stance_queue')
            I.Settings.updateRendererArgument('SettingsZHIAAMain', 'stance_queue_grace', {
                disabled = not sStanceQueue,
            })
            print('ZHI.sStanceQueue = ', sStanceQueue)
        end
        if key == nil or key == "stance_queue_grace" then
            print('set grace')
            sStanceQueueGracePeriod = sectionData:get('stance_queue_grace')
            print('ZHI.sStanceQueueGracePeriod = ', sStanceQueueGracePeriod)
        end
        if key == nil or key == 'window_anchor_x' then
            sWindowAnchor = util.vector2(sectionData:get('window_anchor_x'), sWindowAnchor.y)
            print('ZHI.sWindowAnchor = ', sWindowAnchor)
        end
        if key == nil or key == 'window_anchor_y' then
            sWindowAnchor = util.vector2(sWindowAnchor.x, sectionData:get('window_anchor_y'))
            print('ZHI.sWindowAnchor = ', sWindowAnchor)
        end
    elseif section == 'SettingsZHIHotbarAAMain' then
        if key == nil or key == 'enable_hotbar_hud' then
            sShowHotbarHUD = sectionData:get('enable_hotbar_hud')
            print('ZHI.sShowHotbarHUD = ', sShowHotbarHUD)
            if not showFirstTimeMessageAfterChargen then
                ZHIHotbarHUD.setVisible(sShowHotbarHUD)
            end
        end
    elseif section == "SettingsZHIAAMisc" then
        if key == nil or key == "disable_firsttime_notifcation" then
            sDisableFirstTimeNotification = sectionData:get('disable_firsttime_notifcation')
            print('ZHI.sDisableFirstTimeNotification = ', sDisableFirstTimeNotification)
        end
        if key == nil or key == "extended_tooltips" then
            sExtendedTooltipsEnabled = sectionData:get('extended_tooltips')
            print('ZHI.sExtendedTooltipsEnabled = ', sExtendedTooltipsEnabled)
        end
        if key == nil or key == 'enable_ui_compat' then
            sCompatibilityMode = sectionData:get('enable_ui_compat')
            print('ZHI.sEnableItemConditionCheck = ', sCompatibilityMode)
        end        
        if key == nil or key == 'enable_item_cond_check' then
            sEnableItemConditionCheck = sectionData:get('enable_item_cond_check')
            print('ZHI.sEnableItemConditionCheck = ', sEnableItemConditionCheck)
        end
    end
end

local function modifierFromText(text)
    if text == ZHIL10n('setting_hotbar_modifier_lshift') then return ZHI_MODIFIERS.LeftShift end
    if text == ZHIL10n('setting_hotbar_modifier_lalt') then return ZHI_MODIFIERS.LeftAlt end
    if text == ZHIL10n('setting_hotbar_modifier_lctrl') then return ZHI_MODIFIERS.LeftCtrl end
    if text == ZHIL10n('setting_hotbar_modifier_mouse3') then return ZHI_MODIFIERS.Mouse3 end
    if text == ZHIL10n('setting_hotbar_modifier_mouse4') then return ZHI_MODIFIERS.Mouse4 end
    if text == ZHIL10n('setting_hotbar_modifier_mouse5') then return ZHI_MODIFIERS.Mouse5 end

    return ZHI_MODIFIERS.None
end

local function updateHotbarFromSettings(hotbarNum, section)
    local enabled = section:get(string.format('hotbar%d_enabled', hotbarNum))
    if enabled ~= nil then hotbarSettings[hotbarNum].enabled = enabled end

    local modifierTxt = section:get(string.format('hotbar%d_modifier', hotbarNum))
    if modifierTxt then
        hotbarSettings[hotbarNum].modifier = modifierFromText(modifierTxt)
    end
end

local function hotbarSettingsListener(section, key)
    local hotbar = tonumber(string.sub(section, #section, -1))
    updateHotbarFromSettings(hotbar, storage.playerSection(section))
end

local function loadHotbarSettings()
    for i=1, ZHI_MAXHOTBARS do
        local section = storage.playerSection(string.format('SettingsZHIHotbar%d', i))
        updateHotbarFromSettings(i, section)
    end
end

local function onToggleHUDHandler()
    if I.UI.isHudVisible() then
        ZHIHotbarHUD.setVisible(sShowHotbarHUD)
    else
        ZHIHotbarHUD.setVisible(false)
    end
end

local function onToggleStance(bound)
    if not sStanceQueue then
        return
    end

    local stance = Actor.getStance(self)

    -- If the player is currently unable to switch stances, queue it up instead.
    if not canPlayerChangeStance() then
        print(string.format('ZHI onToggleStance(%s) - Queuing, Current Stance: %s', stanceStrings[bound], stanceStrings[stance]))
        -- Player is in the right stance, but trying to get out of it.
        if stance == bound then
            queueStanceChange(Actor.STANCE.Nothing)
        else
            -- Player is in another stance, but can't switch to the desired stance
            queueStanceChange(bound)
        end
    else
         print(string.format('ZHI onToggleStance(%s) - Ignored, Current Stance: %s', stanceStrings[bound], stanceStrings[stance]))
    end

    -- If the player isn't blocked from stance changing we just don't do anything.
end

local function tryRegisterLayers()
    if ui.layers.indexOf('ZHI_POPUP') == nil then
        ui.layers.insertAfter('Windows', 'ZHI_POPUP', { interactive = true, })
    end

    -- Required because it won't take effect until next frame.
    local isZHIPopupRegistered = ui.layers.indexOf('ZHI_POPUP') ~= nil

    if isZHIPopupRegistered and ui.layers.indexOf('ZHI_POPUP_NO_INTERACT') == nil then
        ui.layers.insertAfter('ZHI_POPUP', 'ZHI_POPUP_NO_INTERACT', { interactive = false, })
    end

    -- Again, doesn't take effect until next frame.
    local isZHIPopupNoInteractRegistered = ui.layers.indexOf('ZHI_POPUP_NO_INTERACT') ~= nil

    print('ZHI tryRegisterLayers isZHIPopupRegistered', isZHIPopupRegistered)
    print('ZHI tryRegisterLayers isZHIPopupNoInteractRegistered', isZHIPopupNoInteractRegistered)

    return isZHIPopupRegistered and isZHIPopupNoInteractRegistered
end

return {
    interfaceName = 'ZHI',
    interface = {
        version = 2,

        ZHI_WINDOWS = ZHI_WINDOWS,
        MAX_HOTBARS = ZHI_MAXHOTBARS,

        getZHIVersionString = function()
            return ZHI_VERSION
        end,

        getPopupLayer = function()
            return 'Popup'
            --return 'ZHI_POPUP'
        end,

        getTooltipLayer = function()
            return 'Notification'
            --return 'ZHI_POPUP_NO_INTERACT'
        end,

        isItemCondCheckEnabled = function() return sEnableItemConditionCheck end,

        isWindowOpen = isWindowOpen,

        getActiveHotbar = getHotbarFromCurrentModifier,

        getSpecificInventoryItem = function(recordId, id)
            local inventory = Actor.inventory(self)
            if not inventory then return nil end

            local items = inventory:findAll(recordId)
            local item = nil

            --print('searching', recordId, id)
            for k, v in pairs(items) do
                if v.id == id then
                    return v
                end
            end

            return nil
        end,

        getFirstInventoryItem = function(recordId, checkCondition)
            local inventory = Actor.inventory(self)
            if not inventory then return nil end

            local items = inventory:findAll(recordId)
            local item = #items > 0 and items[1] or nil

            if item and checkCondition  then
                local itemData = types.Item.itemData(item)
                if itemData and itemData.condition and itemData.condition <= 1e-4 then
                    for k, v in pairs(items) do
                        if v then
                            local iData = types.Item.itemData(v)
                            if iData and iData.condition > 0 then
                                item = v
                                break
                            end
                        end
                    end
                end
            end

            return item
        end,

        setMainWindowAlpha = function(num)
            if isWindowOpen(ZHI_WINDOWS.Main) then
                zhiWindows[ZHI_WINDOWS.Main].layout.props.alpha = num
                zhiWindows[ZHI_WINDOWS.Main]:update()
            end
        end,

        -- Updates the relevant top level window for the Mods UI.
        updateUI = function()

            if (isWindowOpen(ZHI_WINDOWS.MagicSelection)) then
                zhiWindows[ZHI_WINDOWS.MagicSelection]:update()
            elseif isWindowOpen(ZHI_WINDOWS.InventorySelection) then
                zhiWindows[ZHI_WINDOWS.InventorySelection]:update()
            elseif isWindowOpen(ZHI_WINDOWS.HotkeySelect) then
                zhiWindows[ZHI_WINDOWS.HotkeySelect]:update()
            elseif isWindowOpen(ZHI_WINDOWS.FirstTimePopup) then
                zhiWindows[ZHI_WINDOWS.FirstTimePopup]:update()
            else
                for k, window in pairs(zhiWindows) do
                    if window then
                        window:update()
                    end
                end
            end
        end,

        playSound = function(soundId)
            ambient.playSound(soundId)
        end,

        isExtendedTooltipsEnabled = function()
            return sExtendedTooltipsEnabled
        end,

        getWindowAnchor = function()
            return sWindowAnchor
        end
    },

    eventHandlers = {
        -- ZHI_HotkeySelectEvent = function(data)
        --     print('ZHI_HotkeySelectEvent', data.spell, data.item, data.itemEnchant)
        --     if data.spell then
        --         print('Spell: ', data.spell.id)
        --     elseif data.item then
        --         print('Item', data.item.recordId, data.item.id, data.item.typeName)
        --     elseif data.itemEnchant then
        --         print('ItemEnchant', data.itemEnchant.recordId, data.itemEnchant.id, data.itemEnchant.typeName)
        --     end
        -- end,
        -- ZHI_HotkeyEquipEvent = function(data)
        --     print('ZHI_HotkeyEquipEvent', data.item)
        --     if data.item then
        --         print('Item', data.item.id, data.item.typeName)
        --     end            
        -- end,
        -- ZHI_HotkeyUseItemEvent = function(data)
        --     print('ZHI_HotkeyUseItemEvent', data.item.id)
        -- end,
    },

    engineHandlers = {

        onActive = function()
            print('ZHI ON ACTIVE', ZHI_VERSION)
            --tryRegisterLayers()

            -- Load Settings Early!
            local mainSettings = storage.playerSection('SettingsZHIAAMain')
            local miscSettings = storage.playerSection('SettingsZHIAAMisc')
            local hotbarSettings = storage.playerSection('SettingsZHIHotbarAAMain')

            settingsListener('SettingsZHIAAMain', nil)
            settingsListener('SettingsZHIAAMisc', nil)
            settingsListener('SettingsZHIHotbarAAMain', nil)

            -- sForceStandardUI = mainSettings:get('force_standard_ui')
            -- sAutoStanceChange = mainSettings:get('auto_stance_change')
            -- sDisableFirstTimeNotification = miscSettings:get('disable_firsttime_notifcation')
            -- sExtendedTooltipsEnabled = miscSettings:get('extended_tooltips')
            -- sCompatibilityMode = miscSettings:get('enable_ui_compat')
            -- sStanceQueue = mainSettings:get('enable_stance_queue')
            -- sStanceQueueGracePeriod = mainSettings:get('stance_queue_grace')
            -- sWindowAnchor = util.vector2(mainSettings:get('window_anchor_x'), mainSettings:get('window_anchor_y'))
            -- sShowHotbarHUD = hotbarSettings:get('enable_hotbar_hud')


            loadHotbarSettings()

            I.Settings.updateRendererArgument('SettingsZHIAAMain', 'stance_queue_grace', {
                disabled = not sStanceQueue,
            })

            if not (ZHISaveData.onCloseQuickKeyMenuFirstTimeFlag or sDisableFirstTimeNotification) then
                if types.Player.isCharGenFinished(self) then
                    openFirstTimePopup()
                else
                    -- Player is starting a new game, we need to delay the popup until they are finished with the intro.
                    print('ZHI Delay until chargen is complete')
                    showFirstTimeMessageAfterChargen = true
                end
            end

            setQuickMenuToggleEnabled(not sCompatibilityMode)
            if sCompatibilityMode then
                if ZHISaveData.onCloseQuickKeyMenuFirstTimeFlag then
                    compatReplaceDefaultMenu()
                end
            else
                setOverrideDefaultQuickKeyMenu(ZHISaveData.onCloseQuickKeyMenuFirstTimeFlag and (not sForceStandardUI))
            end

            input.registerTriggerHandler('QuickKeysMenu', async:callback(onQuickKeyMenuHandler))
            -- Register trigger handlers
            for i=1,9 do
                input.registerTriggerHandler(string.format('QuickKey%d', i), async:callback(ZMUtility.bindFunction(onQuickKeyPressed, i)))
            end

            input.registerTriggerHandler("ToggleHUD", async:callback(onToggleHUDHandler))

            input.registerTriggerHandler('ToggleWeapon', async:callback(ZMUtility.bindFunction(onToggleStance, Actor.STANCE.Weapon)))
            input.registerTriggerHandler('ToggleSpell', async:callback(ZMUtility.bindFunction(onToggleStance, Actor.STANCE.Spell)))

            mainSettings:subscribe(async:callback(settingsListener))
            miscSettings:subscribe(async:callback(settingsListener))
            hotbarSettings:subscribe(async:callback(settingsListener))

            for i=1,ZHI_MAXHOTBARS do
                local hbSettings = storage.playerSection(string.format("SettingsZHIHotbar%d", i))
                hbSettings:subscribe(async:callback(hotbarSettingsListener))
            end

            if sShowHotbarHUD and not showFirstTimeMessageAfterChargen then
                ZHIHotbarHUD.setVisible(sShowHotbarHUD)
            end

            ZHIHotbarHUD.initialize()
        end,

        onUpdate = function(dt)
            if showFirstTimeMessageAfterChargen and types.Player.isCharGenFinished(self) then
                openFirstTimePopup()
                showFirstTimeMessageAfterChargen = false

                if sShowHotbarHUD then
                    ZHIHotbarHUD.setVisible(sShowHotbarHUD)
                end
            end

            if ZHIHotbarHUD.isVisible() then
                ZHIHotbarHUD.onUpdate(dt)
            end

            if sStanceQueue and queuedStance then
                if queuedStanceTimer > sStanceQueueGracePeriod then
                    print('ZHI Reset Queued Stance - Expired', queuedStanceTimer, sStanceQueueGracePeriod)
                    queuedStance = nil
                elseif canPlayerChangeStance() then
                    print('ZHI Queued Stance Change', queuedStanceTimer, sStanceQueueGracePeriod)
                    Actor.setStance(self, queuedStance)

                    -- If the stance change was accepted, reset.
                    if (Actor.getStance(self) == queuedStance) then
                        queuedStance = nil
                        queuedStanceTimer = 0.0
                    else
                        queuedStanceAttempts = queuedStanceAttempts + 1
                        if queuedStanceAttempts >= queuedStanceAttemptsMax then
                            -- DEBUG
                            local anim = animation.getActiveGroup(self, animation.BONE_GROUP.RightArm)
                            print('ZHI stance change attempts limit reached. Animation: ', anim)

                            queuedStance = nil
                            queuedStanceAttempts = 0
                            queuedStanceTimer = 0
                        end
                    end
                end
                -- Doing it in this order ensures that it works for sStanceQueueGracePeriod == 0
                queuedStanceTimer = queuedStanceTimer + dt
            end
        end,

        onInit = function(initData)
            print('ZHI ON INIT', ZHI_VERSION)
            ZHIHotbarData.initHotbars()
            --tryRegisterLayers()
        end,

        onSave = function()
            print('ZHI ON SAVE', ZHI_VERSION)
            closeAllWindows()
            ZHIHotbarData.saveHotbarData(ZHISaveData)
            return ZHISaveData
        end,

        onLoad = function(loadData)
            print('ZHI ON LOAD', ZHI_VERSION)
            closeAllWindows()
            ZHIHotbarData.initHotbars()

            if loadData then
                if loadData.version == 1 then loadDataV1(loadData) end
            end

            local mainSettings = storage.playerSection('SettingsZHIAAMain')

            setOverrideDefaultQuickKeyMenu(ZHISaveData.onCloseQuickKeyMenuFirstTimeFlag and (not mainSettings:get('force_standard_ui')))
            loadHotbarSettings()

            --tryRegisterLayers()
        end,

        onKeyPress = function(key)
            if key.code == input.KEY.Escape then
                print('ZHI CLOSE ALL WINDOWS')
                closeAllWindows()
            end

            -- if key.symbol == 'x' then
                
            --     -- local sTable = storage.allPlayerSections()
            --     -- for k,v in pairs(sTable) do
            --     --     print('sTable[' .. tostring(k) .. '] = ' .. tostring(v))
            --     -- end

            --     -- ui.showMessage('Open ZHI')
                
            --     -- input.activateTrigger('QuickKey2')

            --     -- print('----ACTIONS----')
            --     -- for k, v in pairs(input.actions) do
            --     --     print(tostring(k), input.actions[k])
            --     -- end

            --     -- print('----TRIGGERS----')
            --     -- for k, v in pairs(input.triggers) do
            --     --     print(tostring(k), input.triggers[k])
            --     -- end

            -- --     -- for k, v in pairs(ui.layers) do
            -- --     --     print(string.format('ui.layers[%s] = %s', tostring(k), tostring(v)))
            -- --     -- end
            -- -- end
            --     ZMUI.uiFunction()
            --     ZMUtility.utilFunction()
            -- end
        end,

        -- Unfortunately we can't get mouse wheel events directly on widgets
        onMouseWheel = function (vScroll, hScroll)

            -- Attempt to scroll the magic select window
            if isWindowOpen(ZHI_WINDOWS.MagicSelection) then
                ZHIUIMagic.scrollContent(zhiWindows[ZHI_WINDOWS.MagicSelection], vScroll)
            elseif isWindowOpen(ZHI_WINDOWS.InventorySelection) then
                ZHIUIInventory.scrollContent(zhiWindows[ZHI_WINDOWS.InventorySelection], vScroll)
            end
        end
    },
}