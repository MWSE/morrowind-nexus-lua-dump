local cfg = require("BeefStranger.Loot Notifcation.config")
local sf = string.format

local lootMenuID = tes3ui.registerID("lootMenu")
local playerInv = {}
local diffAmount = {} --Logs the amount Picked up for Each Item

---Create initial look menu
local function createLootMenu()
    local lootMenu = tes3ui.createMenu({ id = lootMenuID, fixedFrame = true, modal = false })
    lootMenu.width = 300
    lootMenu.height = 200
    lootMenu.absolutePosAlignX = cfg.xPos
    lootMenu.absolutePosAlignY = cfg.yPos
    lootMenu.alpha = cfg.alpha
    lootMenu.visible = false

    local block = lootMenu:createBlock({ id = "LootBlock" })
    block.autoHeight = true
    block.autoWidth = true
    block.flowDirection = tes3.flowDirection.topToBottom

    lootMenu:updateLayout()
end

local notifTimer ---@type mwseTimer
local fadeout ---@type mwseTimer

--Creates or Resets Timer
local function startTimer()
    if notifTimer and notifTimer.state == 0 then
        notifTimer:reset()
    else
        notifTimer = timer.start({
            duration = cfg.showDur,
            callback = function(e)
                local menu = tes3ui.findMenu(lootMenuID):findChild("LootBlock")
                if not menu then e.timer:cancel() return end

                --Cancel fadeout if notifTimer starts again while its running
                if fadeout and fadeout.state == 0 then fadeout:cancel() end

                diffAmount = {}

                fadeout = timer.start({
                    duration = 0.5,
                    iterations = #menu.children,
                    callback = function(e)
                        local index = #menu.children - e.timer.iterations + 1

                        --Check so it doesnt try to delete an element thats already gone
                        if menu and menu.children[index] then
                            menu.children[index]:destroy()
                        else
                            e.timer:cancel()
                        end

                        --Hide menu when all children are gone
                        if #menu.children == 0 then
                            menu:getTopLevelMenu().visible = false
                        end

                        --Update Layout every iteration so background shrinks with each update
                        menu:getTopLevelMenu():updateLayout()
                    end
                })
            end,
        })
    end
end

--Handles Creating the Notification
local function doNotify(amount, itemId, total)
    local menu = tes3ui.findMenu(lootMenuID):findChild("LootBlock")
    local notify = menu:findChild(itemId)
    local name = tes3.getObject(itemId).name
    local text = "doNotify Error"

    if amount > 0 then
        text = sf("%s | +%s (%d)", name, amount, total)
    else
        text = sf("%s | %s (%d)", name, amount, total)
    end

    if not notify then
        notify = menu:createLabel({ id = itemId, text = text })
    end

    notify.text = text

    if amount > 0 then
        notify.color = cfg.obtainColor
    elseif amount < 0 then
        notify.color = cfg.removeColor
    else
        notify.color = cfg.zeroColor
    end

    menu:getTopLevelMenu():updateLayout()

    if #menu.children > cfg.maxNotify then
        for i = 1, #menu.children - cfg.maxNotify do
            menu.children[i]:destroy()
        end
    end
end

local function invUpdate()
    local hasChanges = false
    local currentInv = {}   --Temporary table to hold current inventory state

    local topMenu = tes3ui.findMenu(lootMenuID)

    if not topMenu then
        createLootMenu()
        return
    end

    local menu = topMenu:findChild("LootBlock")

    -- Iterate over the player's inventory and log changes
    for _, stack in pairs(tes3.mobilePlayer.object.inventory) do
        local name = stack.object.name                       --Name of item
        local item = stack.object.id                       --Id of items
        local total = stack.count                            --Total Amount of item in inventory
        local prevTotal = (playerInv[item] or 0)           --Table Stack sizes of each item in current inventory at time of check
        local diff = total - prevTotal                       --How much has been added since start of loop

        if total ~= prevTotal then                           --If items stack size != what's currently in playerInv
            hasChanges = true
            -- mwse.log("Has changes Running")
            topMenu.visible = true
            diffAmount[item] = diffAmount[item] or 0 --Set it to current value or initialize at 0

            topMenu.absolutePosAlignX = cfg.xPos
            topMenu.absolutePosAlignY = cfg.yPos
            topMenu.alpha = cfg.alpha

            if diff ~= 0 then
                startTimer()
                diffAmount[item] = (diffAmount[item] + diff) --Set it to the amount gained from previous inventory check vs now
                local amount = diffAmount[item]
                doNotify(amount, item, total)
                menu:getTopLevelMenu():updateLayout()
            end
        end
        currentInv[item] = total
    end

    -- Check for items that were removed completely
    for itemId, prevCount in pairs(playerInv) do
        if not currentInv[itemId] then
            topMenu.visible = true
            startTimer()
            local amount = -prevCount
            doNotify(amount, itemId, 0)
            menu:getTopLevelMenu():updateLayout()
            hasChanges = true
        end
    end

    -- Update the player's inventory state
    playerInv = currentInv

    if not hasChanges then
        return
    end
end


---Runs when item is dropped
--- @param e itemDroppedEventData
local function itemDroppedCallback(e)
    invUpdate()
end
event.register(tes3.event.itemDropped, itemDroppedCallback)

---Runs on every frame
--- @param e simulateEventData
local function simulateCallback(e)
    invUpdate()
end
event.register(tes3.event.simulate, simulateCallback)


local function onLoad()
    playerInv = {}                                   --Clear table to prevent updates on load
    for _, stack in pairs(tes3.mobilePlayer.object.inventory) do
        playerInv[stack.object.id] = stack.count     --Initialize playerInv to current Inventory
        if not tes3ui.findMenu(lootMenuID) then
            createLootMenu()
        end
    end
end
event.register(tes3.event.loaded, onLoad)


event.register("bsLootNotif", function (e)
    local topMenu = tes3ui.findMenu(lootMenuID)

    if topMenu then
        -- mwse.log("EVENT| top Menu updating")
        topMenu.absolutePosAlignX = cfg.xPos
        topMenu.absolutePosAlignY = cfg.yPos
        topMenu.alpha = cfg.alpha
        topMenu:updateLayout()
    end
end)



event.register("initialized", function()
    print("[MWSE:Loot Notification] initialized")
end)
