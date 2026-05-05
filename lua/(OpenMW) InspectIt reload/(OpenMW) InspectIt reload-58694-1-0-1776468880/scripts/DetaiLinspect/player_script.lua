local mp = "scripts/DetaiLinspect/"
local input = require('openmw.input')
local camera = require('openmw.camera')
local core = require('openmw.core')
local nearby = require('openmw.nearby')
local types = require('openmw.types')
local self_ = require('openmw.self')
local util = require('openmw.util')
local ui = require('openmw.ui')
local OBJECT_WIDGET_CONFIG = require('scripts.DetaiLinspect.object_widget_config')

local shaderUtils = require(mp .. "shader_utils")
local isInspecting = false
local paused = false
local startingSimulationTimeScale = 1.0
local overlay = nil
local hintOverlay = nil
local savedCameraViewMode = nil
local hexDofShader = shaderUtils.ShaderWrapper:new("hexDoFProgrammable", {
    uDepth = 65.0,
    uAperture = 0.5
}, function(self) return DofEffects end)

local ROTATE_SPEED = 0.5
local ZOOM_STEP = 1.0
local MIN_DIST = 7.0
local MAX_DIST = 20.0
local DEFAULT_DIST = 15.0
local active = false
local target = nil
local scrollAccum = 0
local inspectKeyWasDown = false
local currentZoom = DEFAULT_DIST
local activeInventoryInspect = false
local inventoryTarget = nil
local inventoryInspectKeyWasDown = false
local inventoryItems = {}  
local currentInventoryIndex = 1
local isSwitching = false  
local isNextSwitching = false
local isPrevSwitching = false
local nextOverlay = nil  
local NEXT_ITEM_OFFSET_X = 210 
local prevOverlay = nil  
local PREV_ITEM_OFFSET_X = -210  
local detailedOverlay = nil
local prevPrevOverlay = nil 
local nextNextOverlay = nil  
local PREV_PREV_OFFSET_X = -350  
local NEXT_NEXT_OFFSET_X = 350    

local function safeField(rec, field)
    if rec == nil then return nil end
    local ok, v = pcall(function() return rec[field] end)
    return ok and v or nil
end

local function typeName(obj)
    local t = obj.type
    if t == types.Weapon then return 'Weapon'
    elseif t == types.Armor then return 'Armor'
    elseif t == types.Clothing then return 'Clothing'
    elseif t == types.Book then return 'Book/Scroll'
    elseif t == types.Ingredient then return 'Ingredient'
    elseif t == types.Potion then return 'Potion'
    elseif t == types.Miscellaneous then return 'Misc. Item'
    elseif t == types.Apparatus then return 'Apparatus'
    elseif t == types.Lockpick then return 'Lockpick'
    elseif t == types.Probe then return 'Probe'
    elseif t == types.Repair then return 'Repair Item'
    elseif t == types.Light then return 'Light'
    else return 'Object'
    end
end

local function normalizeMaterial(material)
    if not material then return 'local materials' end
    local normalized = string.lower(material)
    normalized = string.gsub(normalized, '%s+armor', '')
    normalized = string.gsub(normalized, '%s+weapon', '')
    normalized = string.gsub(normalized, '%s+potion', '')
    normalized = string.gsub(normalized, '%s+container', '')
    normalized = string.gsub(normalized, '%s+vessel', '')
    normalized = string.gsub(normalized, '%s+cup', '')
    normalized = string.gsub(normalized, '%s+bowl', '')
    normalized = string.gsub(normalized, '%s+plate', '')
    normalized = string.gsub(normalized, '%s+dish', '')
    normalized = string.gsub(normalized, '%s+helmet', '')    
    normalized = string.gsub(normalized, '%s+cuirass', '')   
    normalized = string.gsub(normalized, '%s+gauntlets', '') 
    normalized = string.gsub(normalized, '%s+boots', '')     
    normalized = string.gsub(normalized, '%s+greaves', '')  
    normalized = string.gsub(normalized, '%s+plate', '')
    normalized = string.gsub(normalized, '%s+mail', '')
    normalized = string.gsub(normalized, '%s+banded', '')
    normalized = string.gsub(normalized, '%s+studded', '')
    normalized = string.gsub(normalized, '%s+scaled', '')
    normalized = string.gsub(normalized, '%s+thick', '')
    normalized = string.gsub(normalized, '%s+heavy', '')
    normalized = string.gsub(normalized, '%s+light', '')
    normalized = string.gsub(normalized, '%s+fine', '')
    normalized = string.gsub(normalized, '%s+ancient', '')
    normalized = string.gsub(normalized, '%s+ornate', '')
    normalized = string.gsub(normalized, 'dwemer', 'dwarven')
    normalized = string.gsub(normalized, 'chitin', 'chitinous')
    normalized = string.gsub(normalized, 'earthen', 'earthenware')
    normalized = string.gsub(normalized, 'stonen', 'stoneware')

    return string.trim(normalized)  
