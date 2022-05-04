local mod = {
    name = "Thief!",
    ver = "1.0",
    cf = {onOff = true, key = {keyCode = tes3.scanCode.l, isShiftDown = false, isAltDown = false, isControlDown = false}, dropDown = 0, slider = 70, sliderpercent = 15, blocked = {}, npcs = {},}
            }
local cf = mwse.loadConfig(mod.name, mod.cf)

local state = 0
local thievesList = {}
local stolenList = {}
local stolenData = {}
local stolenCount = {}
local myTimer = nil
local dialogID = {
    "1471322831213057918",
    "10343167362771029193",
    "14035173113161727385",
    "2682931338265694225",
    "189411893301587102",
    "14946981448322538",
    "3204147182354114881",
    "1773222623213229315",
    "3016716281193932537",
    "2086243121703526",
    "1991421659422921552",
    "1643830350181516343",
    "1205123837234059222",
    "2591023515216602066",
    "660830491438831439",
    "48519316258763832"
}

local function validateObjectNPCs(mobile)
    local class = mobile.object and mobile.object.class
    local faction = mobile.object and mobile.object.faction
    local id = class and class.id
    local disposition = mobile.object and mobile.object.disposition
    if faction and faction.playerJoined and not faction.playerExpelled then
        return false
    elseif mobile.inCombat or mobile.isDead or mobile.isPlayerHidden then
        return false
    elseif disposition and disposition > 80 then
        return false
    elseif id and (string.find(id:lower(), "thief") or (string.find(id:lower(), "rogue")) or (string.find(id:lower(), "pauper"))) then
        return true
    end
    return false
end

local function inventoryList()
    local data = {}
    local inventory = {}
    local player = tes3.player.object
    local pcInventory = tes3.player.object.inventory
    for i,stack in pairs(pcInventory) do
        if player and not player:hasItemEquipped(stack.object) then
        --if stack.object.objectType ~= tes3.objectType.armor then
            table.insert(inventory, i, stack.object)
            table.insert(data, i, stack.itemData)
        end
    end
    return inventory, data
end

local function filthyThief()
    local mobileList = tes3.findActorsInProximity{reference = tes3.player, range = 200}
    for _, mobile in ipairs(mobileList) do
        if ((mobile.actorType == tes3.actorType.npc) and validateObjectNPCs(mobile)) and state == 0 then
            local random = math.random(0, 100)
            --tes3.messageBox("Random = %d", random)
            if random < cf.sliderpercent then
                local inventory, data = inventoryList()
                local choice = table.choice(inventory)
                local alert = math.random(0, 100)
                local security = tes3.mobilePlayer.security.current
                local max = tes3.getItemCount({reference = tes3.player, item = choice})
                if max > 200 then
                    max = 100
                elseif max > 2 then
                    max = math.floor(max/2)
                end
                local count = math.random(1, max)
                table.insert(stolenCount, count)
                table.insert(stolenList, choice)
                table.insert(thievesList, mobile.object.id)
                table.insert(stolenData, data[table.find(inventory, choice)])
                if cf.slider*alert <= security*100 then
                    state = 1
                    tes3.transferItem({from = tes3.player, to = mobile, item = choice, itemData = data[table.find(inventory, choice)], count = count})
                    if count == 1 then
                        tes3.messageBox("Your %s just got stolen!", choice.name)
                    else
                        tes3.messageBox("%d of your %ss just got stolen!", count, choice.name)
                    end
                    timer.start({duration = 30, callback = function()
                        state = 0
                    end})
                else
                    state = math.random(0, 1)
                    local dur = math.random(30, 60)
                    tes3.transferItem({from = tes3.player, to = mobile, item = choice, itemData = data[table.find(inventory, choice)], playSound = false, count = count})
                    --tes3.messageBox("state = %s", state)
                    if state == 1 then
                        timer.start({duration = dur, callback = function()
                            state = 0
                            tes3.messageBox("You feel like something is missing from your pockets...")
                        end})
                    end
                end
            end
        end
    end
