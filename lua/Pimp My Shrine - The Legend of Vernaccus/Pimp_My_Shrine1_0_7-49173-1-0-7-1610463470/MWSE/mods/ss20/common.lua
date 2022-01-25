local this  = {}
this.config = require("ss20.config")
local modName = this.config.modName
this.mcmConfig = mwse.loadConfig(this.config.modName, this.config.mcmDefaultValues)
this.data = {}
 
local logLevel = this.mcmConfig.logLevel
mwse.log("loglevel")
local logger = require("ss20.logger")

this.log = logger.new{
    name = modName,
    --outputFile = "Ashfall.log",
    logLevel = logLevel
}

function this.keyPressed(keyEvent, expected)
    return (
        keyEvent.keyCode == expected.keyCode and
        not not keyEvent.isShiftDown == not not expected.isShiftDown and
        not not keyEvent.isControlDown == not not expected.isControlDown and
        not not keyEvent.isAltDown == not not expected.isAltDown
    )
end


function this.traverse(roots)
    local function iter(nodes)
        for _, node in ipairs(nodes or roots) do
            if node then
                coroutine.yield(node)
                if node.children then
                    iter(node.children)
                end
            end
        end
    end
    return coroutine.wrap(iter)
end

--Initialisation
local function initData()
    tes3.player.data[this.config.modName] = tes3.player.data[this.config.modName] or {}
    this.data = tes3.player.data[this.config.modName]
    this.data.unlockedResourcePacks = this.data.unlockedResourcePacks or {}
    this.log:debug("Shrine of Vernaccus Data Initialised")
end
event.register("loaded", initData)

local messageBoxId = tes3ui.registerID("CustomMessageBox_")
function this.messageBox(params)
    --[[
        button = 
    ]]--
    local header = params.header
    local message = params.message
    local buttons = params.buttons
    local sideBySide = params.sideBySide

    local menu = tes3ui.createMenu{ id = messageBoxId, fixedFrame = true }
    menu:getContentElement().childAlignX = 0.5
    tes3ui.enterMenuMode(messageBoxId)
    if header then
        local headerLabel = menu:createLabel{id = tes3ui.registerID("SS20:MessageBox_Title"), text = header}
        headerLabel.color = tes3ui.getPalette("header_color")
    end
    if message then
        local messageLabel = menu:createLabel{id = tes3ui.registerID("SS20:MessageBox_Title"), text = message}
        messageLabel.wrapText = true
    end
    local buttonsBlock = menu:createBlock()
    buttonsBlock.borderTop = 4
    buttonsBlock.autoHeight = true
    buttonsBlock.autoWidth = true
    if sideBySide then
        buttonsBlock.flowDirection = "left_to_right"
    else
        buttonsBlock.flowDirection = "top_to_bottom"
        buttonsBlock.childAlignX = 0.5
    end
    for i, data in ipairs(buttons) do
        local doAddButton = true
        if data.showRequirements then
            if data.showRequirements() ~= true then
                doAddButton = false
            end
        end
        if doAddButton then
            --If last button is a Cancel (no callback), register it for Right Click Menu Exit
            local buttonId = tes3ui.registerID("CustomMessageBox_Button")
            if data.doesCancel then
                buttonId = tes3ui.registerID("CustomMessageBox_CancelButton")
            end

            local button = buttonsBlock:createButton{ id = buttonId, text = data.text}

            local disabled = false
            if data.requirements then
                if data.requirements() ~= true then
                    disabled = true
                end
            end

            if disabled then
                button.widget.state = 2
            else
                button:register( "mouseClick", function()
                    if data.callback then
                        data.callback()
                    end
                    tes3ui.leaveMenuMode()
                    menu:destroy()
                end)
            end

            if not disabled and data.tooltip then
                button:register( "help", function()
                    this.createTooltip(data.tooltip)
                end)
            elseif disabled and data.tooltipDisabled then
                button:register( "help", function()
                    this.createTooltip(data.tooltipDisabled)
                end)
            end
        end
    end
end


