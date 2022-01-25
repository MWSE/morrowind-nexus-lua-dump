--[[
    run code without restarting the game! hotkey alt+x
--]]
local common = require('ss20.common')
local config = common.config
local modName = config.modName
--local sortByName = function(a,b) return a.name < b.name; end

local uiids = {
    titleBlock = tes3ui.registerID("SS20_ShopMenu_TitleBlock"),
    shardCount = tes3ui.registerID("SS20_ShopMenu_ShardCound"),
    shopMenu = tes3ui.registerID("SS20_ShopMenu_Menu"),
    midBlock = tes3ui.registerID("SS20_ShopMenu_MidBlock"),
    previewBorder = tes3ui.registerID("SS20_ShopMenu_PreviewBorder"),
    previewBlock = tes3ui.registerID("SS20_ShopMenu_PreviewBlock"),
    nifPreviewBlock = tes3ui.registerID("SS20_ShopMenu_NifPreviewBlock"),
    imagePreviewBlock = tes3ui.registerID("SS20_ShopMenu_ImagePreviewBlock"),
    selectedItem = tes3ui.registerID("SS20_ShopMenu_SelectedResource"),
    nif = tes3ui.registerID("SS20_ShopMenu_NifPreview"),
    descriptionBlock = tes3ui.registerID("SS20_ShopMenu_DescriptionBlock"),
    buttonsBlock = tes3ui.registerID("SS20_ShopMenu_ButtonsBlock"),
    shopListScrollPane = tes3ui.registerID("SS20_ShopMenu_ShopBlock"),
    previewPane = tes3ui.registerID("SS20_ShopMenu_PreviewPane"),
    previewName = tes3ui.registerID("SS20_ShopMenu_PreviewName"),
    previewDescription = tes3ui.registerID("SS20_ShopMenu_PreviewDescription"),
    previewList = tes3ui.registerID("SS20_ShopMenu_PreviewList"),
    createItemButton = tes3ui.registerID("SS20_ShopMenu_CreateItemButton"),
    unlockPackButton = tes3ui.registerID("SS20_ShopMenu_UnlockPackButton"),
}
local m1 = tes3matrix33.new()
local m2 = tes3matrix33.new()

local shopConfig = {
    shopTypes = {'Rooms','Furniture'},
    defaultShop = 'Furniture',
    menuWidth = 800,
    menuHeight = 800,
    previewHeight = 400,
    previewWidth= 400,
    previewYOffset = -300,
    title = "Transmutation Menu"
}


local function closeMenu()
    local menu = tes3ui.findMenu(uiids.shopMenu)
    if  menu then 
        menu:destroy()
        tes3ui.leaveMenuMode()
    end
end



local function buyItem()

    if common.getSoulShards() < tes3.player.data[modName].selectedResource.cost then
        tes3.messageBox("You can not afford this item!")
        closeMenu()
        return
    end
    common.modSoulShards(-tes3.player.data[modName].selectedResource.cost)

    local eyeOri = tes3.getPlayerEyeVector()
    local eyePos = tes3.getPlayerEyePosition()

    local ray = tes3.rayTest{ 
        position = tes3.getPlayerEyePosition(), 
        direction = tes3.getPlayerEyeVector(),
        ignore = { tes3.player}
    }
    local rayDist = ray and ray.intersection and math.min(ray.distance -5, 200)


    local position = eyePos + eyeOri * rayDist
    
    local ref = tes3.createReference{
        object = tes3.player.data[modName].selectedResource.id,
        cell = tes3.player.cell,
        orientation = tes3.player.orientation:copy() + tes3vector3.new(0, 0, math.pi),
        position = position
    }
    ref.data.soulShards = tes3.player.data[modName].selectedResource.cost
    ref:updateSceneGraph()
    ref.sceneNode:updateNodeEffects()

    closeMenu()
end

local function isPackUnlocked(resourcePack)
    local pack = resourcePack or tes3.player.data[modName].selectedPack
    return tes3.player.data[modName].unlockedResourcePacks[pack.id] == true
