local config = require("hotkeyExtender.config");

local f2Key = {
    keyCode = tes3.scanCode.F2,
    isAltDown = false,
    isControlDown = false,
    isShiftDown = false
}

local _STATE = {
    NORMAL = 0,     -- menu not opened
    OPEN = 1,       -- menu opened
    LISTENING = 1   -- binding a key
}

local state = _STATE.NORMAL
local listeningHotkeyIndex = nil

local menu = nil
local hotkeyContainer = nil
local hotkeyField = nil
local listeningKeyPopup = nil

local hotkeys = config.hotkeys


local function commitChanges()
    local output = {}
    for i,hotkey in ipairs(hotkeys) do
        output[i] = {
            object = hotkey.object,
            actionType = hotkey.actionType,
            actionId = hotkey.actionId,
            keyName = hotkey.keyName
        }
    end
    mwse.saveConfig("hotkeyExtender", { hotkeys = output })
end

-- helper --
local function getKeybindKey(value)
    for k, v in pairs(tes3.scanCode) do
        if v == value then
            return k
        end
    end
    return nil
end


local function closeMenu(e)
    menu:destroy()
    tes3ui.leaveMenuMode()
    state = _STATE.NORMAL
end

local function renderIconBlock(parent, hotkey)
    local button = parent:createThinBorder({ id = "icon_block" })
	button.width = 60
	button.height = 60
	button.borderAllSides = 4
	button.paddingAllSides = 6
    if(hotkey.action) then
        local iconPath
        local borderPath
        if hotkey.actionType == "spell" then
            iconPath = "Icons\\s\\B_" .. string.sub(hotkey.action.effects[1].object.icon,3,100)
            borderPath = "Textures\\menu_icon_select_magic.tga"
        else
            iconPath = "Icons\\" .. hotkey.action.icon
            borderPath = "Textures\\menu_icon_select_magic_magic.tga"
        end
		local barterIcon = button:createImage{ path = borderPath }
		barterIcon.widthProportional = 1
		barterIcon.heightProportional = 1
		barterIcon.childAlignX = 0.0
		barterIcon.childAlignY = 0.0
		barterIcon.consumeMouseEvents = false
		local shadowIcon
		if not hotkey.actionType == "spell" then
			shadowIcon = barterIcon:createImage{ path = iconPath }
			shadowIcon.color = {0.0, 0.0, 0.0}
			shadowIcon.absolutePosAlignX = 0
			shadowIcon.absolutePosAlignY = 0
			shadowIcon.borderAllSides = 12
			shadowIcon.consumeMouseEvents = false
		end
		local icon = barterIcon:createImage{ path = iconPath }
		icon.borderAllSides = 6
		icon.consumeMouseEvents = false
	end
    return button
end

local function renderHotkeyField()
    if not hotkeyField or not menu then
        return
    end
    hotkeyField:destroyChildren()
    for _, hotkey in ipairs(hotkeys) do
        if (_ > 1) then hotkeyField:createDivider() end
        local hotkeyLabel = hotkeyField:createLabel({
            id = "hotkey-name-btn",
            text = hotkey.object and "Hotkey " .. _ or "New hotkey"
        })
        local hotkeyButton = hotkeyField:createButton({
            id = "hotkey-key-btn",
            text = hotkey.object and string.upper(hotkey.keyName) or "Select key"
        })
        hotkeyButton:register(tes3.uiEvent.mouseClick, function(e)
            menu.visible = false
            state = _STATE.LISTENING
            listeningKeyPopup = tes3ui.createMenu({ id = "listening-key-popup",
            dragFrame = false,
            fixedFrame = true,
            modal = true,
            loadable = false })
            listeningKeyPopup:createLabel({ id = "listening-key-popup-text", text = "Press the key you want to bind..." })
            listeningHotkeyIndex = _
            hotkey._button = hotkeyButton
            hotkey._label = hotkeyLabel
            hotkeyButton.text = "Listening..."
        end)
        local actionButton = renderIconBlock(hotkeyField, hotkey)
        actionButton:register(tes3.uiEvent.mouseClick, function(e)
                menu.visible = false
                tes3ui.showMagicSelectMenu({
                    id = "action-selector-menu",
                    title = "Select Action",
                    selectSpells = true,
                    selectPowers = true,
                    selectEnchanted = true,
                    callback = function(e)
                        menu.visible = true
                        hotkey.action = e.spell and e.spell or (e.item and e.item or nil)
                        hotkey.actionId = e.spell and e.spell.id or e.item.id
                        hotkey.actionType = e.spell and "spell" or "item"
                        actionButton.text = hotkey.action.name
                        renderHotkeyField()
                        if hotkey.action and hotkey.object then commitChanges() end
                    end
                })
                end)
        local deleteButton = hotkeyField:createButton({
            id = "hotkey-delete-btn",
            text = "Delete"
        })
        deleteButton:register(tes3.uiEvent.mouseClick, function(e)
            table.remove(hotkeys, _)
            renderHotkeyField()
        end)
    end
    hotkeyContainer:updateLayout()
    menu:updateLayout()
