local self = require("openmw.self")
local I = require("openmw.interfaces")
local core = require("openmw.core")

local deps = require("scripts.CharacterTraitsFramework.utils.dependencies")
deps.checkAll("Character Traits Framework", { {
    plugin = "StatsWindow.omwscripts",
    interface = I.StatsWindow,
} })

local StatsWindow = require("scripts.CharacterTraitsFramework.ui.statWindow")
local Trait = require("scripts.CharacterTraitsFramework.model.trait")
local TraitsWindow = require("scripts.CharacterTraitsFramework.ui.traitsWindow")

---@type table<string, table<string, Trait>>
local allTraits = {
    -- type = {
    --     id = Trait,
    -- },
}
---@type table<string, string>
local selectedTraits = {
    -- type = id,
}
local traitWindowVisible = false
local allTraitsPicked = true
local mouseWheelHandler = function() end

local function traitMenuVisibilityUpdated(prevStatus)
    traitWindowVisible = not prevStatus
    if traitWindowVisible then
        mouseWheelHandler = TraitsWindow.getMouseWheelHandler()
        ---@diagnostic disable-next-line: missing-fields
        I.UI.setMode('Interface', { windows = {} })
        core.sendGlobalEvent('Pause', 'ui')
    else
        mouseWheelHandler = function() end
        I.UI.setMode()
        core.sendGlobalEvent('Unpause', 'ui')
    end
end

local function traitSelected(data)
    selectedTraits[data.type] = data.id

    local trait = allTraits[data.type][data.id]
    StatsWindow.updateTraitLine(trait)
    trait:doOnce()
    trait:onLoad()

    traitMenuVisibilityUpdated(traitWindowVisible)
end

local function initTraitWindow()
    allTraitsPicked = true
    for traitType, traitMap in pairs(allTraits) do
        if not selectedTraits[traitType] then
            TraitsWindow.new(traitMap)
            allTraitsPicked = false
            break
        end
    end

    if allTraitsPicked then
        self:sendEvent("CharacterTraits_allTraitsPicked")
        return
    end

    traitMenuVisibilityUpdated(traitWindowVisible)
end

local function onUpdate()
    if allTraitsPicked
        or not self.type.isCharGenFinished(self)
        or I.UI.getMode()
        or traitWindowVisible
    then
        return
    end

    initTraitWindow()
end

local function addTrait(data)
    local newTrait = Trait:new(data)

    if not allTraits[newTrait.type] then
        local nilTrait = Trait:new {
            id = "nil",
            type = newTrait.type,
            name = "-None-",
            description = "No " .. newTrait.type .. " selected.",
        }
        allTraits[newTrait.type] = {
            [nilTrait.id] = nilTrait,
            [newTrait.id] = newTrait,
        }
        allTraitsPicked = false
        StatsWindow.updateTraitLine(nilTrait)
    else
        if allTraits[newTrait.type][newTrait.id] then
            print("Overriding trait id: " .. newTrait.id)
        end
        allTraits[newTrait.type][newTrait.id] = newTrait
    end

    if selectedTraits[newTrait.type] == newTrait.id then
        StatsWindow.updateTraitLine(newTrait)
        newTrait:onLoad()
    end
end

local function onLoad(data)
    if not data then return end
    selectedTraits = data.selectedTraits or selectedTraits
end

local function onSave()
    return {
        selectedTraits = selectedTraits
    }
end

return {
    engineHandlers = {
        onLoad = onLoad,
        onSave = onSave,
        onMouseWheel = function(...)
            ---@diagnostic disable-next-line: redundant-parameter
            mouseWheelHandler(...)
        end,
        onUpdate = onUpdate,
    },
    eventHandlers = {
        CharacterTraits_traitSelected = traitSelected,
    },
    interfaceName = "CharacterTraits",
    interface = {
        version           = 1,
        addTrait          = addTrait,
        getAllTraits      = function() return allTraits end,
        getSelectedTraits = function() return selectedTraits end,
        allTraitsPicked   = function() return allTraitsPicked end,
    }
}
