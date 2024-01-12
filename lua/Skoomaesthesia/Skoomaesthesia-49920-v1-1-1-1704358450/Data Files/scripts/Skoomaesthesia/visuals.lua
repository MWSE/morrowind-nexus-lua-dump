local core = require('openmw.core')
local storage = require('openmw.storage')
local postprocessing = require('openmw.postprocessing')
local I = require('openmw.interfaces')

I.Settings.registerGroup {
    key = 'SettingsSkoomaesthesia_Visuals',
    page = 'Skoomaesthesia',
    l10n = 'Skoomaesthesia',
    name = 'visualsGroupName',
    permanentStorage = true,
    settings = {
        {
            key = 'maxIntensity',
            name = 'maxIntensity_name',
            renderer = 'number',
            default = 0.3,
            argument = {
                min = 0,
                max = 1,
            },
        },
        {
            key = 'maxBlur',
            name = 'maxBlur_name',
            renderer = 'number',
            default = 1.0,
            argument = {
                min = 0,
                max = 1,
            },
        },
    }
}

local settings = storage.playerSection('SettingsSkoomaesthesia_Visuals')

local shader = postprocessing.load('skoomaesthesia')

local STAGE = {
    idle = "idle",
    beginning = "beginning",
    active = "active",
    ending = "ending"
}

local NEXT_STAGE = {
    [STAGE.beginning] = STAGE.active,
    [STAGE.active] = STAGE.ending,
    [STAGE.ending] = STAGE.idle,
}

local DURATION = {
    [STAGE.beginning] = 1,
    [STAGE.active] = 58,
    [STAGE.ending] = 1,
}

local function elapsed(timestamp)
    return (core.getGameTime() - timestamp) / core.getGameTimeScale()
end

local HANDLER = {
    [STAGE.idle] = function(_) end,
    [STAGE.beginning] = function(state)
        state.power = elapsed(state.timestamp) / DURATION[STAGE.beginning]
    end,
    [STAGE.active] = function(state)
        state.power = 1
    end,
    [STAGE.ending] = function(state)
        state.ending = 1 - elapsed(state.timestamp) / DURATION[STAGE.ending]
    end,
}

local state = {
    stage = STAGE.idle,
    power = 0,
    timestamp = 0,
}

local function dose()
    if state.stage == STAGE.idle then
        shader:enable()
    end
    if state.stage == STAGE.idle or state.stage == STAGE.ending then
        state.stage = STAGE.beginning
    end
    state.timestamp = core.getGameTime()
end

local function frame()
    if state.stage == STAGE.idle then return end
    if elapsed(state.timestamp) > DURATION[state.stage] then
        state.stage = NEXT_STAGE[state.stage]
        state.timestamp = core.getGameTime()
        state.power = 0
        if state.stage == STAGE.idle then
            shader:disable()
        end
    end
    HANDLER[state.stage](state)
    local intensity = state.power * settings:get('maxIntensity')
    shader:setFloat('intensity', intensity)
    local blurRadius = state.power * settings:get('maxBlur')
    shader:setFloat('radius', blurRadius)
    local colorCycle = core.getSimulationTime() * 0.1 % 2
    colorCycle = colorCycle < 1 and colorCycle or (1 - (colorCycle - 1))
    shader:setFloat('cycle', colorCycle)
end

local function save()
    return state
end

local function load(savedState)
    if not savedState then return end
    state.stage = savedState.stage
    state.timestamp = savedState.timestamp
    state.power = savedState.power
end

return {
    dose = dose,
    frame = frame,
    save = save,
    load = load,
}