end




local function removeCollision(sceneNode)
    for node in common.traverse{sceneNode} do
        if node:isInstanceOfType(tes3.niType.RootCollisionNode) then
            node.appCulled = true
        end
    end
end


local function toggleButtonDisabled(button, isVisible, isDisabled)
    button.visible = isVisible
    button.widget.state = isDisabled and 2 or 1
    button.disabled = isDisabled
    if isDisabled then
        button:register("help", function()
            local tooltip = tes3ui.createTooltipMenu()
            tooltip:createLabel{ text = "You don't have enough shards."}
        end)
    end
    
end


local function updateBuyButtons()
    local shopMenu = tes3ui.findMenu(uiids.shopMenu)
    if not shopMenu then return end

    local unlockButton = shopMenu:findChild(uiids.unlockPackButton)
    local createButton = shopMenu:findChild(uiids.createItemButton)
    local resourceUnlocked = isPackUnlocked()

    common.log:debug("Resource %s", resourceUnlocked and "unlocked" or "locked")
    if unlockButton and createButton then
        unlockButton.text = string.format("Unlock %s (%d Soul Shards)", tes3.player.data[modName].selectedPack.name, tes3.player.data[modName].selectedPack.cost)
        createButton.text = string.format("Build %s (%d Soul Shards)", tes3.player.data[modName].selectedResource.name, tes3.player.data[modName].selectedResource.cost)
        toggleButtonDisabled(unlockButton, not resourceUnlocked,  common.getSoulShards() < tes3.player.data[modName].selectedPack.cost)
        toggleButtonDisabled(createButton, resourceUnlocked,  common.getSoulShards() < tes3.player.data[modName].selectedResource.cost)

    end
end


local function updatePreviewPane()
    local selectedResource = tes3.player.data[modName].selectedResource
    local itemId = selectedResource.id
    local itemName = selectedResource.name
    local shopMenu = tes3ui.findMenu(uiids.shopMenu)
    if not shopMenu then return end
    common.log:debug("itemId: %s", itemId)
    local item = tes3.getObject(itemId)
    if item then

        --image preview block
        -- local imagePreviewBlock = shopMenu:findChild(uiids.imagePreviewBlock)
        -- if imagePreviewBlock then
        --     imagePreviewBlock:destroyChildren()
        --     local image = imagePreviewBlock:createImage{ id = tes3ui.registerID("SS20NIF"), path = "textures\\ss20\\preview_bg.dds"}
        --     formatImage(image)
        -- end
        
        --nifPreviewBLock
        local nifPreviewBlock = shopMenu:findChild(uiids.nifPreviewBlock)
        if nifPreviewBlock then 
            nifPreviewBlock:destroyChildren()
            local nif = nifPreviewBlock:createNif{ id = uiids.nif, path = item.mesh}
            if not nif then return end 
            --nif.scaleMode = true
            shopMenu:updateLayout()
            common.log:debug("mesh: %s", item.mesh)
            common.log:debug(nif.sceneNode.name)

            local node = nif.sceneNode:getObjectByName("SS20_ShopMenu_NifPreview")
            common.removeLight(node)
            removeCollision(node)
            node:update()

            local maxDimension
            local bb = node:createBoundingBox(node.scale)
            if selectedResource.height then
                --custom heights for fucky meshes
                maxDimension = selectedResource.height
            else
                --get size from bounding box

                local height = bb.max.z - bb.min.z
                local width = bb.max.y - bb.min.y
                local depth = bb.max.x - bb.min.x

                maxDimension = math.max(width, depth, height)
                --local maxDimension = node.worldBoundRadius
                common.log:debug("bb min: %s, max: %s", bb.min, bb.max)
                common.log:debug("height: %s", height)
                common.log:debug("worldBoundRadius: %s", node.worldBoundRadius)
            end
            local targetHeight = 250
            node.scale = targetHeight / maxDimension

            local lowestPoint = bb.min.z
            common.log:debug("lowestPoint = %s", lowestPoint)
            node.translation.z = node.translation.z - lowestPoint*node.scale 

            do --add properties
                local vertexColorProperty = niVertexColorProperty.new()
                vertexColorProperty.name = "vcol yo"
                vertexColorProperty.source = 2
                node:attachProperty(vertexColorProperty)

                local zBufferProperty = niZBufferProperty.new()
                zBufferProperty.name = "zbuf yo"
                zBufferProperty:setFlag(true, 0)
                zBufferProperty:setFlag(true, 1)
                node:attachProperty(zBufferProperty)
            end

            m1:toRotationX(math.rad(-15))
            m2:toRotationZ(math.rad(180))
            node.rotation = node.rotation * m1:copy() * m2:copy()
            
            
            node.appCulled = false
            node:updateProperties()
            node:update()
            nifPreviewBlock:updateLayout()
        end

        local label = shopMenu:findChild(uiids.selectedItem)
        label.text = itemName
    end
    updateBuyButtons()
