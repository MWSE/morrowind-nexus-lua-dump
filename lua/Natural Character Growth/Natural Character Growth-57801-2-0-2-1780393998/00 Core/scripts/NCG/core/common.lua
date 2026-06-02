local core = require('openmw.core')
local self = require('openmw.self')
local ui = require('openmw.ui')
local T = require('openmw.types')
local I = require('openmw.interfaces')

local mDef = require('scripts.NCG.config.definition')
local mS = require('scripts.NCG.config.store')
local mHelpers = require('scripts.NCG.util.helpers')
local log = require('scripts.NCG.util.log')

local currBaseStatModsKey
local messageStack = {}

local module = {}

module.self = {
    level = T.Actor.stats.level(self),
    health = T.Actor.stats.dynamic.health(self),
}

local function updateSettings()
    mS.settings.luckModifierPerDeath.argument.disabled = not mS.settings.deathCounter.get()
    mS.updateRendererArgument(mS.settings.luckModifierPerDeath)
end

module.initPlayerSettings = function()
    local input = require("openmw.input")

    I.Settings.registerPage {
        key = mDef.MOD_NAME,
        l10n = mDef.MOD_NAME,
        name = "name",
        description = "description",
    }

    input.registerAction {
        key = mDef.actions.showLogs,
        type = input.ACTION_TYPE.Boolean,
        l10n = mDef.MOD_NAME,
        defaultValue = false,
    }

    mS.addTrackerCallback(function(key, _)
        if key == mS.settings.startAttrRatio.key or key == mS.settings.attrGrowthRate.key then
            self:sendEvent(mDef.events.updateRequest, mDef.requestTypes.startAttrsOnResume)
        end
        if key == mS.settings.deathCounter.key then
            updateSettings()
        end
    end)

    updateSettings()
end

module.queueMessage = function(message)
    messageStack[#messageStack + 1] = message
end

module.showMessage = function(state, ...)
    local arg = { ... }
    ui.showMessage(table.concat(arg, "\n"), { showInDialogue = false })
    for i = 1, #arg do
        local message = arg[i]
        log(message)
        table.insert(state.messagesLog, 1, { message = message, time = os.date("%H:%M:%S") })
        if #state.messagesLog > 25 then
            table.remove(state.messagesLog)
        end
    end
end

module.showMessages = function(state)
    if #messageStack > 0 then
        module.showMessage(state, table.unpack(messageStack))
        messageStack = {}
    end
end

module.getBaseStatMods = function()
    local baseStatMods = { attr = {}, skill = {} }
    for _, spell in pairs(T.Actor.activeSpells(self)) do
        if spell.affectsBaseValues then
            for i = 1, #spell.effects do
                local effect = spell.effects[i]
                if effect.affectedAttribute and effect.id == core.magic.EFFECT_TYPE.FortifyAttribute then
                    baseStatMods.attr[effect.affectedAttribute] = (baseStatMods.attr[effect.affectedAttribute] or 0) + math.max(0, effect.magnitudeThisFrame)
                end
                if effect.affectedSkill and effect.id == core.magic.EFFECT_TYPE.FortifySkill then
                    baseStatMods.skill[effect.affectedSkill] = (baseStatMods.skill[effect.affectedSkill] or 0) + math.max(0, effect.magnitudeThisFrame)
                end
            end
        end
    end
    if next(baseStatMods) then
        local baseStatModsKey = string.format("(%s, %s)", mHelpers.mapToString(baseStatMods.attr), mHelpers.mapToString(baseStatMods.skill))
        if baseStatModsKey ~= currBaseStatModsKey then
            currBaseStatModsKey = baseStatModsKey
            log(string.format("Detected new base stats modifiers: %s", baseStatModsKey))
        end
    end
    return baseStatMods
end

return module