end

local function onLoad()
    if myTimer then
        myTimer:cancel()
        myTimer = nil
        state = 0
    end
    myTimer = timer.start({iterations = -1, duration = .5, callback = filthyThief, type = timer.simulate})
end event.register("loaded", onLoad)

    ---@param e infoGetTextEventData
local function giveItBack(e)
    local isSuccess = false
    local talker = tes3ui.getServiceActor()
    if not talker then
        return
    end
    local thief = table.find(thievesList, talker.object.id)
    local gimMe = tes3.findDialogue({type = tes3.dialogueType.service, page = tes3.dialoguePage.service.initimidateSuccess})
    if not thief then
        return
    end
    if e.info.type ~= tes3.dialogueType.service then
        return
    end

    if e.info:findDialogue() == gimMe then
        isSuccess = true
    end
   --[[ for _,info in ipairs(dialogID) do
        if e.info.id and e.info.id == info then
            isSuccess = true
            break
        end
    end]]
    if isSuccess then
        e.text = string.format("All right, all right... here's your %s!", stolenList[thief].name)
        tes3.transferItem({from = talker.object.id, to = tes3.player, item = stolenList[thief], itemData = stolenData[thief], count = stolenCount[thief]})
        if stolenCount[thief] == 1 then
            tes3.messageBox("You got your %s back.", stolenList[thief].name)
        else
            tes3.messageBox("You got your %d %ss back.", stolenCount[thief], stolenList[thief].name)
        end
        table.remove(thievesList, thief)
        table.remove(stolenList, thief)
        table.remove(stolenData, thief)
        table.remove(stolenCount, thief)
    end
end event.register("infoGetText", giveItBack)

--[[
    local function getExclusionList()
        local fullbooklist = {}
        for book in tes3.iterateObjects(tes3.objectType.book) do
            if not (string.find(book.id:lower(), "skill")) then
                table.insert(fullbooklist, book.id)
            end
        end
        table.sort(fullbooklist)
        return fullbooklist
    end]]

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

   -- local category1 = page:createCategory(" ")
  --  local elementGroup = category1:createCategory("")
   --[[ elementGroup:createDropdown { description = " ",
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
    }]]

    local category2 = page:createCategory("")
    local subcat = category2:createCategory("Config:")
    subcat:createSlider{label = "Security Level", description = "Choose at which minimum level the pickpocketing notice will start to appear. [Default: 70]", min = 0, max = 100, step = 1, jump = 10, variable = mwse.mcm.createTableVariable{id = "slider", table = cf}}

    subcat:createSlider{label = "Chance of occurence: ".."%s%%", description = "Configure the chances for something to be stolen from you when you pass by a thief. [Default: 15]", min = 0, max = 100, step = 1, jump = 10, variable = mwse.mcm.createTableVariable{id = "sliderpercent", table = cf}}

    --template:createExclusionsPage{label = " ", description = " ", variable = mwse.mcm.createTableVariable{id = "blocked", table = cf}, filters = {{label = " ", callback = getExclusionList}}}

    --template:createExclusionsPage{label = " ", description = " ", variable = mwse.mcm.createTableVariable{id = "npcs", table = cf}, filters = {{label = "NPCs", type = "Object", objectType = tes3.objectType.npc}}}
end event.register("modConfigReady", registerModConfig)

--[[local function message(e)
    if e.keyCode == tes3.scanCode.u then tes3.messageBox("Welcome to the \"Thief\" mod showcase.") end
    if e.keyCode == tes3.scanCode.o then tes3.messageBox("Just a common day in Balmora...") end
    if e.keyCode == tes3.scanCode.i then tes3.messageBox("Wait... What?") end
    if e.keyCode == tes3.scanCode.k then tes3.messageBox("So many thieves in this town, right?") end
end event.register("keyDown", message)]]

local function initialized()
    print("["..mod.name..", by Spammer] "..mod.ver.." Initialized!")
end event.register("initialized", initialized)



