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

local paused = false
local startingSimulationTimeScale = 1.0

local overlay = nil
local hintOverlay = nil
local savedCameraViewMode = nil

local hexDofShader = shaderUtils.ShaderWrapper:new("hexDoFProgrammable", {
    uDepth = 65.0,
    uAperture = 0.5
}, function(self) return DofEffects end)

local ROTATE_SPEED = 0.003
local ZOOM_STEP = 1.0
local MIN_DIST = 100.0
local MAX_DIST = 110.0
local DEFAULT_DIST = 105.0

local active = false
local target = nil
local scrollAccum = 0
local inspectKeyWasDown = false
local currentZoom = DEFAULT_DIST 

local function isAllowedType(object)
    if not object then return false end

    local t = object.type

    if     t == types.Weapon        then return true
    elseif t == types.Armor         then return true
    elseif t == types.Clothing      then return true
    elseif t == types.Book          then return true
    elseif t == types.Ingredient    then return true
    elseif t == types.Potion        then return true
    elseif t == types.Miscellaneous then return true
    elseif t == types.Apparatus     then return true
    elseif t == types.Lockpick      then return true
    elseif t == types.Probe         then return true
    elseif t == types.Repair        then return true
    elseif t == types.Light         then return true
    else
        return false
    end
end

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

local function createGenericWidget(obj)
    local rec = obj.type.record(obj)
    local objType = obj.type
    local config = OBJECT_WIDGET_CONFIG[objType] or OBJECT_WIDGET_CONFIG[types.Miscellaneous]

    local content = {}
    local _, iconPath = buildInfoText(obj)  

    if iconPath then
        content[#content + 1] = {
            type = ui.TYPE.Image,
            props = {
                position = util.vector2(10, 10),  
                size = util.vector2(64, 64),     
                resource = ui.texture({ path = iconPath }),
                color = util.color.rgb(1.0, 1.0, 1.0)  
            }
        }
        content[#content + 1] = {
            type = ui.TYPE.Text,
            props = { text = '', textSize = 8 }
        }
    end
    content[#content + 1] = {
        type = ui.TYPE.Text,
        props = {
            text = '[ ' .. config.title .. ' ]',
            textSize = 18,
            textColor = config.color,
        }
    }
    content[#content + 1] = {
        type = ui.TYPE.Text,
        props = {
            text = safeField(rec, 'name') or obj.recordId or 'Local materials',
            textSize = 16,
            textColor = util.color.rgb(1.0, 1.0, 1.0)
        }
    }

    local config = OBJECT_WIDGET_CONFIG[obj.type]
    if config then
		local finalDescription = nil
		if config.uniqueDescriptions and obj.recordId then
			finalDescription = config.uniqueDescriptions[obj.recordId]
		end
		local rawMaterial = safeField(rec, 'material')
		local material = normalizeMaterial(rawMaterial)
		local health = safeField(rec, 'health')
		local conditionState = getConditionState(health)
		if not finalDescription then
			if config.materialDescriptions and config.materialDescriptions[material] then
				finalDescription = config.materialDescriptions[material][conditionState]
			end
		end
		if not finalDescription then
			local objTypeName = typeName(obj)
			if obj.type == types.NPC or obj.type == types.Creature then
				finalDescription = {
					objTypeName .. '.'
				}
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
        if finalDescription then
            content[#content + 1] = {
                type = ui.TYPE.Text,
                props = { text = '', textSize = 8 }
            }
            for _, lineText in ipairs(finalDescription) do
                content[#content + 1] = {
                    type = ui.TYPE.Text,
                    props = {
						text = lineText,
						textSize = 14,
						textColor = util.color.rgb(0.7, 0.9, 0.7),
						wordWrap = true,
						autoSize = false,
						size = util.vector2(400, 15),
					}
                }
            end
            content[#content + 1] = {
                type = ui.TYPE.Text,
                props = { text = '', textSize = 8 }
            }
        end
    end
    local config = OBJECT_WIDGET_CONFIG[obj.type]
    if config and config.description then
        content[#content + 1] = {
            type = ui.TYPE.Text,
            props = { text = '', textSize = 8 }
        }
        if type(config.description) == 'table' then
            for _, lineText in ipairs(config.description) do
                content[#content + 1] = {
                    type = ui.TYPE.Text,
                    props = {
                        text = lineText,
                        textSize = 14,
                        textColor = util.color.rgb(0.7, 0.9, 0.7),
						wordWrap = true,
						autoSize = false,
						size = util.vector2(400, 15),
                    }
                }
            end
        else
            content[#content + 1] = {
                type = ui.TYPE.Text,
                props = {
                    text = config.description,
                    textSize = 14,
                    textColor = util.color.rgb(0.7, 0.9, 0.7),
					wordWrap = true,
					autoSize = false,
					size = util.vector2(400, 15),
                }
            }
        end
        content[#content + 1] = {
            type = ui.TYPE.Text,
            props = { text = '', textSize = 8 }
        }
    end
