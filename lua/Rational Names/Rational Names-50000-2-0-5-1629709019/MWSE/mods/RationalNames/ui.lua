-- Everything in this file exists to enable the ability to display names for items other than the actual object names,
-- including having names longer than 31 characters. This is just UI trickery; in this file, we force the UI to display
-- the desired names in various contexts.
local common = require("RationalNames.common")
local data = require("RationalNames.data")
local config = require("RationalNames.config")

local hudText, gmstCount
local objectText = {}
local currentEquip = {}

local elementIDs = {
    weapon = tes3ui.registerID("MenuInventory"),
    magic = tes3ui.registerID("MenuMagic"),
    multi = tes3ui.registerID("MenuMulti"),
    invSel = tes3ui.registerID("MenuInventorySelect"),
    headerTitle = tes3ui.registerID("PartDragMenu_title"),
    magicSpellsList = tes3ui.registerID("MagicMenu_spells_list"),
    hudNotify = tes3ui.registerID("MenuMulti_weapon_magic_notify"),
    tooltipName = tes3ui.registerID("HelpMenu_name"),
    magicItemNames = tes3ui.registerID("MagicMenu_item_names"),
    scrollPane = tes3ui.registerID("PartScrollPane_pane"),
    itemBrick = tes3ui.registerID("MenuInventorySelect_item_brick"),
    uiExpSoulgemItemBrick = tes3ui.registerID("UIEXP:InventorySelect:SoulGemName"),
    magicIconsList = tes3ui.registerID("MagicMenu_icons_list_inner"),
    hudIconsList = tes3ui.registerID("MenuMulti_magic_icons_box"),
    magicSourceList = tes3ui.registerID("PartHelpMenu_main"),
    dialogMainPane = tes3ui.registerID("MenuDialog_scroll_pane"),
    dialogNotify = tes3ui.registerID("MenuDialog_notify"),
    enchantNameField = tes3ui.registerID("MenuEnchantment_SpellName"),
    enchantItem = tes3ui.registerID("MenuEnchantment_Item"),
}

local properties = {
    magic = tes3ui.registerProperty("MagicMenu_object"),
    repair = tes3ui.registerProperty("MenuRepair_Object"),
    serviceRepair = tes3ui.registerProperty("MenuServiceRepair_Object"),
    invSel = tes3ui.registerProperty("MenuInventorySelect_object"),
    enchantItem = tes3ui.registerProperty("MenuEnchantment_SoulGem"),
}

local textGMSTs = {
    weapon = "sSkillHandtohand",
    magic = "sNone",
}

local defaultGMSTs = {
    sNotifyMessage50 = "Ingredient has no effect on you.",
    sNotifyMessage51 = "The tool has been used up.",
}

local wordsToReplace = {
    sNotifyMessage50 = "Ingredient",
    sNotifyMessage51 = "tool",
}

local this = {}

-- The following two functions replace the vanilla code for unlocking doors or containers with the key. This is needed
-- to change the messagebox to display the correct name. Thanks to NullCascade for this.
--- Override the vanilla logic to display a message when the player unlocks an object.
--- @param lockedRef tes3reference The reference being unlocked.
--- @param activatingActor tes3actor The actor doing the unlocking.
local function checkForKeyUnlock(lockedRef, activatingActor)
    local activator = activatingActor.reference
    local lockNode = lockedRef.lockNode
    local key = lockNode.key

    -- Check to see if the activating actor has the key.
    if (not key) or (not activatingActor.inventory:contains(key)) then
        return false
    end

    -- Unlock the reference.
    lockNode.locked = false
    lockedRef.modified = true

    if activator == tes3.player then
        tes3.game:clearTarget()
        local displayName = common.getDisplayName(key.id:lower()) or key.name
        local messageText = string.format("%s unlocked using key: %s", lockedRef.object.name, displayName)

        tes3.messageBox(messageText)
        common.logMsg(string.format("Changing key unlock messagebox to: %s", messageText))
    end

    -- Let the trap system know we successfully unlocked.
    return true
end

