types = require('openmw.types')
NPC = require('openmw.types').NPC
core = require('openmw.core')
storage = require('openmw.storage')
MODNAME = "OwnlysQuickLoot"
playerSettings = storage.playerSection('SettingsPlayer'..MODNAME)
I = require("openmw.interfaces")
self = require("openmw.self")
nearby = require('openmw.nearby')
camera = require('openmw.camera')
Camera = require('openmw.interfaces').Camera
util = require('openmw.util')
ui = require('openmw.ui')
auxUi = require('openmw_aux.ui')
async = require('openmw.async')
vfs = require('openmw.vfs')
KEY = require('openmw.input').KEY
input = require('openmw.input')
v2 = util.vector2
v3 = util.vector3
local Controls = require('openmw.interfaces').Controls
local makeBorder = require("scripts.OwnlysQuickLoot.ql_makeborder")
local settings = require("scripts.OwnlysQuickLoot.ql_settings")
local helpers = require("scripts.OwnlysQuickLoot.ql_helpers")
readFont, texText, rgbToHsv, hsvToRgb,fromutf8,toutf8 = unpack(helpers)
glyphs,lineHeight = readFont("textures\\fonts\\Asul.fnt")
lineXOffset = 0.0
TEXT_OFFSET = 0
local background = ui.texture { path = 'black' }
valueTex = ui.texture { path = 'textures\\QuickLoot_coins.dds' }
valueByWeightTex = ui.texture { path = 'textures\\QuickLoot_scale.dds' }
weightTex = ui.texture { path = 'textures\\QuickLoot_weight.dds' }
local fKeyTex = ui.texture { path = 'textures\\QuickLoot_F.dds' }
local rKeyTex = ui.texture { path = 'textures\\QuickLoot_R.dds' }
local inspectedContainer = nil
local resources = types.Actor.stats.dynamic
TAKEALL_KEYBINDING = KEY.F
local selectedIndex = 1
local lastItemCount = 99999999
local uiLoc = v2(0.75,0.5)
local uiSize = v2(0.25,0.4)
local textureCache = {}








local function getTexture(path)
	if not textureCache[path] then
		textureCache[path] = ui.texture{path = path}
	end
	
	return textureCache[path]
end
for a,b in pairs(input.triggers) do
print(a,b)
end
input.registerTriggerHandler("ToggleSpell", async:callback(function(dt, use, sneak, run)
      -- while sneaking, only activate things while holding the run binding
      --print(dtff)
	  return false
end))
input.registerTriggerHandler("ToggleWeapon", async:callback(function(dt, use, sneak, run)
      -- while sneaking, only activate things while holding the run binding
      --print(dt)
	  return false
end)) 


