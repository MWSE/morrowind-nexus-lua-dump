local bs = require("BeefStranger.functions")
local config = require("BeefStranger.ExpBar.config")
local common = require("BeefStranger.ExpBar.common")
-- local log = bs.createLog("ExpBar")
local log = bs.getLog("ExpBar")
-- log.log:setLogLevel(config.logLevel)
local db, tr, er = log.debug, log.trace, log.error
log.setLogLevel("DEBUG")


event.register("initialized", function()
    print("[MWSE:ExpBar] initialized")
end)


local lastUpdate = 0 --Gets changed to current time
-- local cooldown = 1 --The cooldown for exerciseSkill
local activeSkillBar = {} --Stores a list of active expBars
local skillUpdates = {} --Table to mark a skill as needing an update
local lastProgress = {}

local skillProgressDebug = {} --Debug table to inspect everything in player.skillProgress

---------------------------------------------------------------------------------
---Skill calculations
---------------------------------------------------------------------------------
---@return table skillOutput Table with a list of all allowed skills and their name/level/progress
local function getPlayerSkills()
    ---tr"enabled = %s", config.enabled)
    ---tr"getPlayerSkills triggered")

    local player = tes3.mobilePlayer
    local class = player.object.class

    ---Get all skill bonuses from gmst
    local majorBonus = tes3.findGMST("fMajorSkillBonus").value
    local minorBonus = tes3.findGMST("fMinorSkillBonus").value
    local miscBonus = tes3.findGMST("fMiscSkillBonus").value
    local specialBonus = tes3.findGMST("fSpecialSkillBonus").value

    ---@class SkillInfo
    ---@field skillName string?  -- The name of the skill
    ---@field skillLevel number?  -- The level of the skill
    ---@field normalizedProgress number?  -- The normalized progress of the skill

    ---@type SkillInfo
    local skillOutput = {}

    for skillIndex, progress in ipairs(player.skillProgress) do
        local skillId = skillIndex - 1  -- Adjust for 0-based skill indices
        local skillName = tes3.skillName[skillId]
        local skillLevel = player.skills[skillId + 1].base  -- Getting current skill level
        local skillObj = tes3.getSkill(skillId)

        -----------------------------------
        skillProgressDebug[skillIndex] = {
            skillIndex = skillIndex,
            progress = progress,
            skillName = skillName,
            skillLevel = skillLevel,
            skillId = skillId
        }
        -----------------------------------
        ---Get skills specialization
        local special = skillObj.specialization
        ---Get skillTypes
        local skillType = tes3.mobilePlayer:getSkillStatistic(skillId).type

        -- bs.inspect(config.allowed)
        ---tr"skillName %s - %s", skillName, config.allowed[skillName])

        if config.allowed[skillName] then
            local progressRequirement = 1 + skillLevel
            -- Adjust progress requirement based on skill type and bonuses
            if skillType == tes3.skillType.major then
                progressRequirement = progressRequirement * majorBonus
            elseif skillType == tes3.skillType.minor then
                progressRequirement = progressRequirement * minorBonus
            elseif skillType == tes3.skillType.misc then
                progressRequirement = progressRequirement * miscBonus
            end

            if special == class.specialization then
                progressRequirement = progressRequirement * specialBonus
            end

            local normalizedProgress = (progress / progressRequirement) * 100

            skillOutput[skillId] = {
                skillName = skillName,
                skillLevel = skillLevel,
                normalizedProgress = normalizedProgress,
            }
        end
    end
    return skillOutput
end

---------------------------------------------------------------------------------
---saveMenuLayout not working, using this instead
---------------------------------------------------------------------------------
---@param menu tes3uiElement
local function saveMenuPosition(menu)
    if not tes3.player.data.expMenuPos then
        tes3.player.data.expMenuPos = {}
    end

    -- tes3.player.data.expMenuPos.selected = config.allowed

    tes3.player.data.expMenuPos.x = menu.positionX
    tes3.player.data.expMenuPos.y = menu.positionY
    tes3.player.data.expMenuPos.w = menu.width
    tes3.player.data.expMenuPos.h = menu.height

    local scroller = menu:findChild("scroller")
    if scroller then
        tes3.player.data.expMenuPos.sY = scroller.widget.positionY
    end
end

local function restoreMenuPosition(menu)
    if tes3.player.data.expMenuPos then

        -- config.allowed = tes3.player.data.expMenuPos.selected

        menu.positionX = tes3.player.data.expMenuPos.x
        menu.positionY = tes3.player.data.expMenuPos.y
        menu.width = tes3.player.data.expMenuPos.w
        menu.height = tes3.player.data.expMenuPos.h

        local scroller = menu:findChild("scroller")
        if scroller then
            scroller.widget.positionY = tes3.player.data.expMenuPos.sY or 0
        end
    end
end