end

local function getConditionState(health)
    health = health or 100
    if health >= 80 then return 'conditionGood'
    elseif health >= 30 then return 'conditionBad'
    else return 'conditionBroken'
    end
end

local function buildInfoText(obj)
    local ok, rec = pcall(function() return obj.type.record(obj) end)
    if not ok then rec = nil end

    local lines = {}
    lines[#lines + 1] = '[ ' .. typeName(obj) .. ' ]'
    lines[#lines + 1] = safeField(rec, 'name') or obj.recordId or '?'
    local config = OBJECT_WIDGET_CONFIG[obj.type]
    if config then
        local finalDescription = nil
        if config.uniqueDescriptions and obj.recordId then
            finalDescription = config.uniqueDescriptions[obj.recordId]
        end

        if not finalDescription then
            local rawMaterial = safeField(rec, 'material')
            local material = normalizeMaterial(rawMaterial)
            local health = safeField(rec, 'health')
            local conditionState = getConditionState(health)

            if config.materialDescriptions and config.materialDescriptions[material] then
                finalDescription = config.materialDescriptions[material][conditionState]
            end
        end

		if not finalDescription then
			local objTypeName = typeName(obj)
			if obj.type == types.NPC or obj.type == types.Creature then
				finalDescription = { objTypeName .. '.' }
			else
				local rawMaterial = safeField(rec, 'material')
				local material = normalizeMaterial(rawMaterial)
				local health = safeField(rec, 'health')
				local conditionState = getConditionState(health)  

				finalDescription = {
					objTypeName .. ' made of ' .. (material or 'local materials') .. '.',
					'Condition: ' .. conditionState:gsub('condition', '')
				}
			end
		end


        lines[#lines + 1] = ''  
        for _, line in ipairs(finalDescription) do
            lines[#lines + 1] = line
        end
    end

    local w = safeField(rec, 'weight')
    local v = safeField(rec, 'value')
    if w then lines[#lines + 1] = string.format('Weight: %.2f', w) end
    if v then lines[#lines + 1] = string.format('Value: %d gold', v) end

    local t = obj.type
    if t == types.Weapon then
        local c1, c2 = safeField(rec,'chopMinDamage'),  safeField(rec,'chopMaxDamage')
        local s1, s2 = safeField(rec,'slashMinDamage'), safeField(rec,'slashMaxDamage')
        local h1, h2 = safeField(rec,'thrustMinDamage'),safeField(rec,'thrustMaxDamage')
        if c1 and c2 then lines[#lines + 1] = string.format('Chop: %d-%d', c1, c2) end
        if s1 and s2 then lines[#lines + 1] = string.format('Slash: %d-%d', s1, s2) end
        if h1 and h2 then lines[#lines + 1] = string.format('Thrust: %d-%d', h1, h2) end
    end

    local iconField = safeField(rec, 'icon')
    local iconPath = nil

    if iconField then
        iconPath = '' .. string.gsub(iconField, '\\', '/')
        iconPath = string.lower(iconPath)
    end


    return table.concat(lines, '\n'), iconPath
end

local function buildBriefInfoText(obj)
    local ok, rec = pcall(function() return obj.type.record(obj) end)
    if not ok then rec = nil end

    local lines = {}
    lines[#lines + 1] = '[ ' .. typeName(obj) .. ' ]'
    lines[#lines + 1] = safeField(rec, 'name') or obj.recordId or '?'

    local w = safeField(rec, 'weight')
    local v = safeField(rec, 'value')
    if w then lines[#lines + 1] = string.format('Weight: %.2f', w) end
    if v then lines[#lines + 1] = string.format('Value: %d gold', v) end

    local iconField = safeField(rec, 'icon')
    local iconPath = nil

    if iconField then
        iconPath = '' .. string.gsub(iconField, '\\', '/')
        iconPath = string.lower(iconPath)
    end

    return table.concat(lines, '\n'), iconPath
end

local function destroyUI()
    if overlay then
        overlay:destroy()
        overlay = nil
    end
    if nextOverlay then
        nextOverlay:destroy()
        nextOverlay = nil
    end
    if prevOverlay then
        prevOverlay:destroy()  
        prevOverlay = nil
    end
    if hintOverlay then
        hintOverlay:destroy()
        hintOverlay = nil
    end
    if detailedOverlay then
        detailedOverlay:destroy()
        detailedOverlay = nil
    end	
    if prevPrevOverlay then
        prevPrevOverlay:destroy()
        prevPrevOverlay = nil
    end
    if nextNextOverlay then
        nextNextOverlay:destroy()
        nextNextOverlay = nil
    end
end	

local function createDetailedDescriptionWidget(currentObj)
    if not currentObj then return end
    local detailedContent = ui.content({})
    local detailedText, iconPath = buildInfoText(currentObj)
    if iconPath then
        table.insert(detailedContent, {
            type = ui.TYPE.Image,
            props = {
                position = util.vector2(10, 10),
                size = util.vector2(64, 64),
                resource = ui.texture({ path = iconPath }),
                color = util.color.rgb(1.0, 1.0, 1.0)
            }
        })
    end

    local textPositionX = iconPath and 80 or 10
    table.insert(detailedContent, {
        type = ui.TYPE.Text,
        props = {
            text = detailedText,
            textSize = 14,
            textColor = util.color.rgb(0.9, 0.95, 0.8),
            wordWrap = true,
            autoSize = false,
            size = util.vector2(300, 190),
            position = util.vector2(textPositionX, 10)
        }
    })
    return ui.create {
        layer = 'HUD',
        type = ui.TYPE.Image,
        props = {
            relativePosition = util.vector2(0.05, 0.5), 
            anchor = util.vector2(0.05, 0.5),
            alpha = 0.8,
            resource = ui.texture({ path = 'White' }),
            color = util.color.rgb(30 / 255, 30 / 255, 30 / 255),
            size = util.vector2(400, 200),
            backgroundColor = util.color.rgba(0, 0, 0, 0.75),
        },
        content = detailedContent
    }
end

local function createUI(currentObj, prevObj, nextObj, prevPrevObj, nextNextObj)
    destroyUI()  

    local currentInfoText, currentIconPath = buildBriefInfoText(currentObj)
    local currentUIContent = ui.content({})

    if currentIconPath then
        table.insert(currentUIContent, {
            type = ui.TYPE.Image,
            props = {
                position = util.vector2(10, 10),
                size = util.vector2(64, 64),
                resource = ui.texture({ path = currentIconPath }),
                color = util.color.rgb(1.0, 1.0, 1.0)
            }
        })
    end

    local textPositionX = currentIconPath and 80 or 10
    table.insert(currentUIContent, {
        type = ui.TYPE.Text,
        props = {
            text = currentInfoText,
            textSize = 14,
            textColor = util.color.rgb(1.0, 0.88, 0.55),
            wordWrap = true,
            autoSize = false,
            size = util.vector2(110, 90),
            position = util.vector2(textPositionX, 10)
        }
    })

    overlay = ui.create {
        layer = 'HUD',
        type  = ui.TYPE.Image,
        props = {
            relativePosition = util.vector2(0.5, 0.15),
			anchor = util.vector2(0.5, 0.15),
            position = util.vector2(0, 0),
            alpha = 0.8,
            resource = ui.texture({ path = 'White' }),
            color = util.color.rgb(1 / 255, 1 / 255, 1 / 255),
            size = currentIconPath
                and util.vector2(200, 100)
                or util.vector2(130, 100),
            backgroundColor = util.color.rgba(0, 0, 0, 0.65),
        },
        content = currentUIContent
    }

    if prevObj then
        local prevInfoText, prevIconPath = buildBriefInfoText(prevObj)
        local prevUIContent = ui.content({})
        if prevIconPath then
            table.insert(prevUIContent, {
                type = ui.TYPE.Image,
                props = {
                    position = util.vector2(10, 10),
                    size = util.vector2(60, 60),
                    resource = ui.texture({ path = prevIconPath }),
                    color = util.color.rgb(0.7, 0.7, 0.7)  
                }
            })
        end
        local prevTextPositionX = prevIconPath and 80 or 10
        table.insert(prevUIContent, {
            type = ui.TYPE.Text,
            props = {
                text = prevInfoText,
                textSize = 12,  
                textColor = util.color.rgb(0.8, 0.8, 0.8),  
                wordWrap = true,
                autoSize = false,
                size = util.vector2(100, 90),
                position = util.vector2(prevTextPositionX, 10)
            }
        })
        prevOverlay = ui.create {
            layer = 'HUD',
            type  = ui.TYPE.Image,
            props = {
                relativePosition = util.vector2(0.5, 0.15),
				anchor = util.vector2(0.5, 0.15),
                position = util.vector2(-5 + PREV_ITEM_OFFSET_X, -20),  
                alpha = 0.5,
                resource = ui.texture({ path = 'White' }),
                color = util.color.rgb(1 / 255, 1 / 255, 1 / 255),
                size = prevIconPath
                    and util.vector2(190, 90)
                    or util.vector2(120, 90),
                backgroundColor = util.color.rgba(0, 0, 0, 0.5), 
            },
            content = prevUIContent
        }
    else
        prevOverlay = nil
    end
		if prevPrevObj then
			local prevPrevInfoText, prevPrevIconPath = buildBriefInfoText(prevPrevObj)
			local prevPrevUIContent = ui.content({})
			if prevPrevIconPath then
				table.insert(prevPrevUIContent, {
					type = ui.TYPE.Image,
					props = {
						position = util.vector2(10, 10),
						size = util.vector2(55, 55),
						resource = ui.texture({ path = prevPrevIconPath }),
						color = util.color.rgb(0.5, 0.5, 0.5)  
					}
				})
			end
			local prevPrevTextPositionX = prevPrevIconPath and 80 or 10
			table.insert(prevPrevUIContent, {
				type = ui.TYPE.Text,
				props = {
					text = prevPrevInfoText,
					textSize = 10,  
					textColor = util.color.rgb(0.6, 0.6, 0.6),  
					wordWrap = true,
					autoSize = false,
					size = util.vector2(95, 80),
					position = util.vector2(prevPrevTextPositionX, 10)
				}
			})
			prevPrevOverlay = ui.create {
				layer = 'HUD',
				type  = ui.TYPE.Image,
				props = {
					relativePosition = util.vector2(0.5, 0.15),
					anchor = util.vector2(0.5, 0.15),
					position = util.vector2(-20 + PREV_PREV_OFFSET_X, -110),  
					alpha = 0.3,  
					resource = ui.texture({ path = 'White' }),
					color = util.color.rgb(1 / 255, 1 / 255, 1 / 255),
					size = prevPrevIconPath
						and util.vector2(180, 80)
						or util.vector2(110, 80),
					backgroundColor = util.color.rgba(0, 0, 0, 0.3),  
				},
				content = prevPrevUIContent
			}
		else
			prevPrevOverlay = nil
		end
    if nextObj then
        local nextInfoText, nextIconPath = buildBriefInfoText(nextObj)
        local nextUIContent = ui.content({})
        if nextIconPath then
            table.insert(nextUIContent, {
                type = ui.TYPE.Image,
                props = {
                    position = util.vector2(10, 10),
                    size = util.vector2(64, 64),
                    resource = ui.texture({ path = nextIconPath }),
                    color = util.color.rgb(0.7, 0.7, 0.7)
                }
            })
        end
        local nextTextPositionX = nextIconPath and 80 or 10
        table.insert(nextUIContent, {
            type = ui.TYPE.Text,
            props = {
                text = nextInfoText,
                textSize = 12,
                textColor = util.color.rgb(0.8, 0.8, 0.8),
                wordWrap = true,
                autoSize = false,
                size = util.vector2(100, 90),
                position = util.vector2(nextTextPositionX, 10)
            }
        })
        nextOverlay = ui.create {
            layer = 'HUD',
            type  = ui.TYPE.Image,
            props = {
                relativePosition = util.vector2(0.5, 0.15),
				anchor = util.vector2(0.5, 0.15),
                position = util.vector2(5 + NEXT_ITEM_OFFSET_X, -20),
                alpha = 0.5,
                resource = ui.texture({ path = 'White' }),
                color = util.color.rgb(1 / 255, 1 / 255, 1 / 255),
                size = nextIconPath
                    and util.vector2(190, 90)
                    or util.vector2(120, 90),
                backgroundColor = util.color.rgba(0, 0, 0, 0.5),
            },
            content = nextUIContent
        }
    else
        nextOverlay = nil
    end
	if nextNextObj then
		local nextNextInfoText, nextNextIconPath = buildBriefInfoText(nextNextObj)
		local nextNextUIContent = ui.content({})
		if nextNextIconPath then
			table.insert(nextNextUIContent, {
				type = ui.TYPE.Image,
				props = {
					position = util.vector2(10, 10),
					size = util.vector2(55, 55),
					resource = ui.texture({ path = nextNextIconPath }),
					color = util.color.rgb(0.5, 0.5, 0.5)
				}
			})
		end
		local nextNextTextPositionX = nextNextIconPath and 80 or 10
		table.insert(nextNextUIContent, {
			type = ui.TYPE.Text,
			props = {
				text = nextNextInfoText,
				textSize = 10,
				textColor = util.color.rgb(0.6, 0.6, 0.6),
				wordWrap = true,
				autoSize = false,
				size = util.vector2(95, 80),
				position = util.vector2(nextNextTextPositionX, 10)
			}
		})
		nextNextOverlay = ui.create {
			layer = 'HUD',
			type  = ui.TYPE.Image,
			props = {
				relativePosition = util.vector2(0.5, 0.15),
				anchor = util.vector2(0.5, 0.15),
				position = util.vector2(20 + NEXT_NEXT_OFFSET_X, -110),  
				alpha = 0.3,
				resource = ui.texture({ path = 'White' }),
				color = util.color.rgb(1 / 255, 1 / 255, 1 / 255),
				size = nextNextIconPath
					and util.vector2(180, 80)
					or util.vector2(110, 80),
				backgroundColor = util.color.rgba(0, 0, 0, 0.3),
			},
			content = nextNextUIContent
		}
	else
		nextNextOverlay = nil
	end
    hintOverlay = ui.create {
        layer = 'HUD',
        type = ui.TYPE.Text,
        props = {
            relativePosition = util.vector2(0.5, 1.0),
            anchor = util.vector2(0.5, 1.0),
            position = util.vector2(0, -14),
            text = 'Move mouse for vertical and horizontal inspect     [LMB drag] Rotate     [Scroll] Zoom     [Configured Keys] Select item/Exit',
            textSize = 13,
            textColor = util.color.rgb(0.6, 0.6, 0.6),
            autoSize = true,
        },
    }
    detailedOverlay = createDetailedDescriptionWidget(currentObj)	
end

local function switchInventoryItem(direction)
    if not activeInventoryInspect or #inventoryItems == 0 then return end
    currentInventoryIndex = currentInventoryIndex + direction
    if currentInventoryIndex < 1 then
        currentInventoryIndex = #inventoryItems
    elseif currentInventoryIndex > #inventoryItems then
        currentInventoryIndex = 1
    end

    local currentItem = inventoryItems[currentInventoryIndex]
    local prevIndex = currentInventoryIndex - 1
    local nextIndex = currentInventoryIndex + 1
    local prevPrevIndex = currentInventoryIndex - 2
    local nextNextIndex = currentInventoryIndex + 2

    if prevIndex < 1 then prevIndex = #inventoryItems end
    if nextIndex > #inventoryItems then nextIndex = 1 end
    if prevPrevIndex < 1 then prevPrevIndex = #inventoryItems + prevPrevIndex end
    if nextNextIndex > #inventoryItems then nextNextIndex = nextNextIndex - #inventoryItems end

    local prevItem = inventoryItems[prevIndex]
    local nextItem = inventoryItems[nextIndex]
    local prevPrevItem = inventoryItems[prevPrevIndex]
    local nextNextItem = inventoryItems[nextNextIndex]

    core.sendGlobalEvent('destroyInventoryPreviewObject')
    core.sendGlobalEvent('createInventoryPreviewObject', {
        referenceId = currentItem.recordId
    })

    currentZoom = DEFAULT_DIST
    scrollAccum = 0

    destroyUI()
    createUI(currentItem, prevItem, nextItem, prevPrevItem, nextNextItem)
end

local function handleInventorySwitchInput()
    if not activeInventoryInspect then return end

    local nextKeyDown = input.getBooleanActionValue('InventoryInspectSelectNext')
    local prevKeyDown = input.getBooleanActionValue('InventoryInspectSelectPrev')

    if nextKeyDown then
        if not isNextSwitching then
            switchInventoryItem(1)
            isNextSwitching = true
        end
    else
        isNextSwitching = false
    end

    if prevKeyDown then
        if not isPrevSwitching then
            switchInventoryItem(-1)
            isPrevSwitching = true
        end
    else
        isPrevSwitching = false
    end
end

local function isInputAPIAvailable()
    return input and input.setActionEnabled and input.getActionEnabled
end

local function disablePlayerControl()
    types.Player.setControlSwitch(self_, types.Player.CONTROL_SWITCH.Controls, false)
    types.Player.setControlSwitch(self_, types.Player.CONTROL_SWITCH.Fighting, false)
    types.Player.setControlSwitch(self_, types.Player.CONTROL_SWITCH.Jumping, false)
    types.Player.setControlSwitch(self_, types.Player.CONTROL_SWITCH.Looking, false)
    types.Player.setControlSwitch(self_, types.Player.CONTROL_SWITCH.Magic, false)
    types.Player.setControlSwitch(self_, types.Player.CONTROL_SWITCH.VanityMode, false)
    types.Player.setControlSwitch(self_, types.Player.CONTROL_SWITCH.ViewMode, false)
end

local function restorePlayerControl()
    types.Player.setControlSwitch(self_, types.Player.CONTROL_SWITCH.Controls, true)
    types.Player.setControlSwitch(self_, types.Player.CONTROL_SWITCH.Fighting, true)
    types.Player.setControlSwitch(self_, types.Player.CONTROL_SWITCH.Jumping, true)
    types.Player.setControlSwitch(self_, types.Player.CONTROL_SWITCH.Looking, true)
    types.Player.setControlSwitch(self_, types.Player.CONTROL_SWITCH.Magic, true)
    types.Player.setControlSwitch(self_, types.Player.CONTROL_SWITCH.VanityMode, true)
    types.Player.setControlSwitch(self_, types.Player.CONTROL_SWITCH.ViewMode, true)
end

local function freezeTime()
    if paused then
        return
    end
    paused = true
    startingSimulationTimeScale = core.getSimulationTimeScale()
    local success = pcall(function()
        core.sendGlobalEvent('toggleSimulation', 0)
    end)
end

local function unfreezeTime()
    if not paused then
        return
    end
    paused = false
    local success = pcall(function()
        core.sendGlobalEvent('toggleSimulation', startingSimulationTimeScale)
    end)
end

local function isAllowedType(obj)
    if not obj then return false end

    local objType = obj.type
    if not objType then
        return false
    end

    if OBJECT_WIDGET_CONFIG[objType] then
        return true
    end

    return false
end

local function getInventoryItems()
    local inventory = types.Actor.inventory(self_)

    if not inventory then
        return {}
    end

    local items = nil

    if inventory.slots then
        items = inventory.slots
    end
	
    if not items and inventory.iterable then
        items = {}
        for item in inventory.iterable do
            table.insert(items, item)
        end
    end

    if not items then
        items = {}
        local allItems = inventory:getAll()
        for _, item in ipairs(allItems) do
            table.insert(items, { object = item })
        end
    end

    if not items or #items == 0 then
        return {}
    end

    local allowedItems = {}
    for i = 1, #items do
        local itemData = items[i]
        local obj = itemData.object or itemData
        if isAllowedType(obj) then
            table.insert(allowedItems, obj)
        end
    end

    return allowedItems
end

local function handleMouseInput()
    if not activeInventoryInspect then
        return
    end

    local mouseMoveX = input.getMouseMoveX() or 0
    local mouseMoveY = input.getMouseMoveY() or 0

    if math.abs(mouseMoveX) > 0.001 or math.abs(mouseMoveY) > 0.001 then
        local lmbPressed = input.isMouseButtonPressed(1)
        local mmbPressed = input.isMouseButtonPressed(2)
        local rmbPressed = input.isMouseButtonPressed(3)
        if lmbPressed then
            core.sendGlobalEvent('rotateInventoryPreviewObject', {
                movePos = {
                    x = mouseMoveX * ROTATE_SPEED,
                    y = mouseMoveY * ROTATE_SPEED
                }
            })
        elseif not (lmbPressed or mmbPressed or rmbPressed) then
            core.sendGlobalEvent('translateInventoryPreviewObject', {
                movePos = {
                    x = mouseMoveX,
                    y = mouseMoveY
                }
            })
        end
    end
end

local function beginInventoryInspect()
    if activeInventoryInspect then return end
    inventoryItems = getInventoryItems()

    if #inventoryItems == 0 then
        return
    end

    activeInventoryInspect = true
	savedCameraViewMode = camera.getMode()
	camera.setMode(camera.MODE.FirstPerson)
    currentInventoryIndex = 1  

    disablePlayerControl()
    freezeTime()

	local firstItem = inventoryItems[1]
	local prevPrevItem = inventoryItems[#inventoryItems - 1] or inventoryItems[#inventoryItems]  
	local prevItem = inventoryItems[#inventoryItems]                                         
	local nextItem = #inventoryItems > 1 and inventoryItems[2] or nil               
	local nextNextItem = #inventoryItems > 2 and inventoryItems[3] or nextItem     

    core.sendGlobalEvent('createInventoryPreviewObject', {
        referenceId = firstItem.recordId
    })
    currentZoom = DEFAULT_DIST
    scrollAccum = 0

    createUI(firstItem, prevItem, nextItem, prevPrevItem, nextNextItem)
    hexDofShader:enable()
end

local function endInventoryInspect()
    if not activeInventoryInspect then return end
    activeInventoryInspect = false
    inventoryTarget = nil
    inventoryItems = {}  
    currentInventoryIndex = 1
    if savedCameraViewMode then
        camera.setMode(savedCameraViewMode)
        savedCameraViewMode = nil  
    end
    restorePlayerControl()
    unfreezeTime()
    core.sendGlobalEvent('destroyInventoryPreviewObject')
    destroyUI()  
    hexDofShader:disable()
    currentZoom = DEFAULT_DIST
    scrollAccum = 0
end

local function handleInventoryInspectInput()
    local keyDown = input.getBooleanActionValue('InventoryInspectAction')
    if keyDown and not inventoryInspectKeyWasDown then
        if activeInventoryInspect then
            endInventoryInspect()
        else
            beginInventoryInspect()
        end
    end
    inventoryInspectKeyWasDown = keyDown
end

local function getRecordIdOfPointedItem()
    return nil, nil
end

local function beginInspect(recordId)
    active = true
	savedCameraViewMode = camera.getMode()
	camera.setMode(camera.MODE.FirstPerson)
    target = recordId
    disablePlayerControl()
    freezeTime()
    core.sendGlobalEvent('createWorldPreviewObject', { referenceId = recordId })
    createUI(nil)  
    hexDofShader:enable()
end

local function endInspect()
    if not active then return end
    active = false
    target = nil
    if savedCameraViewMode then
        camera.setMode(savedCameraViewMode)
        savedCameraViewMode = nil  
    end
    restorePlayerControl()
    unfreezeTime()
    core.sendGlobalEvent('destroyWorldPreviewObject')
    destroyUI()
    hexDofShader:disable()
end

local function onFrame(dt)
    handleInventoryInspectInput()
    handleInventorySwitchInput()  
    local inspectKeyDown = input.getBooleanActionValue('InventoryInspectAction')
    if inspectKeyDown and not inspectKeyWasDown then
        if active then
            endInspect()
        else
            local recordId, hitObject = getRecordIdOfPointedItem()
            if recordId then
                beginInspect(recordId)
            end
        end
    end
    inspectKeyWasDown = inspectKeyDown
    handleMouseInput()
end

local function onMouseWheel(delta)
    if not activeInventoryInspect then
        return
    end
    scrollAccum = scrollAccum + delta
    if math.abs(scrollAccum) > 0.05 then
        local newZoom = currentZoom - (scrollAccum * ZOOM_STEP)
        newZoom = math.max(MIN_DIST, math.min(MAX_DIST, newZoom))
        if newZoom ~= currentZoom then
            core.sendGlobalEvent('zoomInventoryPreviewObject', { zoom = newZoom - currentZoom })
            currentZoom = newZoom
        end
        scrollAccum = 0
    end
end

function onUnload()
    destroyUI()  
    unfreezeTime()
end

return {
    engineHandlers = {
        onFrame = onFrame,
        onMouseWheel = onMouseWheel
    },
    eventHandlers = {
        InspectPreview_InspectConfirmed = function(data)
            if data and data.recordId then
                beginInspect(data.recordId)
            end
        end,
        InspectPreview_InspectDenied = function(data) end
    }
}