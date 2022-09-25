local mod = {
    name = "Actual Illegal Resting",
    ver = "1.5",
    author = "Spammer",
    cf = {onOff = true, slider = 50, sliderpercent = 10}
}
local cf = mwse.loadConfig(mod.name, mod.cf)
local state = false
local permitted = false

---comment
---@param e table|activateEventData
event.register("activate", function(e)
    local owned = e.target
    and e.target.object
    and e.target.object.objectType == tes3.objectType.activator
    and tes3.hasOwnershipAccess{target = e.target}
    if not owned then return end
    permitted = true
    timer.delayOneFrame(function()
        timer.delayOneFrame(function()
            timer.delayOneFrame(function()
        permitted = false
            end)
        end)
    end)
end)


local function hobo()
    if not state then return end
    local gold = tes3.getPlayerGold()
    if tes3.mobilePlayer.bounty > 5 then
        timer.delayOneFrame(function()
            tes3.removeItem{reference = "player", item = "gold_001", count = math.min(gold, cf.slider)}
            tes3.runLegacyScript{command = "GoToJail"}
        end)
    else
        tes3.mobilePlayer.inJail = true
        timer.delayOneFrame(function()
            tes3.removeItem{reference = "player", item = "gold_001", count = math.min(gold, cf.slider)}
            tes3.runLegacyScript{command = string.format("ModPcCrimeLevel %s", -(tes3.mobilePlayer.bounty))}
            tes3.runLegacyScript{command = "PayFineThief"}
        end)
    end
    tes3.messageBox{message = "You were caught by the Guards while sleeping and brought to Jail."}
    state = false
end



event.register("uiActivated", function(e)
    if not cf.onOff then return end
    state = false
    local cell = tes3.getPlayerCell()
    if not (cell and cell.restingIsIllegal) then return end
    if permitted then return end
    local button = e.element:findChild("MenuRestWait_rest_button")
    button.visible = true
    button:registerBefore("mouseClick", function()
        state = true
        local witness = tes3.triggerCrime{type = tes3.crimeType.trespass}
        if not witness then
            local bar = e.element:findChild("MenuRestWait_scrollbar")
            local random = math.random(1, 100)
            local count = 0
            for ref in cell:iterateReferences(tes3.objectType.npc) do
                if ref then count = count+1 end
            end
            local limit = (cf.sliderpercent)*(math.sqrt(bar.widget.current))*(math.sqrt(count))
            if random <= limit then hobo() end
        end
    end)
    e.element:updateLayout()
end, {filter = "MenuRestWait"})

---comment
---@param e table|crimeWitnessedEventData
event.register("crimeWitnessed", function(e)
    if e.type ~= "trespass" then state = false end
    if not state then return end
    hobo()
end)

local function registerModConfig()
    local template = mwse.mcm.createTemplate(mod.name)
    template:saveOnClose(mod.name, cf)
    template:register()

    local page = template:createSideBarPage({label="\""..mod.name.."\" Settings"})
    page.sidebar:createInfo{ text = "Welcome to \""..mod.name.."\" Configuration Menu. \n \n \n A mod by "..mod.author.."."}
    page.sidebar:createHyperLink{ text = mod.author.."'s Nexus Profile", url = "https://www.nexusmods.com/users/140139148?tab=user+files" }

    local category2 = page:createCategory{label = "Mod Configs"}
    category2 = page:createCategory{label = ""}
    category2:createOnOffButton{label = "Mod On/Off", description = "Turns the mod On or Off. [Default: On]", variable = mwse.mcm.createTableVariable{id = "onOff", table = cf}}
    category2 = page:createCategory{label = ""}
    category2:createSlider{label = "Fine for being Caught: ".."%s drakes.", description = "Fine to be paid when resting illegally. [Default: 50]", min = 0, max = 1000, step = 5, jump = 100, variable = mwse.mcm.createTableVariable{id = "slider", table = cf}}
    category2 = page:createCategory{label = ""}
    category2:createSlider{label = "Chances to be Caught: ".."%s%%", description = "Chances to be caught while resting. [Default 10] \nNotes: \n- You will always be caught if you rest in front of a witness. \n- The longer you rest, the higher your chances to be caught.\n- The more NPCs in the cell, the higher the chances.", min = 0, max = 100, step = 1, jump = 10, variable = mwse.mcm.createTableVariable{id = "sliderpercent", table = cf}}
end event.register("modConfigReady", registerModConfig)

local function initialized()
    print("["..mod.name..", by "..mod.author.."] "..mod.ver.." Initialized!")
end event.register("initialized", initialized, {priority = -1000})