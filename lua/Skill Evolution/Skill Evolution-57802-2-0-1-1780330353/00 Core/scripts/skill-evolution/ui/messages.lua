local core = require('openmw.core')
local ui = require('openmw.ui')
local ambient = require('openmw.ambient')

local mDef = require('scripts.skill-evolution.config.definition')
local mCore = require('scripts.skill-evolution.util.core')
local log = require('scripts.skill-evolution.util.log')

local L = core.l10n(mDef.MOD_NAME)

local module = {}

module.showMessage = function(message)
    ui.showMessage(message, { showInDialogue = false })
    log("Notif: " .. message)
end

module.showModSkill = function(skillId, value, diff, options)
    value = math.floor(value)
    local skillName = mCore.getSkillRecord(skillId).name
    if diff > 0 then
        -- only handle recovered skills, as normal increase notifications are handled by the engine
        if options and options.recovered then
            ambient.playSound("skillraise")
            module.showMessage(L("skillRecovered", { stat = skillName, value = value }))
        end
    else
        ambient.playSound("skillraise", { pitch = 0.79 })
        ambient.playSound("skillraise", { pitch = 0.76 })
        module.showMessage(L("skillDecayed", { stat = skillName, value = value }))
    end
end

return module