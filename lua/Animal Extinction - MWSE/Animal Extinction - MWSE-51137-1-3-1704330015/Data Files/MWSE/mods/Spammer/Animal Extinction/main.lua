local mod = {
    name = "Animal Extinction",
    ver = "1.3",
    cf = { onOff = true, key = { keyCode = tes3.scanCode.l, isShiftDown = false, isAltDown = false, isControlDown = false }, dropDown = 0, slider = 2000, sliderpercent = 50, blocked = {}, npcs = {}, switch = false }
}
local cf = mwse.loadConfig(mod.name, mod.cf)


--- @param e mobileActivatedEventData
local function onMobileActivated(e)
    if e.reference.object.objectType ~= tes3.objectType.creature then return end
    if cf.blocked[e.reference.baseObject.id] then return end
    local killCount = tes3.getKillCount({ actor = e.reference.baseObject })
    local random = math.random(0, tonumber(cf.slider))
    --debug.log(killCount)
    --debug.log(random)
    if random < killCount then
        e.reference:delete()
    end
end
event.register("mobileActivated", onMobileActivated)

---@param e infoGetTextEventData
local function rumours(e)
    local extinct = {}
    local talker = tes3ui.getServiceActor()
    if not talker then return end
    local gimMe = tes3.findDialogue({ topic = "latest rumors" })
    if e.info:findDialogue() ~= gimMe then return end

    for i, v in pairs(tes3.getKillCounts()) do
        if (i.objectType == tes3.objectType.creature) and not cf.blocked[i.id] and v >= tonumber(cf.slider) * 0.9 then
            table.insert(extinct, i.name:lower())
        end
    end
    local isSuccess = math.random(0, 100) > 90
    if (not table.empty(extinct)) and isSuccess then
        e.text = string.format("Have you heard? No one has seen any %s in days! I wonder where they went...",
            table.choice(extinct))
    end
end
event.register("infoGetText", rumours)

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


---@return string
local function killSorted()
    local list = {}
    for actor, value in pairs(tes3.getKillCounts()) do
        if ((actor.objectType == tes3.objectType.creature) and actor.cloneCount > 1) and (cf.switch or (value >= tonumber(cf.slider))) then
            list[actor.name] = value
        end
    end
    local sort = ""
    local values = table.values(list, function(a, b) return a > b end)
    while table.size(list) ~= 0 do
        local dead = table.find(list, values[1])
        local n = (cf.switch and string.format("s: %d", values[1])) or " (RIP)"
        sort = sort .. string.trim(dead) .. n .. "\n"
        table.remove(values, 1)
        list[dead] = nil
    end
    return sort
end



local function registerModConfig()
    local template = mwse.mcm.createTemplate(mod.name)
    template:saveOnClose(mod.name, cf)
    template:register()

    local page = template:createSideBarPage({ label = "\"" .. mod.name .. "\" Settings" })
    page.sidebar:createInfo { text = "Welcome to \"" .. mod.name .. "\" Configuration Menu. \n \n \n A mod by Spammer." }
    page.sidebar:createHyperlink { text = "Spammer's Nexus Profile", url = "https://www.nexusmods.com/users/140139148?tab=user+files" }

    local category2 = page:createCategory("")
    local subcat = category2:createCategory(" ")
    subcat:createTextField {
        label = "Minimum number of kills to declare a creature \"extinct\":",
        variable = mwse.mcm.createTableVariable {
            id = "slider",
            table = cf,
            numbersOnly = true,
        }
    }

    template:createExclusionsPage { label = "Creatures Blacklist", leftListLabel = "Protected Creatures", rightListLabel = "Extinguishable Creatures", description = "Here you can configure which creatures you won't be able to exterminate.", variable = mwse.mcm.createTableVariable { id = "blocked", table = cf }, filters = { { label = "Creatures", callback = getbooks } } }

    local page2 = template:createSideBarPage({ label = "Extermination list" })
    page2:createButton {
        buttonText = "Switch",
        callback = function()
            cf.switch = not cf.switch
            local pageBlock = template.elements.pageBlock
            pageBlock:destroyChildren()
            page2:create(pageBlock)
            template.currentPage = page2
            pageBlock:getTopLevelMenu():updateLayout()
        end,
        inGameOnly = false }
    local category = page2:createCategory("")
    category:createInfo {
        text = "",
        inGameOnly = false,
        postCreate = function(self)
            self.elements.info.text = (cf.switch and "Creatures you've killed:") or "Creatures gone extinct:"
            self.elements.info.color = tes3ui.getPalette("journal_finished_quest_pressed_color")
        end }
    category:createInfo {
        text = "Load a saved game to see this.",
        inGameOnly = true,
        postCreate = function(self)
            if tes3.player then
                local list = killSorted()
                if list == "" then
                    list = "None."
                end
                self.elements.info.text = list
            end
        end }
end
event.register("modConfigReady", registerModConfig)



local function initialized()
    print("[" .. mod.name .. ", by Spammer] " .. mod.ver .. " Initialized!")
end
event.register("initialized", initialized)
