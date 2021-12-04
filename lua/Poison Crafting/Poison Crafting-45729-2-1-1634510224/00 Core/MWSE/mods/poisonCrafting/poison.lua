local config = require("poisonCrafting.config")
local projectiles = require("poisonCrafting.projectiles")

--- Get the poison on the given weapon.
---
--- @param item tes3weapon
--- @param itemData tes3itemData|nil
--- @return tes3alchemy|nil
local function getPoison(item, itemData)
    local id

    local projectile = projectiles.storage[item.id]
    if projectile then
        id = projectile.poison
    elseif itemData then
        id = itemData.data.g7_poison
    end

    if id then
        return tes3.getObject(id)
    end
end

--- Get the icon path of the item's (first) magic effect.
--- @param item tes3alchemy
--- @return string|nil
local function getEffectIconPath(item)
    local success, icon = pcall(function()
        return "icons\\" .. item.effects[1].object.bigIcon
    end)
    return success and icon
end

--- Add an appropriate effect icon to the given item tile.
--- @param element tes3uiElement
--- @param item tes3item
local function addEffectIcon(element, item)
    local path = getEffectIconPath(item)
    if path then
        local image = element:createImage{id="Effect_Icon", path=path}
        image.width = 16
        image.height = 16
        image.scaleMode = true
        image.absolutePosAlignX = 1.0
        image.absolutePosAlignY = 0.2
        image.consumeMouseEvents = false
    end
end

--- Update the effect icon on the equipped weapon slot.
local function updateEquippedIcon(e)
    if not config.useEffectIcons then
        return
    elseif e.reference ~= tes3.player then
        return
    elseif e.item.objectType ~= tes3.objectType.weapon then
        return
    end

    local element = tes3ui.findMenu("MenuMulti"):findChild("MenuMulti_weapon_icon")
    local oldIcon = element:findChild("Effect_Icon")
    if oldIcon then
        oldIcon:destroy()
    end

    if e.eventType ~= "unequipped" then
        local poison = getPoison(e.item, e.itemData)
        if poison then
            addEffectIcon(element, poison)
        end
    end
end
event.register("equipped", updateEquippedIcon)
event.register("unequipped", updateEquippedIcon)

-- Manually refresh the equipped weapon icon on reloads.
local function onLoaded()
    local weapon = tes3.mobilePlayer.readiedWeapon
    if weapon then
        updateEquippedIcon{reference = tes3.player, item = weapon.object, itemData = weapon.itemData}
    end
end
event.register("loaded", onLoaded)

--- Add poison icons to inventory tiles.
local function addPoisonIcon(e)
    if config.useEffectIcons then
        local poison = getPoison(e.item, e.itemData)
        if poison then
            addEffectIcon(e.element, poison)
        end
    end
end
event.register("itemTileUpdated", addPoisonIcon)

--- Add poison information to weapon tooltips.
local function addPoisonTooltip(e)
    local poison = getPoison(e.object, e.itemData)
    if not poison then return end

    local label = e.tooltip:createLabel{id="Poison_Tooltip_Name", text="Poisoned"}
    label.wrapText = false

    local parent = e.tooltip:createBlock{id="Poison_Tooltip_Effects"}
    parent.flowDirection = "top_to_bottom"
    parent.autoWidth = true
    parent.autoHeight = true
    parent.borderAllSides = 4
    parent.borderLeft = 6
    parent.borderRight = 6

    for _, effect in ipairs(poison.effects) do
        if effect.object then
            local child = parent:createBlock{}
            child.minWidth = 1
            child.maxWidth = 640
            child.autoWidth = true
            child.autoHeight = true
            child.widthProportional = 1.0
            child.borderAllSides = 1

            local image = child:createImage{path=("icons\\" .. effect.object.icon)}
            image.borderTop = 1
            image.borderRight = 6

            local label = child:createLabel{text=tostring(effect):gsub(" on .+$", "")}
            label.wrapText = false
        end
    end
