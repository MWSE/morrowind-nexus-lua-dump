--[[
    Mod: TES3UI TextInput
    Author: Hrnchamd
]]
--

local this = {}


local pathPrefix = "Clone.scripts.CloningAvatar"
local rightBlock
local button_block
local cloneData  = require(pathPrefix .. ".common.cloneData")
local playerCloneData
local selectedId

local buttonId
function this.init()
    this.id_menu = tes3ui.registerID("zhac_clone:MenuTextInput")
    this.id_input = tes3ui.registerID("zhac_clone:MenuTextInput_Text")
    this.id_ok = tes3ui.registerID("zhac_clone:MenuTextInput_Ok")
    this.id_cancel = tes3ui.registerID("zhac_clone:MenuTextInput_Cancel")
    this.id_createClone = tes3ui.registerID("zhac_clone:MenuTextid_createClone")
end

local function getPlayerItemCount(itemId)
    local count = 0


    local player = tes3.player
    local inventory = player.object.inventory

    for _, stack in pairs(inventory) do
        if string.find(stack.object.id, itemId) then
            count = count + stack.count
        end
    end


    return count
end
local function removePlayerItemCount(itemId, fcount)
    local count = 0
    if not fcount then
        fcount = 1
    end

    local player = tes3.player
    local inventory = player.object.inventory

    for _, stack in pairs(inventory) do
        if string.find(stack.object.id, itemId) and stack.count > fcount then
            tes3.removeItem({ reference = player, item = stack.object.id, count = fcount })
            count = count + stack.count
            --stack.count = stack.count - fcount
            return fcount
        end
    end


    return count
end
local clonePaneData
-- Create window and layout. Called by onCommand.
function this.createWindow(bid)
    if (tes3ui.findMenu(this.id_menu) ~= nil) then
        return
    end
    buttonId = bid
    -- Create window and frame
    local menu = tes3ui.createMenu { id = this.id_menu, fixedFrame = true }
    menu.alpha = 1.0
    local occupied = false

    -- Create label for the select menu
    local inputLabel = menu:createLabel { text = "Clone Pod Management" }

    local occupantName = "None"

    local currentID = cloneData.getCloneIDForPod(buttonId)
    if currentID then
        occupantName = cloneData.getCloneDataForID(currentID).name
        occupied = true
    end
    local infoLabel = menu:createLabel { text = "Current Occupant: " .. occupantName }
    local spacerLabel = menu:createLabel { text = "" }
    inputLabel.borderBottom = 5

    -- Create layout
    local mainBlock = menu:createBlock()
    mainBlock.flowDirection = "left_to_right"
    mainBlock.autoHeight = true
    mainBlock.autoWidth = false
    mainBlock.width = 300

    -- local leftBlock = mainBlock:createBlock()
    -- leftBlock.flowDirection = "top_to_bottom"
    ----leftBlock.autoHeight = true
    --leftBlock.autoWidth = true

    rightBlock = mainBlock:createBlock()
    rightBlock.flowDirection = "top_to_bottom"
    rightBlock.autoHeight = true
    rightBlock.autoWidth = true

    -- Create select menu
    -- local scrollPane = leftBlock:createVerticalScrollPane({ id = "myPane" })


    -- Create labels on the right
    local label1
    local label2
    local label3

    label3 = rightBlock:createLabel { text = "Available Corpusmeat: " ..
    tostring(getPlayerItemCount("ingred_6th_corp")) }
    label2 = rightBlock:createLabel { text = "Available Daedra Heart: " ..
    tostring(getPlayerItemCount("ingred_daedras_heart_01")) }
    label1 = rightBlock:createLabel { text = "Available Frost Salt: " ..
    tostring(getPlayerItemCount("ingred_frost_salts_01")) }
    --scrollPane.width = 300
    -- scrollPane.autoHeight = true
    -- scrollPane.childAlignX = 0.5
    -- scrollPane.childAlignY = 0.5
    -- scrollPane.positionY = 8
    --scrollPane.minWidth = 250
    -- scrollPane.minHeight = 300
    -- scrollPane.autoWidth = true
    -- scrollPane.autoHeight = true

    button_block = menu:createBlock {}
    button_block.widthProportional = 1.0 -- width is 100% parent width
    button_block.autoHeight = true
    button_block.childAlignX = -1.0      -- right content alignment

    local button_cancel = button_block:createButton { id = this.id_cancel, text = tes3.findGMST("sCancel").value }
    --  local button_ok = button_block:createButton { id = this.id_ok, text = "Control Selected" }

    local createText = "Create Clone"
    if occupied then
        createText = "Open Occupant Inventory"
    end
    local button_createClone = button_block:createButton { id = this.id_createClone, text = createText }


    button_cancel:register(tes3.uiEvent.mouseClick, this.onCancel)
    menu:register(tes3.uiEvent.keyEnter, this.onCloneCreate) -- only works when text input is not captured
    button_createClone:register(tes3.uiEvent.mouseClick, this.onCloneCreate)
    -- Register key events
    menu:register("keyEnter", this.onCloneCreate)
    menu:register("keyEsc", this.onCancel)

    menu:updateLayout()
    tes3ui.enterMenuMode(this.id_menu)