--- Generates the necessary patches to replace key checks in Morrowind.exe.
--- @param startAddress number Where the patch begins.
--- @param endAddress number Where the patch ends.
local function replaceKeyCheckLogic(startAddress, endAddress)
    -- Zero out existing vanilla logic.
    mwse.memory.writeNoOperation({
        address = startAddress,
        length = endAddress - startAddress,
    })

    -- Establish call for following function call.
    mwse.memory.writeBytes({
        address = startAddress,
        bytes = {
            0x8B, 0x4C, 0x24, 0x14,       -- mov ecx, [esp+0x80+var_0x6C]
            0x51,                         -- push ecx
            0x8B, 0xCD,                   -- mov ecx, ebp
            0x90, 0x90, 0x90, 0x90, 0x90, -- call lua:checkForKeyUnlock
            0x84, 0xC0,                   -- test al, al
            0x74, 0x05,                   -- jz $+0x5 ; skip the next line
            0xC6, 0x44, 0x24, 0x13, 0x01, -- mov [esp+0x80+var_0x6D], 1
        },
    })

    -- Call our checkForKeyUnlock function.
    mwse.memory.writeFunctionCall({
        address = startAddress + 0x7,
        call = checkForKeyUnlock,
        signature = {
            this = "tes3object",
            arguments = {
                "tes3object",
            },
            returns = "bool",
        },
    })
end

--[[ These next five functions change the text of the messageboxes that display whenever a tool (lockpick, probe, repair
item or soulgem) has been used up, or when an ingredient has no effect on you. This is needed to show the correct
display name instead of the object name. It gets changed back to a generic message 1 second later (in case something
goes wrong, the messagebox will still be correct). ]]--
local function changeGMST(gmstName, newValue)
    tes3.findGMST(tes3.gmst[gmstName]).value = newValue
    common.logMsg(string.format("%s GMST is now: %s", gmstName, newValue))
end

local function tempSetGMST(gmstName, name)
    changeGMST(gmstName, string.gsub(defaultGMSTs[gmstName], wordsToReplace[gmstName], name))
    gmstCount = gmstCount + 1

    timer.start{
        duration = 1,
        callback = function()
            gmstCount = gmstCount - 1

            if gmstCount <= 0 then
                changeGMST(gmstName, defaultGMSTs[gmstName])
            end
        end,
    }
end

local function setGMSTBasedOnItem(gmstName, item)
    local id = item.id:lower()
    local name = common.getDisplayName(id) or item.name
    tempSetGMST(gmstName, name)
end

this.onEquip = function(e)
    if e.reference ~= tes3.player then
        return
    end

    local object = e.item
    local objectType = object.objectType

    if objectType == tes3.objectType.repairItem then
        setGMSTBasedOnItem("sNotifyMessage51", object)
    elseif objectType == tes3.objectType.miscItem then
        -- We can't use the display name of the soulgem the player equipped, because the recharge menu asks them to
        -- select the soulgem again before recharging and it might be a different one. So we just use the generic
        -- "soulgem" in the messagebox.
        tempSetGMST("sNotifyMessage51", "soulgem")
    elseif objectType == tes3.objectType.ingredient then
        setGMSTBasedOnItem("sNotifyMessage50", object)
    end
end

-- Runs whenever the player uses a lockpick or probe.
this.onPickProbe = function(e)
    setGMSTBasedOnItem("sNotifyMessage51", e.tool)
end

-- Runs whenever the player's currently equipped weapon or active magic has changed. menu is either the inventory or
-- magic menu, and newText is the name (display name if applicable) of the equipped weapon or magic.
local function updateHeaderHudText(menu, newText)
    if menu then
        local nameElem = menu:findChild(elementIDs.headerTitle)
        nameElem.text = newText
        common.logMsg(string.format("Weapon/magic changed or game loaded. Menu header text set to: %s.", newText))
    end

    -- This mod totally overrides the text of the weapon/magic notification display in the HUD. It's displayed as two
    -- lines, one for weapon and one for magic, regardless of which one just changed, because that was the only way to
    -- force it to consistently display correctly.
    hudText = string.format("%s\n%s", objectText.weapon, objectText.magic)
    common.logMsg(string.format("Weapon/magic changed or game loaded. HUD notify text set to: %s.", hudText))
end

