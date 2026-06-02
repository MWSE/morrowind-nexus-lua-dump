local self = require('openmw.self')
local T = require('openmw.types')

local mS = require('scripts.MULE.settings')
mS.initPlayerSettings()

local mDef = require('scripts.MULE.definition')
local log = require('scripts.MULE.util')
local mSkills = require('scripts.MULE.skills')

local state = {
    savedGameVersion = mDef.savedGameVersion,
    isInitialized = false,
    miscSkillsRaised = 0,
    skills = { major = {}, minor = {}, misc = {}, baseValues = {}, lastUsed = {} },
    attrs = { progress = {} },
}

local handlersInstalled = false
local function installHandlers()
    if handlersInstalled then return end
    handlersInstalled = true
    mSkills.addHandlers(state)
end

local function init()
    for attrId in pairs(T.Actor.stats.attributes) do
        state.attrs.progress[attrId] = state.attrs.progress[attrId] or 0
    end
    mSkills.classifySkills(state)
    mSkills.captureBaseSkills(state)
    state.isInitialized = true
    installHandlers()
    log("MULE initialized.")
end

local function onUpdate()
    if not state.isInitialized and T.Player.isCharGenFinished(self) then
        init()
    end
end

local function onActive()
    if state.isInitialized then installHandlers() end
end

local function onLoad(data)
    if not data then return end
    state = data
    state.savedGameVersion = mDef.savedGameVersion
    if state.isInitialized then installHandlers() end
end

local function onSave()
    return state
end

local function uiModeChanged(data)
    -- class can change during chargen review
    if not data.newMode and data.oldMode == "ChargenClassReview" then
        mSkills.classifySkills(state)
    end
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onActive = onActive,
        onLoad = onLoad,
        onSave = onSave,
    },
    eventHandlers = {
        UiModeChanged = uiModeChanged,
    },
}