end
event.register("uiObjectTooltip", addPoisonTooltip, { priority = -70 }) -- After UI Expansion

--- Set the poison on the given weapon.
---
--- @param owner tes3reference
--- @param item tes3weapon
--- @param itemData tes3itemData|nil
--- @param poison tes3alchemy
local function setPoison(owner, item, itemData, poison)
    if item.isProjectile then
        -- check if we need to equip
        local isEquipped = owner.object:hasItemEquipped(item) ---@diagnostic disable-line: undefined-field

        -- remove initial projectile
        tes3.removeItem{reference=owner, item=item, playSound=false, updateGUI=false}

        -- create a poisoned version
        item = projectiles.createPoisonProjectile(item, poison)

        -- add it to owner inventory
        tes3.addItem{reference=owner, item=item, playSound=false, updateGUI=false}

        -- equip it when appropriate
        if isEquipped then
            timer.frame.delayOneFrame(function() owner.mobile:equip{item=item} end) ---@diagnostic disable-line: undefined-field
        end
    else
        -- we use itemData for melee
        assert(item.isMelee)
        if not itemData then
            itemData = tes3.addItemData{to=owner, item=item, updateGUI=false}
        end

        -- save the poison object id
        itemData.data.g7_poison = poison.id

        -- update icon if applicable
        if owner == tes3.player then
            updateEquippedIcon{reference=owner, item=item, itemData=itemData}
        end
    end
    -- mwse.log('"%s" set poison "%s" on weapon "%s"', owner, poison, item)
end

--- Set the poison on the given weapon, interactively.
---
--- Player-only, the weapon/poison must be present in the player's inventory.
---
--- @param weapon tes3weapon
--- @param weaponData tes3itemData|nil
--- @param poison tes3alchemy
--- @param poisonData tes3itemData|nil
local function setPoisonInteractive(weapon, weaponData, poison, poisonData)
    -- Helper function that can be called directly or passed to messageBox.
    local function callback(e)
        -- cancelled by "No" button
        if e and e.button == 1 then return end
        -- set poison on the weapon
        setPoison(tes3.player, weapon, weaponData, poison)
        -- this consumes the poison
        tes3.removeItem{reference=tes3.player, item=poison, itemData=poisonData, playSound=false}
    end

    -- Always shows message if overwriting, otherwise respect users config.
    local message
    if getPoison(weapon, weaponData) then
        message = ("Apply poison to %s?\n\nThe previous poison will be lost!"):format(weapon.name)
    elseif config.useApplyMessage then
        message = ("Apply poison to %s?"):format(weapon.name)
    end

    if message then
        tes3.messageBox{message = message, buttons = {"Yes", "No"}, callback = callback}
    else
        callback()
    end
end

--- Add click events to inventory tiles for interactive poisoning.
local function addPoisonClickEvent(e)
    -- Ensure it's a supported item and in the player's inventory.
    if not (e.item.isMelee or e.item.isProjectile)
        or e.menu:getPropertyObject("MenuContents_Actor")
        or e.menu:getPropertyObject("MenuContents_ObjectContainer")
    then
        return
    end

    -- Register a new click event for when we drop a poison on it.
    e.element:registerBefore("mouseClick", function()
        local success, c = pcall(function()
            -- Get the thing that is currently on the cursor tile.
            local c = tes3ui.findHelpLayerMenu("CursorIcon"):getPropertyObject("MenuInventory_Thing", "tes3inventoryTile")
            -- Ensure it's a alchemy object from player inventory.
            local pcInventory = tes3.player.object.inventory
            return assert(
                c.item.objectType == tes3.objectType.alchemy
                and pcInventory:contains(c.item, c.itemData)
                and pcInventory:contains(e.item, e.itemData)
                and c
            )
        end)
        if success then
            if tes3.mobilePlayer.inCombat then
                tes3.messageBox("You cannot apply poisons during combat.")
            else
                setPoisonInteractive(e.item, e.itemData, c.item, c.itemData)
            end
        end
    end)
