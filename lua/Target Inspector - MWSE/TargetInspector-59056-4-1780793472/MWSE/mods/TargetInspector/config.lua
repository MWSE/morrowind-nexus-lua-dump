local configPath = "Target Inspector"

local defaultConfig = {
    enabled = true,

    inspectKey = {
        keyCode = tes3.scanCode.i,
        isShiftDown = false,
        isAltDown = false,
        isControlDown = false,
    },

    showVitals             = true,
    showDisposition        = true,
    showFaction            = true,
    showCombatStats        = true,
    showAttributes         = true,
    showSkills             = true,
    showActiveMagicEffects = true,

    debug = false,
}

local config = mwse.loadConfig(configPath, defaultConfig)

if config.inspectKey            == nil then config.inspectKey            = defaultConfig.inspectKey            end
if config.enabled               == nil then config.enabled               = defaultConfig.enabled               end
if config.showVitals            == nil then config.showVitals            = defaultConfig.showVitals            end
if config.showDisposition       == nil then config.showDisposition       = defaultConfig.showDisposition       end
if config.showFaction           == nil then config.showFaction           = defaultConfig.showFaction           end
if config.showCombatStats       == nil then config.showCombatStats       = defaultConfig.showCombatStats       end
if config.showAttributes        == nil then config.showAttributes        = defaultConfig.showAttributes        end
if config.showSkills            == nil then config.showSkills            = defaultConfig.showSkills            end
if config.showActiveMagicEffects== nil then config.showActiveMagicEffects= defaultConfig.showActiveMagicEffects end
if config.debug                 == nil then config.debug                 = defaultConfig.debug                 end

return {
    path    = configPath,
    default = defaultConfig,
    current = config,
}
