
local Background = require("mer.characterBackgrounds.Background")
local common = require("mer.characterBackgrounds.common")
local logger = common.createLogger("Interop")
local UI = require("mer.characterBackgrounds.UI")

---@class CharacterBackgrounds.Interop
local Interop = {}

---@param backgroundConfig CharacterBackgrounds.BackgroundConfig
function Interop.addBackground(backgroundConfig)
    local background = Background:new(backgroundConfig)
    if Background.registeredBackgrounds[background.id] then
        logger:warn("Background %s already exists", background.name)
        return
    end
    Background.registeredBackgrounds[background.id] = background
    logger:info("Background %s added successfully", background.name)
    return background
end

---@param id string
---@return CharacterBackgrounds.Background?
function Interop.getBackground(id)
    return Background.get(id)
end

---@return CharacterBackgrounds.Background?
function Interop.getCurrentBackground()
    return Background.getCurrentBackground()
end

--- Returns true if the background is currently active
---@param backgroundId string The id of the background
---@return boolean #Whether the background is currently active
function Interop.isActive(backgroundId)
    local background = Background.get(backgroundId)
    return background and background:isActive()
end

--- Returns the data table for the background
---@return table? #The data table for the background if available
function Interop.getData(backgroundId)
    local background = Background.get(backgroundId)
    if not background then
        return
    end
    if not tes3.player then
        return
    end
    return background.data
end

---@param e CharacterBackgrounds.UI.createPerkMenu.params
function Interop.openMenu(e)
    UI.createPerkMenu(e)
end

return Interop