end

local myClone
local function fixScale()
    if myClone.scale < 1 then
        myClone.scale = myClone.scale + 0.01
        if myClone.scale < 1 then
            timer.start({
                duration = 0.01,   -- Duration of the timer in seconds
                callback = fixScale, -- Function to be called when the timer expires
                type = timer.simulate, -- Timer type (timer.simulate or timer.real)
                iterations = 1     -- Number of times the timer should repeat (optional, default is 1)
            })
        end
    end
end
function this.onCloneCreate()
    local menu = tes3ui.findMenu(this.id_menu)
    if cloneData.getCloneIDForPod(buttonId) and menu then
        --tes3ui.showNotifyMenu("Pod already occupied")
        menu:destroy()
        tes3ui.leaveMenuMode()
        local actor = cloneData.getCloneObject(cloneData.getCloneIDForPod(buttonId))
        local buttons = {
            {
                text = "Cancel",
                callback = function(e)

                end,
            },
            {
                text = "Open Anyway",
                callback = function(e)

                    tes3.showContentsMenu({reference = actor})
                end,
            },
        }
        tes3ui.showMessageMenu({ message = "WARNING: There is a MWSE bug with this companion share menu(only via this menu), that can cause the game to crash if you change equipment on your clone. \nIf you choose to still use this, make sure to save before doing so.", buttons = buttons })
        return
    end

    local check1, check2, check3 = getPlayerItemCount("ingred_6th_corp"), getPlayerItemCount("ingred_daedras_heart_01"),
        getPlayerItemCount("ingred_frost_salts_01")
    if check1 > 0 and check2 > 0 and check3 > 0 then
        local check1, check2, check3 = removePlayerItemCount("ingred_6th_corp"),
            removePlayerItemCount("ingred_daedras_heart_01"), removePlayerItemCount("ingred_frost_salts_01")
    else
        tes3ui.showNotifyMenu("Required Items are Missing")
        return
    end
    --make sure the clone tube is empty, and we have the items needed
    if buttonId == "tdm_controlpanel_left" then
        local newClone = cloneData.addCloneToWorld("gnisis, arvs-drelen", { x = 4637, y = 6015, z = 146 })
        newClone.newClone.scale = 0.01
        myClone = newClone.newClone
        timer.start({
            duration = 0.01,       -- Duration of the timer in seconds
            callback = fixScale,   -- Function to be called when the timer expires
            type = timer.simulate, -- Timer type (timer.simulate or timer.real)
            iterations = 1         -- Number of times the timer should repeat (optional, default is 1)
        })
        cloneData.setClonePodName(newClone.createdCloneId, buttonId)
    elseif buttonId == "tdm_controlpanel_right" then
        local newClone = cloneData.addCloneToWorld("gnisis, arvs-drelen", { x = 4637, y = 5766, z = 146 })
        newClone.newClone.scale = 0.01
        myClone = newClone.newClone
        timer.start({
            duration = 0.01,       -- Duration of the timer in seconds
            callback = fixScale,   -- Function to be called when the timer expires
            type = timer.simulate, -- Timer type (timer.simulate or timer.real)
            iterations = 1         -- Number of times the timer should repeat (optional, default is 1)
        })
        cloneData.setClonePodName(newClone.createdCloneId, buttonId)
    end
    if (menu) then
        -- Copy text *before* the menu is destroyed

        tes3ui.leaveMenuMode()
        menu:destroy()
    end
end

-- OK button callback.
function this.onOK(e)
    if not selectedId then
        return
    end
    local destActor = cloneData.getCloneObject(selectedId)
    if tes3.player.id == destActor.id then
        error("Player and dest are the same")
    end
    cloneData.transferPlayerData(tes3.player, destActor, true)
    local menu = tes3ui.findMenu(this.id_menu)

    if (menu) then
        -- Copy text *before* the menu is destroyed

        tes3ui.leaveMenuMode()
        menu:destroy()
    end
end

-- Cancel button callback.
function this.onCancel(e)
    local menu = tes3ui.findMenu(this.id_menu)

    if (menu) then
        tes3ui.leaveMenuMode()
        menu:destroy()
    end
end

-- Keydown callback.
function this.onCommand(e)
    local t = tes3.getPlayerTarget()
    if (t) then
        t = t.object.baseObject or t.object -- Select actor base object

        if (t.name) then
            this.item = t
            this.createWindow()
        end
    end
end

event.register(tes3.event.initialized, this.init)
--   event.register(tes3.event.keyDown, this.onCommand, { filter = tes3.scanCode["/"] }) -- "/" key
return this
