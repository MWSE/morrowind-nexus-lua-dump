local mod = require("Spammer/QoL Improvements/config")
local cf = mwse.loadConfig(mod.name, mod.cf)

--------------------------------------------------------------------------------------------------

--Look at me when I'm talking to you
---@param e table|activateEventData
event.register("activate", function(e)
    if not cf.faceMe then return end
    if e.activator ~= tes3.player then return end
    if e.target and e.target.object and ((e.target.object.objectType == tes3.objectType.npc) or (e.target.object.objectType == tes3.objectType.creature)) and not (tes3.mobilePlayer.isSneaking) and not (e.target.mobile.isDead) then
        local orientation = tes3.player.facing
        local faceMe = orientation - (math.pi)
        e.target.facing = faceMe
    end
end)

--------------------------------------------------------------------------------------------------

--Press M to bring up Map
---@param e keyDownEventData
event.register(tes3.event.keyDown, function(e)
    if not cf.map then return end
    if tes3ui.menuMode() then return end
    local map = tes3ui.findMenu("MenuMap")
    if not map then return end
    local buttonOn = map:findChild("MenuMulti_title_button_1")
    local buttonOff = map:findChild("MenuMulti_title_button_2")
    if map.visible then
        timer.delayOneFrame(function()
            tes3ui.enterMenuMode("MenuMap")
            timer.frame.delayOneFrame(function()
                buttonOff:triggerEvent("mouseClick")
                tes3ui.leaveMenuMode()
            end)
        end)
    else
        map.visible = true
        timer.delayOneFrame(function()
            tes3ui.enterMenuMode("MenuMap")
            timer.frame.delayOneFrame(function()
                buttonOn:triggerEvent("mouseClick")
                tes3ui.leaveMenuMode()
            end)
        end)
    end
end, { filter = tes3.scanCode.m })

--- Allow map mode switching with a key.
event.register("keyDown", function()
    local MenuMap = tes3ui.findMenu("MenuMap")
    if not cf.map then return end
    if not (MenuMap and MenuMap.visible) then return end
    local switch = MenuMap:findChild("MenuMap_switch")
    if switch then
        switch:triggerEvent("mouseClick")
    end
end, { filter = tes3.scanCode.rAlt })

-------------------------------------------------------------------------------------------------

--Equip the damn magic scroll, don't read it
---@param e table|equipEventData
event.register("equip", function(e)
    if not cf.scroll then return end
    local scroll = e.item
        and e.item.objectType == tes3.objectType.book
        and e.item.type == tes3.bookType.scroll
    if not scroll then return end
    local enchant = e.item.enchantment
    if (enchant and enchant.castType and (enchant.castType == tes3.enchantmentType.castOnce)) and not (tes3.worldController.inputController:isShiftDown()) then
        tes3.mobilePlayer:equipMagic({
            source = e.item, itemData = e.itemData, equipItem = true
        })
        local message = string.format("%s: %s.", tes3.findGMST("sReady_Magic").value, e.item.name)
        tes3.messageBox(message)
        return false
    end
end)



---@param e equippedEventData
event.register("equipped", function(e)
    if not cf.scroll then return end
    if (e.item and e.item.objectType == tes3.objectType.weapon) then return end
    local enchant = e.item and e.item.enchantment
    if not enchant then return end
    if (enchant and enchant.castType and (enchant.castType == tes3.enchantmentType.onUse)) then
        timer.frame.delayOneFrame(function() tes3.mobilePlayer:equipMagic({ source = e.item, itemData = e.itemData, equipItem = false }) end)
    end
end)

--------------------------------------------------------------------------------------------------

--Scroll scrolls with arrow keys.
local speed = 0
event.register("keyDown", function(e)
    if not cf.book then return end
    if not tes3ui.menuMode() then return end
    local book = tes3ui.findMenu("MenuScroll")
    if book and tes3ui.getMenuOnTop() == book then
        local bar = book:findChild("MenuScroll_Scroll")
        local buffer = bar:findChild("PartScrollPane_outer_frame")
        local height = bar:getContentElement().height - buffer.height
        local myTimer
        local function timerCallback()
            if tes3.worldController.inputController:isKeyDown(tes3.scanCode.keyUp) then
                bar.widget.positionY = math.clamp((bar.widget.positionY - (10 + speed)), 0, height)
                speed = math.min(speed + 1, 60)
            elseif myTimer then
                book:updateLayout()
                speed = 0
                --debug.log("Cancelling...")
                myTimer:cancel()
                myTimer = nil
            end
        end
        myTimer = timer.start { type = timer.real, duration = 0.1, iterations = -1, callback = timerCallback }
    end
end, { filter = tes3.scanCode.keyUp })

event.register("keyDown", function()
    if not cf.book then return end
    if not tes3ui.menuMode() then return end
    local book = tes3ui.findMenu("MenuScroll")
    if book and tes3ui.getMenuOnTop() == book then
        local bar = book:findChild("MenuScroll_Scroll")
        local buffer = bar:findChild("PartScrollPane_outer_frame")
        local height = bar:getContentElement().height - buffer.height
        local myTimer
        local function timerCallback()
            if tes3.worldController.inputController:isKeyDown(tes3.scanCode.keyDown) then
                bar.widget.positionY = math.clamp((bar.widget.positionY + 10 + speed), 0, height)
                speed = math.min(speed + 1, 60)
            elseif myTimer then
                book:updateLayout()
                speed = 0
                --debug.log("Cancelling...")
                myTimer:cancel()
                myTimer = nil
            end
        end
        myTimer = timer.start { type = timer.real, duration = 0.1, iterations = -1, callback = timerCallback }
    end
end, { filter = tes3.scanCode.keyDown })

--------------------------------------------------------------------------------------------------