-- Runs on loaded, and then every frame.
local function getCurMagic()
    return tes3.mobilePlayer.currentEnchantedItem.object
    or tes3.mobilePlayer.currentSpell
    or nil
end

local function getEquipment(objectType)
    return tes3.getEquippedItem{
        actor = tes3.player,
        objectType = objectType,
    }
end

-- Runs on loaded and when the player's equipped weapon changes.
local function getCurWeapon()
    local curWeaponStack = getEquipment(tes3.objectType.weapon)
    or getEquipment(tes3.objectType.lockpick)
    or getEquipment(tes3.objectType.probe)
    or nil

    return ( curWeaponStack and curWeaponStack.object ) or nil
end

-- type is "weapon" or "magic". Runs when the player's weapon or active magic changes, and on loaded.
local function setWeaponMagicText(type)
    common.logMsg(string.format("Updating %s display.", type))
    local object = currentEquip[type]

    if object then
        local id = object.id:lower()
        local displayName = common.getDisplayName(id)
        common.logMsg(string.format("Player currently has %s equipped. ID: %s.", type, id))

        if displayName then
            objectText[type] = displayName
            common.logMsg(string.format("Equipped %s has a display name different from object name. Display name: %s.", type, objectText[type]))
        else
            objectText[type] = object.name
            common.logMsg(string.format("Equipped %s does not have a display name different from object name. Name: %s.", type, objectText[type]))
        end
    else
        objectText[type] = tes3.findGMST(tes3.gmst[textGMSTs[type]]).value
        common.logMsg(string.format("Player currently has no %s equipped. Text: %s.", type, objectText[type]))
    end

    local menu = tes3ui.findMenu(elementIDs[type])
    updateHeaderHudText(menu, objectText[type])
end

-- The width of most menus does not automatically increase to accomodate longer displayed object names, so we need to
-- widen the menu accordingly.
local function setMenuWidth(element, longest, desiredWidth, logText)
    local oldWidth = element.width
    common.logMsg(string.format("Longest name: %u pixels. Desired width: %u. Old width: %u. Setting %s width accordingly.", longest, desiredWidth, oldWidth, logText))

    if desiredWidth > oldWidth then
        element.width = desiredWidth
    end
end

-- Used for the inventory select, repair, and service repair menus.
local function renameItemElement(element, id, newText, longest, extraLogText)
    element.text = newText
    common.logMsg(string.format("%s: %sChanging displayed name to: %s.", id, extraLogText, newText))

    element:updateLayout()
    local elemWidth = element.width
    longest = math.max(longest, elemWidth)
    return longest
end

-- Used for the magic and magic select menus.
local function renameMagicElement(element)
    local object = element:getPropertyObject(properties.magic)
    local id = object.id:lower()
    local displayName = common.getDisplayName(id)

    -- Only set the text if it needs to be changed, for performance reasons.
    if displayName and element.text ~= displayName then
        element.text = displayName
        common.logMsg(string.format("%s: Changing displayed name to: %s.", id, displayName))
    end
end

local function findLastIndex(text, pattern)
    local index = nil
    local i = 0

    -- index will end up being the index of the *last* instance of the pattern in the text. We're only doing it this way
    -- in the unlikely event some mod changes object names to include the pattern string.
    while true do
        i = string.find(text, pattern, i + 1)

        if i then
            index = i
        else
            break
        end
    end

    return index
end

