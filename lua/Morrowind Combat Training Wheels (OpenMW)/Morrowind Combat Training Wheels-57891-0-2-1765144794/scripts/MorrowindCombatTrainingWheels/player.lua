local self = require('openmw.self')
local Types = require('openmw.types')
local Core = require('openmw.core')
local Storage = require('openmw.storage')
local Interface = require('openmw.interfaces')
local Async = require('openmw.async')
local UI = require('openmw.ui')
local util = require('openmw.util')
local l10n = Core.l10n('MorrowindCombatTrainingWheels')

-- Settings defaults
local settings = {
    enableAttackBonus = false,
    attackBonus = 0,
    enableMagickaRegen = false,
    magickaRegenRate = 1.0,
    enableFatigueRegen = false,
    fatigueRegenMult = 1.0,
}

-- Register MCM page
Interface.Settings.registerPage({
    key = 'MorrowindCombatTrainingWheels',
    l10n = 'MorrowindCombatTrainingWheels',
    name = 'name',
    description = 'description',
})

-- Register settings group
Interface.Settings.registerGroup({
    key = 'Settings_MorrowindCombatTrainingWheels',
    page = 'MorrowindCombatTrainingWheels',
    l10n = 'MorrowindCombatTrainingWheels',
    name = 'combat_settings',
    permanentStorage = true,
    settings = {
        {
            key = 'enableAttackBonus',
            default = settings.enableAttackBonus,
            renderer = 'checkbox',
            name = 'enable_attack_bonus',
            description = 'enable_attack_bonus_desc',
        },
        {
            key = 'attackBonus',
            default = settings.attackBonus,
            renderer = 'number',
            name = 'attack_bonus',
            description = 'attack_bonus_desc',
            argument = {
                min = 0,
                max = 1000,
                integer = true,
            },
        },
        {
            key = 'enableMagickaRegen',
            default = settings.enableMagickaRegen,
            renderer = 'checkbox',
            name = 'enable_magicka_regen',
            description = 'enable_magicka_regen_desc',
        },
        {
            key = 'magickaRegenRate',
            default = settings.magickaRegenRate,
            renderer = 'number',
            name = 'magicka_regen_rate',
            description = 'magicka_regen_rate_desc',
            argument = {
                min = 0.1,
                max = 100.0,
            },
        },
        {
            key = 'enableFatigueRegen',
            default = settings.enableFatigueRegen,
            renderer = 'checkbox',
            name = 'enable_fatigue_regen',
            description = 'enable_fatigue_regen_desc',
        },
        {
            key = 'fatigueRegenMult',
            default = settings.fatigueRegenMult,
            renderer = 'number',
            name = 'fatigue_regen_mult',
            description = 'fatigue_regen_mult_desc',
            argument = {
                min = 0.1,
                max = 100.0,
            },
        },
    },
})

-- Storage
local settingsGroup = Storage.playerSection('Settings_MorrowindCombatTrainingWheels')
local saveData = Storage.playerSection('MorrowindCombatTrainingWheels_SaveData')

-- First time popup flag
local showPopupAfterChargen = false
local welcomeWindow = nil

-- Update local settings from storage
local function updateSettingsFromStorage()
    settings.enableAttackBonus = settingsGroup:get('enableAttackBonus')
    settings.attackBonus = settingsGroup:get('attackBonus')
    settings.enableMagickaRegen = settingsGroup:get('enableMagickaRegen')
    settings.magickaRegenRate = settingsGroup:get('magickaRegenRate')
    settings.enableFatigueRegen = settingsGroup:get('enableFatigueRegen')
    settings.fatigueRegenMult = settingsGroup:get('fatigueRegenMult')
end

-- Subscribe to setting changes and reapply when changed
settingsGroup:subscribe(Async:callback(function()
    print("[MCTW] Settings changed, updating...")
    updateSettingsFromStorage()
    applyDicerollSetting()
end))

-- Callback function to close the welcome window
local welcomeCloseCallback = nil

local function closeWelcomeWindow()
    if welcomeWindow then
        welcomeWindow:destroy()
        welcomeWindow = nil
    end
    -- Restore normal UI mode
    Interface.UI.setMode()
    if welcomeCloseCallback then
        welcomeCloseCallback()
        welcomeCloseCallback = nil
    end
end