end
event.register("itemTileUpdated", addPoisonClickEvent, { filter = "MenuInventory" })

--- Inflict a projectile's poison on its damaged reference.
local function onDamagedProjectile(e)
    if e.source ~= "attack" then
        return
    elseif e.projectile == nil then
        return
    end

    local ref = e.projectile.reference
    if not (ref and ref.object) then
        return
    end

    local poison = getPoison(ref.object)
    if not poison then return end

    -- mwse.log('"%s" inflicts poison "%s" on target "%s"', e.attackerReference, poison, e.reference)
    tes3.applyMagicSource{reference=e.reference, source=poison}
end
event.register("damaged", onDamagedProjectile)

--- Inflict a melee weapon's poison on its damaged reference.
local function onDamagedMelee(e)
    if e.source ~= "attack" then
        return
    elseif e.projectile ~= nil then
        return
    end

    local weapon = e.attacker.readiedWeapon
    if not (weapon and weapon.object.isMelee) then
        return
    end

    local poison = getPoison(weapon.object, weapon.itemData)
    if not poison then return end

    -- mwse.log('"%s" inflicts poison "%s" on target "%s"', e.attackerReference, poison, e.reference)
    tes3.applyMagicSource{reference=e.reference, source=poison}

    -- Clear the poison from the weapon.
    weapon.itemData.data.g7_poison = nil

    -- Ensure GUI is updated for player.
    if e.attackerReference == tes3.player then
        updateEquippedIcon({reference=tes3.player, item=weapon.object, itemData=weapon.itemData})
        tes3.updateInventoryGUI{reference=tes3.player}
    end
end
event.register("damaged", onDamagedMelee)

--- Make actors of appropriate classes apply poisons to their weapons.
local function onMobileActivated(e)
    if not e.mobile then return end

    local weapon = e.mobile.readiedWeapon
    if weapon and weapon.object.isRanged then
        weapon = e.mobile.readiedAmmo
    end
    if not weapon then return end

    local class = e.mobile.object.class
    if not class then return end

    local chance = config.classPoisonChance[class.id:lower()]
    if not chance then return end

    local alreadyAdded = e.reference.data.g7_poison_added
    if alreadyAdded then return end

    --
    local roll = math.random(100)
    if chance >= roll then
        assert(e.reference ~= tes3.player) -- presumedly not necessary?
        local poison = tes3.getObject("g7a_levelled_poison"):pickFrom()
        setPoison(e.reference, weapon.object, weapon.itemData, poison)
    end

    e.reference.data.g7_poison_added = true
end
event.register("mobileActivated", onMobileActivated)

--- Add dynamic effect labels to alchemy meshes.
local function onAlchemySceneNodeCreated(e)
    if e.reference.object.objectType ~= tes3.objectType.alchemy then
        return
    end

    -- only applies to meshes marked with "HasEffectLabel"
    if not e.reference.sceneNode:hasStringDataWith("HasEffectLabel") then
        return
    end

    local path = getEffectIconPath(e.reference.object)
    if not path then
        return
    end

    pcall(function()
        local node = e.reference.sceneNode:getObjectByName("EffectLabel")
        local texProp = node.texturingProperty
        local baseMap = texProp.maps[1]

        -- if the file on disk is a dds rather than a tga we need to remap
        local temp = path:lower():gsub("tga$", "dds")
        if tes3.getFileExists(temp) then
            path = temp
        end

        if baseMap.texture.fileName ~= path then
            node.texturingProperty = texProp:clone()
            node.texturingProperty.maps[1].texture = niSourceTexture.createFromPath(path)
            node:updateProperties()
        end
    end)
end
event.register("referenceSceneNodeCreated", onAlchemySceneNodeCreated)

--- Add effect icons to the alchemy inventory tiles.
local function onAlchemyTileUpdated(e)
    if config.useEffectIcons then
        if e.item.objectType == tes3.objectType.alchemy then
            addEffectIcon(e.element, e.item)
        end
    end
end
event.register("itemTileUpdated", onAlchemyTileUpdated)
