local achievements = require("sb_achievements.achievements")
local interop = require("sb_achievements.interop")
local ui = require("sb_achievements.ui")
local mcm = require("sb_achievements.mcm")

---@type tes3uiElement[]
local menu = {}
---@type tes3uiElement[]
local menuCategories = {}
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
            ---@param achievement achievement
            for _, achievement in ipairs(achievementList) do
                if (tes3.player.data["achievements"][achievement.id] == false and achievement.condition() == true) then
                    tes3.player.data["achievements"][achievement.id] = true

                    popup.visible = true
                    popupAchievements.icon.color = achievement.colour
                    popupAchievements.subicon.contentPath = achievement.icon
                    popupAchievements.title.text = achievement.title
                    popupAchievements.desc.text = achievement.desc
                    popup:updateLayout()

                    timer.start { duration = (achievement.title:len() + achievement.desc:len()) *
                        tes3.findGMST(tes3.gmst.fMessageTimePerChar).value, type = timer.real, callback = function()
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
        interop.unlockedAchievements[0] = 0

        ---@param category category
        for category, _ in ipairs(interop.category) do
            interop.unlockedAchievements[category] = 0

            if (interop.countTotalAchievements(category) == 0) then
                menu[category].visible = false
            else
                menu[category].visible = true

                ---@param index number
                ---@param achievementElement achievementElement
                for index, achievementElement in ipairs(menuAchievements[category]) do
                    ---@type achievement
                    local achievement = achievements[category][index]
                    ---@type boolean
                    local unlocked = tes3.player.data["achievements"][achievementElement.id]
                    ---@type boolean
                    local choice = mcm.config.showHiddenAchievements == 0
                    ---@type boolean
                    local hidden = mcm.config.showHiddenAchievements == 1
                    ---@type boolean
                    local grouped = mcm.config.showHiddenAchievements == 3
                    ---@type boolean
                    local hide = achievement.configDesc == interop.configDesc.hideDesc
                    ---@type boolean
                    local group = achievement.configDesc == interop.configDesc.groupHidden

                    interop.unlockedAchievements[category] = interop.unlockedAchievements[category] +
                        (unlocked and 1 or 0)

                    if (unlocked == false and ((hidden and group) or (grouped and (hide or group)))) then
                        achievementElement.element.visible = false
                    else
                        achievementElement.element.visible = true

                        achievementElement.icon.color = unlocked == true and achievement.colour or interop.colours.white
                        achievementElement.desc.text = ((unlocked == false and hide and choice) and achievement.lockedDesc)
                            or (unlocked == false and hidden and "")
                            or achievement.desc

                        achievementElement.icon.imageScaleX = 0.5
                        achievementElement.icon.imageScaleY = 0.5
                        achievementElement.subicon.imageScaleX = 0.5
                        achievementElement.subicon.imageScaleY = 0.5

                        achievementElement.title.parent.borderLeft = 4
                        achievementElement.desc.borderTop = 4
                    end
                end
            end

            local hiddentCount = interop.countHiddenAchievements(category, mcm.config.showHiddenAchievements)
            if (hiddentCount > 0) then
                menuAchievements[category][256].element.visible = true
                menuAchievements[category][256].desc.text = tostring(hiddentCount) .. " remaining."
                menuAchievements[category][256].icon.imageScaleX = 0.5
                menuAchievements[category][256].icon.imageScaleY = 0.5
                menuAchievements[category][256].subicon.imageScaleX = 0.5
                menuAchievements[category][256].subicon.imageScaleY = 0.5
                menuAchievements[category][256].title.parent.borderLeft = 4
                menuAchievements[category][256].desc.borderTop = 4
            else
                menuAchievements[category][256].element.visible = false
            end

            interop.unlockedAchievements[0] = interop.unlockedAchievements[0] + interop.unlockedAchievements[category]
            menuCategories[category].text = tostring(interop.countUnlockedAchievements(category)) ..
                " / " .. tostring(interop.countTotalAchievements(category))
        end

        menuCategories[0].text = tostring(interop.countUnlockedAchievements()) ..
            " / " .. tostring(interop.countTotalAchievements())
    end
end

--- @param e uiActivatedEventData
local function uiActivatedCallback(e)
    if (e.element.id == tes3ui.registerID("MenuStat") and e.newlyCreated) then
        local menuStat = e.element:findChild("MenuStat_left_main")
        menuStat.heightProportional = 1
        menuStat.parent.parent.heightProportional = 1

        local menuInner = menuStat:createThinBorder { id = "sb_achievement_menu" }
        menuInner.widthProportional = 1
        menuInner.heightProportional = 1
        menuInner.borderAllSides = 4
        menuInner.paddingAllSides = 4
        menuInner.flowDirection = tes3.flowDirection.topToBottom

        local menuInnerTop = menuInner:createBlock()
        menuInnerTop.widthProportional = 1
        menuInnerTop.autoHeight = true

        local menuInnerTitle = menuInnerTop:createLabel { text = "Achievements" }
        menuCategories[0] = menuInnerTop:createLabel { text = "0/0" }
        menuInnerTitle.color = { 0.875, 0.788, 0.624 }
        menuCategories[0].absolutePosAlignX = 1

        local menuSub = menuStat.parent.parent:createVerticalScrollPane { id = "sb_achievement_menu" }
        menuSub.autoWidth = true
        menuSub.heightProportional = nil
        menuSub.height = 192
        menuSub.maxHeight = 192
        menuSub.borderAllSides = 4

        if (tes3.player.data["achievements"] == nil) then
            tes3.player.data["achievements"] = {}
        end

        ---@param index number
        for index, category in ipairs(interop.category) do
            local categoryBlock = menuSub:createBlock { id = "sb_" .. tostring(index) }
            categoryBlock.flowDirection = tes3.flowDirection.topToBottom
            categoryBlock.autoHeight = true
            categoryBlock.widthProportional = 1

            menu[index] = categoryBlock
            menu[index]:createLabel { text = category }

            local menuInnerTop = menuInner:createBlock()
            menuInnerTop.widthProportional = 1
            menuInnerTop.borderLeft = 10
            menuInnerTop.autoHeight = true
            menuInnerTop:createLabel { text = category }
            menuCategories[index] = menuInnerTop:createLabel { text = "0/0" }
            menuCategories[index].absolutePosAlignX = 1

            menuAchievements[index] = {}
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
                achievementElement.desc.text = achievement.hideDesc and achievement.desc or achievementElement.desc.text
                achievementElement.element.paddingBottom = 4
                menuAchievements[achievement.category][index] = achievementElement
            end
        end

        ---@param category category
        for category, _ in ipairs(menuCategories) do
            menuAchievements[category][256] = ui.createHiddenGroup(menu[category], category)
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
    popup.maxWidth = 1920 / 5
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

    mcm.init()
end
event.register("initialized", initializedCallback, { priority = interop.priority })
