local mod = {
    name = "Enslaved",
    ver = "1.1",
    cf = {onOff = false, onOff2 = false, onOff3 = false, key = {keyCode = tes3.scanCode.l, isShiftDown = false, isAltDown = false, isControlDown = false}, dropDown = 0, slider = 5, sliderpercent = 10, blocked = {}, npcs = {}, textfield = "hello", switch = false}}

local cf = mwse.loadConfig(mod.name, mod.cf)
local tpcells = require("Spammer.Enslaved.locations")
local notslave = true

local container
local containerPosition = {}

event.register("calcRestInterrupt", function(e)
    local random = math.random(100)
    if random >= cf.sliderpercent then return end
    if not e.resting then return end
    local cell = tes3.getPlayerCell()
    if cell.restingIsIllegal and (cf.onOff3 == false) then
        return
    end
    local race = tes3.player.object.race.id
    if (string.find(race:lower(), "argonian") or string.find(race:lower(), "khajiit")) or cf.onOff2 then
        tes3.player.data.spa_enslavedloc = tes3.player.data.spa_enslavedloc or tpcells.locations
        local data = tes3.player.data.spa_enslavedloc
        if not data then
            return
        end
        if #data == 0 then
            return
        end
        local region = tes3.getRegion(true)
        if not region then return end
        for i,location in ipairs(data) do
            if region.id == location.region then
                e.count = 0
                notslave = false
                tes3.messageBox("You have been abducted by slave traders during your sleep!")
                tes3.positionCell{reference = "player", cell = location.cell, position = location.position}
                table.remove(tes3.player.data.spa_enslavedloc, i)
                break
            end
        end
    end
end)

---@param e referenceActivatedEventData
event.register("referenceActivated", function(e)
    if notslave then
        return
    end
    if not (e.reference.object and e.reference.object.objectType == tes3.objectType.container) then
        return
    end
    if e.reference.object.organic then
        return
    end
    local ref = e.reference
    ref:clone()
    for _,stack in pairs(tes3.player.object.equipment) do
        if stack.object then
            tes3.transferItem{from = "player", to = ref, item = stack.object, itemData = stack.itemData, limitCapacity = false, playSound = false}
            ref.data.spa_enslavedcont = true
            --debug.log(ref)
            --debug.log(ref.position)
        end
    end
    if cf.onOff then
        container = ref.id
        containerPosition = {ref.position.x, ref.position.y, ref.position.z}
        print(ref.id)
        print(string.format("Position: x = %f, y = %f, z = %f", ref.position.x, ref.position.y, ref.position.z), true)
    end
    tes3.mobilePlayer:equip{item = "slave_bracer_right", addItem = true}
    tes3.mobilePlayer:equip{item = "slave_bracer_left", addItem = true}
    notslave = true
end)

local function addTooltip(tooltip)
    local label = tooltip:findChild(tes3ui.registerID("HelpMenu_name"))
    label.text = label.text .. " (Your Stuff)"
end

event.register("uiObjectTooltip", function(e)
    if not cf.onOff then
        return
    end
    if not e.reference then
        return
    end
    if not e.reference.data then
        return
    end
    if not e.reference.data.spa_enslavedcont then
        return
    end
    addTooltip(e.tooltip)
end)


local function buttonText()
    if cf.onOff then
        return tes3.findGMST("sOn").value
    else
        return tes3.findGMST("sOff").value
    end
end

local function registerModConfig()
    local template = mwse.mcm.createTemplate(mod.name)
    template:saveOnClose(mod.name, cf)
    template:register()

    local page = template:createSideBarPage({label="\""..mod.name.."\" Settings"})
    page.sidebar:createInfo{ text = "Welcome to \""..mod.name.."\" Configuration Menu. \n \n \n A mod by Spammer."}
    page.sidebar:createHyperLink{ text = "Spammer's Nexus Profile", url = "https://www.nexusmods.com/users/140139148?tab=user+files" }

    local category1 = page:createCategory("All race abduction enabled?")
    category1:createOnOffButton{label = "On/Off", description = "Configure whether the slave traders will abduct you only if you're Argonian/Khajiit or if they won't care about your race. [Default: Off]", variable = mwse.mcm.createTableVariable{id = "onOff2", table = cf}}

    local category = page:createCategory("Allow abduction in Towns/Interiors?")
    category:createOnOffButton{label = "On/Off", description = "Configure whether you can be abducted outside of the Wilderness. [Default: Off]", variable = mwse.mcm.createTableVariable{id = "onOff3", table = cf}}

    local category0 = page:createCategory("Container Marker")
    --category0:createOnOffButton{label = "On/Off", description = "Configure whether the container containing your equipments will be labeled or not. [Default: Off]", variable = mwse.mcm.createTableVariable{id = "onOff", table = cf}}
    category0:createButton{
        buttonText = buttonText(),
        label = "On/Off",
        description = "Configure whether the container containing your equipments will be labeled or not. [Default: Off]",
        callback = function(self)
            cf.onOff = not cf.onOff
            self.buttonText = buttonText()
            local pageBlock = template.elements.pageBlock
            pageBlock:destroyChildren()
            page:create(pageBlock)
            template.currentPage = page
            pageBlock:getTopLevelParent():updateLayout()
        end,
        inGameOnly = false}
    category0:createInfo{
        text = "",
        inGameOnly = true,
        postCreate = function(self)
        if cf.onOff and container then
            self.elements.info.text = string.format("Container ID: %s\n\nContainer Position: x = %f, y = %f, z= %f", container, unpack(containerPosition))
        else
            self.elements.info.text = ""
        end
    end}

    local category2 = page:createCategory("Abduction Chance:")
    category2:createSlider{label = "Chance: ".."%s%%", description = "Chance for your char to be abducted by slave traders during your sleep. [Default = 10%]", min = 0, max = 100, step = 1, jump = 10, variable = mwse.mcm.createTableVariable{id = "sliderpercent", table = cf}}

    local category3 = page:createCategory("Clean your Save")
    category3:createButton{
        buttonText = "Clean",
        description = "Updating the mod mid playthrough? Use this button to clean your save.\nWarning: This will also clear the visited jails list, so you might end up unprisoned in dungeons you already cleared...",
        callback = function()
            if not tes3.player then
                tes3.messageBox("Load a saved game first!")
            elseif not tes3.player.data.spa_enslavedloc then
                tes3.messageBox("Your save is already clean!")
            else
                tes3.player.data.spa_enslavedloc = nil
                tes3.messageBox("Save cleaned!")
            end
        end,
        inGameOnly = false}
end event.register("modConfigReady", registerModConfig)

local function initialized()
    tpcells:registerLocation{region = "West Gash Region", cell = "Assarnud", position = {-3517.98,1729.67,-36.04}}
    tpcells:registerLocation{region = "Bitter Coast Region",cell = "Aharunartus", position = {-1853.24,3133.37,-295.50}}
    tpcells:registerLocation{region = "Sheogorad", cell = "Habinbaes", position = {2209.55,924.98,-1441.07}}
    tpcells:registerLocation{region = "Azura's Coast Region", cell = "Minabi, Bandit Lair", position = {4500.94,3663.54,12409.66}}
    tpcells:registerLocation{region = "Molag Mar Region", cell = "Zebabi", position = {1819.16,-1394.20,602.12}}
    tpcells:registerLocation{region = "Ascadian Isles Region", cell = "Sinsibadon", position = {-2763.09,1390.16,568.09}}
    print("["..mod.name..", by Spammer] "..mod.ver.." Initialized!")
end event.register("initialized", initialized, {priority = -1000})

