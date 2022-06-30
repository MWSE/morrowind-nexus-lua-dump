local async = require("openmw.async")
local camera = require("openmw.camera")
local input = require("openmw.input")
local self = require("openmw.self")
local storage = require('openmw.storage')
local ui = require("openmw.ui")
local I = require('openmw.interfaces')

local MOD_NAME = "ActionCameraSwap"
local Player = require('openmw.types').Player
local playerSettings = storage.playerSection("SettingsPlayer" .. MOD_NAME)

local hasStats = false
local interior1st = false
local manual = false

local TO_FIRST_DELAY = .1
local TO_THIRD_DELAY = .3

local interfaceVersion = 1
local scriptVersion = 1

I.Settings.registerPage {
    key = MOD_NAME,
    l10n = MOD_NAME,
    name = "Action Camera Swap",
    description = "Auto-swap from first to third person based on stance."
}

I.Settings.registerGroup {
    key = "SettingsPlayer" .. MOD_NAME,
    l10n = MOD_NAME,
    name = "Action Camera Swap",
    page = MOD_NAME,
    description = "Enable or disable features",
    permanentStorage = false,
    settings = {
        {
            key = "always1stIndoors",
            name = "Always First Person Indoors",
            default = true,
            renderer = "checkbox"
        },
        {
            key = "autoSwap",
            name = "Auto swap",
            default = true,
            renderer = "checkbox"
        },
        {
            key = "showMessages",
            name = "Show Messages",
            default = true,
            renderer = "checkbox"
        }
    }
}

local function msg(str)
    if not playerSettings:get("showMessages") then return end
    ui.showMessage(str)
end

local function isQuickKeyPressed(id)
    if
        id == input.ACTION.QuickKey1
        or id == input.ACTION.QuickKey2
        or id == input.ACTION.QuickKey3
        or id == input.ACTION.QuickKey4
        or id == input.ACTION.QuickKey5
        or id == input.ACTION.QuickKey6
        or id == input.ACTION.QuickKey7
        or id == input.ACTION.QuickKey8
        or id == input.ACTION.QuickKey9
        or id == input.ACTION.QuickKey10
    then
        return true
    end
    return false
end

local function spellWeaponSwap()
    local cb, delay
    if Player.stance(self) ~= Player.STANCE.Nothing then
        cb = async:registerTimerCallback(
            "acs_swapToFirstPerson",
            function() camera.setMode(camera.MODE.FirstPerson) end
        )
        -- Just a slight delay gives the impression of a swap animation
        delay = TO_FIRST_DELAY
    else
        if not (self.cell.isExterior or self.cell.isQuasiExterior) then return end
        cb = async:registerTimerCallback(
            "acs_swapToThirdPerson",
            function() camera.setMode(camera.MODE.ThirdPerson) end
        )
        -- There needs to be a bit more of a delay when
        -- swapping to 3rd person to avoid seeing a snap
        delay = TO_THIRD_DELAY
    end
    async:newSimulationTimer(delay, cb)
end

local function onInputAction(id)
    if not hasStats or not playerSettings:get("autoSwap") then return end

    if id == input.ACTION.TogglePOV then
        -- Don't toggle when alt-tabbing
        if input.isAltPressed() then return end

        manual = not manual
        if manual then
            msg("Auto switching off")
        else
            msg("Auto switching on")
        end
    end

    if manual or interior1st then return end

    if
        id == input.ACTION.ToggleSpell
        or id == input.ACTION.ToggleWeapon
    then
        spellWeaponSwap()
        return
    end

    -- Quick keys don't trigger the ToggleSpell or ToggleWeapon
    -- actions, so scan for their usage as well.
    if isQuickKeyPressed(id) then spellWeaponSwap() end
end

local function onLoad(data)
    if data then
        hasStats = data.hasStats
        interior1st = data.interior1st
        manual = data.manual
    end
end

--TODO: don't toggle when the console is down

local function onSave()
    return {
        hasStats = hasStats,
        interior1st = interior1st,
        manual = manual,
        version = scriptVersion
    }
end

local function onUpdate()
    -- This is a hack to see if we're far enough along in CharGen to have stats
    if not hasStats and input.getControlSwitch(input.CONTROL_SWITCH.ViewMode) then
        hasStats = true
    elseif not hasStats then
        return
    end

    if not playerSettings:get("always1stIndoors")
        or not playerSettings:get("autoSwap")
        or manual then
        return
    end

    local camMode = camera.getMode()
    local exterior = self.cell.isExterior or self.cell.isQuasiExterior

    if (
        not exterior
        and (camMode == camera.MODE.ThirdPerson or camMode == camera.MODE.Preview)
    ) then
        async:newSimulationTimer(
            TO_FIRST_DELAY,
            async:registerTimerCallback(
                "acs_swapToFirstPerson",
                function() camera.setMode(camera.MODE.FirstPerson) end
        ))
        interior1st = true

    elseif (
        exterior
        and camMode == camera.MODE.FirstPerson
        and Player.stance(self) == Player.STANCE.Nothing
        and interior1st
    ) then
        async:newSimulationTimer(
            TO_THIRD_DELAY,
            async:registerTimerCallback(
                "acs_swapToThirdPerson",
                function() camera.setMode(camera.MODE.ThirdPerson) end
        ))
        interior1st = false

    elseif (
        not exterior
        and not interior1st
        and camMode == camera.MODE.FirstPerson
    ) then
        -- This happens when using mark/recall (as well as chargen)
        interior1st = true
    end
end

local function Auto()
    if playerSettings:get("autoSwap") then
        return not manual
    end
    return false
end

return {
    engineHandlers = {
        onInputAction = onInputAction,
        onLoad = onLoad,
        onSave = onSave,
        onUpdate = onUpdate
    },
    interfaceName = MOD_NAME,
    interface = {
        version = interfaceVersion,
        Auto = Auto
    }
}
