local mod = {
    name = "Animal Extinction",
    ver = "1.2",
    cf = {onOff = true, key = {keyCode = tes3.scanCode.l, isShiftDown = false, isAltDown = false, isControlDown = false}, dropDown = 0, slider = 2000, sliderpercent = 50, blocked = {}, npcs = {}, switch = false}
            }
local cf = mwse.loadConfig(mod.name, mod.cf)

local disabled = {}


--- @param e mobileActivatedEventData
local function onMobileActivated(e)
    if e.reference.object.objectType ~= tes3.objectType.creature then
        return
    end
    if cf.blocked[e.reference.baseObject.id] then
        return
    end
        --print(e.reference.baseObject.id)
        local killCount = tes3.getKillCount({actor = e.reference.baseObject})
        local random = math.random(0, tonumber(cf.slider))
        --debug.log(killCount)
        --debug.log(random)
        if random < killCount then
            e.reference:disable()
            table.insert(disabled, e.reference.object.id)
        elseif table.find(disabled, e.reference.object.id) then
            e.reference:enable()
            table.removevalue(disabled, e.reference.object.id)
        end
end event.register("mobileActivated", onMobileActivated)

--[[local function onMobileDeactivated(e)
    if table.find(disabled, e.reference.object.id) then
        e.reference:enable()
        table.removevalue(disabled, e.reference.object.id)
    end
end event.register("mobileDeactivated", onMobileDeactivated)]]

---@param e infoGetTextEventData
local function rumours(e)
    local extinct = {}
    local talker = tes3ui.getServiceActor()
    if not talker then
        return
    end
    local gimMe = tes3.findDialogue({topic = "latest rumors"})

    if e.info:findDialogue() ~= gimMe then
        return
    end

    for i,v in pairs(tes3.getKillCounts()) do
        if (i.objectType == tes3.objectType.creature) and not cf.blocked[i.id] and v >= tonumber(cf.slider)*0.9 then
            table.insert(extinct, i.name:lower())
        end
    end
    local isSuccess = math.random(0, 100) > 90
    if (not table.empty(extinct)) and isSuccess then
        e.text = string.format("Have you heard? No one has seen any %s in days! I wonder where they went...", table.choice(extinct))
    end
end event.register("infoGetText", rumours)

local function getbooks()
    local fullbooklist = {}
    for book in tes3.iterateObjects(tes3.objectType.creature) do
        if not string.find(book.id:lower(), "uniq") and not string.find(book.id:lower(), "00") and not string.find(book.id:lower(), "summon") then
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

    --local category = page:createCategory(" ")
    --category:createOnOffButton{label = " ", description = " ", variable = mwse.mcm.createTableVariable{id = "onOff", table = cf}}

    --category:createKeyBinder{label = " ", description = " ", allowCombinations = false, variable = mwse.mcm.createTableVariable{id = "key", table = cf, restartRequired = true, defaultSetting = {keyCode = tes3.scanCode.l, isShiftDown = false, isAltDown = false, isControlDown = false}}}

    --[[local category1 = page:createCategory(" ")
    local elementGroup = category1:createCategory("")
    elementGroup:createDropdown { description = " ",
        options  = {
            { label = " ", value = 0 },
            { label = " ", value = 1 },
            { label = " ", value = 2 },
            { label = " ", value = 3 },
            { label = " ", value = 4 },
            { label = " ", value = 5 }
        },
        variable = mwse.mcm:createTableVariable {
            id    = "dropDown",
            table = cf
        }
    }]]

    local category2 = page:createCategory("")
    local subcat = category2:createCategory(" ")
    subcat:createTextField{
        label = "Minimum number of kills to declare a creature \"extinct\":",
        variable = mwse.mcm.createTableVariable{
            id = "slider",
            table = cf,
            numbersOnly = true,
        }
    }

    --subcat:createSlider{label = " ".."%s%%", description = " ", min = 0, max = 100, step = 1, jump = 10, variable = mwse.mcm.createTableVariable{id = "sliderpercent", table = cf}}

    template:createExclusionsPage{label = "Creatures Blacklist", leftListLabel = "Protected Creatures", rightListLabel = "Extinguishable Creatures", description = "Here you can configure which creatures you won't be able to exterminate.", variable = mwse.mcm.createTableVariable{id = "blocked", table = cf}, filters = {{label = "Creatures", callback = getbooks}}}

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
end event.register("modConfigReady", registerModConfig)



local function initialized()
    print("["..mod.name..", by Spammer] "..mod.ver.." Initialized!")
end event.register("initialized", initialized)

