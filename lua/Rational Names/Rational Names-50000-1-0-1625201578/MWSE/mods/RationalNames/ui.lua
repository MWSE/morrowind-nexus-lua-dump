-- Everything in this file exists to enable the ability to have object names longer than 31 characters. Long object
-- names are just UI trickery; in this file, we force the UI to display the full object names in various contexts.
local data = require("RationalNames.data")
local common = require("RationalNames.common")

local hudText
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
    hudIconsList = tes3ui.registerID("MenuMulti_magic_icons_1"),
    magicSourceList = tes3ui.registerID("PartHelpMenu_main"),
}

local properties = {
    magic = tes3ui.registerProperty("MagicMenu_object"),
    repair = tes3ui.registerProperty("MenuRepair_Object"),
    serviceRepair = tes3ui.registerProperty("MenuServiceRepair_Object"),
    invSel = tes3ui.registerProperty("MenuInventorySelect_object"),
}

local textGMSTs = {
    weapon = "sSkillHandtohand",
    magic = "sNone",
}

local this = {}

-- Runs whenever the player's currently equipped weapon or active magic has changed. menu is either the inventory or
-- magic menu, and newText is the name (full name if applicable) of the equipped weapon or magic.
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
    local curMagic = nil
    local curEnchItem = tes3.mobilePlayer.currentEnchantedItem.object

    if curEnchItem then
        curMagic = curEnchItem
    else
        local curSpell = tes3.mobilePlayer.currentSpell

        if curSpell then
            curMagic = curSpell
        end
    end

    return curMagic
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
    local curWeapon = nil

    if not curWeaponStack then
        curWeaponStack = getEquipment(tes3.objectType.lockpick)
    end

    if not curWeaponStack then
        curWeaponStack = getEquipment(tes3.objectType.probe)
    end

    if curWeaponStack then
        curWeapon = curWeaponStack.object
    end

    return curWeapon
end

