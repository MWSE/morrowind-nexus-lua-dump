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
    log(message)
end

module.showModSkill = function(skillId, value, diff)
    local messageKey
    if diff > 0 then
        messageKey = "skillUp"
        ambient.playSound("skillraise")
    else
        messageKey = "skillDown"
        ambient.playSound("skillraise", { pitch = 0.79 })
        ambient.playSound("skillraise", { pitch = 0.76 })
    end
    value = math.floor(value)
    module.showMessage(L(messageKey, { stat = mCore.getSkillName(skillId), value = value }))
end

return module