-- Create a "simple" message box with OK button
local function createMessageBox(title, message, okCallback)
    welcomeCloseCallback = okCallback

    -- Set UI to Interface mode to ensure proper input handling
    Interface.UI.setMode('Interface', { windows = {} })

    local content = {
        {
            template = Interface.MWUI.templates.borders,
            type = UI.TYPE.Container,
            content = UI.content({
                {
                    template = Interface.MWUI.templates.padding,
                    content = UI.content({
                        {
                            template = Interface.MWUI.templates.padding,
                            content = UI.content({
                                {
                                    type = UI.TYPE.Flex,
                                    props = {
                                        horizontal = false,
                                        arrange = UI.ALIGNMENT.Center,
                                        align = UI.ALIGNMENT.Center,
                                    },
                                    content = UI.content({
                -- Title
                {
                    type = UI.TYPE.Text,
                    props = {
                        text = title,
                        textSize = 20,
                        textColor = util.color.rgb(1, 1, 1),
                    }
                },
                -- Spacer
                {
                    type = UI.TYPE.Flex,
                    props = {
                        size = util.vector2(0, 16),
                    }
                },
                -- Horizontal line
                {
                    template = Interface.MWUI.templates.horizontalLine,
                    -- I don't know WHY this works if its set to image but okay. I think its probably technically an image.
                    type = UI.TYPE.Image,
                    props = {
                        autoSize = false,
                        size = util.vector2(450, 2),
                    }
                },
                -- Spacer
                {
                    type = UI.TYPE.Flex,
                    props = {
                        size = util.vector2(0, 16),
                    }
                },
                -- Message
                {
                    template = Interface.MWUI.templates.textNormal,
                    type = UI.TYPE.Text,
                    props = {
                        text = message,
                        textSize = 16,
                        multiline = true,
                        wordWrap = true,
                    }
                },
                -- Spacer
                {
                    type = UI.TYPE.Flex,
                    props = {
                        size = util.vector2(0, 16),
                    }
                },
                -- OK Button
                {
                    template = Interface.MWUI.templates.boxSolid,
                    type = UI.TYPE.Container,
                    content = UI.content({
                        {
                            template = Interface.MWUI.templates.padding,
                            content = UI.content({
                                {
                                    template = Interface.MWUI.templates.textNormal,
                                    type = UI.TYPE.Text,
                                    props = {
                                        text = l10n('button_ok'),
                                        textSize = 18,
                                    },
                                }
                            })
                        }
                    }),
                    events = {
                        mouseClick = Async:callback(closeWelcomeWindow),
                    }
                },
                -- Spacer
                {
                    type = UI.TYPE.Flex,
                    props = {
                        size = util.vector2(0, 12),
                    }
                },
                                    })
                                }
                            })
                        }
                    })
                }
            })
        }
    }

    welcomeWindow = UI.create({
        layer = 'Windows',
        template = Interface.MWUI.templates.boxSolidThick,
        type = UI.TYPE.Container,
        props = {
            anchor = util.vector2(0.5, 0.5),
            relativePosition = util.vector2(0.5, 0.3),
            size = util.vector2(500, 300),
        },
        content = UI.content(content)
    })
end

-- Show first time popup with settings information
local function showFirstTimePopup()
    local title = l10n('welcome_popup_title')
    local message = l10n('welcome_popup_message')
    -- Check if UI is in normal mode (nil = normal gameplay, no menus open)
    -- If any UI is open, delay the popup to avoid conflicts
    local currentMode = Interface.UI.getMode()
    if currentMode ~= nil then
        print("[MCTW] UI mode active (" .. tostring(currentMode) .. "), delaying popup by 3 seconds")
        Async:newUnsavableSimulationTimer(3.0, function()
            -- Recursively try again - this will keep delaying until UI is clear
            -- Why? Because everyone uses a crap ton of mods. And a new user really needs a clear message if this is included in a mod pack.
            showFirstTimePopup()
        end)
    else
        print("[MCTW] UI clear, showing popup now")
        -- TEST: Show template test instead
        -- createMessageBox(title, message)
        createMessageBox(title, message, function()
            saveData:set('hasSeenFirstTimePopup', true)
        end)
    end
end

-- Initialize settings on load
local function initializeSettings()
    print("[MCTW] Initializing settings...")
    updateSettingsFromStorage()
    applyDicerollSetting()

    -- Reset the popup flag if this is a new character (chargen not finished yet)
    -- This ensures new characters always see the welcome message
    if not Types.Player.isCharGenFinished(self) then
        print("[MCTW] New character detected, resetting popup flag")
        saveData:set('hasSeenFirstTimePopup', false)
    end

    -- Check if we should show the first time popup
    local hasSeenPopup = saveData:get('hasSeenFirstTimePopup')
    print("[MCTW] hasSeenFirstTimePopup =", hasSeenPopup)
    print("[MCTW] isCharGenFinished =", Types.Player.isCharGenFinished(self))

    if not hasSeenPopup then
        -- Always use the onUpdate path to show the popup
        -- This ensures consistent delay regardless of when the game is loaded
        print("[MCTW] Popup will show via onUpdate handler with delay")
        showPopupAfterChargen = true
    else
        print("[MCTW] Popup already seen, skipping")
    end
end

-- Apply attack bonus setting using active effects
-- Track last applied attack bonus to avoid unnecessary re-applies
local lastAppliedAttackBonus = nil