this.menuServiceRepairActivated = function(e)
    local scrollPane = e.element:findChild(elementIDs.scrollPane)
    local longest = 0
    common.logMsg("Service repair menu created. Displaying long item names.")

    for _, itemElement in ipairs(scrollPane.children) do
        local itemStack = itemElement:getPropertyObject(properties.serviceRepair, "tes3itemStack")
        local id = itemStack.object.id:lower()
        local displayName = common.getDisplayName(id)

        if not displayName then
            goto continue
        end

        -- Handling this menu is complicated because the element text is not just the object name; it also displays the
        -- gold cost of repairing the item at the end.
        local oldText = itemElement.text
        local goldTransition = "  - "
        local lastTransIndex = findLastIndex(oldText, goldTransition) or nil

        -- This should never happen. If it does, something weird is going on, like some other mod mucking with this
        -- menu, so do nothing.
        if not lastTransIndex then
            goto continue
        end

        local goldText = string.sub(oldText, lastTransIndex, #oldText)
        local newText = string.format("%s%s", displayName, goldText)
        common.logMsg(string.format("%s: Old text: %s. Gold text: %s.", id, oldText, goldText))

        longest = renameItemElement(itemElement, id, newText, longest, "")

        ::continue::
    end

    local desiredWidth = longest + 55
    setMenuWidth(e.element, longest, desiredWidth, "service repair menu")
end

-- This also covers the enchanted item recharge menu, which just repurposes the repair menu.
this.menuRepairActivated = function(e)
    local scrollPane = e.element:findChild(elementIDs.scrollPane)
    local longest = 0
    common.logMsg("Repair menu created. Displaying long item names.")

    for _, itemBlock in ipairs(scrollPane.children) do
        -- All of these elements are null elements, which is why we have to define them this way.
        local iconElement = itemBlock.children[2].children[1]
        local itemStack = iconElement:getPropertyObject(properties.repair, "tes3itemStack")
        local id = itemStack.object.id:lower()
        local displayName = common.getDisplayName(id)

        if displayName then
            local nameElement = itemBlock.children[1]
            longest = renameItemElement(nameElement, id, displayName, longest, "")
        end
    end

    local desiredWidth = longest + 60
    local oldWidth = e.element.width
    setMenuWidth(e.element, longest, desiredWidth, "repair menu")

    -- If setMenuWidth actually increased the width of the menu, we additionally have to go through the item blocks
    -- again and widen the fillbars so they'll extend as far to the left as they did before.
    if desiredWidth > oldWidth then
        for _, itemBlock in ipairs(scrollPane.children) do
            local fillBarElem = itemBlock.children[2].children[2]
            fillBarElem.width = desiredWidth - 130
        end
    end
end

this.menuInvSelActivated = function()
    -- This function is also run whenever UI Expansion updates its filters, so we have to grab the menu like this.
    local menu = tes3ui.findMenu(elementIDs.invSel)

    if not menu then
        return
    end

    local itemList = menu:findChild(elementIDs.scrollPane)
    local longest = 0
    common.logMsg("Inventory select menu created or tiles updated. Displaying long item names.")

    for _, brick in ipairs(itemList.children) do
        local object = brick:getPropertyObject(properties.invSel)
        local id = object.id:lower()
        local displayName = common.getDisplayName(id)

        if displayName then
            local itemElement = brick:findChild(elementIDs.itemBrick)

            --[[ Only change the element text if the element is visible, to work around an issue caused by UI Expansion.
            If this is the "soulGemFilled" variety of the inventory select menu (selecting a filled soulgem in the
            enchant menu), UI Expansion hides the vanilla name display element and creates its own. For some reason this
            causes the width of the hidden element to be enormous, which messes with setting the menu width correctly
            later. So just skip it in that case (we'll modify UI Expansion's new element later). ]]--
            if itemElement.visible then
                longest = renameItemElement(itemElement, id, displayName, longest, "")
            else
                common.logMsg(string.format("%s: Item element not visible. Skipping rename.", id))
            end

            local uiExpSoulgemNameElem = brick:findChild(elementIDs.uiExpSoulgemItemBrick)

            -- Change the text of UI Expansion's new element for soulgem names.
            if uiExpSoulgemNameElem then
                longest = renameItemElement(uiExpSoulgemNameElem, id, displayName, longest, "UI Expansion soulgem name. ")
            end
        end
    end

    local desiredWidth = longest + 130
    setMenuWidth(menu, longest, desiredWidth, "inventory select menu")
end

this.menuMagSelActivated = function(e)
    local itemNamesList = e.element:findChild(elementIDs.magicItemNames)
    local longest = 0
    common.logMsg("Magic select menu created. Displaying long item names.")

    for _, nameElement in ipairs(itemNamesList.children) do
        renameMagicElement(nameElement)

        -- We need to do :updateLayout() here in order to grab the new element width.
        nameElement:updateLayout()
        local elemWidth = nameElement.width
        longest = math.max(longest, elemWidth)
    end

    local desiredWidth = longest + 40
    local spellsList = e.element:findChild(elementIDs.magicSpellsList)
    local spellsListParent = spellsList.parent
    setMenuWidth(spellsListParent, longest, desiredWidth, "spells list")
end

-- The purpose of this function is to remove the prefix that would otherwise display in the name field of the enchant
-- menu (the real prefix will be added when the enchanted item is created).
local function enchantMenuUpdate(menu)
    local nameElem = menu:findChild(elementIDs.enchantNameField)
    local currentText = nameElem.text
    local textNoPrefix = common.getInitialNameForEnch(currentText)

    if currentText ~= textNoPrefix then
        local desiredText = textNoPrefix
        local object = menu:findChild(elementIDs.enchantItem):getPropertyObject(properties.enchantItem)

        if object then
            desiredText = data.displayNamesNoPrefix[object.id:lower()] or object.name

            if #desiredText > 31 then
                desiredText = string.sub(desiredText, 1, 31)
            end
        end

        nameElem.text = desiredText
        menu:updateLayout()
        common.logMsg(string.format("Enchanting menu: Changed text in name field from %s to %s", currentText, desiredText))
    end
end

this.enchantMenuActivated = function(e)
    if not e.newlyCreated then
        return
    end

    e.element:registerAfter("update", function()
        enchantMenuUpdate(e.element)
    end)
end

-- Changes the text of dialogue notification messages to show display names of objects given to or taken from player.
local function dialogUpdate(menu)
    local mainPane = menu:findChild(elementIDs.dialogMainPane)
    local pane = mainPane:findChild(elementIDs.scrollPane)
    local dialogElements = pane.children

    for i = 1, #dialogElements do
        local element = dialogElements[i]

        if element.id ~= elementIDs.dialogNotify then
            goto continue
        end

        local oldText = element.text

        if (not oldText) or oldText == "" then
            goto continue
        end

        -- This is just in case the player is using a mod that changes these GMSTs, though it still might not work right
        -- depending on how they're changed.
        local addedMessage = tes3.findGMST(tes3.gmst.sNotifyMessage60).value
        local removedMessage = tes3.findGMST(tes3.gmst.sNotifyMessage62).value
        local addedBeginIndex = string.find(addedMessage, " ")
        local removedBeginIndex = string.find(removedMessage, " ")
        local addedText = string.sub(addedMessage, addedBeginIndex, #addedMessage)
        local removedText = string.sub(removedMessage, removedBeginIndex, #removedMessage)

        local postDividerIndex = string.find(oldText, addedText)
        or string.find(oldText, removedText)
        or nil

        if not postDividerIndex then
            goto continue
        end

        local postText = string.sub(oldText, postDividerIndex, #oldText)
        local preText, oldNameText

        -- The element text starts with a number, in which case we're assuming it's because more than one of the item
        -- has been added/removed. If instead it's because the object name starts with a number, then this won't work
        -- and the object name will show in the element.
        if string.find(oldText, "%d") == 1 then
            local nameBeginIndex = string.find(oldText, " ") + 1

            -- Would only happen if the object name starts with a number and has no spaces, in which case this wouldn't
            -- work anyway.
            if nameBeginIndex >= postDividerIndex then
                goto continue
            end

            preText = string.sub(oldText, 1, nameBeginIndex - 1)
            oldNameText = string.sub(oldText, nameBeginIndex, postDividerIndex - 1)
        else
            preText = ""
            oldNameText = string.sub(oldText, 1, postDividerIndex - 1)
        end

        -- Like with magic effect tooltips below, for these notification messages we have to get the ID from the
        -- displayed object name, which is not guaranteed to always work, but should work in almost all cases.
        local id, displayName = common.getDisplayNameFromObjectName(oldNameText)

        if not displayName then
            goto continue
        end

        local newText = string.format("%s%s%s", preText, displayName, postText)

        if element.text == newText then
            goto continue
        end

        element.text = newText
        common.logMsg(string.format("Dialog notify element: %s: Element text changed to: %s", id, newText))

        ::continue::
    end
end

this.onDialogActivated = function(e)
    if not e.newlyCreated then
        return
    end

    e.element:registerAfter("update", function()
        dialogUpdate(e.element)
    end)
end

-- Runs whenever the tooltip of one of the magic effect icons (for the effects affecting the player) is created. This
-- only happens a couple times each when hovering over the icons in the magic menu, but happens basically every frame
-- for as long as the player mouses over one of the magic icons in the HUD.
local function onMagicEffectTooltip()
    -- For some reason this doesn't work when registering the ID like the others.
    local tooltip = tes3ui.findHelpLayerMenu("HelpMenu")

    if not tooltip then
        return
    end

    local sourceList = tooltip:findChild(elementIDs.magicSourceList)

    if not sourceList then
        return
    end

    local sources = sourceList.children
    local numSources = #sources

    -- This should never happen. The first child of the sourceList element is the effect name. Subsequent children list
    -- each source for the effect.
    if numSources < 2 then
        return
    end

    -- Start with the second child, or the first source in the source list.
    for i = 2, numSources do
        local source = sources[i]
        local oldText = source.text

        --[[ This case is pretty complicated. For object tooltips and most other menus we modify here, some element has
        a property which points to the actual object in question, but that's not the case for these tooltips. This means
        we have to get the item's object name from the tooltip text, and look up the ID from there. This isn't ideal,
        because it can result in the wrong display name displaying in the case of two items with identical object names
        but different display names (this won't happen with only vanilla items).

        What we're looking for is the beginning of the transition between the object name and the text the tooltip
        displays after that. pattern1 matches Fortify Maximum Magicka tooltips (a space, one or more digits, a period,
        one or more digits, an x). pattern2 matches a couple effects that affect skills, like Fortify Skill. pattern3
        matches most other attribute- or skill-affecting effects. pattern4 matches the "normal" case of an effect that
        doesn't affect an attribute or skill but that does have a magnitude. There's also a fifth possibility, an effect
        with no magnitude (or most effects from potions and ingredients), in which there is no "post text" at all and
        the tooltip just displays the item name.

        There's a potential problem here: if an enchanted item has " (" in its object name, the display name might not
        show in the tooltip, depending on the enchantment's effects. This won't happen with only vanilla items, and is a
        minor issue regardless. ]]--
        local pattern1 = " %d+%.%d+x"
        local pattern2 = "  %("
        local pattern3 = " %("
        local pattern4 = ": "

        local lastIndex = findLastIndex(oldText, pattern1)
        or findLastIndex(oldText, pattern2)
        or findLastIndex(oldText, pattern3)
        or findLastIndex(oldText, pattern4)
        or nil

        local objectName = ( lastIndex and string.sub(oldText, 1, lastIndex - 1) ) or oldText
        local postText = ( lastIndex and string.sub(oldText, lastIndex, #oldText) ) or ""

        -- If it's > 31 characters, then either the text hasn't changed since the last time we did this, or something
        -- went wrong when determining the transition point above. In either case, bail.
        if #objectName > 31 then
            goto continue
        end

        local id, displayName = common.getDisplayNameFromObjectName(objectName)

        if not displayName then
            goto continue
        end

        local newText = string.format("%s%s", displayName, postText)

        if source.text == newText then
            goto continue
        end

        source.text = newText
        common.logMsg(string.format("Magic effect tooltip: %s: Element text changed to: %s", id, newText))

        ::continue::
    end
end

-- Runs whenever the HUD updates (basically every frame). Unfortunately this is necessary to ensure our tooltip function
-- runs.
local function hudUpdate(menu)
    local iconsList = menu:findChild(elementIDs.hudIconsList)

    for _, iconRow in ipairs(iconsList.children) do
        for _, icon in ipairs(iconRow.children) do
            icon:registerAfter("help", onMagicEffectTooltip)
        end
    end
end

-- Runs whenever the magic menu updates (so continuously whenever the player is scrolling through the menu, for
-- example). We have to do it this way to make sure correct display names are displayed when things change, such as when
-- the player picks up a magic item while the menu is open.
local function menuMagicUpdate(menu)
    local itemNamesList = menu:findChild(elementIDs.magicItemNames)
    common.logMsg("Magic menu updating. Displaying long item names.")

    for _, nameElement in ipairs(itemNamesList.children) do
        renameMagicElement(nameElement)
    end

    local iconsList = menu:findChild(elementIDs.magicIconsList)

    for _, iconRow in ipairs(iconsList.children) do
        for _, icon in ipairs(iconRow.children) do
            icon:registerAfter("help", onMagicEffectTooltip)
        end
    end
end

this.hudActivated = function(e)
    if not e.newlyCreated then
        return
    end

    -- registerAfter means the game still does its thing, then we do ours after.
    e.element:registerAfter("preUpdate", function()
        hudUpdate(e.element)
    end)
end

this.menuMagicActivated = function(e)
    if not e.newlyCreated then
        return
    end

    e.element:registerAfter("preUpdate", function()
        menuMagicUpdate(e.element)
    end)
end

-- Runs every frame. We need to make sure the text of this element is correct every frame, otherwise it will still
-- display incorrect names (object names) under certain circumstances (such as selecting an active magic that's already
-- the active magic).
this.updateHudText = function()
    local multiMenu = tes3ui.findMenu(elementIDs.multi)

    if not multiMenu then
        return
    end

    local nameElemMulti = multiMenu:findChild(elementIDs.hudNotify)

    if nameElemMulti.text ~= hudText then
        nameElemMulti.text = hudText
    end
end

-- Also runs every frame. We have to check the player's active magic every frame and run setWeaponMagicText when it
-- changes because there's no event for when the player equips a spell/item as active magic.
this.checkMagic = function()
    if not tes3.mobilePlayer then
        return
    end

    local newMagic = getCurMagic()

    if newMagic == currentEquip.magic then
        return
    end

    currentEquip.magic = newMagic
    setWeaponMagicText("magic")
end

this.onEquipmentChanged = function(e)
    if e.reference ~= tes3.player then
        return
    end

    local object = e.item

    if object.objectType ~= tes3.objectType.weapon
    and object.objectType ~= tes3.objectType.lockpick
    and object.objectType ~= tes3.objectType.probe then
        return
    end

    -- This function runs on both equipped and unequipped, so we have to check the equipped weapon again.
    currentEquip.weapon = getCurWeapon()
    setWeaponMagicText("weapon")
end

this.onLoaded = function()
    currentEquip.magic = getCurMagic()
    currentEquip.weapon = getCurWeapon()
    setWeaponMagicText("magic")
    setWeaponMagicText("weapon")

    for gmstName, defaultValue in pairs(defaultGMSTs) do
        changeGMST(gmstName, defaultValue)
    end

    gmstCount = 0
end

-- Changes the displayed name in object tooltips (e.g. in the inventory).
this.onTooltip = function(e)
    local object = e.object
    local id = object.id:lower()
    local displayName = common.getDisplayName(id)

    if not displayName then
        return
    end

    local newText = displayName

    -- Since this function totally overrides the tooltip name display, we need to do this to make sure the creature name
    -- is displayed for filled soulgems.
    if object.isSoulGem then
        if e.itemData and e.itemData.soul then
            local soulName = e.itemData.soul.name
            newText = string.format("%s (%s)", newText, soulName)
        end
    end

    -- In the player inventory and objects in the world, the tooltip will display a quantity indicator if there's more
    -- than one of the object. e.count is always 0 outside the player inventory, so we have to get the stack size in the
    -- case of a reference in the world.
    local ref = e.reference
    local count = ( ref and ref.stackSize ) or e.count

    -- Force the tooltip to display the item count, if applicable. This will never display in the container/barter menu
    -- (as in vanilla), because e.count is always 0 in those cases.
    if count > 1 then
        newText = string.format("%s (%u)", newText, count)
    end

    local nameElement = e.tooltip:findChild(elementIDs.tooltipName)
    nameElement.text = newText
    common.logMsg(string.format("Tooltip: %s: Name displayed as %s.", id, newText))
end

this.onInitialized = function()
    if config.changeKeyMessage then
        common.logMsg("Config option to change key-unlock messagebox is enabled. Patching code to change messagebox.")
        replaceKeyCheckLogic(0x4E9DF4, 0x4E9E86)
        replaceKeyCheckLogic(0x4EACF8, 0x4EAD8A)
    else
        common.logMsg("Config option to change key-unlock messagebox is disabled. Skipping code patching.")
    end

    changeGMST("sNotifyMessage49", "Hey, that's mine!")
end

return this