--Browse books with arrow keys.
event.register("keyDown", function()
    if not cf.book then return end
    if not tes3ui.menuMode() then return end
    local book = (tes3ui.findMenu("MenuBook") or tes3ui.findMenu("MenuJournal"))
    if book and tes3ui.getMenuOnTop() == book then
        local next = book:findChild("MenuBook_button_next")
        local close = book:findChild("MenuBook_button_close")
        if next and next.visible then
            next:triggerEvent("mouseClick")
        else
            close:triggerEvent("mouseClick")
        end
    end
end, { filter = tes3.scanCode.keyRight })

event.register("keyDown", function()
    if not cf.book then return end
    if not tes3ui.menuMode() then return end
    local book = (tes3ui.findMenu("MenuBook") or tes3ui.findMenu("MenuJournal"))
    if book and tes3ui.getMenuOnTop() == book then
        local next = book:findChild("MenuBook_button_prev")
        local close = book:findChild("MenuBook_button_close")
        if next and next.visible then
            next:triggerEvent("mouseClick")
        else
            close:triggerEvent("mouseClick")
        end
    end
end, { filter = tes3.scanCode.keyLeft })


--------------------------------------------------------------------------------------------------

--What did you say again?
---@param str string
---@return string
local function lesting(str)
    local text = string.gsub(str, "(%%+%s*)%a+%s*", "")
    return text
end

---@param text string
---@return boolean
local function testing(text)
    local first, second, third, fourth, fifth = tes3.findGMST("sNotifyMessage60").value, tes3.findGMST("sNotifyMessage61").value, tes3.findGMST("sNotifyMessage62").value, tes3.findGMST("sNotifyMessage63").value, tes3.findGMST("sJournalEntry").value
    first, second, third, fourth, fifth = lesting(first), lesting(second), lesting(third), lesting(fourth), lesting(fifth)
    return (string.endswith(text:lower(), first:lower())
        or string.endswith(text:lower(), second:lower())
        or string.endswith(text:lower(), third:lower())
        or string.endswith(text:lower(), fourth:lower())
        or string.endswith(text:lower(), fifth:lower()))
end

event.register("journal", function()
    if not cf.keepNotes then return end
    local menu = tes3ui.findMenu("MenuDialog")
    if not menu then return end
    local pane = menu:findChild("MenuDialog_scroll_pane"):findChild("PartScrollPane_pane")
    local i = (#pane.children)
    local text = pane.children[i] and pane.children[i].text
    while (text and testing(text) and (i > 1)) do
        i = i - 1
        text = pane.children[i] and pane.children[i].text
    end
    ---@diagnostic disable-next-line: assign-type-mismatch
    local actor = tes3ui.getServiceActor()
    text = tes3.applyTextDefines({ text = text, actor = actor.reference.object })
    tes3.addJournalEntry({ text = actor.object.name .. ", \"" .. text .. "\"", showMessage = false })
end)

--------------------------------------------------------------------------------------------------

--Stop spamming the same line again and again
local voices = {}
---@param e table|addTempSoundEventData
local function isVoice(e)
    if not cf.parrot then return end
    if not e.isVoiceover then return end
    local voice = e.path or (e.sound and e.sound.id)
    if not voice then return end
    if voices[voice] then return false end
    voices[voice] = true
    timer.start({ duration = 5, callback = function() voices[voice] = nil end })
end
event.register(tes3.event.addSound, isVoice)
event.register(tes3.event.addTempSound, isVoice)


-------------------------------------------------------------------------------------------------

local modConfig = {}
function modConfig.onSearch(search)
    return string.startswith("spammer", search)
end


function modConfig.onCreate(parent)
    parent.flowDirection = "left_to_right"
    local page = parent:createThinBorder({})
    page.flowDirection = "top_to_bottom"
    page.layoutHeightFraction = 1.0
    page.layoutWidthFraction = 1.0
    page.paddingAllSides = 12
    --page.childAlignX = 0.5
    -- page.childAlignY = 0.5
    local page2 = parent:createThinBorder({})
    page2.flowDirection = "top_to_bottom"
    page2.layoutHeightFraction = 1.0
    page2.layoutWidthFraction = 1.0
    page2.paddingAllSides = 12
    page2.wrapText = true
    local presentation = page2:createLabel({
        text = "Welcome to \"" .. mod.name ..
            "\" Configuration Menu. \n \n \n A mod by " .. mod.author .. ".\n"
    })
    local link = page2:createHyperlink({
        text = "Spammer's Nexus Profile",
        url = "https://www.nexusmods.com/users/140139148?tab=user+files"
    })

    for id, _ in pairs(cf) do
        local label = page:createLabel({ text = mod.face[id] })
        label.color = tes3ui.getPalette(tes3.palette.bigHeaderColor)
        label.borderBottom = 5
        local desc = page2:createLabel({ text = mod.desc[id] })
        desc.visible = false
        local button = page:createButton({ id = id, text = table.find(mod.onOff, cf[id]) })
        button:register("mouseClick", function()
            cf[id] = not cf[id]
            button.text = table.find(mod.onOff, cf[id])
            mwse.saveConfig(mod.name, cf)
            tes3.messageBox("Modifications applied.")
        end)
        button:register("mouseOver", function()
            presentation.visible = false
            link.visible = false
            desc.visible = true
        end)
        button:register("mouseLeave", function()
            desc.visible = false
            presentation.visible = true
            link.visible = true
        end)
        button.borderBottom = 20
    end
end

local function registerModConfig() mwse.registerModConfig(mod.name, modConfig) end
event.register("modConfigReady", registerModConfig)


local function initialized()
    print("[" .. mod.name .. ", by " .. mod.author .. "] " .. mod.ver .. " Initialized!")
end
event.register("initialized", initialized, { priority = -1000 })