end

local function resetCb(e)
    hotkeys = {}
    commitChanges()
    renderHotkeyField()
end

local function addCb(e)
    table.insert(hotkeys, {
        object = nil,
        keyName = null,
        action = nil
    })
    renderHotkeyField()
end

local function renderMenu()
    if not menu then
        return
    end
    menu:createLabel({
        id = "hotkey-map-title",
        text = "Hotkey Map"
    })
    hotkeyContainer = menu:createVerticalScrollPane{
        id = 'hotkey-container'
    };
    hotkeyContainer.width = 130
    hotkeyContainer.heightProportional = nil
    hotkeyContainer.widthProportional = nil
    hotkeyContainer.height = 400
    hotkeyContainer.maxHeight = 400
    hotkeyContainer.borderAllSides = 4
    hotkeyField = hotkeyContainer:getContentElement();
    hotkeyField.flowDirection = tes3.flowDirection.topToBottom;
    local addHotkey = menu:createButton({
        id = 'add-hotkey-btn',
        text = "Add hotkey"
    })
    addHotkey:register(tes3.uiEvent.mouseClick, addCb)
    local resetButton = menu:createButton({
        id = 'reset-hotkeys-btn',
        text = "Reset all"
    })
    resetButton:register(tes3.uiEvent.mouseClick, resetCb)
    local okButton = menu:createButton({
        id = 'close-btn',
        text = "Finish"
    })
    okButton:register(tes3.uiEvent.mouseClick, closeMenu)
end

local function setupConfigHotkeys()
    if hotkeys[1] ~= nil then
        for _, hotkey in ipairs(hotkeys) do
            if hotkey.actionType == "spell" then
                local spells = tes3.getSpells({ target = tes3.mobilePlayer })
                for __, spell in ipairs(spells) do
                    if(spell.id == hotkey.actionId) then 
                        hotkey.action = spell
                        break
                    end
                end
            end
            if hotkey.actionType == "item" then
                for __,item in ipairs(tes3.mobilePlayer.inventory) do
                    if(item.object.id == hotkey.actionId) then
                        hotkey.action = item.object
                        break
                    end
                end
            end
        end
    end
end

local function openMenu()
    state = _STATE.OPEN
    menu = tes3ui.createMenu({
        id = "extended-hotkeys-menu",
        dragFrame = false,
        fixedFrame = true,
        modal = true,
        loadable = false
    })
    tes3ui.enterMenuMode(menu.id)
    renderMenu()
    renderHotkeyField()
    renderHotkeyField()
end

local function keybindPressed(key)
    for _, hotkey in ipairs(hotkeys) do
        if hotkey.object.keyCode == key.keyCode then
            tes3.player.mobile:equipMagic({
            source = hotkey.action, equipItem = hotkey.actionType == 'item'
            })
        end
    end
end

local function isNativeKeybind(key)
    for k, keybind in pairs(tes3.keybind) do
        if key.keyCode == tes3.getInputBinding(keybind).code then
            return true
        end
    end
    return false
end

local function fetchKeybindFromKey(key)
    for _, hotkey in ipairs(hotkeys) do
        if hotkey.object and hotkey.object.keyCode == key.keyCode then
            return hotkey
        end
    end
    return nil
end

local function main(e)
    setupConfigHotkeys()
    if state == _STATE.NORMAL then
        if not tes3.isKeyEqual({
            expected = f2Key,
            actual = e
        }) then
            if not tes3.menuMode() then keybindPressed(e) end
            return
        end
        openMenu()
        return
    end
    if state == _STATE.OPEN then
        if tes3.isKeyEqual({ expected = f2Key, actual = e }) then
            closeMenu(e)
        end
    end
    if state == _STATE.LISTENING then
        if not listeningHotkeyIndex or e.keyCode == tes3.scanCode.lShift then
            return
        end
        if isNativeKeybind(e) then
            tes3.messageBox("This key is already bound to a native action.")
            return
        end
        local alreadyBound = fetchKeybindFromKey(e)
        if alreadyBound then
            tes3.messageBox("This key is already bound to " .. (alreadyBound.action and alreadyBound.action.name or "an action"))
            return
        end
        local listeningHotkey = hotkeys[listeningHotkeyIndex]
        if(listeningKeyPopup) then listeningKeyPopup:destroy() end
        listeningKeyPopup = nil
        menu.visible = true
        state = _STATE.OPEN
        listeningHotkey.object = e
        listeningHotkey.keyName = getKeybindKey(e.keyCode)
        if listeningHotkey._button then
            listeningHotkey._button.text = listeningHotkey.keyName
        end
        if listeningHotkey._label then
            listeningHotkey._label.text = "Hotkey " .. listeningHotkeyIndex
        end
        renderHotkeyField()
        if listeningHotkey.action and listeningHotkey.object then commitChanges() end
    end
end

local function loaded()
    
    event.register(tes3.event.keyDown, main)
end

event.register(tes3.event.loaded, loaded)