end




local function rotateNif(e)
    local menu = tes3ui.findMenu(uiids.shopMenu)
    if not menu then 
        event.unregister("enterFrame", rotateNif)
        return 
    end
    local nif = menu:findChild(uiids.nif)
    
    if nif and nif.sceneNode then
        local node = nif.sceneNode
        

        m2:toRotationZ(math.rad(15) * e.delta)
        node.rotation = node.rotation * m2

        node:update()
    end
end

local function resourceSorter(a, b)
	return a.name:lower() < b.name:lower()
end


local function updateSelectedResourcePack()
    local shopMenu = tes3ui.findMenu(uiids.shopMenu)
    if not shopMenu then return end
    common.log:debug("updating selected resource: %s", tes3.player.data[modName].selectedPack.id)

    --update preview pane
    local nifPreviewBlock = shopMenu:findChild(uiids.nifPreviewBlock)
    nifPreviewBlock:destroyChildren()

    local pack = tes3.player.data[modName].selectedPack

    --update name/description
    local previewName = shopMenu:findChild(uiids.previewName)
    previewName.text = pack and pack.name or ""

    local previewDescription = shopMenu:findChild(uiids.previewDescription)
    previewDescription.text = pack and pack.description or ""

    --List all the items in the tes3.player.data[modName].selectedPack 
    local previewList = shopMenu:findChild(uiids.previewList)
    previewList:getContentElement():destroyChildren()
    
    if pack then
        
        local items = pack.items
        table.sort(items, resourceSorter)
        for _, data in ipairs(items) do
            --replace preview pane with nif on click?
            local button = previewList:createTextSelect()
            button.text = string.format("(%d) - %s", data.cost, data.name)
            if (
                not isPackUnlocked(pack)
                or data.cost > common.getSoulShards()
            ) then
                button.color = tes3ui.getPalette("disabled_color")
                button.widget.idle = tes3ui.getPalette("disabled_color")
            end
            button:register("mouseClick", function()
                tes3.player.data[modName].selectedResource = data
                updatePreviewPane()
            end)
        end
        
    end
    
    updatePreviewPane()
    previewList.widget:contentsChanged()
    shopMenu:updateLayout()
end

local function getShardText()
    return string.format("Soul Shards: %d", common.getSoulShards())
end



