local core = require('openmw.core')
local ui = require('openmw.ui')
local ambient = require('openmw.ambient')

local log = require('scripts.skill-evolution.util.log')
local mDef = require('scripts.skill-evolution.config.definition')
local mCore = require('scripts.skill-evolution.util.core')

local L = core.l10n(mDef.MOD_NAME)

local module = {}

module.showMessage = function(message)
    ui.showMessage(message, { showInDialogue = false })
    log("Notif: " .. message)
end

module.showModSkill = function(skillId, value, diff, options)
    value = math.floor(value)
    if diff > 0 then
        ambient.playSound("skillraise")
        if options and options.recovered then
            module.showMessage(L("skillRecovered", { stat = mCore.getSkillName(skillId), value = value }))
        else
            module.showMessage(string.format(core.getGMST("sNotifyMessage39"), mCore.getSkillName(skillId) , value))
        end
    else
        ambient.playSound("skillraise", { pitch = 0.79 })
        ambient.playSound("skillraise", { pitch = 0.76 })
        module.showMessage(string.format(core.getGMST("sNotifyMessage44"), mCore.getSkillName(skillId) , value))
    end
end

return module