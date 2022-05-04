local ui = {}

---@class achievementElement
---@field id string
---@field element tes3uiElement
---@field icon tes3uiElement
---@field subicon tes3uiElement
---@field title tes3uiElement
---@field desc tes3uiElement

---@class pairCatAch
---@field category category
---@field achievementElement achievementElement

---createAchievementElement
---@param parent tes3uiElement
---@return achievementElement
function ui.createAchievementElement(parent, id)
    local element = parent:createBlock("inner")
    element.width = parent.maxWidth - 20
    element.autoHeight = true
    --element.borderAllSides = 12
    local icon = element:createImage { id = "icon", path = "Icons\\sb_achievements\\icnBackground.tga" }
    local subicon = icon:createImage { path = "Icons\\sb_achievements\\icnDebug.tga" }
    subicon.color = { 0, 0, 0 }

    local textBlock = element:createBlock("text")
    textBlock.width = element.width - 64 - 10
    textBlock.autoHeight = true
    textBlock.borderLeft = 10
    textBlock.flowDirection = tes3.flowDirection.topToBottom

    local title = textBlock:createLabel { id = "title", text = "What is Lorem Ipsum?" }
    title.color = { 0.875, 0.788, 0.624 }
    title.autoHeight = false

    local desc = textBlock:createLabel { id = "desc", text = "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum." }
    desc.borderTop = 10
    desc.wrapText = true

    return { id = id, element = element, icon = icon, subicon = subicon, title = title, desc = desc }
end

return ui