local function updateShopMenu(e)
    e = e or {}
    local menu = tes3ui.findMenu(uiids.shopMenu)
    if not menu then return end

    common.log:debug("Updating shop meny azdzfguj")

    local shopListScrollPane = menu:findChild(uiids.shopListScrollPane)
    if not shopListScrollPane then
        return error()
    end
    local contentElement = shopListScrollPane:getContentElement()
    contentElement:destroyChildren()

    local shop = e.shop or shopConfig.defaultShop
    common.log:debug("shop: %s", shop)
    table.sort(config.resourcePacks, resourceSorter)
    for _, resourcePack in ipairs(config.resourcePacks) do
        local button = shopListScrollPane:createTextSelect{}
        
        if not isPackUnlocked(resourcePack) then
            button.text = string.format("(%s) - %s", resourcePack.cost, resourcePack.name)
            button.color = tes3ui.getPalette("disabled_color")
            button.widget.idle = tes3ui.getPalette("disabled_color")
        else 
            button.text = resourcePack.name
        end
        button:register("mouseClick", function()
            tes3.player.data[modName].selectedPack = resourcePack
            tes3.player.data[modName].selectedResource = tes3.player.data[modName].selectedPack.items[1]
            updateSelectedResourcePack()
        end)
    end

    local shardCount = menu:findChild(uiids.shardCount)
    shardCount.text = getShardText()

    menu:updateLayout()
    updateSelectedResourcePack()
end
event.register("SS20:UpdateShopMenu", updateShopMenu)



local function unlockPack()
    common.modSoulShards(-tes3.player.data[modName].selectedPack.cost)
    tes3.player.data[modName].unlockedResourcePacks[tes3.player.data[modName].selectedPack.id] = true
    updateShopMenu()
end


local function createTitle(block)
    local title = block:createLabel{ }
    title.text = shopConfig.title
    title.color = tes3ui.getPalette("header_color")

    local shardCount = block:createLabel{id = uiids.shardCount}
    shardCount:register("help", function()
        local tooltip = tes3ui.createTooltipMenu()
        tooltip:createLabel{ text = "Earn Soul Shards by killing enemies with the Bottle of Souls in your inventory."}
    end)
    shardCount.text = getShardText()
    return title
end

local function createButtons(block)
    local buttons = {
        {
            name = "Cancel",
            callback = closeMenu
        }
    }
    for _, buttonConf in ipairs(buttons) do
        local button = block:createButton()
        button.text = buttonConf.name
        button.borderLeft = 0
        button:register("mouseClick", buttonConf.callback)
    end
end


local function createTitleBlock(parent)
    local titleBlock = parent:createBlock{ id = uiids.titleBlock }
    titleBlock.flowDirection = "top_to_bottom"
    titleBlock.childAlignX = 0.5
    titleBlock.autoHeight = true
    titleBlock.widthProportional = 1.0
    titleBlock.borderBottom = 10
    createTitle(titleBlock)
end

local function createShopListPane(parent)
    local block = parent:createThinBorder{}
    block.flowDirection = "top_to_bottom"
    block.paddingAllSides = 10
    block.widthProportional = 0.6
    block.heightProportional = 1.0
    
    local resourceTitle = block:createLabel()
    resourceTitle.color = tes3ui.getPalette("header_color")
    resourceTitle.text = "Resource Packs:"

    local shopListScrollPane = block:createVerticalScrollPane({ id = uiids.shopListScrollPane})
    shopListScrollPane.borderTop = 4
    --shopListScrollPane.flowDirection = "top_to_bottom"
    shopListScrollPane.widthProportional = 1.0
    shopListScrollPane.heightProportional = 1.0


end

