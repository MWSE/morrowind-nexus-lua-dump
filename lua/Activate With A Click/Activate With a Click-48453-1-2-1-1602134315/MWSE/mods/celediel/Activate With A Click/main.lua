-- {{{ variables and config and such
local common = require("celediel.Activate With A Click.common")
local config = require("celediel.Activate With A Click.config")

local activateKey = nil

-- https://mwse.readthedocs.io/en/latest/mwscript/references.html#control-types
local activateKeyScanCode = 5

-- }}}

-- {{{ helper functions

local function getActivateKey()
    local inputMaps = tes3.worldController.inputController.inputMaps

    -- offset +1 between control type and inputMaps array (thanks cpassuel)
    if (inputMaps[activateKeyScanCode + 1].device == 0) then
        return inputMaps[activateKeyScanCode + 1].code
    else
        return nil
    end
end

-- }}}

-- {{{ event functions

local function onMouseButtonDown(e)
    -- not in menus
    if tes3.menuMode() then return end

    -- not if weapon readied if configured to do so
    if tes3.mobilePlayer and tes3.mobilePlayer.weaponDrawn and config.disableWithWeapon then return end

    if e.button == config.activateMouseButton and config.clickActivate and activateKey then tes3.tapKey(activateKey) end
end

-- refresh keybinding when leaving menu (thanks again cpassuel)
local function onMenuExit() activateKey = getActivateKey() end

local function onInitialized()
    activateKey = getActivateKey()

    event.register("mouseButtonDown", onMouseButtonDown)
    event.register("menuExit", onMenuExit)

    if activateKey then
        mwse.log("[%s] Successfully initialized", common.modName)
    else
        mwse.log("[%s] activate key not bound to keyboard, mod will not work until activate is bound to keyboard",
                 common.modName)
    end
end

event.register("initialized", onInitialized)

-- }}}

-- {{{ MCM

event.register("modConfigReady", function() mwse.mcm.register(require("celediel.Activate With A Click.mcm")) end)

-- }}}

-- vim:fdm=marker