function applyDicerollSetting()
    -- Behavior:
    -- IF dice roll is ENABLED and value is incorrect (another mod changed it):
    --  Correct it back to our setting value when menu is opened
    -- IF dice roll is DISABLED and we already set it to 0 (valueToSet):
    --  Don't touch it again (let other mods use FortifyAttack without interference. e.g. they can set it 5, and this mod won't touch it.)
    -- IF setting changes (user toggles or adjusts slider):
    --  Apply the new value immediately
    -- Note: This does not conflict with spells/enchantments/abilities - those are separate effect sources.
    -- Only affects the base FortifyAttack value set via activeEffects:set()
    -- In an ideal world no one else is touching this IF the setting is ENABLED.
    -- I don't want to have this script constantly looking for and getting into conflicts if I can avoid it. Hence the whole "behavior" thing.
    local valueToSet = (settings.enableAttackBonus and settings.attackBonus) or 0

    -- Ensure value is not below 0 (floor at 0)
    valueToSet = math.max(valueToSet, 0)

    print("[MCTW] applyDicerollSetting called, enabled =", settings.enableAttackBonus, "bonus =", settings.attackBonus)
    print("[MCTW] Desired value =", valueToSet)

    -- Track if setting value changed
    local settingChanged = lastAppliedAttackBonus ~= valueToSet

    -- If disabled and value is already at what we set (0), don't touch it even if another mod changed it
    if not settings.enableAttackBonus and lastAppliedAttackBonus == 0 and not settingChanged then
        print("[MCTW] Dice roll disabled and already set to 0 - not interfering with other mods")
        return
    end

    -- If nothing changed and we're disabled, skip
    if not settingChanged and not settings.enableAttackBonus then
        print("[MCTW] Attack bonus unchanged and disabled, skipping re-apply")
        return
    end

    -- Apply the value
    if settingChanged then
        print("[MCTW] Setting changed - applying new value:", valueToSet)
    elseif settings.enableAttackBonus then
        print("[MCTW] Dice roll enabled - re-applying value (in case another mod changed it):", valueToSet)
    end

    local activeEffects = Types.Actor.activeEffects(self)
    activeEffects:set(valueToSet, Core.magic.EFFECT_TYPE.FortifyAttack)
    lastAppliedAttackBonus = valueToSet

    print("[MCTW] FortifyAttack set successfully")
end




-- Handle magicka regeneration
local magickaRegenTimer = 0
local function updateMagickaRegen(dt)
    if not settings.enableMagickaRegen then return end

    magickaRegenTimer = magickaRegenTimer + dt

    -- Regen every 0.5 seconds
    if magickaRegenTimer >= 0.5 then
        -- Note: Cache function calls as advised (S3ct0r recommended this to avoid clogging the pipes)
        local magicka = Types.Actor.stats.dynamic.magicka(self)
        local willpower = Types.Actor.stats.attributes.willpower(self)

        if magicka.current < magicka.base then
            -- Base regen: 1% of max magicka per second, scaled by Willpower
            local regenAmount = (magicka.base * 0.01 * magickaRegenTimer) * (willpower.modified / 50) * settings.magickaRegenRate

            magicka.current = math.min(magicka.current + regenAmount, magicka.base)
            -- Ensure magicka never goes to 0 or below (minimum is 0.01)
            magicka.current = math.max(magicka.current, 0.01)
        end

        magickaRegenTimer = 0
    end
end

-- Handle fatigue regeneration (boost natural regen)
local lastFatigue = nil
local function updateFatigueRegen(dt)
    if not settings.enableFatigueRegen or settings.fatigueRegenMult == 1.0 then
        lastFatigue = nil
        return
    end

    -- Cache the fatigue stat call (S3ct0r recommended this to avoid clogging the pipes)
    local fatigue = Types.Actor.stats.dynamic.fatigue(self)

    if lastFatigue == nil then
        lastFatigue = fatigue.current
        return
    end

    -- Calculate how much fatigue regenerated naturally this frame
    local naturalRegen = fatigue.current - lastFatigue

    -- Only boost positive regeneration (not damage/drain)
    -- Note: Check some of these when the player is effected by a stat drain.
    if naturalRegen > 0 then
        -- Apply multiplier: e.g. if mult is 2.0, add another 100% of natural regen
        local bonusRegen = naturalRegen * (settings.fatigueRegenMult - 1.0)
        fatigue.current = math.min(fatigue.current + bonusRegen, fatigue.base)
    end

    -- Ensure fatigue never goes to 0 or below (minimum is 0.01)
    fatigue.current = math.max(fatigue.current, 0.01)
    lastFatigue = fatigue.current
end

return {
    engineHandlers = {
        onActive = initializeSettings,

        onUpdate = function(dt)
            -- Check if we need to show popup after chargen (only runs until popup is shown)
            if showPopupAfterChargen then
                if Types.Player.isCharGenFinished(self) then
                    print("[MCTW] CharGen finished, delaying popup by 1 second to avoid colliding with other mods")
                    Async:newUnsavableSimulationTimer(1.0, function()
                        showFirstTimePopup()
                    end)
                    showPopupAfterChargen = false
                end
            end

            -- Update regeneration
            updateMagickaRegen(dt)
            updateFatigueRegen(dt)
        end,
    },

    eventHandlers = {
        UiModeChanged = function(data)
            -- If user pressed Escape and left Interface mode while our window is open, close it
            if data.oldMode == 'Interface' and data.newMode == nil and welcomeWindow then
                print("[MCTW] UI mode closed by Escape, cleaning up popup")
                closeWelcomeWindow()
            end
        end
    }
}
