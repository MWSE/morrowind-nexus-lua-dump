local mod = {
    name = "Training Rebalance",
    ver = "1.0",
    cf = {onOff = true, key = {keyCode = tes3.scanCode.l, isShiftDown = false, isAltDown = false, isControlDown = false}, dropDown = 0, slider = 5, sliderpercent = 50, blocked = {}, npcs = {}, textfield = "hello", switch = false}
            }
local cf = mwse.loadConfig(mod.name, mod.cf)

mod.state = 0
local fatigueCurrent
local fatigueMax
mod.skillRaised = function(e)
    mod.state = 0
    if e.source ~= "training" then
        return
    end
    mod.state = 3
    local trainer = tes3ui.getServiceActor()
    if not trainer then
        return
    end
    local skill = e.skill
    local trainerSkill = trainer:getSkillValue(skill)
    local playerSkill = e.level
    local skillRatio = trainerSkill/math.max(1, playerSkill)
    local fatigueBase = tes3.findGMST("fFatigueBase").value
    local fatigueMult = tes3.findGMST("fFatigueMult").value
    fatigueCurrent = tes3.mobilePlayer.fatigue.current
    fatigueMax = tes3.mobilePlayer.fatigue.base
    local normalFatigue = math.max(0, fatigueCurrent/fatigueMax)
    local fatigueTerm = fatigueBase - fatigueMult*(1-normalFatigue)
    local rng = math.random(0, 100)
    local total = rng*skillRatio*fatigueTerm*trainerSkill/65
    if total <= 125-tes3.mobilePlayer.luck.current then
        mod.state = 2
        tes3.modStatistic({reference = tes3.player, skill = skill, limit = true, value = -1})
    elseif total >= 550-tes3.mobilePlayer.luck.current then
        mod.state = 1
        tes3.mobilePlayer:exerciseSkill(skill, 100)
        tes3.messageBox("You doubled your skill increase!")
    end
end

mod.stopSound = function(e)
    if e.sound == tes3.getSound("skillraise") and mod.state == 2 then
        tes3.setStatistic({reference = tes3.player, name = "fatigue", limit = true, current = math.max(1, fatigueCurrent-(fatigueMax/5))})
        return false
    end
end

mod.uiActivated = function()
    local messagebox = {
        tes3ui.findHelpLayerMenu(tes3ui.registerID("MenuNotify1")),
        tes3ui.findHelpLayerMenu(tes3ui.registerID("MenuNotify2")),
        tes3ui.findHelpLayerMenu(tes3ui.registerID("MenuNotify3"))
    }
    for _,menu in pairs(messagebox) do
        local message = menu:findChild("MenuNotify_message")
        if string.find(message.text, "skill increased to") and mod.state == 2 then
            message.text = "You failed to raise your skill."
        elseif string.find(message.text, "skill increased to") and mod.state ~= 0 then
            break
        end
    end
end

mod.enterFrame = function()
    if not fatigueCurrent or not fatigueMax then
        return
    end
    if mod.state == 2 then
        tes3.setStatistic({reference = tes3.player, name = "fatigue", limit = true, current = math.max(1, fatigueCurrent-(fatigueMax/5))})
        timer.start({duration = 1, callback = function() mod.state = 0 end})
    elseif mod.state ~= 0 then
        tes3.setStatistic({reference = tes3.player, name = "fatigue", limit = true, current = math.max(1, fatigueCurrent-(fatigueMax/10))})
        timer.start({duration = 1, callback = function() mod.state = 0 end})
    end
end

local function getExclusionList()
    local fullbooklist = {}
    for book in tes3.iterateObjects(tes3.objectType.book) do
        if not (string.find(book.id:lower(), "skill")) then
            table.insert(fullbooklist, book.id)
        end
    end
    table.sort(fullbooklist)
    return fullbooklist
end