if config.showWeight then
    local weight = safeField(rec, 'weight')
    if weight then
        content[#content + 1] = {
            type = ui.TYPE.Text,
            props = {
                text = string.format('Weight: %.2f', weight),
                textSize = 14,
                textColor = util.color.rgb(0.9, 0.9, 0.7)
            }
        }
    end
end

if config.showValue then
    if objType ~= types.Container
        and objType ~= types.Activator
        and objType ~= types.NPC
        and objType ~= types.Creature then
        local value = safeField(rec, 'value')
        if value then
            content[#content + 1] = {
                type = ui.TYPE.Text,
                props = {
                    text = string.format('Value: %d gold', value),
                    textSize = 14,
            textColor = util.color.rgb(0.9, 0.9, 0.7)
                }
            }
        end
    end
end

if config.showDamage then
    local c1, c2 = safeField(rec, 'chopMinDamage'), safeField(rec, 'chopMaxDamage')
    local s1, s2 = safeField(rec, 'slashMinDamage'), safeField(rec, 'slashMaxDamage')
    local h1, h2 = safeField(rec, 'thrustMinDamage'), safeField(rec, 'thrustMaxDamage')

    if c1 and c2 then
        content[#content + 1] = {
            type = ui.TYPE.Text,
            props = {
                text = string.format('Chop: %d-%d', c1, c2),
                textSize = 14,
                textColor = util.color.rgb(0.9, 0.9, 0.7)
            }
        }
    end
    if s1 and s2 then
        content[#content + 1] = {
            type = ui.TYPE.Text,
            props = {
                text = string.format('Slash: %d-%d', s1, s2),
                textSize = 14,
                textColor = util.color.rgb(0.9, 0.9, 0.7)
            }
        }
    end
    if h1 and h2 then
        content[#content + 1] = {
            type = ui.TYPE.Text,
            props = {
                text = string.format('Thrust: %d-%d', h1, h2),
                textSize = 14,
                textColor = util.color.rgb(0.9, 0.9, 0.7)
            }
        }
    end
end

if config.showArmorRating then
    local ar = safeField(rec, 'baseArmor')
    if ar then
        content[#content + 1] = {
            type = ui.TYPE.Text,
            props = {
                text = string.format('Armor Rating: %d', ar),
                textSize = 14,
                textColor = util.color.rgb(0.9, 0.9, 0.7)
            }
        }
    end
end

if config.showCondition then
    local hp = safeField(rec, 'health')
    if hp then
        content[#content + 1] = {
            type = ui.TYPE.Text,
            props = {
                text = string.format('Condition: %d%%', hp),
                textSize = 14,
                textColor = util.color.rgb(0.9, 0.9, 0.7)
            }
        }
    end
end

if config.showSkill then
    local sk = safeField(rec, 'skill')
    if sk and sk ~= '' then
        content[#content + 1] = {
            type = ui.TYPE.Text,
            props = {
                text = 'Teaches: ' .. sk,
                textSize = 14,
                textColor = util.color.rgb(0.9, 0.9, 0.7)
            }
        }
    end
end

if config.showQuality then
    local q = safeField(rec, 'quality')
    if q then
        content[#content + 1] = {
            type = ui.TYPE.Text,
            props = {
                text = string.format('Quality: %.2f', q),
                textSize = 14,
                textColor = util.color.rgb(0.9, 0.9, 0.7)
            }
        }
    end
end

if config.showUses then
    local u = safeField(rec, 'maxCondition')
    if u then
        content[#content + 1] = {
            type = ui.TYPE.Text,
            props = {
                text = string.format('Uses: %d', u),
                textSize = 14,
                textColor = util.color.rgb(0.9, 0.9, 0.7)
            }
        }
    end
end

return ui.create {
    layer = 'HUD',
    type  = ui.TYPE.Image,
    props = {
        anchor = util.vector2(0.0, 0.0),  
        position = util.vector2(50, 50),       
        alpha = 0.8,
        resource = ui.texture({ path = 'White' }),
        color = util.color.rgb(1 / 255, 1 / 255, 1 / 255),
        size = util.vector2(415, 300),
        backgroundColor = util.color.rgba(0, 0, 0, 0.65),
    },
    content = ui.content({
        {
            type = ui.TYPE.Flex,
            props = {
                autoSize = true,
                vertical = true,
                size = util.vector2(410, 295),
                position = util.vector2(10, 10)
            },
            content = ui.content(content)
        }
    })
}
end

