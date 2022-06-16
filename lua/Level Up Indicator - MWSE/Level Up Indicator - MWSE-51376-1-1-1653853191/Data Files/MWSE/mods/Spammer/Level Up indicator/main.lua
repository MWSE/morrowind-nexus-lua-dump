local mod = {
    name = "Level Up Indicator",
    ver = "1.1",
    cf = {onOff = true, key = {keyCode = tes3.scanCode.l, isShiftDown = false, isAltDown = false, isControlDown = false}, dropDown = 0, slider = 5, sliderpercent = 50, blocked = {}, npcs = {}, textfield = "hello", switch = false}
            }
local cf = mwse.loadConfig(mod.name, mod.cf)

local indicator
local myTimer
event.register("load", function()
    indicator = nil
    myTimer = nil
end)
event.register("uiActivated", function(e)
    if not e.newlyCreated then
        return
    end
    if indicator then
        return
    end

    local parent = e.element:findChild(tes3ui.registerID("PartNonDragMenu_main"))
    indicator = parent:createImage{id = "spa_levelUpIndicator", path = "Textures\\Spammer\\level_up_arrow_512.tga"}
    indicator.absolutePosAlignX = 0
    indicator.absolutePosAlignY = 0.2
    indicator.scaleMode = true
    indicator.width = 48
    indicator.height = 48
    indicator.visible = false
end, {filter = "MenuMulti"})

local function timerCallback(self)
    if not indicator then
        return
    end
    if tes3.mobilePlayer.levelUpProgress < tes3.findGMST("iLevelupTotal").value then
        indicator.visible = false
        self.timer:cancel()
        myTimer = nil
        return
    end
    indicator.visible = not indicator.visible
end

event.register("uiActivated", function()
    if not indicator then
        return
    end
    if not tes3.mobilePlayer then
        return
    end
    if not (indicator.visible and myTimer) then
        indicator.visible = tes3.mobilePlayer.levelUpProgress >= tes3.findGMST("iLevelupTotal").value
    end
    if indicator.visible and not myTimer then
        myTimer = timer.start{type = timer.real, duration = 2, iterations = -1, callback = timerCallback}
    end
end)

event.register("loaded", function()
    if not indicator then
        return
    end
    if not tes3.mobilePlayer then
        return
    end
    if not (indicator.visible and myTimer) then
        indicator.visible = tes3.mobilePlayer.levelUpProgress >= tes3.findGMST("iLevelupTotal").value
    end
    if indicator.visible then
        myTimer = timer.start{type = timer.real, duration = 2, iterations = -1, callback = timerCallback}
    end
end)

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

local function registerModConfig()
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
end --event.register("modConfigReady", registerModConfig)

local function initialized()
local seph = include("seph.hudCustomizer.interop")
if seph then
seph:registerElement("spa_levelUpIndicator", "Level Up Indicator", {positionX = 0.02, positionY = 0.2, width = 48, height = 48}, {position = true, size = true})
end
print("["..mod.name..", by Spammer] "..mod.ver.." Initialized!")
end event.register("initialized", initialized, {priority = -1000})

