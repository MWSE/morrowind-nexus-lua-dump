local vfs = require('openmw.vfs')

local onInitJobs = {}
local onLoadJobs = {}
local onSaveJobs = {}
local onUpdateJobs = {}
local onActiveJobs = {}
local onUiModeChangedJobs = {}
local eventHandlers = {}

for path in vfs.pathsWithPrefix('scripts/wispspell/effects/') do
    if path:match('player%.lua$') then
        local effectKey = path:match('scripts/wispspell/effects/(.-)/player%.lua$')
        if effectKey then
            local modulePath = 'scripts.wispspell.effects.' .. effectKey .. '.player'
            local handlers = require(modulePath)
            if handlers.onInit then onInitJobs[effectKey] = handlers.onInit end
            if handlers.onLoad then onLoadJobs[effectKey] = handlers.onLoad end
            if handlers.onSave then onSaveJobs[effectKey] = handlers.onSave end
            if handlers.onUpdate then onUpdateJobs[effectKey] = handlers.onUpdate end
            if handlers.onActive then onActiveJobs[effectKey] = handlers.onActive end
            if handlers.onUiModeChanged then onUiModeChangedJobs[effectKey] = handlers.onUiModeChanged end
            if handlers.eventHandlers then
                for name, fn in pairs(handlers.eventHandlers) do
                    eventHandlers[name] = fn
                end
            end
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

local function onUiModeChanged(args)
    args = args or {}
    for _, fn in pairs(onUiModeChangedJobs) do
        fn(args.oldMode, args.newMode)
    end
end

local rootEventHandlers = {}
for name, fn in pairs(eventHandlers) do
    rootEventHandlers[name] = fn
end
rootEventHandlers.UiModeChanged = onUiModeChanged

return {
    engineHandlers = {
        onInit = function()
            for _, fn in pairs(onInitJobs) do fn() end
        end,
        onLoad = loadEffectData,
        onSave = saveEffectData,
        onUpdate = function(dt)
            for _, fn in pairs(onUpdateJobs) do fn(dt) end
        end,
        onActive = function()
            for _, fn in pairs(onActiveJobs) do fn() end
        end,
    },
    eventHandlers = rootEventHandlers,
}
