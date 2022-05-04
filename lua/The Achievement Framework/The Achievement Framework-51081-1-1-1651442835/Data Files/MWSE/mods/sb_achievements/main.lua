---@type achievement[]
local achievements = require("sb_achievements.achievements")
local interop = require("sb_achievements.interop")
local ui = require("sb_achievements.ui")

---@type tes3uiElement[]
local menu = {}
---@type achievementElement[][]
local menuAchievements = {}
---@type tes3uiElement
local popup = {}
---@type achievementElement
local popupAchievements = {}

--- @param e enterFrameEventData
local function enterFrameCallback(e)
    if (tes3.player and tes3.player.data["achievements"]) then
        ---@param achievementList achievement[]
        for _, achievementList in ipairs(achievements) do
            ---@param index number
            ---@param achievement achievement
            for index, achievement in ipairs(achievementList) do
                if (tes3.player.data["achievements"][achievement.id] == false and achievement.condition() == true) then
                    tes3.player.data["achievements"][achievement.id] = true

                    popup.visible = true
                    popupAchievements.icon.color = achievement.colour
                    popupAchievements.subicon.contentPath = achievement.icon
                    popupAchievements.title.text = achievement.title
                    popupAchievements.desc.text = achievement.desc
                    popup:updateLayout()

                    timer.start { duration = (achievement.title:len() + achievement.desc:len()) * tes3.findGMST(tes3.gmst.fMessageTimePerChar).value, type = timer.real, callback = function()
                        popup.visible = false
                    end }
                end
            end
        end
    end
end

--- @param e menuEnterEventData
local function menuCallback(e)
    local menuStat = tes3ui.findMenu("MenuStat")
    if (menuStat and menuStat.visible) then
        ---@param category number
        for category, _ in ipairs(interop.category) do
            if (interop.countAchievements(category) == 0) then
                menu[category].visible = false
            else
                menu[category].visible = true
                ---@param index number
                ---@param achievementElement achievementElement
                for index, achievementElement in ipairs(menuAchievements[category]) do
                    local unlocked = tes3.player.data["achievements"][achievementElement.id]
                    achievementElement.icon.color = unlocked == true and achievements[category][index].colour or interop.colours.white
                    achievementElement.desc.text = (unlocked == false and achievements[category][index].hideDesc) and achievements[category][index].replaceDesc or achievements[category][index].desc

                    achievementElement.icon.imageScaleX = 0.5
                    achievementElement.icon.imageScaleY = 0.5
                    achievementElement.subicon.imageScaleX = 0.5
                    achievementElement.subicon.imageScaleY = 0.5

                    achievementElement.title.parent.borderLeft = 4
                    achievementElement.desc.borderTop = 4
                end
            end
        end
    end
end

--- @param e uiActivatedEventData
local function uiActivatedCallback(e)
    if (e.element.id == tes3ui.registerID("MenuStat") and e.newlyCreated) then
        local menuStat = e.element:findChild("MenuStat_left_main")
        menuStat.autoWidth = false
        menuStat.autoHeight = false
        menuStat.width = tes3.worldController.viewWidth / 5
        menuStat.heightProportional = 1
        local menuInner = menuStat:createVerticalScrollPane("sb_achievement_menu")
        menuInner.autoWidth = true
        menuInner.heightProportional = 1
        menuInner.borderAllSides = 4

        if (tes3.player.data["achievements"] == nil) then
            tes3.player.data["achievements"] = {}
        end

        ---@param category number
        for category, _ in ipairs(interop.category) do
            local categoryBlock = menuInner:createBlock { id = "sb_" .. tostring(category) }
            categoryBlock.flowDirection = tes3.flowDirection.topToBottom
            categoryBlock.maxWidth = tes3.worldController.viewWidth / 5
            categoryBlock.autoHeight = true
            categoryBlock.widthProportional = 1
            menu[category] = categoryBlock
            menuAchievements[category] = {}
        end

        ---@param index number
        ---@param category string
        for index, category in ipairs(interop.category) do
            menu[index]:createLabel { text = category }
        end

        ---@param menuElement tes3uiElement
        for _, menuElement in ipairs(menu) do
            menuElement.children[1].color = { 0.875, 0.788, 0.624 }
            menuElement.children[1].borderTop = 4
            menuElement.children[1].borderBottom = 4
        end

        ---@param achievementList achievement[]
        for _, achievementList in ipairs(achievements) do
            ---@param index number
            ---@param achievement achievement
            for index, achievement in ipairs(achievementList) do
                if (tes3.player.data["achievements"][achievement.id] == nil) then
                    tes3.player.data["achievements"][achievement.id] = false
                end
                local achievementElement = ui.createAchievementElement(menu[achievement.category], achievement.id)
                achievementElement.icon.color = achievement.colour
                achievementElement.subicon.contentPath = achievement.icon
                achievementElement.title.text = achievement.title
                achievementElement.desc.text = achievement.hideDesc and "Earn to unlock." or achievement.desc
                achievementElement.element.paddingBottom = 4
                menuAchievements[achievement.category][index] = achievementElement
            end
        end
    end
end

--- @param e loadedEventData
local function loadedCallback(e)
    popup = tes3ui.createHelpLayerMenu { id = "sb_achievement" }
    popup.absolutePosAlignX = 1 - (10 / tes3.worldController.viewWidth)
    popup.absolutePosAlignY = (10 / tes3.worldController.viewHeight)
    popup.autoWidth = true
    popup.autoHeight = true
    popup.maxWidth = tes3.worldController.viewWidth / 5
    popup.borderAllSides = 10
    popupAchievements = ui.createAchievementElement(popup, "inner")
    popup:updateLayout()

    popup.visible = false
end

local function initializedCallback(e)
    event.register(tes3.event.enterFrame, enterFrameCallback)
    event.register(tes3.event.menuEnter, menuCallback)
    event.register(tes3.event.uiActivated, uiActivatedCallback)
    event.register(tes3.event.loaded, loadedCallback)
end
event.register("initialized", initializedCallback, { priority = interop.priority })