local function expBarUI()
    local skillInfo = getPlayerSkills()
    ---------------------------------------------------------------------------------
    ---Top Level expMenu creation
    ---------------------------------------------------------------------------------
    local expBarID = tes3ui.registerID("bsExpBar")
    local expMenu = tes3ui.createMenu { id = expBarID, fixedFrame = false, dragFrame = true }
        expMenu.alpha = config.opacity
        expMenu.flowDirection = tes3.flowDirection.topToBottom
        expMenu.height = 400
        expMenu.minHeight = 100
        expMenu.minWidth = 215
        expMenu.positionX = -842
        expMenu.positionY = 477
        expMenu.text = "Experience"
        expMenu.width = 300

    ---------------------------------------------------------------------------------
    ---Scroll bar creation
    ---------------------------------------------------------------------------------
    local scroller = expMenu:createVerticalScrollPane { id = "Scroller" }

    local scrollTitle = expMenu:findChild("PartDragMenu_title_tint")
        scrollTitle.autoHeight = false
        scrollTitle.childAlignX = 0.5
        scrollTitle.childAlignY = 0
        scrollTitle.height = 18
    local titleLeft = scrollTitle:findChild("PartDragMenu_left_title_block")
        titleLeft.visible = false
    local titleRight = scrollTitle:findChild("PartDragMenu_right_title_block")
        titleRight.visible = false
    ---------------------------------------------------------------------------------------
    for skillId, info in pairs(skillInfo) do
        local name = info.skillName
        local level = info.skillLevel
        local progress = info.normalizedProgress

        if config.allowed[name] then --if skill in allowed table
            ---------------------------------------------------------------------------------
            ---skills Container creation
            ---------------------------------------------------------------------------------
            local skills = scroller:createBlock { id = name .. " Skills" }
                skills.autoHeight = true
                skills.flowDirection = tes3.flowDirection.topToBottom
                skills.widthProportional = 1

            local skillBlock = skills:createBlock { id = "Text-Icon" } --to be able to have this go lefToRight but have bar below,
                skillBlock.flowDirection = tes3.flowDirection.leftToRight
                skillBlock.height = 30
                skillBlock.widthProportional = 1
            ---------------------------------------------------------------------------------
            ---SkillLabel creation
            ---------------------------------------------------------------------------------
            local label = skillBlock:createLabel { id = "Label", text = name }
                label.absolutePosAlignX = 0.6
                label.borderBottom = 8
                label.borderRight = 6
                label.borderTop = 8
                label.positionY = -8

            local lvl = skillBlock:createLabel{id = "lvl", text = tostring(level)}
                lvl.absolutePosAlignX = 1
                lvl.positionY = -12
            ---------------------------------------------------------------------------------
            ---Image creation
            ---------------------------------------------------------------------------------
            local icon = skillBlock:createImage{ id = "Icon", path = common.skillIcon[name] }
                icon.absolutePosAlignX = 0 --Put on left edge
                icon.absolutePosAlignY = 0.07
                icon.borderBottom = 5
                icon.borderTop = 3
                icon.height = 24
                icon.imageScaleX = 0.75
                icon.imageScaleY = 0.75
                icon.width = 24

            skills:register("mouseClick", function()
                if config.removeCheck then 
                    bs.yesNo("Add %s to the blacklist?", name, function(e)
                        if e.button == 0 then
                            bs.msg("%s added to Blacklist", name)
                            config.allowed[name] = false
                            skills.visible = false
                            bs.playSound(bs.sound.Menu_Click)
                        elseif e.button == 1 then
                        end
                    end)
                else
                    bs.playSound(bs.sound.Menu_Click)
                    config.allowed[name] = false
                    skills.visible = false
                end
            end)

            ---------------------------------------------------------------------------------
            ---FillBar/Divider creation
            ---------------------------------------------------------------------------------
            local bar = skills:createFillBar{id = "FillBar", current = progress, max = 100}
                bar.borderBottom = 1
                bar.height = config.slim and 12 or 20
                bar.widthProportional = 1

            local barText = bar:findChild("PartFillbar_text_ptr") --Dont know how to get this otherwise
                barText.absolutePosAlignY = config.slim and 0.75 or nil

            activeSkillBar[name] = bar --Keeping track of active bars

            if config.enableThreshold and (progress < config.threshold) then
                skills.visible = false
            elseif not config.enableThreshold or (progress >= config.threshold) then
                skills.visible = true
            end

            if not config.slim then
                local dividers = skills:createDivider { id = "Divider" }
                    dividers.borderBottom = 5
                    dividers.borderLeft = 30
                    dividers.borderRight = 30
                    dividers.borderTop = 5
            end
        end
    end

    restoreMenuPosition(expMenu)
    expMenu:updateLayout()

end

