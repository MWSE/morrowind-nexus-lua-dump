local vfs = require('openmw.vfs')

local eventHandlers = {}
local onLoadJobs = {}
local onSaveJobs = {}
local onUpdateJobs = {}

for path in vfs.pathsWithPrefix('scripts/wispspell/effects/') do
    if path:match('global%.lua$') then
        local effectKey = path:match('scripts/wispspell/effects/(.-)/global%.lua$')
        if effectKey then
            local modulePath = 'scripts.wispspell.effects.' .. effectKey .. '.global'
            local handlers = require(modulePath)
            if handlers.eventHandlers then
                for name, fn in pairs(handlers.eventHandlers) do
                    eventHandlers[name] = fn
                end
            end
            if handlers.onLoad then onLoadJobs[effectKey] = handlers.onLoad end
            if handlers.onSave then onSaveJobs[effectKey] = handlers.onSave end
            if handlers.onUpdate then onUpdateJobs[effectKey] = handlers.onUpdate end
        end
    end
end

local function loadEffectData(save)
    local savedEffects = save and save.effectData or {}
    for key, fn in pairs(onLoadJobs) do
        fn(savedEffects[key])
    end
end

local function saveEffectData()
    local effectData = {}
    for key, fn in pairs(onSaveJobs) do
        effectData[key] = fn()
    end
    return { effectData = effectData }
end

return {
    engineHandlers = {
        onLoad = loadEffectData,
        onSave = saveEffectData,
        onUpdate = function(dt)
            for _, fn in pairs(onUpdateJobs) do fn(dt) end
        end,
    },
    eventHandlers = eventHandlers,
}