local function createResourceDescriptionPane(parent)
    local descriptionBlock = parent:createThinBorder{ ids = uiids.descriptionBlock}
    descriptionBlock.flowDirection = "top_to_bottom"
    descriptionBlock.paddingAllSides = 10
    descriptionBlock.widthProportional = 1.4
    descriptionBlock.heightProportional = 1.0

    local previewName = descriptionBlock:createLabel{ id = uiids.previewName }
    previewName.text = ""
    previewName.color = tes3ui.getPalette("header_color")
    
    local previewDescription = descriptionBlock:createLabel{ id = uiids.previewDescription }
    previewDescription.wrapText = true
    previewDescription.text = ""

    local listTitle = descriptionBlock:createLabel()
    listTitle.text = "Items:"
    listTitle.color = tes3ui.getPalette("header_color")

    local previewList = descriptionBlock:createVerticalScrollPane{ id  = uiids.previewList }
    previewList.borderTop = 4
    previewList.widthProportional = 1.0
    previewList.heightProportional = 1.0

    local buttonBlock = descriptionBlock:createBlock()
    buttonBlock.paddingTop = 5
    buttonBlock.autoHeight = true
    buttonBlock.widthProportional = 1.0
    buttonBlock.flowDirection = "left_to_right"


    local createItemButton = buttonBlock:createButton{ text = "Create item", id = uiids.createItemButton }
    --createItemButton.widget.idleDisabled = tes3ui.getPalette("color_disabled")
    createItemButton:register("mouseClick", buyItem)
    local unlockPackButton = buttonBlock:createButton{ text = "Unlock Pack", id = uiids.unlockPackButton }
    --unlockPackButton.widget.idleDisabled = tes3ui.getPalette("color_disabled")
    unlockPackButton:register("mouseClick", unlockPack)
    --if tes3.player.data[modName].unlockedResourcePacks[] then

    do
        local buttonsBlock = buttonBlock:createBlock{ id = uiids.buttonsBlock}
        buttonsBlock.autoHeight = true
        buttonsBlock.autoWidth = true
        buttonsBlock.childAlignX = 1.0
        buttonsBlock.absolutePosAlignX = 1
        buttonsBlock.absolutePosAlignY = 1.0
        createButtons(buttonsBlock)
    end
end

local function createPreviewPane(parent)
    local previewBorder = parent:createThinBorder{ id = uiids.previewBorder }
    --previewBorder.width = shopConfig.previewWidth
    previewBorder.flowDirection = "top_to_bottom"
    previewBorder.widthProportional= 1
    previewBorder.autoHeight = true
    previewBorder.childAlignX = 0.5
    --previewBorder.absolutePosAlignX = 0


    local nifPreviewBlock = previewBorder:createBlock{ id = uiids.nifPreviewBlock }
    --nifPreviewBlock.width = shopConfig.previewWidth
    nifPreviewBlock.width = shopConfig.previewWidth
    nifPreviewBlock.height = shopConfig.previewHeight

    common.log:debug("width: %s", shopConfig.menuWidth)
    nifPreviewBlock.childOffsetX = shopConfig.previewWidth/2
    nifPreviewBlock.childOffsetY = shopConfig.previewYOffset
    nifPreviewBlock.paddingAllSides = 2

    local selectedItemLabel = previewBorder:createLabel{ id = uiids.selectedItem }
    selectedItemLabel.autoWidth = true
    selectedItemLabel.autoHeight = true
    selectedItemLabel.text = ""
    selectedItemLabel.borderAllSides = 5
end

local function createShopMenu()
    local shopMenu = tes3ui.findMenu(uiids.shopMenu)
    if shopMenu then shopMenu:destroy() end
    shopMenu = tes3ui.createMenu{ id = uiids.shopMenu, fixedFrame = true }
   
   
    shopMenu.minWidth = shopConfig.menuWidth
    shopMenu.minHeight = shopConfig.menuHeight

    createTitleBlock(shopMenu)
    createPreviewPane(shopMenu)
    
    do --mid block
        local midBlock = shopMenu:createBlock{ id = uiids.midBlock }
        midBlock.widthProportional = 1.0
        midBlock.heightProportional = 1.0
        midBlock.flowDirection = "left_to_right"
        createShopListPane(midBlock)
        createResourceDescriptionPane(midBlock) 
    end


    tes3.player.data[modName].selectedPack = config.resourcePacks[1]
    tes3.player.data[modName].selectedResource = tes3.player.data[modName].selectedPack.items[1]

    updateShopMenu()
    updateSelectedResourcePack()

    shopMenu:updateLayout()
    tes3ui.enterMenuMode(uiids.shopMenu)
    event.register("enterFrame", rotateNif)
end

local function onSpellCast(e)
    if (
        e.source and e.source.id == config.manipulateSpellId 
        and common.isAllowedToManipulate() 
    ) then
        createShopMenu()
    end
end
event.register("spellCast", onSpellCast)