function drawUI()
	local uiSize = uiSize
	borderFile = "thin"
	if playerSettings:get("BORDER_STYLE") == "verythick" or playerSettings:get("BORDER_STYLE") == "thick" then
		borderFile = "thick"
	end
	borderOffset = playerSettings:get("BORDER_STYLE") == "verythick" and 4 or playerSettings:get("BORDER_STYLE") == "thick" and 3 or playerSettings:get("BORDER_STYLE") == "normal" and 2 or (playerSettings:get("BORDER_STYLE") == "thin" or playerSettings:get("BORDER_STYLE") == "max performance") and 1 or 0
	borderTemplate =  makeBorder(borderFile, borderColor or nil, borderOffset).borders
	if hud then 
		hud:destroy()
	end
	local localizedName = inspectedContainer.type.records[inspectedContainer.recordId].name
	
	print(111)
	hud = ui.create({	--root
		type = ui.TYPE.Widget,
		layer = 'HUD',
		props = {
			--position = playerSettings:get("POSITION") == "Bottom Left" and v2(94,-startOffset) or v2(startOffset,startOffset),
			--size = v2(0.2,0.2),
			anchor = v2(0.5,0.5), --playerSettings:get("POSITION") == "Bottom Left" and v2(0,1) or v2(0,0),
			relativePosition = uiLoc, --playerSettings:get("POSITION") == "Bottom Left" and v2(0,1) or v2(0,0),
			relativeSize =  uiSize,
		},
		content = ui.content {
			--{ --background
			--	type = ui.TYPE.Image,
			--	props = {
			--		resource = background,
			--		tileH = false,
			--		tileV = false,
			--		relativeSize  = v2(1,1),
			--		relativePosition = v2(0,0),
			--		--position = v2(1,1),
			--		--size = v2(-2,-2),
			--		alpha = 0.3,
			--	}
			--}
		}
	})
	local screenAspectRatio = ui.screenSize()
	print (screenAspectRatio)
	screenAspectRatio = screenAspectRatio.x/screenAspectRatio.y
	print(screenAspectRatio)
	uiSize= v2(uiSize.x*screenAspectRatio, uiSize.y)
	print(uiSize)
	local headerFooterMargin = 0.01
	local headerFooterHeight = 0.06
	
	--Header
	table.insert(hud.layout.content,{
		name = 'text',
		type = ui.TYPE.Text,
		props = {
			text = localizedName,
			textColor = util.color.rgba(1, 1, 1, 0.85),
			textShadow = true,
			anchor = v2(0, 0.5),
			textSize = 35,
			textShadowColor = util.color.rgba(0,0,0,0.75),
			position = v2(0, 0),
			relativeSize  = v2(1,headerFooterHeight),
			relativePosition = v2(0.01, 0),
			--position = NAME.position,
			--visible = c.textVisible and  playerLevel>=level + playerSettings:get("REQUIRED_HP"),
			anchor = v2(0,0),
			
		}
	})
	--table.insert(hud.layout.content,{ -- r.1.7
	--	type = ui.TYPE.Widget,
	--	props = {
	--		position = v2(0, 0),
	--		relativeSize  = v2(1,headerFooterHeight),
	--		relativePosition = v2(0.01, 0),
	--		--position = NAME.position,
	--		--visible = c.textVisible and  playerLevel>=level + playerSettings:get("REQUIRED_HP"),
	--		anchor = v2(0,0),
	--	},
	--	content = ui.content (texText({align = "right",currentHealth = localizedName,widgetWidth=uiSize.x,widgetHeight = uiSize.y*headerFooterHeight, color = nameColor, size = 1}))
	--})
	
	--Footer
	table.insert(hud.layout.content,{ -- r.1.7
		type = ui.TYPE.Widget,
		props = {
			position = v2(0, 0),
			relativeSize  = v2(1,headerFooterHeight),
			relativePosition = v2(0.55,1-headerFooterHeight),
			--position = NAME.position,
			--visible = c.textVisible and  playerLevel>=level + playerSettings:get("REQUIRED_HP"),
			anchor = v2(0,0),
		},
		content = ui.content (texText({align = "right",currentHealth = "[F] TakeAll",widgetWidth=uiSize.x,widgetHeight = uiSize.y*headerFooterHeight, color = nameColor, size = 0.65}))
	})
	table.insert(hud.layout.content,{ -- r.1.7
		type = ui.TYPE.Widget,
		props = {
			position = v2(0, 0),
			relativeSize  = v2(1,headerFooterHeight),
			relativePosition = v2(0.45,1-headerFooterHeight),
			--position = NAME.position,
			--visible = c.textVisible and  playerLevel>=level + playerSettings:get("REQUIRED_HP"),
			anchor = v2(1,0),
		},
		content = ui.content (texText({align = "left",currentHealth = "[R] Search",widgetWidth=uiSize.x,widgetHeight = uiSize.y*headerFooterHeight, color = nameColor, size = 0.65}))
	})
	
	
	local itemHud = { -- r.1.7
		type = ui.TYPE.Widget,
		props = {
			relativeSize  = v2(1,1-2*(headerFooterHeight+headerFooterMargin)),
			relativePosition = v2(0,headerFooterHeight+headerFooterMargin),
			--position = NAME.position,
			--visible = c.textVisible and  playerLevel>=level + playerSettings:get("REQUIRED_HP"),
			anchor = v2(0,0),
		},
		content = ui.content {}
	}
	table.insert(hud.layout.content, itemHud)
	table.insert(itemHud.content, {
		type = ui.TYPE.Image,
		props = {
			resource = background,
			tileH = false,
			tileV = false,
			relativeSize  = v2(1,1),
			relativePosition = v2(0,0),
			--position = v2(1,1),
			--size = v2(-2,-2),
			alpha = 0.3,
		}
	})
	table.insert(itemHud.content, { -- Border
		template = borderTemplate,
		props = {
			relativeSize  = v2(1,1),
			relativePosition = v2(0,0),
			alpha = 0.5,
			--relativePosition= v2(0,0),
		}
	})
	local relativePosition = 0.01
	local lineHeight = 0.06
	local margin = 0.01
	local entryWidth = 0.7--1-(1.5*lineHeight + 0.01)
	local boxDimensions = v2(uiSize.x,uiSize.y*(1-2*(headerFooterHeight+headerFooterMargin)))
	local textDimensions = v2(uiSize.x*entryWidth,uiSize.y*(1-2*(headerFooterHeight+headerFooterMargin)))
	local aspectRatio = boxDimensions.x/boxDimensions.y 
	local itemNameX = lineHeight/aspectRatio + 0.02
	local widgets = {"valueByWeight","value","weight"} --inverse sorting
	
	local itemBoxHeaderFooterScale = 1.3333
	if #widgets > 1 then
		---[[
		--TopLine
		table.insert(itemHud.content,
		{
			type = ui.TYPE.Image,
			props = {
				resource = getTexture("textures/menu_thin_border_bottom.dds"),
				tileH = false,
				tileV = false,
				relativeSize  = v2(1,0),
				size = v2(-borderOffset*2,1),
				position = v2(borderOffset,0),
				relativePosition = v2(0, lineHeight*itemBoxHeaderFooterScale),
				alpha = 0.4,
			}
		})
		--BottomLine
		table.insert(itemHud.content,
		{
			type = ui.TYPE.Image,
			props = {
				resource = getTexture("textures/menu_thin_border_bottom.dds"),
				tileH = false,
				tileV = false,
				relativeSize  = v2(1,0),
				size = v2(-borderOffset*2,1),
				position = v2(borderOffset,0),
				relativePosition = v2(0, 1-lineHeight*itemBoxHeaderFooterScale),
				alpha = 0.4,
			}
		})
		--]]
		--TopBackground
		table.insert(itemHud.content,
		{
			type = ui.TYPE.Image,
			props = {
				resource = background,
				tileH = false,
				tileV = false,
				relativeSize  = v2(1,lineHeight*itemBoxHeaderFooterScale),
				size = v2(-borderOffset*2,0),
				position = v2(borderOffset,0),
				relativePosition = v2(0, 0),
				alpha = 0.4,
			}
		})
		--BottomBackground
		table.insert(itemHud.content,
		{
			type = ui.TYPE.Image,
			props = {
				resource = background,
				tileH = false,
				tileV = false,
				relativeSize  = v2(1,lineHeight*itemBoxHeaderFooterScale),
				size = v2(-borderOffset*2,0),
				position = v2(borderOffset,0),
				relativePosition = v2(0, 1-lineHeight*itemBoxHeaderFooterScale),
				alpha = 0.4,
			}
		})
		relativePosition = relativePosition + lineHeight*itemBoxHeaderFooterScale+margin
		local widgetOffset = 0.05 --scrollbar
		for _, widget in pairs(widgets) do
			print(widget)
			table.insert(itemHud.content,{
				type = ui.TYPE.Image,
				props = {
					resource = _G[widget.."Tex"],
					tileH = false,
					tileV = false,
					relativeSize  = v2(0.9*lineHeight*itemBoxHeaderFooterScale/aspectRatio,0.9*lineHeight*itemBoxHeaderFooterScale),
					relativePosition = v2(1-widgetOffset, lineHeight*itemBoxHeaderFooterScale),
					anchor = v2(1,1),
					alpha = 0.6,
				}
			})
			widgetOffset =widgetOffset+ lineHeight*itemBoxHeaderFooterScale*1.1
		end
	end
	--{
	--	type = ui.TYPE.Widget,
	--	props = {
	--		--position = v2(0, 0),
	--		relativeSize  = v2(1,0),
	--		size = v2(-borderOffset*2,1),
	--		position = v2(borderOffset,0),
	--		relativePosition = v2(0, lineHeight),
	--		--position = NAME.position,
	--		--visible = c.textVisible and  playerLevel>=level + playerSettings:get("REQUIRED_HP"),
	--		anchor = v2(0,0),
	--	},
	--	content = ui.content {
	--		--{ -- Border
	--		--	template = borderTemplate,
	--		--	props = {
	--		--		relativeSize  = v2(1,1),
	--		--		relativePosition = v2(0,0),
	--		--		alpha = 0.5,
	--		--		--relativePosition= v2(0,0),
	--		--	}
	--		--}
	--		
	--		
	--	}textures/menu_%s_border_%s.dds
	--	
	--})
	
	for _, thing in pairs(types.Container.inventory(inspectedContainer):getAll()) do
		local thingRecord = thing.type.records[thing.recordId]
		if not thingRecord then
			ui.showMessage("ERROR: no record for "..thing.id.." (please report this bug)")
		else
			local thingName =  thingRecord.name or thing.id
			thingName= fromutf8(thingName)
			print(thingName)
			local icon = thingRecord.icon
			local thingCount = thing.count or 1
			local countText = thingCount > 1 and " ("..thing.count..")" or ""
			if icon then
				local ench = thing and (thing.enchant or thingRecord.enchant ~= "" and thingRecord.enchant )
				if ench then
					print("ench")
					table.insert(itemHud.content, {
						type = ui.TYPE.Image,
						props = {
							resource = getTexture("textures\\menu_icon_magic_mini.dds"),
							tileH = false,
							tileV = false,
							relativeSize  = v2(lineHeight/aspectRatio,lineHeight),
							relativePosition = v2(0.01,relativePosition),
							--position = v2(1,1),
							--size = v2(-2,-2),
							alpha = 0.7,
						}
					})			
				end
				table.insert(itemHud.content, {
					type = ui.TYPE.Image,
					props = {
						resource = getTexture(icon),
						tileH = false,
						tileV = false,
						relativeSize  = v2(lineHeight/aspectRatio,lineHeight),
						relativePosition = v2(0.01,relativePosition),
						--position = v2(1,1),
						--size = v2(-2,-2),
						alpha = 0.7,
					}
				})
			end
			table.insert(itemHud.content, 
			{ -- r.1.7
				type = ui.TYPE.Widget,
				props = {
					--position = v2(0, 0),
					relativeSize  = v2(entryWidth,lineHeight),
					relativePosition = v2(itemNameX, relativePosition),
					--position = NAME.position,
					--visible = c.textVisible and  playerLevel>=level + playerSettings:get("REQUIRED_HP"),
					anchor = v2(0,0),
				},
				content = ui.content (texText({align = "right",currentHealth = thingName..countText,widgetWidth=boxDimensions.x, widgetHeight = boxDimensions.y*lineHeight, color = nameColor, size = 1}))
			})
			local widgetOffset = 0.05 --scrollbar
			--thingCount
			local thingValue = thingRecord.value
			local thingWeight = thingRecord.weight
			for _, widget in pairs(widgets) do
				local text = ""..math.floor(thingValue*10)/10
				if widget == "valueByWeight" then
					text = ""..(math.floor(thingValue/thingWeight*10)/10)
				elseif widget == "weight" then
					text = ""..math.floor(thingWeight*10)/10
				end
				print(widget)
				local tempSize = v2(1.1*lineHeight*itemBoxHeaderFooterScale,lineHeight)
				table.insert(itemHud.content, 
				{ -- r.1.7
					type = ui.TYPE.Widget,
					props = {
						--position = v2(0, 0),
						relativeSize  = tempSize,
						relativePosition = v2(1-widgetOffset, relativePosition+lineHeight),
						anchor = v2(1,1),
						--alpha = 0.4,
					},
					content = ui.content (texText({align = "left",currentHealth =text,widgetWidth=boxDimensions.x*tempSize.x, widgetHeight = boxDimensions.y*tempSize.y, color = nameColor, size = 1}))
				})
				widgetOffset =widgetOffset+ lineHeight*1.1*itemBoxHeaderFooterScale
			end
			
			
			relativePosition = relativePosition + lineHeight+margin
		end
		
	end
	hud:update()
	
	
	
	do return end
	for _,resource in pairs(widgets) do

		table.insert(container.layout.content, ui.create({ --r.1
				type = ui.TYPE.Widget,
				props = {
					size = v2(0,0),
					anchor = v2(0,1),
					relativePosition = v2(0,1),
					relativeSize = v2(1,0),
					position = v2(0,-pos),
					},
				content = ui.content {
					ui.create({ --r.1
						type = ui.TYPE.Widget,
						props = {
							relativeSize  = v2(0,1),
							size = v2(max*LENGTH_MULT,0),
						},
						content = ui.content ({
							{
								type = ui.TYPE.Image,
								props = {
									resource = background,
									tileH = false,
									tileV = false,
									relativeSize  = v2(1,1),
									alpha = 0.5,
								},
							},
							playerSettings:get("BORDER_STYLE")~="none" and 
							{ -- Border
								template = borderTemplate,
								props = {
									relativeSize  = v2(1,1),
									alpha = 0.5,
								}
							} or {},
						})
					}),
					ui.create({ --r.2
						type = ui.TYPE.Widget,
						props = {
							relativeSize  = v2(1,1)
						},
						content = ui.content ({
							playerSettings:get("LAGBAR") and { -- Damage Bar r.2.lag
								name = "lag",
								type = ui.TYPE.Image,
								props = {
									resource = foreground,
									--relativePosition= v2(0,0.5),
									tileH = true,
									tileV = false,
									color =  playerSettings:get(resource:upper().."LAG_COL"),
									position = v2(borderOffset,borderOffset),
									--size = v2(-2,-3),
									size = v2(current*LENGTH_MULT-borderOffset*2,-borderOffset*2),
									relativeSize  = v2(0,1),
									alpha = 0.85,
								}
							} or {},
							{ -- HP Bar r.2.main
								name = "main",
								type = ui.TYPE.Image,
								props = {
									resource = foreground,
									tileH = false,
									tileV = false,
									color =  playerSettings:get(resource:upper().."_COL"),
									--position = v2(1, 1),
									position = v2(borderOffset,borderOffset),
									size = v2(math.min(max,current)*LENGTH_MULT-borderOffset*2,-borderOffset*2),
									relativeSize  = v2(0,1),
								},
							},
							resource == "health" and playerSettings:get("HEALBAR") and { -- Healing r.2.healing
								name = "healing",
								type = ui.TYPE.Image,
								props = {
									resource = foreground,
									tileH = true,
									tileV = false,
									color =  playerSettings:get("HEALING_COL"),
									alpha = 0.45,
									size = v2(0,0),
									position = v2(-borderOffset,0),
									relativeSize  = v2(0,1),
								}
							} or {},
							playerSettings:get("TEXT") ~= "hidden" and {
								name = 'text',
								type = ui.TYPE.Text,
								props = {
									text = playerSettings:get("TEXT") == "current" and ""..math.floor(current) or math.floor(current).."/".. math.floor(max),
									textColor = util.color.rgba(1, 1, 1, 0.85),
									position = v2(2, -math.floor(barThickness/12)),
									textShadow = true,
									anchor = v2(0, 0.5),
									relativePosition = v2(0, 0.5),
									textSize = barThickness+math.floor(barThickness/6),
									textShadowColor = util.color.rgba(0,0,0,0.75)
								}
							} or {},
						})
					}),
					playerSettings:get(resource:upper().."_FLASHING_THRESHOLD") >0 and ui.create{ -- r.3
						type = ui.TYPE.Image,
						props = {
							resource = flashing,
							tileH = false,
							tileV = false,
							color =  playerSettings:get(resource:upper().."LAG_COL"),
							--position = v2(1, 1),
							--position = v2(borderOffset,borderOffset),
							--size = v2(math.min(max,current)*LENGTH_MULT-borderOffset*2,-borderOffset*2),
							relativeSize  = v2(0,1),
							size = v2(max*LENGTH_MULT,0),
							alpha = 0,
						},
					} or {},
				}
			})
		)
		
		pos = pos+verticalOffset
		_G[resource] = { -- magicka, fatigue, health =
			bar = container.layout.content[#container.layout.content].layout.content,
			max = max*LENGTH_MULT,
			current = current,
			cached = current,
			paused = current,
			lag = current,
			lagCached = current,
			timer = 0,
			lerp = current,
			LENGTH_MULT = LENGTH_MULT,
			flashing = false
		}
		if playerSettings:get("TEXT_POS") == "right" then
			_G[resource].bar[2].layout.content["text"].props.position = v2(math.floor(max*LENGTH_MULT)-2,0)
			_G[resource].bar[2].layout.content["text"].props.anchor = v2(1,0.5)
		elseif playerSettings:get("TEXT_POS") == "right outside" then
			_G[resource].bar[2].layout.content["text"].props.position = v2(math.floor(max*LENGTH_MULT)+2,0)
			
		end
	end
	
end



local animation = require('openmw.animation')
function onFrame(dt)
--I.UI.setMode()
	local camera = require('openmw.camera')
	local cameraPos = camera.getPosition()
	local rayDistance = core.getGMST("iMaxActivateDist")+0.1
	local res = nearby.castRenderingRay(cameraPos, cameraPos+camera.viewportToWorldVector(v2(0.5,0.5)):emul(v3(rayDistance,rayDistance,rayDistance)))
	--print(res.hitObject)
	--print(animation.hasGroup(res.hitObject, "ContainerOpen Start"))
	--I.UI.addMode('Container', {target = res.hitObject})
	if inspectedContainer and (res.hitObject == nil or res.hitObject ~= inspectedContainer) then
		inspectedContainer:sendEvent("OwnlysQuickLoot_closeAnimation",self)
		inspectedContainer = nil
		Controls.overrideCombatControls(false)
		Camera.enableZoom("quickloot")
		lastItemCount = 99999999
		if hud then 
			hud:destroy() 
		end
	end
	
	--print(res.hitObject.type == types.Container)
	--print(res.hitObject)
	if not inspectedContainer 
	and res.hitObject 
	and (
		res.hitObject.type == types.Container 
		or (
			res.hitObject.type == types.NPC
			and types.Actor.isDead(res.hitObject)
		)
	)	
	and not types.Lockable.isLocked(res.hitObject)
	and not types.Lockable.getTrapSpell(res.hitObject)
	then
		if not types.Container.inventory(res.hitObject):isResolved() then
			core.sendGlobalEvent("OwnlysQuickLoot_resolve",res.hitObject)
		else
			inspectedContainer = res.hitObject
			Controls.overrideCombatControls(true) 
			Camera.disableZoom("quickloot")
			inspectedContainer:sendEvent("OwnlysQuickLoot_openAnimation",self)
			selectedIndex = 1
		end
	end
	if inspectedContainer then
		local itemCount = 0
		local entryCount = 0
		for _, thing in pairs(types.Container.inventory(inspectedContainer):getAll()) do
			itemCount = itemCount + thing.count
			entryCount = entryCount + 1
		end
		if entryCount < selectedIndex then
			selectedIndex = entryCount
		end
		
		
		if lastItemCount ~= itemCount then
			drawUI()
		end
		
		lastItemCount = itemCount
	end
end
local function onKey(key)
	--print(core.getRealTime() - OPENED_TIMESTAMP)
	if inspectedContainer and key.code == TAKEALL_KEYBINDING then
		core.sendGlobalEvent("OwnlysQuickLoot_takeAll",{self, inspectedContainer})
	end
	return false
end
return {    
	eventHandlers = {
		UiModeChanged = UiModeChanged,
		OwnlysQuickLoot_activatedContainer = activatedContainer
	},
	engineHandlers = {
		onFrame = onFrame,
		onUpdate = onUpdate,
		onKeyPress = onKey
    },
	--eventHandlers = {
    --    FHB_AI_update = AI_update,
    --}
}