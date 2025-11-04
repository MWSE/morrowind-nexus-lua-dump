local I = require("openmw.interfaces")
local storage = require('openmw.storage')

local mDef = require('scripts.HBFS.config.definition')
local mCfg = require('scripts.HBFS.config.configuration')

local module = {
    sections = mCfg.sections,
    settings = mCfg.settings,
}

for _, section in pairs(module.sections) do
    section.get = function(key)
        local group = storage.globalSection(section.key)
        if key then
            return group:get(key)
        else
            return group
        end
    end
    section.getCopy = function(key)
        return storage.globalSection(section.key):getCopy(key)
    end
    section.set = function(key, value)
        storage.globalSection(section.key):set(key, value)
    end
end

for key, setting in pairs(module.settings) do
    setting.get = function()
        if setting.enum then return setting.values[setting.section.get(key)] end
        return setting.section.get(key)
    end
    setting.getCopy = function()
        if setting.enum then return setting.values[setting.section.getCopy(key)] end
        return setting.section.getCopy(key)
    end
    setting.set = function(value)
        if setting.enum then return setting.section.set(key, setting.keys[value]) end
        return setting.section.set(key, value)
    end
    setting.isPercent = setting.renderer == mDef.renderers.percentAndIncrease
end

module.setDisabled = function(key, disabled)
    module.settings[key].argument.disabled = disabled
    I.Settings.updateRendererArgument(module.settings[key].section.key, key, module.settings[key].argument)
end

module.updatePercentArgument = function(key, disabled, withIncrease, perActor)
    module.settings[key].argument.disabled = disabled or module.settings[key].argument.requiresOMW50
    module.settings[key].argument.withIncrease = withIncrease
    module.settings[key].argument.perActor = perActor
    I.Settings.updateRendererArgument(module.settings[key].section.key, key, module.settings[key].argument)
end

return module