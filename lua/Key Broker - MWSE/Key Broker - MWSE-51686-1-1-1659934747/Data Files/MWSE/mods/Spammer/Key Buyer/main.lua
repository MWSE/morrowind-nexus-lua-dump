local mod = {
    name = "Key Buyer",
    ver = "1.1",
    cf = {onOff = true, key = {keyCode = tes3.scanCode.l, isShiftDown = false, isAltDown = false, isControlDown = false}, dropDown = 0, slider = 5, sliderpercent = 50, blocked = {}, npcs = {}, textfield = "hello", switch = false}
            }
local cf = mwse.loadConfig(mod.name, mod.cf)
local skip = true
local count = 0


event.register("loaded", function()
    tes3.addTopic{topic = "keys", updateGUI = true}
end)

---comment
---@param e table|infoGetTextEventData
event.register("infoGetText", function(e)
    local talker = tes3ui.getServiceActor() and tes3ui.getServiceActor().object
    if not talker then return end
    if talker.baseObject.id ~= "tgc_keyBuyer" then return end
    local gimMe = tes3.findDialogue({topic = "keys"})
    if e.info:findDialogue() ~= gimMe then
        tes3.addTopic{topic = "keys", updateGUI = true}
            return
    end
    local text = e:loadOriginalText()
    if string.find(text, "I collect") then
        local keys = 0
        local pcInventory = tes3.player.object.inventory
        for _,stack in pairs(pcInventory) do
            if ((stack.object.objectType == tes3.objectType.miscItem) and stack.object.isKey) then
                keys = keys+1
            end
        end
        if keys > 1 then
            timer.frame.delayOneFrame(function() tes3ui.choice("Yes", 3) end)
            skip = false
        elseif keys > 0 then
            timer.frame.delayOneFrame(function() tes3ui.choice("Yes", 1) end)
            skip = false
        end
    elseif text == "Great!" then
        local keyCount = 0
        local pcInventory = talker.inventory
        for _,stack in pairs(pcInventory) do
            if ((stack.object.objectType == tes3.objectType.miscItem) and stack.object.isKey) then
                keyCount = keyCount+1
            end
        end
        local stock = count-keyCount
        if stock <= 0 then
            e.text = "Thank you! I am now the master of all keys! Here, for you!"
            tes3.addItem{reference= tes3.player, item = "pick_secretmaster"}
            tes3.addItem{reference= tes3.player, item = "probe_secretmaster"}
            talker.aiConfig.bartersLockpicks = true
            talker.aiConfig.bartersProbes = true
            tes3.setStatistic{reference = tes3ui.getServiceActor(), value = 100, skill = tes3.skill.security}
            talker.aiConfig.offersTraining = true
        elseif stock ~= 1 then
            e.text = string.format("Great! There's %s more keys out there. Get them all for me and I'll give you something special!", stock)
        else
            e.text = string.format("Great! There's %s more key out there. Get it for me and I'll give you something special!", stock)
        end
    end
end)


function mod.callback(e)
    if e.item == nil then return end
    local actor = tes3ui.getServiceActor()
    if not actor then return end
    local cost = 1
    tes3.transferItem({from = tes3.player, to = actor, item = e.item, count = e.count})
    tes3.addItem({reference = tes3.player, item = "gold_001", count = e.count*5})
    skip = true
    if cost > 0 then
        timer.delayOneFrame(function()
            local menu = tes3ui.findMenu("MenuDialog")
        if not menu then return end
        local block = menu:findChild("MenuDialog_answer_block")
        if not block then return end
        for _, child in pairs(block.parent.children) do
            if child.name == "MenuDialog_answer_block" and string.find(child.text,"Yes") then
                child:triggerEvent("mouseClick")
            end
        end
        end, timer.real)
    end
end


function mod.showInventorySelect()
    tes3ui.showInventorySelectMenu({
        title = "Keys",
        filter = function(e)
            return ((e.item.objectType == tes3.objectType.miscItem) and e.item.isKey)
        end,
        callback = mod.callback,
    })
    skip = true
end

event.register("enterFrame", function()
    if skip then return end
    local menu = tes3ui.findMenu("MenuDialog")
    if not menu then return end
    local block = menu:findChild("MenuDialog_answer_block")
    if not block then return end
    for _, child in pairs(block.parent.children) do
        if child.name == "MenuDialog_answer_block" and string.find(child.text,"Yes") then child:registerBefore("mouseClick", mod.showInventorySelect)
        elseif child.name == "MenuDialog_answer_block" and string.find(child.text,"No") then
        child:registerBefore("mouseClick", function()
            skip = true end)
        end
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
    print("["..mod.name..", by Spammer] "..mod.ver.." Initialized!")
    if not tes3.isModActive("Key Buyer.ESP") then
        print("Warning: Plugin not enabled! This mod won't work properly!")
    end
    for key in tes3.iterateObjects(tes3.objectType.miscItem) do
        if key.isKey then
            count = count+1
        end
    end
end event.register("initialized", initialized, {priority = -1000})