local function updateFillBar(skillName, newProgress)
    local menu = tes3ui.findMenu("bsExpBar")
    local bar = activeSkillBar[skillName]
    db("[updateFillBar] %s | newProgress - %s", skillName, newProgress)

    if bar then
        if menu then
            local skills = menu:findChild(skillName .. " Skills")
            local fillbar = skills:findChild("FillBar")
            if skills then

                if config.enableThreshold and (newProgress > config.threshold) and not skills.visible then
                    skills.visible = true
                end

                fillbar.widget.current = newProgress
                menu:updateLayout()
            else
                db("No fillbar destroying menu")
                menu:destroy()
                expBarUI()
            end
            menu:updateLayout()
        end
    end
end

local function skillUpdate()

    if next(skillUpdates) == nil then return end --Bail if table is empty

    local skillOutput = getPlayerSkills()
    for skillID, _ in pairs(skillOutput) do --Get all skillID's in skillOutput
        local info = skillOutput[skillID]
        if info then
            local progress = info.normalizedProgress
            local last = lastProgress[skillID] or 0

            tr("threshhold >= config %s", progress >= config.threshold)
            
            if (progress >= config.threshold or config.threshold == false) and progress - last >= 1 then
                updateFillBar(info.skillName, progress)
                tr("[skillUpdate]: progress - %s, last - %s, calc - %s", progress, last, progress - last)
            end
            lastProgress[skillID] = progress
        end
    end
    skillUpdates = {} --Clear skillUpdates table
end

---@param e exerciseSkillEventData
event.register("exerciseSkill", function(e)
    if config.enabled == false then return end

    skillUpdates[e.skill] = true --set e.skill to true in skillUpdates table
    local cooldown = config.refreshRate

    local currentTime = os.clock()
    if currentTime - lastUpdate >= cooldown then
        tr("refreshRate - %s", cooldown)
        tr("time %s, last %s, diff - %s", currentTime, lastUpdate, currentTime - lastUpdate)
        lastUpdate = currentTime
        skillUpdate()
    end
end)

event.register("skillRaised", function(e)
    if config.enabled == false then return end
    local menu = tes3ui.findMenu("bsExpBar")

    if menu then
        saveMenuPosition(menu)
        menu:destroy() -- Destroy then remake expBar on skill level gain
        expBarUI()
    end
end)


---@param e keyUpEventData
event.register("keyUp", function (e)
    if not tes3.onMainMenu() and e.keyCode == config.keycode.keyCode and tes3.isCharGenFinished() then
        if config.enabled == false then return end


        -- event.trigger("bxExpBar:RefreshUI")

        tr("%s pressed", config.keycode.keyCode)

        local menu = tes3ui.findMenu("bsExpBar")
        if menu then
            saveMenuPosition(menu)
            menu:destroy()
        else
            expBarUI()
        end
    end
end)

local refreshExp = "bsExpBar:RefreshUI"


---Why is Hand to hand only different in this menu 
local skillNameMapping = {
    ["Hand-to-hand"] = "Hand to Hand",
}
local function trigger()
    event.trigger("bsExpBar:RefreshUI")
    bs.playSound(bs.sound.Menu_Click)
end

---Add Skill to bar when clicking it in Stat Menu
event.register("menuEnter", function(e)
    local menu = tes3ui.findMenu("MenuStat")

    if menu and menu.visible then
        tr("MenuStat visible")
        local scrollPane = menu:findChild("PartScrollPane_pane")

        for _, child in ipairs(scrollPane.children) do
            local major = child:findChild("MenuStat_major_name")
            local minor = child:findChild("MenuStat_minor_name")
            local misc = child:findChild("MenuStat_misc_name")

            if major then
                local correctedMajor = skillNameMapping[major.text] or major.text
                major:register(tes3.uiEvent.mouseClick, function()
                    ---err("Major: %s clicked", major.text)
                    config.allowed[correctedMajor] = true
                    bs.msg("%s added to ExpBar", correctedMajor)
                    trigger()
                end)
            elseif minor then
                local correctedMinor = skillNameMapping[minor.text] or minor.text
                minor:register(tes3.uiEvent.mouseClick, function()
                    ---err("Minor: %s clicked", minor.text)
                    tr("CorrectMinor: %s clicked", correctedMinor)
                    config.allowed[correctedMinor] = true
                    bs.msg("%s added to ExpBar", correctedMinor)
                    trigger()
                end)
            elseif misc then
                local correctedMisc = skillNameMapping[misc.text] or misc.text
                misc:register(tes3.uiEvent.mouseClick, function()
                    ---err("Misc: %s clicked", misc.text)
                    tr("CorrectMisc: %s clicked", correctedMisc)
                    config.allowed[correctedMisc] = true
                    bs.msg("%s added to ExpBar", correctedMisc)
                    trigger()
                end)
            end
        end

        menu:updateLayout()
    end
end)


---Custom event test
event.register(refreshExp, function ()
    if tes3.player then
        local menu = tes3ui.findMenu("bsExpBar")
        if menu then
            saveMenuPosition(menu)
            menu:destroy()
        end
        expBarUI()
    end
end)