--Generic Tooltip with header and description
function this.createTooltip(e)
    local thisHeader, thisLabel = e.header, e.text
    local tooltip = tes3ui.createTooltipMenu()
    
    local outerBlock = tooltip:createBlock({ id = tes3ui.registerID("Ashfall:temperatureIndicator_outerBlock") })
    outerBlock.flowDirection = "top_to_bottom"
    outerBlock.paddingTop = 6
    outerBlock.paddingBottom = 12
    outerBlock.paddingLeft = 6
    outerBlock.paddingRight = 6
    outerBlock.maxWidth = 300
    outerBlock.autoWidth = true
    outerBlock.autoHeight = true    
    
    if thisHeader then
        local headerText = thisHeader
        local headerLabel = outerBlock:createLabel({ id = tes3ui.registerID("Ashfall:temperatureIndicator_header"), text = headerText })
        headerLabel.autoHeight = true
        headerLabel.width = 285
        headerLabel.color = tes3ui.getPalette("header_color")
        headerLabel.wrapText = true
        --header.justifyText = "center"
    end
    if thisLabel then
        local descriptionText = thisLabel
        local descriptionLabel = outerBlock:createLabel({ id = tes3ui.registerID("Ashfall:temperatureIndicator_description"), text = descriptionText })
        descriptionLabel.autoHeight = true
        descriptionLabel.width = 285
        descriptionLabel.wrapText = true
    end
    
    tooltip:updateLayout()
end

function this.addTooltipMessage(tooltip, labelText, color)

    local function setupOuterBlock(e)
        e.flowDirection = 'left_to_right'
        e.paddingTop = 0
        e.paddingBottom = 2
        e.paddingLeft = 6
        e.paddingRight = 6
        e.autoWidth = 1.0
        e.autoHeight = true
        e.childAlignX = 0.5
    end

    --Get main block inside tooltip
    local partmenuID = tes3ui.registerID('PartHelpMenu_main')
    local mainBlock = tooltip:findChild(partmenuID):findChild(partmenuID):findChild(partmenuID)

    local outerBlock = mainBlock:createBlock()
    setupOuterBlock(outerBlock)

    local label = outerBlock:createLabel({text = labelText})
    label.autoHeight = true
    label.autoWidth = true
    if color then label.color = color end
    mainBlock:reorderChildren(1, -1, 1)
    mainBlock:updateLayout()
end

this.sortByName = function(a,b) return a.name < b.name; end
this.sortById = function(a,b) return a.id < b.id; end
function this.makeFilteredList(objectTypes, searchParam)


    local list = {}
    this.log:debug("searchParam: %s, objectTypes: %s", searchParam)
    for objectType, _ in ipairs(objectTypes) do
        for obj in tes3.iterateObjects(objectType) do
            if not searchParam or searchParam.len == 0 then
                table.insert(list, obj);
            elseif obj.id:lower():find(searchParam:lower()) then
                table.insert(list, obj);
            end
        end
    end
    table.sort(list, this.sortById);
    return list
end

local function isCollisionNode(node)
    return node:isInstanceOfType(tes3.niType.RootCollisionNode) 
end

function this.onLight(lightRef)
    if (not lightRef.object.mesh) or (string.len(lightRef.object.mesh) == 0) then
        return
    end
    lightRef:deleteDynamicLightAttachment()
    local newNode = tes3.loadMesh(lightRef.object.mesh):clone()
    --[[
        Remove existing children and reattach them from the base mesh,
        to restore light properties. Ignore collision node to avoid 
        crashes from collision detection. 
    ]]
    for i, childNode in ipairs(lightRef.sceneNode.children) do
        if childNode and not isCollisionNode(childNode) then
            lightRef.sceneNode:detachChildAt(i)
        end
    end
    for i, childNode in ipairs(newNode.children) do
        if childNode and not isCollisionNode(childNode) then
            lightRef.sceneNode:attachChild(newNode.children[i], true)
        end
    end
    local lightNode = niPointLight.new()
    lightNode.name = "LIGHTNODE"
    if lightRef.object.color then
        lightNode.ambient = tes3vector3.new(0,0,0)
        lightNode.diffuse = tes3vector3.new(
            lightRef.object.color[1] / 255,
            lightRef.object.color[2] / 255,
            lightRef.object.color[3] / 255
        )
    else
        lightNode.ambient = tes3vector3.new(0,0,0)
        lightNode.diffuse = tes3vector3.new(255, 255, 255)
    end
    lightNode:setAttenuationForRadius(lightRef.object.radius)
    --see if there's an attachlight node to work with
    local attachLight = lightRef.sceneNode:getObjectByName("attachLight")
    local windowsGlowAttach = lightRef.sceneNode:getObjectByName("NightDaySwitch")
    attachLight = attachLight or windowsGlowAttach or lightRef.sceneNode
    attachLight:attachChild(lightNode)

    lightRef.sceneNode:update()
    lightRef.sceneNode:updateNodeEffects()
    lightRef:getOrCreateAttachedDynamicLight(lightNode, 1.0)
    this.log:debug("onlight done")
