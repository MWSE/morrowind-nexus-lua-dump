if require('openmw.core').API_REVISION < 44 then
    error('This mod requires a newer version of OpenMW, please update.')
end

local async = require('openmw.async')
local core = require('openmw.core')
local input = require('openmw.input')
local self = require('openmw.self')
local ui = require('openmw.ui')
local util = require('openmw.util')
local I = require('openmw.interfaces')
local Actor = require('openmw.types').Actor
local Player = require('openmw.types').Player

local MODE = I.UI.MODE
local WINDOW = I.UI.WINDOW
local v2 = util.vector2

I.Controls.overrideUiControls(true)

local mode = nil
local modeMenu = nil

local function closeModeMenu()
    if modeMenu then
        modeMenu:destroy()
        modeMenu = nil
    end
end

local function toggleJournal(key)
    if I.UI.getMode() == MODE.Journal then
        I.UI.removeMode(MODE.Journal)
        mode = nil
    elseif I.UI.getWindowsForMode(MODE.Interface)[WINDOW.Magic] then
        I.UI.setMode(MODE.Journal)
        mode = 'journal'
    end
end

local function toggleMap(key)
    if I.UI.getMode() == MODE.Interface and mode == 'map' then
        I.UI.removeMode(MODE.Interface)
        mode = nil
    else
        I.UI.setMode(MODE.Interface, {windows = {WINDOW.Map}})
        mode = 'map'
        closeModeMenu()
    end
end

local function toggleInventoryAndStats(key)
    if I.UI.getMode() == MODE.Interface and mode == 'stats' then
        I.UI.removeMode(MODE.Interface)
        mode = nil
    else
        I.UI.setMode(MODE.Interface, {windows = {WINDOW.Magic}})
        mode = 'stats'
        closeModeMenu()
    end
end

local function toggleInventoryAndMagic(key)
    if I.UI.getMode() == MODE.Interface and mode == 'magic' then
        I.UI.removeMode(MODE.Interface)
        mode = nil
    else
        I.UI.setMode(MODE.Interface, {windows = {WINDOW.Inventory}})
        mode = 'magic'
        closeModeMenu()
    end
end

local function createModeOption(pos, text, fn)
    return {
        type = ui.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
            text = text,
            multiline = true,
            anchor = pos,
            relativePosition = pos,
			textSize = 18,
  		textColor = util.color.rgb(0, 255, 255)
        },
        events = {
            mouseClick = async:callback(fn),
        },
    }
end

local modeMenuLayout = {
  layer = 'Windows',
  type = ui.TYPE.Image,
  props = {
    size = v2(390, 390),
    relativePosition = v2(0.5, 0.5),
    anchor = v2(0.5, 0.5),
    resource = ui.texture{path = 'textures/UiModes/modeMenu.png'},
  },
  content = ui.content {
    createModeOption(v2(0.5, 0.1), 'Logbook', toggleJournal),
    createModeOption(v2(0.5, 0.9), 'Map', toggleMap),
    createModeOption(v2(0.1, 0.5), 'Inventory', toggleInventoryAndMagic),
    createModeOption(v2(0.9, 0.5), 'Ship Menu', toggleInventoryAndStats),
  },
}

local function openModeMenu()
    modeMenu = modeMenu or ui.create(modeMenuLayout)
    modeMenu:update()
    I.UI.setMode(MODE.Interface, {windows = {}})
end

local function checkNotWerewolf()
    if Player.isWerewolf(self) then
        ui.showMessage(core.getGMST('sWerewolfRefusal'))
        return false
    else
        return true
    end
end

local defaultStance = Actor.STANCE.Weapon

local function onInputAction(action)
    if not input.getControlSwitch(input.CONTROL_SWITCH.Controls) then
        return
    end

    if action == input.ACTION.Inventory then
        if I.UI.getMode() == nil and next(I.UI.getWindowsForMode(MODE.Interface)) then
            openModeMenu()
        elseif I.UI.getMode() == MODE.Interface or I.UI.getMode() == MODE.Container or I.UI.getMode() == MODE.Journal then
            I.UI.removeMode(I.UI.getMode())
            mode = nil
        end
    elseif action == input.ACTION.Journal then
        toggleJournal()
    elseif action == input.ACTION.QuickKeysMenu then
        if I.UI.getMode() == MODE.QuickKeysMenu then
            I.UI.removeMode(MODE.QuickKeysMenu)
        elseif checkNotWerewolf() and Player.isCharGenFinished(self) then
            I.UI.addMode(MODE.QuickKeysMenu)
        end
    elseif modeMenu and action == input.ACTION.MoveBackward then
        toggleMap()
    elseif modeMenu and action == input.ACTION.MoveForward then
        toggleJournal()
    elseif modeMenu and action == input.ACTION.MoveLeft then
        toggleInventoryAndMagic()
    elseif modeMenu and action == input.ACTION.MoveRight then
        toggleInventoryAndStats()
    end

    if core.isWorldPaused() then
        return
    end

    if action == input.ACTION.Use then
        if Actor.getStance(self) == Actor.STANCE.Nothing then
            local weaponAllowed = input.getControlSwitch(input.CONTROL_SWITCH.Fighting)
            local magicAllowed = input.getControlSwitch(input.CONTROL_SWITCH.Magic) and not Player.isWerewolf(self)
                and (Actor.getSelectedSpell(self) or Actor.getSelectedEnchantedItem(self))
            if weaponAllowed and magicAllowed then
                Actor.setStance(self, defaultStance)
            elseif weaponAllowed then
                defaultStance = Actor.STANCE.Weapon
                Actor.setStance(self, defaultStance)
            elseif magicAllowed then
                defaultStance = Actor.STANCE.Spell
                Actor.setStance(self, defaultStance)
            end
        end
    elseif action == input.ACTION.ToggleWeapon then
        defaultStance = Actor.STANCE.Weapon
    elseif action == input.ACTION.ToggleSpell then
        defaultStance = Actor.STANCE.Spell
    end
end

local function onKeyPress(key)
    if not input.getControlSwitch(input.CONTROL_SWITCH.Controls) then
        return
    end

    if key.code == input.KEY.M then
        toggleMap()
    elseif key.code == input.KEY.I then
        toggleInventoryAndMagic()
    elseif key.code == input.KEY.C then
        toggleInventoryAndStats()
    elseif modeMenu and key.code == input.KEY.DownArrow then
        toggleMap()
    elseif modeMenu and key.code == input.KEY.UpArrow then
        toggleJournal()
    elseif modeMenu and key.code == input.KEY.LeftArrow then
        toggleInventoryAndMagic()
    elseif modeMenu and key.code == input.KEY.RightArrow then
        toggleInventoryAndStats()
    end
end

local function onControllerButtonPress(id)
    if not modeMenu then return end
    if id == input.CONTROLLER_BUTTON.DPadDown then
        toggleMap()
    elseif id == input.CONTROLLER_BUTTON.DPadUp then
        toggleJournal()
    elseif id == input.CONTROLLER_BUTTON.DPadLeft then
        toggleInventoryAndMagic()
    elseif id == input.CONTROLLER_BUTTON.DPadRight then
        toggleInventoryAndStats()
    end
end

return {
    engineHandlers = {
        onInputAction = onInputAction,
        onKeyPress = onKeyPress,
        onControllerButtonPress = onControllerButtonPress,
    },
    eventHandlers = {
        UiModeChanged = function(m)
            if m.newMode == nil then mode = nil end
            if m.newMode ~= MODE.Interface then closeModeMenu() end
        end,
    },
}

