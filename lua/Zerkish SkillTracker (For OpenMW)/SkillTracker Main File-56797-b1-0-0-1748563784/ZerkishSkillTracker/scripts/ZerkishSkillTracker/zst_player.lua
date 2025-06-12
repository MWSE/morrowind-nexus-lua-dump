local async = require('openmw.async')
local core = require('openmw.core')
local self = require('openmw.self')
local storage = require('openmw.storage')
local ui = require('openmw.ui')
local vector2 = require('openmw.util').vector2
local input = require('openmw.input')
local I = require('openmw.interfaces')
local auxUI = require('openmw_aux.ui')

local ZUtility = require('scripts.ZModUtils.Utility')

local ZSTUI = require('scripts.ZerkishSkillTracker.zst_ui')
local ZSTUIConfig = require('scripts.ZerkishSkillTracker.zst_ui_config')


local sEnableTracker = true
local sWindowPositionX = 0.0
local sWindowPositionY = 0.0
local sUpdateInterval = 0.2
local sConfigKey = input.KEY.K
local sCompatMode = false

local trackerWindow = nil
local updateTimer = 0.0

local configWindow = nil

local ZSTSaveData = {
    skills = { 'Athletics', 'Acrobatics', 'Destruction' }
}


local function getSkillId(skillName)
    local id = skillName:lower()
    id = id:gsub(' ', '')
    return id
end

local function getSkillDisplayValue(skillId)
    local value = ZUtility.Stats.getActorSkill(self.object, skillId)
    local progress = ZUtility.Stats.getActorSkillProgress(self.object, skillId)
    if progress > 1.0 then progress = 0.0 end
    return value + progress
end

local function createTracker()
    if #ZSTSaveData.skills == 0 then
        print('ZST no tracked skills, aborting createTracker')
        return
    end

    trackerWindow = ZSTUI.create()
    for i=1,10 do
        if ZSTSaveData.skills[i] and ZSTSaveData.skills[i] ~= 'None' then
            ZSTUI.setTrackedSkill(trackerWindow, i, ZSTSaveData.skills[i], getSkillDisplayValue(getSkillId(ZSTSaveData.skills[i])))
        end
    end
    ZSTUI.setPosition(trackerWindow, vector2(sWindowPositionX, sWindowPositionY))
end

local function settingsListener(section, key)
    local sectionData = storage.playerSection(section)

    if not sectionData then return end

    -- for some reason nil key means 'all keys'

    if section == "SettingsZSTAAMain" then
        if key == nil or key == "enable_tracker" then
            sEnableTracker = sectionData:get('enable_tracker')
            print('ZST.sEnableTracker = ', sEnableTracker)
            if not sEnableTracker and trackerWindow then
                auxUI.deepDestroy(trackerWindow)
                trackerWindow = nil
            elseif sEnableTracker then
                if not trackerWindow then
                    createTracker()
                end
            end
        end
        if key == nil or key == 'toggle_config_key' then
            sConfigKey = sectionData:get('toggle_config_key')
            print('ZST.toggleKey = ', sConfigKey)
        end
        if key == nil or key == "window_position_x" then
            sWindowPositionX = sectionData:get('window_position_x')
            print('ZST.sWindowPositionX = ', sWindowPositionX)
            if trackerWindow then
                ZSTUI.setPosition(trackerWindow, vector2(sWindowPositionX, trackerWindow.layout.props.position.y))
            end
        end
        if key == nil or key == "window_position_y" then
            sWindowPositionY = sectionData:get('window_position_y')
            print('ZST.sWindowPositionY = ', sWindowPositionY)
            if trackerWindow then
                ZSTUI.setPosition(trackerWindow, vector2(trackerWindow.layout.props.position.x, sWindowPositionY))
            end
        end
        if key == nil or key == "update_interval" then
            sUpdateInterval = sectionData:get('update_interval')
            print('ZST.sUpdateInterval = ', sUpdateInterval)
        end
        if key == nil or key == 'enable_compat_mode' then
            sCompatMode = sectionData:get('enable_compat_mode')
            print('ZST.sCompatMode = ', sCompatMode)
        end
    elseif section == 'SettingsZSTZAAppearance' then
        if key == nil or key == 'alpha' then
            local a = sectionData:get('alpha')
            print('ZST.appearance.sWindowAlpha = ', a)
            ZSTUI.setWindowAlpha(a)
            if sEnableTracker then
                if trackerWindow then
                    auxUI.deepDestroy(trackerWindow)
                    createTracker()
                end
            end
        end
        if key == nil or key == 'bg_alpha' then
            local a = sectionData:get('bg_alpha')
            print('ZST.appearance.sBackgroundAlpha = ', a)
            ZSTUI.setBackgroundAlpha(a)
            if sEnableTracker then
                if trackerWindow then
                    auxUI.deepDestroy(trackerWindow)
                    createTracker()
                end
            end
        end
        if key == nil or key == 'window_border' then
            local a = sectionData:get('window_border')
            print('ZST.appearance.sWindowBorder = ', a)
            ZSTUI.setWindowBorder(a)
            if sEnableTracker then
                if trackerWindow then
                    auxUI.deepDestroy(trackerWindow)
                    createTracker()
                end
            end
        end
        if key == nil or key == 'flash_time' then
            local a = sectionData:get('flash_time')
            print('ZST.appearance.setSkillFlashTime = ', a)
            ZSTUI.setSkillFlashTime(a)
        end
    end
