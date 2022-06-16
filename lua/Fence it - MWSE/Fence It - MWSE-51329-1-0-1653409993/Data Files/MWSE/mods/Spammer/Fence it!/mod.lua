local mod = {
    name = "Fence it!",
    ver = "1.0",
    cf = {onOff = true, key = {keyCode = tes3.scanCode.l, isShiftDown = false, isAltDown = false, isControlDown = false}, dropDown = 0, slider = 5, sliderpercent = 50, blocked = {}, npcs = {}, textfield = "hello", switch = false}
            }
local cf = mwse.loadConfig(mod.name, mod.cf)
local count
local answer1
local answer2
local answer3 = string.format("Nevermind.")
local cost
local list = {}


---@param e infoGetTextEventData
function mod.onInfoGetText(e)
    list = {}
    count = 0
    if not tes3.player then return end
    local talker = tes3ui.getServiceActor()
    if not talker then return end
    if talker.object.class.name ~= "Pawnbroker" then return end
    if not talker.reference.data.spa_fenceCost then
        talker.reference.data.spa_fenceCost = math.random(4000, 10000)
    end
    local pcInventory = tes3.player.object.inventory
    for _,stack in pairs(pcInventory) do
        if tes3.getItemIsStolen({item = stack.object, from = nil}) and not table.find(list, stack.object.id) then
            table.insert(list, stack.object.id)
        end
    end
    count = #list
    if count == 0 then return end
    local gold = tes3.getPlayerGold()
    local gimMe = tes3.findDialogue({topic = "little secret"})
    if e.info:findDialogue() ~= gimMe then
        return
    end
    local random = talker.reference.data.spa_fenceCost
    cost = math.floor(random/talker.object.disposition)
    answer1 = string.format("[Fence your stolen items] (10%% of their real value)")
    answer2 = string.format("[Clean one of your stolen items] (Cost: %s gold)", cost)
    e.text = string.format("So you have some goods from questionable provenance, eh? I might be able to help you clean'em... for a price of course. It will cost you %s gold per item. Sounds fair, don't you think? /nIf you don't like it, I guess I could also buy them from you... not at full price, obviously.", cost)
    timer.delayOneFrame(function()
        if gold >= cost then tes3ui.choice(answer2, 8) end
        tes3ui.choice(answer1, 9)
        tes3ui.choice(answer3, 7)
    end, timer.real)
end


function mod.callback(e)
    if e.item == nil then return end
    local _, stolenFrom = tes3.getItemIsStolen({item = e.item, from = nil})
    for _, owner in pairs(stolenFrom) do
    tes3.setItemIsStolen({item = e.item, from = owner, stolen = false})
    end
    tes3.transferItem({from = tes3.player, to = tes3ui.getServiceActor(), item = "gold_001", count = cost})
    count = 0
    local gold = tes3.getPlayerGold()
    if gold >= cost then
        timer.delayOneFrame(function()
            local menu = tes3ui.findMenu("MenuDialog")
            if not menu then return end
            local block = menu:findChild("MenuDialog_answer_block")
            if not block then return end
            for _, child in pairs(block.parent.children) do
                if child.name == "MenuDialog_answer_block" and string.find(child.text,"Clean one of your stolen items") then
                    child:triggerEvent("mouseClick")
                end
            end
        end, timer.real)
    else
        tes3.closeDialogueMenu({force = true})
    end
end

function mod.showInventorySelect()
    local itemDatas = {}
    for _, stack in pairs(tes3.player.object.inventory) do
        if tes3.getItemIsStolen{item = stack.object} then
            local vars = stack.variables or { false }
            itemDatas[stack.object] = vars[1]
        end
    end
    tes3ui.showInventorySelectMenu({
        title = "Stolen Items",
        leaveMenuMode = true,
        filter = function(e)
            local data = e.itemData or false
            return itemDatas[e.item] == data
        end,
        callback = mod.callback,
    })
end


function mod.buyback(e)
    if e.item == nil then return end
    local gold = tes3.getItemCount({reference = tes3ui.getServiceActor(), item = "gold_001"})
    local buyingCost = math.floor(e.item.value*e.count/10)
    if gold < buyingCost then
        tes3.messageBox("%s does not have enough gold to buy that many %ss!", tes3ui.getServiceActor().object.name, e.item.name)
        timer.delayOneFrame(function()
            local menu = tes3ui.findMenu("MenuDialog")
            if not menu then return end
            local block = menu:findChild("MenuDialog_answer_block")
            if not block then return end
            for _, child in pairs(block.parent.children) do
                if child.name == "MenuDialog_answer_block" and string.find(child.text,"Fence your stolen items") then
                    child:triggerEvent("mouseClick")
                end
            end
        end, timer.real)
        return
    end
    local _, stolenFrom = tes3.getItemIsStolen({item = e.item, from = nil})
    for _, owner in pairs(stolenFrom) do
    tes3.setItemIsStolen({item = e.item, from = owner, stolen = false})
    end
    tes3.transferItem({from = tes3.player, to = tes3ui.getServiceActor(), item = e.item, itemData = e.itemData, count = e.count})
    tes3.transferItem({from = tes3ui.getServiceActor(), to = tes3.player, item = "gold_001", count = buyingCost})
    count = 0
    timer.delayOneFrame(function()
        local menu = tes3ui.findMenu("MenuDialog")
        if not menu then return end
        local block = menu:findChild("MenuDialog_answer_block")
        if not block then return end
        for _, child in pairs(block.parent.children) do
            if child.name == "MenuDialog_answer_block" and string.find(child.text,"Fence your stolen items") then
                child:triggerEvent("mouseClick")
            end
        end
    end, timer.real)
end

function mod.showBuyingMenu()
    local itemDatas = {}
    for _, stack in pairs(tes3.player.object.inventory) do
        if tes3.getItemIsStolen{item = stack.object} then
            local vars = stack.variables or { false }
            itemDatas[stack.object] = vars[1]
        end
    end
    tes3ui.showInventorySelectMenu({
        title = "Stolen Items",
        leaveMenuMode = true,
        filter = function(e)
            local data = e.itemData or false
            return itemDatas[e.item] == data
        end,
        callback = mod.buyback,
    })
end

function mod.postInfoResponse()
    if count == 0 then return end
    local menu = tes3ui.findMenu("MenuDialog")
    if not menu then return end
    local block = menu:findChild("MenuDialog_answer_block")
    if not block then return end
    for _, child in pairs(block.parent.children) do
        if child.name == "MenuDialog_answer_block" and string.find(child.text,"Clean one of your stolen items") then child:registerBefore("mouseClick", mod.showInventorySelect)
        elseif child.name == "MenuDialog_answer_block" and string.find(child.text,"Fence your stolen items") then child:registerBefore("mouseClick", mod.showBuyingMenu)
        elseif child.name == "MenuDialog_answer_block" and string.find(child.text,"Nevermind") then
        child:registerBefore("mouseClick", function()
            count = 0
            tes3.closeDialogueMenu({force = true}) end)
        end
    end
    local goodbye = menu:findChild("MenuDialog_button_bye")
    goodbye:registerBefore("mouseClick", function()
        count = 0
        tes3.closeDialogueMenu({force = true}) end)
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

function mod.registerModConfig()
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