-- type is "weapon" or "magic". Runs when the player's weapon or active magic changes, and on loaded.
local function setWeaponMagicText(type)
    common.logMsg(string.format("Updating %s display.", type))
    local object = currentEquip[type]

    if object then
        local id = object.id:lower()
        local fullName = data.fullNamesList[id]
        common.logMsg(string.format("Player currently has %s equipped. ID: %s.", type, id))

        if fullName then
            objectText[type] = fullName
            common.logMsg(string.format("Equipped %s is on fullNamesList. Full name: %s.", type, objectText[type]))
        else
            objectText[type] = object.name
            common.logMsg(string.format("Equipped %s is not on fullNamesList. Name: %s.", type, objectText[type]))
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
    local fullName = data.fullNamesList[id]

    if fullName
    and element.text ~= fullName then
        element.text = fullName
        common.logMsg(string.format("%s: Changing displayed name to: %s.", id, fullName))
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
        local fullName = data.fullNamesList[id]

        if not fullName then
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
        local newText = string.format("%s%s", fullName, goldText)
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
        local fullName = data.fullNamesList[id]

        if fullName then
            local nameElement = itemBlock.children[1]
            longest = renameItemElement(nameElement, id, fullName, longest, "")
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
        local fullName = data.fullNamesList[id]

        if fullName then
            local itemElement = brick:findChild(elementIDs.itemBrick)

            --[[ Only change the element text if the element is visible, to work around an issue caused by UI Expansion.
            If this is the "soulGemFilled" variety of the inventory select menu (selecting a filled soulgem in the
            enchant menu), UI Expansion hides the vanilla name display element and creates its own. For some reason this
            causes the width of the hidden element to be enormous, which messes with setting the menu width correctly
            later. So just skip it in that case (we'll modify UI Expansion's new element later). ]]--
            if itemElement.visible then
                longest = renameItemElement(itemElement, id, fullName, longest, "")
            else
                common.logMsg("%s: Item element not visible. Skipping rename.", id)
            end

            local uiExpSoulgemNameElem = brick:findChild(elementIDs.uiExpSoulgemItemBrick)

            -- Change the text of UI Expansion's new element for soulgem names. This should actually never happen by
            -- default anyway, since soulgems don't have long names, but we're doing it just in case some player changes
            -- soulgem base names in data.lua to be really long.
            if uiExpSoulgemNameElem then
                longest = renameItemElement(uiExpSoulgemNameElem, id, fullName, longest, "UI Expansion soulgem name. ")
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

        nameElement:updateLayout()
        local elemWidth = nameElement.width
        longest = math.max(longest, elemWidth)
    end

    local desiredWidth = longest + 40
    local spellsList = e.element:findChild(elementIDs.magicSpellsList)
    local spellsListParent = spellsList.parent
    setMenuWidth(spellsListParent, longest, desiredWidth, "spells list")
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
        local oldTextLength = #oldText

        if oldTextLength < 31 then
            goto continue
        end

        --[[ This case is pretty complicated. For object tooltips and the other menus we modify here, some element has a
        property which points to the actual object in question, but that's not the case for these tooltips. This means
        we have to get the item's "short name" from the tooltip text, and look up the ID from there. This isn't ideal,
        because it can result in the wrong full name displaying in the case of two items with identical short names but
        different full names (this won't happen in vanilla).

        What we're looking for is the beginning of the transition between the object name and the text the tooltip
        displays after that. pattern1 matches Fortify Maximum Magicka tooltips (a space, one or more digits, a period,
        one or more digits, an x). pattern2 matches a couple effects that affect skills, like Fortify Skill. pattern3
        matches most other attribute- or skill-affecting effects (unfortunately Damage Attribute is excluded entirely,
        because it doesn't have a space at all in the transition, but that's not a big deal). pattern4 matches the
        "normal" case of an effect that doesn't affect an attribute or skill but that does have a magnitude. There's
        also a fifth possibility, an effect with no magnitude (or most effects from potions and ingredients), in which
        there is no "post text" at all and the tooltip just displays the item name.

        There's a potential problem here: if an enchanted item has " (" in its (short) name, the full name might not
        display in the tooltip, depending on the enchantment's effects. This won't happen in vanilla, and is a minor
        issue regardless. ]]--
        local pattern1 = " %d+%.%d+x"
        local pattern2 = "  %("
        local pattern3 = " %("
        local pattern4 = ": "

        local lastIndex = findLastIndex(oldText, pattern1)
        or findLastIndex(oldText, pattern2)
        or findLastIndex(oldText, pattern3)
        or findLastIndex(oldText, pattern4)
        or nil

        local shortName
        local postText

        if lastIndex then
            shortName = string.sub(oldText, 1, lastIndex - 1)
            postText = string.sub(oldText, lastIndex, oldTextLength)
        else
            shortName = oldText
            postText = ""
        end

        -- If it's < 31 characters, then the item doesn't have a full name. If it's > 31 characters, then either the
        -- text hasn't changed since the last time we did this, or something went wrong when determining the transition
        -- point above. In either case, bail.
        if #shortName ~= 31 then
            goto continue
        end

        local id = data.shortNameToID[shortName]

        if not id then
            goto continue
        end

        local fullName = data.fullNamesList[id]

        -- This should never happen if there's an ID in the shortNameToID table, but just in case.
        if not fullName then
            goto continue
        end

        local newText = string.format("%s%s", fullName, postText)

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

    for _, icon in ipairs(iconsList.children) do
        icon:registerAfter("help", onMagicEffectTooltip)
    end
end

-- Runs whenever the magic menu updates (so continuously whenever the player is scrolling through the menu, for
-- example). We have to do it this way to make sure full names are displayed when things change, such as when the player
-- picks up a magic item while the menu is open.
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
-- display the "short" names under certain circumstances (such as selecting an active magic that's already the active
-- magic).
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
end

this.onTooltip = function(e)
    local object = e.object
    local id = object.id:lower()
    local fullName = data.fullNamesList[id]

    if not fullName then
        return
    end

    local newText = fullName

    -- Since this function totally overrides the tooltip name display, we need to do this to make sure the creature name
    -- is displayed for filled soulgems. This should never happen by default, since soulgems don't have long names.
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

return this