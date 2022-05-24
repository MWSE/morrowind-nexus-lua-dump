local mod = {
    name = "Critical Locks and Traps",
    ver = "1.0",
    cf = {onOff = true, key = {keyCode = tes3.scanCode.l, isShiftDown = false, isAltDown = false, isControlDown = false}, dropDown = 0, slider = 5, sliderpercent = 50, blocked = {}, npcs = {}, textfield = "hello", switch = false}
            }
--local cf = mwse.loadConfig(mod.name, mod.cf)


local lockState
local lockSux
--- @param e lockPickEventData
local function picky(e)
    if e.tool.id == "skeleton_key" then
        return
    end
    tes3.findGMST("sLockFail").value = lockState
    tes3.findGMST("sLockSuccess").value = lockSux
    local security = tes3.mobilePlayer.security.current
    local level = e.lockData.level
    local random = math.random(0, 100)
    if level > security and 10*security < random then
        e.toolItemData.condition = 0
        e.chance = 0
        tes3.findGMST("sLockFail").value = "You completely fail to find the pins and your lockpick shatters in your hands."
    elseif level > security and 2*security < random and e.toolItemData.condition > 1 then
        e.toolItemData.condition = e.toolItemData.condition-1
        tes3.findGMST("sLockFail").value = "Your hand slips and you hear a screeching noise. Your lockpick gets damaged."
        tes3.findGMST("sLockSuccess").value = "Your hand slips and you hear a screeching noise. Your lockpick gets damaged, but you manage to pick the lock."
    elseif security > level and 10*random <= security then
        e.toolItemData.condition = e.toolItemData.condition+1
        e.chance = 100
        tes3.findGMST("sLockSuccess").value = "You manage to perfectly align the pins of the lock without the slightest hiccup."
    end
end event.register("lockPick", picky)
local trapState
local trapSux
--- @param e trapDisarmEventData
local function blinders(e)
    tes3.findGMST("sTrapFail").value = trapState
    tes3.findGMST("sTrapSuccess").value = trapSux
    local security = tes3.mobilePlayer.security.current
    local level = math.random(50, 100)
    local random = math.random(0, 100)
    print(random)
    if level > security and 10*security < random then
        e.toolItemData.condition = 0
        e.chance = 100
        tes3.findGMST("sTrapSuccess").value = "You completely fail to disarm the trap, and instead activate it. Your probe shatters in your hands."
        tes3.cast({reference = e.reference, target = tes3.player, spell = e.lockData.trap, instant = true})
    elseif level > security and 2*security < random and e.toolItemData.condition > 1 then
        e.toolItemData.condition = e.toolItemData.condition-1
        tes3.findGMST("sTrapFail").value = "Your hand slips and you hear a screeching noise. Your probe gets damaged."
        tes3.findGMST("sTrapSuccess").value = "Your hand slips and you hear a screeching noise. Your probe gets damaged, but you manage to disarm the trap."
    elseif security > level and 10*random <= security then
        e.toolItemData.condition = e.toolItemData.condition+1
        e.chance = 100
        tes3.findGMST("sTrapSuccess").value = "You manage to perfectly disarm the trap without the slightest hiccup."
    end
end event.register("trapDisarm", blinders)
















    --[[local function getExclusionList()
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
            { label = " ", value = -1 }
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
end event.register("modConfigReady", registerModConfig)]]

local function initialized()
    print("["..mod.name..", by Spammer] "..mod.ver.." Initialized!")
    lockState = tes3.findGMST("sLockFail").value
    lockSux = tes3.findGMST("sLockSuccess").value
    trapState = tes3.findGMST("sTrapFail").value
    trapSux = tes3.findGMST("sTrapSuccess").value
end event.register("initialized", initialized)

