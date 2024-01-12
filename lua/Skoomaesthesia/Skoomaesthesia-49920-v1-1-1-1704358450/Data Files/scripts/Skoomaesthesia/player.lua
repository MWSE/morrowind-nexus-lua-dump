local I = require('openmw.interfaces')

I.Settings.registerPage {
    key = 'Skoomaesthesia',
    l10n = 'Skoomaesthesia',
    name = 'pageName',
    description = 'pageDescription',
}

local addiction = require('scripts.Skoomaesthesia.addiction')
local visuals = require('scripts.Skoomaesthesia.visuals')

return {
    engineHandlers = {
        onConsume = function(item)
            if item.recordId ~= 'potion_skooma_01' then return end
            visuals.dose()
            addiction.dose()
        end,
        onUpdate = function()
            addiction.update()
        end,
        onFrame = function(_)
            visuals.frame()
        end,
        onSave = function()
            return {
                visuals = visuals.save(),
                addiction = addiction.save()
            }
        end,
        onLoad = function(savedState)
            if not savedState then return end
            visuals.load(savedState.visuals)
            addiction.load(savedState.addiction)
        end,
    }
}