end

local function openConfigWindow()
    if I.UI.getMode() ~= nil then return end

    if not configWindow then
        configWindow = ZSTUIConfig.create()
        I.UI.setMode('Interface', {windows = {}})
        if not sCompatMode then
            I.Controls.overrideUiControls(true)
        end
    end
end

local function closeConfigWindow()
    if configWindow then
        ZSTUIConfig.destroy(configWindow)
        configWindow = nil
        I.UI.setMode()
        if not sCompatMode then
            I.Controls.overrideUiControls(false)
        end
    end
end

local function onToggleHUDHandler()
    if trackerWindow then
        trackerWindow.layout.props.visible = sEnableTracker and I.UI.isHudVisible()
        trackerWindow:update()
    end
end

local function onInit()
    print('ZST onInit')
    if ui.layers.indexOf('ZST_WINDOW') == nil then
        ui.layers.insertAfter('HUD', 'ZST_WINDOW', { interactive = true })
    end
end

local function onActive()
    print('ZST onActive')

    if ui.layers.indexOf('ZST_WINDOW') == nil then
        ui.layers.insertAfter('HUD', 'ZST_WINDOW', { interactive = true })
    end

    -- input.registerTrigger({
    --     description = nil,
    --     key = 'ZST_toggle_tracker_config_window',
    --     l10n = 'ZST_l10n',
    --     name = 'Toggle Config Window'
    -- })

    local mainSection = storage.playerSection('SettingsZSTAAMain')
    local appearanceSection = storage.playerSection('SettingsZSTZAAppearance')

    local asyncSettingsListener = async:callback(settingsListener)

    mainSection:subscribe(asyncSettingsListener)
    appearanceSection:subscribe(asyncSettingsListener)

    settingsListener('SettingsZSTAAMain', nil)
    settingsListener('SettingsZSTZAAppearance', nil)

    if sEnableTracker and not trackerWindow then
        createTracker()
    end

    input.registerTriggerHandler("ToggleHUD", async:callback(onToggleHUDHandler))
end

local function onUpdate(dt)
    updateTimer = updateTimer + dt
    if trackerWindow and updateTimer > sUpdateInterval then
        updateTimer = 0.0

        for i=1,10 do
            if ZSTSaveData.skills[i] and ZSTSaveData.skills[i] ~= 'None' then
                ZSTUI.updateTrackedSkill(trackerWindow, i, getSkillDisplayValue(getSkillId(ZSTSaveData.skills[i])))
            end
        end

        ZSTUI.update(trackerWindow, sUpdateInterval)
    end
end

local function loadData_V1(data)
    print('ZST loadData_V1')
    assert(data.version == 1)
    if data.data then
        ZSTSaveData.skills = data.data.skills and data.data.skills or {}
        for i=1, #ZSTSaveData.skills do
            print(string.format("ZST load [%d] => %s", i, ZSTSaveData.skills[i]))
        end

        if #ZSTSaveData.skills == 0 then
            ZSTSaveData.skills = { 'Athletics', 'Acrobatics', 'Destruction' }
        end
    end
end

local function onLoad(data)
    print('ZST onLoad')

    if data.version == 1 then
        loadData_V1(data)
    end
end

local function saveData_V1()
    print('ZST saveData_V1')
    return {
        version = 1,
        data = ZSTSaveData,
    }
end

local function onSave()
    print('ZST onSave')
    return saveData_V1()
end

return {
    interfaceName = 'ZST',
    interface = {
        version = 1,

        setWindowPosition = function(newPos)
            local section = storage.playerSection('SettingsZSTAAMain')
            section:set('window_position_x', newPos.x)
            section:set('window_position_y', newPos.y)
        end,

        getTrackedSkills = function()
            return ZSTSaveData.skills
        end,

        onTrackerConfigResult = function(newSkills)
            if newSkills then
                ZSTSaveData.skills = newSkills
            end

            closeConfigWindow()
            if trackerWindow then
                auxUI.deepDestroy(trackerWindow)
            end
            createTracker()
        end,
    },

    engineHandlers = {
        onInit = onInit,
        onActive = onActive,
        onUpdate = onUpdate,
        onLoad = onLoad,
        onSave = onSave,
        onKeyPress = function(key)
            if key.code == input.KEY.Escape then
                closeConfigWindow()
            end

            if key.code == sConfigKey then
                print('ZST Toggle Config Window')
                if configWindow then
                    closeConfigWindow()
                else
                    openConfigWindow()
                end
            end
        end,

        onMouseWheel = function (vScroll, hScroll)
            if configWindow then
                ZSTUIConfig.onMouseWheel(vScroll)
            end
        end
    }
}