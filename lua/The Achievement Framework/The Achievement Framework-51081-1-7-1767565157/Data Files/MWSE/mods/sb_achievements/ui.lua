local utils = require("sb_achievements.utils")
local i18n = mwse.loadTranslations("sb_achievements")
local ui = {}

---@class achievementElement
---@field id string
---@field element tes3uiElement
---@field icon tes3uiElement
---@field subIcon tes3uiElement
---@field title tes3uiElement
---@field desc tes3uiElement

---@class pairCatAch
---@field category category
---@field achievementElement achievementElement

---createAchievementElement
---@param parent tes3uiElement
---@param id string
---@return achievementElement
function ui.createAchievementElement(parent, id)
    local element = parent:createBlock{ id = "inner"}
    if (parent.maxWidth) then
        element.width = parent.maxWidth - 20
    else
        element.widthProportional = parent.widthProportional
    end
    element.autoHeight = true
    local icon = element:createImage { id = "icon", path = "Icons\\sb_achievements\\icnBackground.tga" }
    local subIcon = icon:createImage { path = "Icons\\sb_achievements\\icnDebug.tga" }
    subIcon.color = { 0, 0, 0 }

    local textBlock = element:createBlock{id ="text"}
    textBlock.widthProportional = 1
    textBlock.autoHeight = true
    textBlock.borderLeft = 10
    textBlock.flowDirection = tes3.flowDirection.topToBottom

    local title = textBlock:createLabel { id = "title", text = i18n("element.base.title") }
    title.color = { 0.875, 0.788, 0.624 }
    title.widthProportional = 1
    title.autoHeight = false
    title.wrapText = true

    local desc = textBlock:createLabel { id = "desc", text = i18n("element.base.desc") }
    desc.borderTop = 10
    desc.widthProportional = 1
    desc.wrapText = true

    return { id = id, element = element, icon = icon, subIcon = subIcon, title = title, desc = desc }
end

---createHiddenGroup
---@param category category
---@return achievementElement
function ui.createHiddenGroup(parent, category)
    local element = ui.createAchievementElement(parent, tostring(category) .. "_hidden")
    element.icon.color = utils.colours.white
    element.title.text = i18n("element.Group.title")
    element.desc.text = i18n("element.Group.desc")
    element.element.paddingBottom = 4
    return element
end

return ui