end
function this.removeLight(lightNode) 

    for node in this.traverse{lightNode} do
        --Kill particles
        if node.RTTI.name == "NiBSParticleNode" then
            --node.appCulled = true
            node.parent:detachChild(node)
        end
        --Kill Melchior's Lantern glow effect
        if node.name == "Glow" then
            --node.appCulled = true
            node.parent:detachChild(node)
        end
        if node.name == "AttachLight" then
            --node.appCulled = true
            node.parent:detachChild(node)
        end
        
        -- Kill materialProperty 
        local materialProperty = node:getProperty(0x2)
        if materialProperty then
            if (materialProperty.emissive.r > 1e-5 or materialProperty.emissive.g > 1e-5 or materialProperty.emissive.b > 1e-5 or materialProperty.controller) then
                materialProperty = node:detachProperty(0x2):clone()
                node:attachProperty(materialProperty)
        
                -- Kill controllers
                materialProperty:removeAllControllers()
                
                -- Kill emissives
                local emissive = materialProperty.emissive
                emissive.r, emissive.g, emissive.b = 0,0,0
                materialProperty.emissive = emissive
        
                node:updateProperties()
            end
        end
     -- Kill glowmaps
        local texturingProperty = node:getProperty(0x4)
        local newTextureFilepath = "Textures\\tx_black_01.dds"
        if (texturingProperty and texturingProperty.maps[4]) then
        texturingProperty.maps[4].texture = niSourceTexture.createFromPath(newTextureFilepath)
        end
        if (texturingProperty and texturingProperty.maps[5]) then
            texturingProperty.maps[5].texture = niSourceTexture.createFromPath(newTextureFilepath)
        end 
    end
    lightNode:update()
    lightNode:updateNodeEffects()

end

function this.isShiftDown()
    local ic = tes3.worldController.inputController
	return ic:isKeyDown(tes3.scanCode.leftShift) or ic:isKeyDown(tes3.scanCode.rightShift)
end



function this.isAllowedToManipulate()
    local inShrine = tes3.player.cell.id == this.config.shrineTeleportPosition.cell
    local inBoudoir = tes3.player.cell.id == this.config.horavathaTeleportPosition.cell
    local finishedQuest = tes3.getJournalIndex{id = "ss20_CS"} >= 100
    local isInside = tes3.player.cell.isInterior

    local ss20_main_i = tes3.getJournalIndex({id="ss20_main"})
    local duringAttack = ss20_main_i >= 50 and ss20_main_i < 59

    --Always block when outside
    if not isInside then return false end
    --Block during final attack and statue is crumbled
    if duringAttack then return false end
    --ALlowed only in shrines unless quest is finished
    if finishedQuest or inShrine or inBoudoir then
        return true
    else
        return false
    end
end



function this.getRoomCost(room)
    local data = tes3.player.data[modName]
    local multiplier = data.roomsBuilt and (this.config.roomCostMulti * data.roomsBuilt) or 1
    local cost = room.cost * multiplier
    return cost
end


function this.getSoulShards()
    return tes3.player.object.inventory:contains("ss20_bottle_of_souls")
        and tes3.player.data[modName].soulShards or 0
end

function this.modSoulShards(count)
    this.log:debug("Modding soul shards! They are curently: %s", tes3.player.data[modName].soulShards )
    this.log:debug("Modding by %s", count)
    tes3.player.data[modName].soulShards = this.getSoulShards() + count
    this.log:debug("New value: %s", tes3.player.data[modName].soulShards )
end


mwse.log("Common done just fine")
return this