local function destroyUI()
    if overlay then
        overlay:destroy()
        overlay = nil
        print("[InspectIt] Overlay destroyed")
    end
    if hintOverlay then
        hintOverlay:destroy()
        hintOverlay = nil
        print("[InspectIt] Hint overlay destroyed")
    end
end

local function createUI(obj)
    if not active then return end 
	
	destroyUI()

    local objType = obj.type

    overlay = createGenericWidget(obj)

    hintOverlay = ui.create {
        layer = 'HUD',
        type  = ui.TYPE.Text,
        props = {
            relativePosition = util.vector2(0.5, 1.0),
            anchor           = util.vector2(0.5, 1.0),
            position         = util.vector2(0, -14),
            text             = 'Move mouse for vertical inspect     [LMB drag] Rotate     [Scroll] Zoom     [Configured Key / RMB] Exit',
            textSize         = 13,
            textColor        = util.color.rgb(0.6, 0.6, 0.6),
            autoSize         = true,
        },
    }
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

local function getPointedObject()
    local cameraPos = camera.getPosition()
    local iMaxActivateDist = core.getGMST("iMaxActivateDist") + 0.1
    local activationDistance = iMaxActivateDist + camera.getThirdPersonDistance()

    local telekinesis = types.Actor.activeEffects(self_):getEffect(core.magic.EFFECT_TYPE.Telekinesis)
    if telekinesis then
        activationDistance = activationDistance + (telekinesis.magnitude * 22)
    end

    activationDistance = activationDistance + 0.1

    local res = nearby.castRenderingRay(
        cameraPos,
        cameraPos + camera.viewportToWorldVector(util.vector2(0.5, 0.5)) * activationDistance,
        { ignore = self_ }
    )

    return res.hitObject
end

local function getRecordIdOfPointedItem()
    local cameraPos = camera.getPosition()
    local iMaxActivateDist = core.getGMST("iMaxActivateDist") + 0.1
    local activationDistance = iMaxActivateDist + camera.getThirdPersonDistance()

    local telekinesis = types.Actor.activeEffects(self_):getEffect(core.magic.EFFECT_TYPE.Telekinesis)
    if telekinesis then
        activationDistance = activationDistance + (telekinesis.magnitude * 22)
    end

    activationDistance = activationDistance + 0.1

    local res = nearby.castRenderingRay(
        cameraPos,
        cameraPos + camera.viewportToWorldVector(util.vector2(0.5, 0.5)) * activationDistance,
        { ignore = self_ }
    )

    if res.hitObject and isAllowedType(res.hitObject) then
        return res.hitObject.recordId, res.hitObject
    else
        return nil, nil
    end
end

local function beginInspect(recordId)
    if not recordId then
        return
    end

    active = true
	savedCameraViewMode = camera.getMode()
	camera.setMode(camera.MODE.FirstPerson)
    target = recordId

    disablePlayerControl()
    freezeTime()

    core.sendGlobalEvent('createObjectToPreview', { referenceId = recordId })

    local _, hitObject = getRecordIdOfPointedItem()
    if hitObject then
        createUI(hitObject)
    end
	hexDofShader:enable()
	print("[InspectIt] DOF enabled")  
end

local function endInspect()
	hexDofShader:disable()
	if not active then return end
	
    active = false
	destroyUI()
    target = nil
    currentZoom = DEFAULT_DIST
    if savedCameraViewMode then
        camera.setMode(savedCameraViewMode)
        savedCameraViewMode = nil  
    end
    restorePlayerControl()
    unfreezeTime()
    core.sendGlobalEvent('destroyObjectToPreview')
end

local function handleMouseInput()
    if not active then return end

    local mouseMoveX = input.getMouseMoveX()
    local mouseMoveY = input.getMouseMoveY()
    if input.isMouseButtonPressed(1) then
        core.sendGlobalEvent('rotatePreviewObject', {
            movePos = {
                x = mouseMoveX,
                y = mouseMoveY
            }
        })
    elseif not input.isMouseButtonPressed(1) and not input.isMouseButtonPressed(2) then
        core.sendGlobalEvent('translatePreviewObject', {
            movePos = {
                x = mouseMoveX,
                y = mouseMoveY
            }
        })
    end
end

local function onFrame(dt)
    local inspectKeyDown = input.getBooleanActionValue('DetailItemAction')
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
    if not active then return end

    scrollAccum = scrollAccum + delta

    if math.abs(scrollAccum) > 0.1 then
        local newZoom = currentZoom - (scrollAccum * ZOOM_STEP)

        newZoom = math.max(MIN_DIST, math.min(MAX_DIST, newZoom))

        if newZoom ~= currentZoom then
            core.sendGlobalEvent('zoomPreviewObject', { zoom = newZoom - currentZoom })
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
        InspectPreview_InspectDenied = function(data)
        end
    }
}