mod.registerModConfig = function()
    local template = mwse.mcm.createTemplate(mod.name)
    template:saveOnClose(mod.name, cf)
    template:register()

    local page = template:createSideBarPage({label="\""..mod.name.."\" Settings"})
    page.sidebar:createInfo{ text = "Welcome to \""..mod.name.."\" Configuration Menu. \n \n \n A mod by Spammer."}
    page.sidebar:createHyperLink{ text = "Spammer's Nexus Profile", url = "https://www.nexusmods.com/users/140139148?tab=user+files" }

    local category0 = page:createCategory(" ")
    category0:createOnOffButton{label = " ", description = " ", variable = mwse.mcm.createTableVariable{id = "onOff", table = cf}}

    category0:createKeyBinder{label = " ", description = " ", allowCombinations = false, variable = mwse.mcm.createTableVariable{id = "key", table = cf, restartRequired = true, defaultSetting = {keyCode = tes3.scanCode.l, isShiftDown = false, isAltDown = false, isControlDown = false}}}

    local category1 = page:createCategory(" ")
    local elementGroup = category1:createCategory("")

    elementGroup:createDropdown { description = " ",
        options  = {
            { label = " ", value = 0 },
            { label = " ", value = 1 },
            { label = " ", value = 2 },
            { label = " ", value = 3 },
            { label = " ", value = 4 },
            { label = " ", value = -1}
        },
        variable = mwse.mcm:createTableVariable {
            id    = "dropDown",
            table = cf
        }
    }

    elementGroup:createTextField{
        label = " ",
        variable = mwse.mcm.createTableVariable{
            id = "textfield",
            table = cf,
            numbersOnly = false,
        }
    }

    local category2 = page:createCategory(" ")
    local subcat = category2:createCategory(" ")

    subcat:createSlider{label = " ", description = " ", min = 0, max = 10, step = 1, jump = 1, variable = mwse.mcm.createTableVariable{id = "slider", table = cf}}

    subcat:createSlider{label = " ".."%s%%", description = " ", min = 0, max = 100, step = 1, jump = 10, variable = mwse.mcm.createTableVariable{id = "sliderpercent", table = cf}}

    template:createExclusionsPage{label = " ", description = " ", variable = mwse.mcm.createTableVariable{id = "blocked", table = cf}, filters = {{label = " ", callback = getExclusionList}}}

    template:createExclusionsPage{label = " ", description = " ", variable = mwse.mcm.createTableVariable{id = "npcs", table = cf}, filters = {{label = "NPCs", type = "Object", objectType = tes3.objectType.npc}}}

    local page2 = template:createSideBarPage({label = "Extermination list"})
    page2:createButton{
        buttonText = "Switch",
        callback = function()
            cf.switch = not cf.switch
            local pageBlock = template.elements.pageBlock
            pageBlock:destroyChildren()
            page2:create(pageBlock)
            template.currentPage = page2
            pageBlock:getTopLevelParent():updateLayout()
        end,
        inGameOnly = false}
    local category = page2:createCategory("")
    category:createInfo{
        text = "",
        inGameOnly = false,
        postCreate = function(self)
        if cf.switch then
            self.elements.info.text = "Creatures gone extinct:"
            self.elements.info.color = tes3ui.getPalette("journal_finished_quest_pressed_color")
        else
            self.elements.info.text = "Creatures you've killed:"
            self.elements.info.color = tes3ui.getPalette("journal_finished_quest_pressed_color")
        end
    end}
    category:createInfo{
        text = "Load a saved game to see this.",
        inGameOnly = true,
        postCreate = function(self)
        if cf.switch then
            if tes3.player then
                local list = ""
                for actor,value in pairs(tes3.getKillCounts()) do
                    if (actor.objectType == tes3.objectType.creature) and (value >= tonumber(cf.slider)) then
                        list = actor.name.."s (RIP)".."\n" .. list
                    end
                end
                if list == "" then
                    list = "None."
                end
                self.elements.info.text = list
            end
        else
            if tes3.player then
                local list = ""
                for actor,value in pairs(tes3.getKillCounts()) do
                    if (actor.objectType == tes3.objectType.creature) and actor.cloneCount > 1 then
                        list = actor.name.."s: "..value.."\n" .. list
                    end
                end
                if list == "" then
                    list = "None."
                end
                self.elements.info.text = list
            end
        end
    end}
end

return mod