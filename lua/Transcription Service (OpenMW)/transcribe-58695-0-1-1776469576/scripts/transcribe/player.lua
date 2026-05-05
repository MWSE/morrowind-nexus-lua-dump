local self                      = require('openmw.self')
local types                     = require('openmw.types')
local core                      = require('openmw.core')
local input                     = require('openmw.input')
local async                     = require('openmw.async')
local ui                        = require('openmw.ui')
local store                     = require('openmw.storage')
local util                      = require('openmw.util')
local I                         = require('openmw.interfaces')
local T                         = require("openmw.types")
local ambient                   = require('openmw.ambient')
local auxUi                     = require('openmw_aux.ui')
local storage                   = require('openmw.storage')

local settings = storage.playerSection('Settings_Transcription')

local v2 = util.vector2
local rgb = util.color.rgb

local EnchantRecords = core.magic.enchantments.records

local currentDialogueNPC

--local hasDummySpell = false
local uiActive = false
local infoActive = 0

local scrollPosition = 0

-- Color utility functions
function getColorFromGameSettings(colorTag)
	local result = core.getGMST(colorTag)
	if not result then
		return util.color.rgb(1,1,1)
	end
	local rgb = {}
	for color in string.gmatch(result, '(%d+)') do
		table.insert(rgb, tonumber(color))
	end
	if #rgb ~= 3 then
		print("UNEXPECTED COLOR: rgb of size=", #rgb)
		return util.color.rgb(1, 1, 1)
	end
	return util.color.rgb(rgb[1] / 255, rgb[2] / 255, rgb[3] / 255)
end

function mixColors(color1, color2, mult)
	local mult = mult or 0.5
	return util.color.rgb(color1.r*mult+color2.r*(1-mult), color1.g*mult+color2.g*(1-mult), color1.b*mult+color2.b*(1-mult))
end

function darkenColor(color, mult)
	return util.color.rgb(color.r*mult, color.g*mult, color.b*mult)
end

local function printTable(tab)
  for k,v in ipairs(tab) do
    print(v)
  end
end

morrowindGold = getColorFromGameSettings("fontColor_color_normal")
goldenMix =  mixColors(getColorFromGameSettings("fontColor_color_normal_over"), morrowindGold)

uiMain = {}
infoPanel = {}

local function paddedBox(layout, template)
  return {
    template = template,
    content = ui.content {
      {
        template = I.MWUI.templates.padding,
        content = ui.content { layout },
      },
    }
  }
end

local function destroyInfo()
  if infoActive == 1 and infoPanel then
    infoPanel:destroy()
    infoActive = 0
  end
end

local function destroyUI()
  if uiActive and uiMain then
    uiMain:destroy()
    uiActive = false
    destroyInfo()
  end
end

local function createInfo(itemRecord, enchant)
  infoPanel = ui.create {
    template = I.MWUI.templates.boxSolidThick,
    layer = 'Modal',
    type = ui.TYPE.Container,
    props = {

      position = v2(0.0,0.0),
      anchor = v2(-0.05,-0.05),
    },
    content = ui.content {}
  }
  
  local infoFlex = {
    type = ui.TYPE.Flex,
    props = {
      autoSize = true,
      arrange = ui.ALIGNMENT.Start,
      horizontal = false,
    },
    content = ui.content {}
  }
  infoPanel.layout.content:add(paddedBox(infoFlex,I.MWUI.templates.padding))
  
  local infoName = ui.create {
    template = I.MWUI.templates.textNormal,
    type = ui.TYPE.Text,
    props = {
      multiline = true,
      text = itemRecord.name .. '\n',
      relativePosition = util.vector2(0.5,1),
      textSize = 16
    },
  }
  infoFlex.content:add(infoName)
  
  local effects = enchant.effects
  
  for k,v in ipairs(effects) do
    local infoText = ""
    local name = v.effect.name
    
    local area = v.area
    local duration = v.duration
    local magnitudeMax = v.magnitudeMax
    local magnitudeMin = v.magnitudeMin
    
    local range = v.range
    
    local icon = v.effect.icon
    
    if v.effect.hasAttribute then
      local index = string.find(name, " Attribute")
      name = string.sub(name, 1, index-1)
      
      local attribute = v.affectedAttribute
      attribute = attribute:gsub("^%l", string.upper)
      
      infoText = infoText .. name .. ' ' .. attribute .. ' '
    elseif v.effect.hasSkill then
      infoText = infoText .. name .. ' ' .. v.affectedSkill .. ' '
    else
      infoText = infoText .. name .. ' '
    end
    
    infoText = infoText .. magnitudeMin .. ' '
    
    if not (magnitudeMin == magnitudeMax) then
      infoText = infoText .. 'to '.. magnitudeMax .. ' '
    end
    
    infoText = infoText .. 'pts '
    
    if duration > 1 then
      infoText = infoText .. 'for ' .. duration .. ' secs '
    end
    
    if area > 1 then
      infoText = infoText .. 'in ' .. area .. ' ft '
    end
    
    if range == 0 then
      infoText = infoText .. 'on Self'
    elseif range == 2 then
      infoText = infoText .. 'on Target'
    elseif range == 1 then
      infoText = infoText .. 'on Touch'
    end
    
    --print(range)
    
    local effectFlex = {
      type = ui.TYPE.Flex,
      props = {
        autoSize = true,
        arrange = ui.ALIGNMENT.Start,
        horizontal = true,
      },
      content = ui.content {}
    }
    infoFlex.content:add(effectFlex)
    
    local effectIcon = {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture { path = icon },
        tileH = false,
        tileV = false,
        relativePosition = v2(0,0),
        size = v2(16,16),
        alpha = 1.0,
        color = rgb(1,1,1),
      },
    }
    effectFlex.content:add(effectIcon)
    
    local effectInfo = ui.create {
      template = I.MWUI.templates.textNormal,
      type = ui.TYPE.Text,
      props = {
        multiline = true,
        text = infoText,
        relativePosition = util.vector2(0.5,1),
        textSize = 16
      },
    }
    effectFlex.content:add(effectInfo)
    
  end
  
  infoActive = 1
  --printTable(core.magic.spells.records)
end

--[[
for kk,vv in ipairs(effects) do
      local baseCost = vv.effect.baseCost
      local area = vv.area
      local duration = vv.duration
      local magnitudeMax = vv.magnitudeMax
      local magnitudeMin = vv.magnitudeMin
      
      cost = cost + math.floor( ( ( magnitudeMin + magnitudeMax) * math.max( duration, 1 ) + area ) * baseCost / 40 )
    end
]]

local function createUI()
  uiActive = true

  local actor = currentDialogueNPC

  local enchantSkill = types.NPC.stats.skills.enchant(actor).modified
  local mercantile = types.NPC.stats.skills.mercantile(actor).modified
  local disposition = types.NPC.getDisposition(actor, self.object)
  local enchanterName = actor.type.record(actor).name
  
  local playerMercantile = types.NPC.stats.skills.mercantile(self).modified
  local playerGoldObj = self.type.inventory(self):find("gold_001")
  local playerGold = 0
  
  if playerGoldObj then
    playerGold = playerGoldObj.count
  end
  
  local allItems = self.type.inventory(self):getAll()
  
  local items = {}

  local playerSpells = types.Player.spells(self)
  
  for k,v in ipairs(allItems) do
    local record = v.type.record(v)  
    if v.type == types.Book then
      --print("yup")
      local enchant
      
      if record.enchant then
        enchant = EnchantRecords[record.enchant]
      end
      --print(enchant)
    
      if enchant then
        if playerSpells["sp_" .. enchant.id] == nil then
          table.insert(items, v)
        end
      end
    end
  end

  local borderWidth = 4
  local titleSize = 18
  local barSize = 14
  local entryWidth = 200
  local entryHeight = titleSize + barSize + borderWidth
  local buttonWidth = entryHeight
  
  local wrapperHeight = 5
  local scrollWidth = 12
  
  if #items <= wrapperHeight then
    scrollPosition = 0
  end

  uiMain = ui.create {
    template = I.MWUI.templates.boxSolidThick,
    layer = 'Modal',
    type = ui.TYPE.Container,
    props = {
      relativePosition = v2(0.5,0.45),
      anchor = v2(0.5,0.5),
    },
    content = ui.content {}
  }
  
  mainFlex = {
    type = ui.TYPE.Flex,
    props = {
      autoSize = true,
      arrange = ui.ALIGNMENT.Start,
      horizontal = false,
    },
    content = ui.content {}
  }
  uiMain.layout.content:add(mainFlex)
  
  -----------------
  --Entry Wrapper--
  -----------------
  
  local entryWrapperBox = ui.create {
    template = I.MWUI.templates.box,
    type = ui.TYPE.Container,
    props = {
      relativePosition = v2(0,0),
      anchor = v2(0,0),
    },
    content = ui.content {}
  }
  mainFlex.content:add(entryWrapperBox)
  
  
  local entryWrapperFlex = {
    type = ui.TYPE.Flex,
    props = {
      autoSize = false,
      size = v2(entryWidth+entryHeight+buttonWidth+scrollWidth+4,(entryHeight+4) * wrapperHeight),
      arrange = ui.ALIGNMENT.Start,
      horizontal = true,
    },
    content = ui.content {}
  }
  entryWrapperBox.layout.content:add(entryWrapperFlex)
  
  local entryObjectWrapperBox = ui.create {
    type = ui.TYPE.Container,
    props = {
      relativePosition = v2(0,0),
      anchor = v2(0,0),
    },
    content = ui.content {}
  }
  entryWrapperFlex.content:add(entryObjectWrapperBox)
  
  
  local entryObjectWrapperFlex = {
    type = ui.TYPE.Flex,
    props = {
      position = v2(0,(-1*scrollPosition) * math.max(#items-wrapperHeight,1) * (entryHeight+borderWidth)),
      anchor = v2(0,0),
      autoSize = false,
      size = v2(entryWidth+entryHeight+buttonWidth+4,(entryHeight+borderWidth) * 100),
      arrange = ui.ALIGNMENT.Start,
      horizontal = false,
    },
    content = ui.content {}
  }
  entryObjectWrapperBox.layout.content:add(entryObjectWrapperFlex)
  
  --------------
  --Scroll Bar--
  --------------
  
  local barHeight = ((entryHeight + borderWidth) * wrapperHeight) - borderWidth
  
  local entryScrollBox = ui.create {
    template = I.MWUI.templates.box,
    type = ui.TYPE.Container,
    props = {
      relativePosition = v2(0,0),
      relativeSize = v2(1,1),
      anchor = v2(0,0),
    },
    content = ui.content {}
  }
  entryWrapperFlex.content:add(entryScrollBox)
  
  local entryScroll = {
    props = {
      autoSize = false,
      size = v2(scrollWidth,barHeight),
    },
    content = ui.content {}
  }
  entryScrollBox.layout.content:add(entryScroll)
  
  local thumbY = math.min(1, (wrapperHeight / #items)) * barHeight 
  
  local entryScrollThumb = {
    type = ui.TYPE.Image,
    props = {
      resource = ui.texture { path = 'white' },
      tileH = false,
      tileV = false,
      position = v2(0,scrollPosition*(barHeight-thumbY)),
      size = v2(scrollWidth,thumbY),
      alpha = 1.0,
      color = goldenMix
    },
  }
  entryScroll.content:add(entryScrollThumb)
  
  entryScrollThumb.events = {
    mouseRelease = async:callback(function(data, elem)
			if elem.userData then
				elem.userData.isDragging = false
			end
		end),
  
    mousePress = async:callback(function(data, elem)
			if data.button == 1 then
				if not elem.userData then
					elem.userData = {}
				end
				
				elem.userData.isDragging = true
				elem.userData.dragStartY = data.position.y
        
        elem.userData.dragStartThumbY = elem.props.position.y
      end
		end),
  
    mouseMove = async:callback(function(data, elem)
			if elem.userData and elem.userData.isDragging then
				local scrollContainerHeight = entryHeight * wrapperHeight
				local thumbHeight = elem.props.size.y
				local availableScrollDistance = scrollContainerHeight - thumbHeight
        
				if availableScrollDistance > 0 then
					local deltaY = data.position.y - elem.userData.dragStartY
					local newThumbY = math.max(0, math.min(availableScrollDistance, elem.userData.dragStartThumbY + deltaY))
					
					local newScrollPosition = math.max(0, math.min(1, newThumbY / availableScrollDistance))
          
          
          scrollPosition = newScrollPosition
          
          entryScrollThumb.props.position = v2(0,scrollPosition*(barHeight-thumbHeight))
          
          entryScrollBox:update()
          
          entryObjectWrapperFlex.props.position = v2(0,(-1*scrollPosition) * math.max(#items-wrapperHeight,1) * (entryHeight+borderWidth))
          entryObjectWrapperBox:update()
          
				end
			end
		end),
  }
  
  for k,v in ipairs(items) do 
  
    local record = v.type.record(v)
    
    local name = record.name
    
    --print(name)
    local itemValue = record.value
    
    local enchant = EnchantRecords[record.enchant]

    local effects = enchant.effects
    local cost = 0
    
    for kk,vv in ipairs(effects) do
      local baseCost = vv.effect.baseCost
      local area = vv.area
      local duration = vv.duration
      local magnitudeMax = vv.magnitudeMax
      local magnitudeMin = vv.magnitudeMin
      local range = vv.range
      
      --print(range)
      
      --cost = cost + math.floor( ( ( ( magnitudeMin + magnitudeMax) * math.max( duration, 1 ) + area ) / 40 ) * baseCost)
      
      cost = 0.5 * (magnitudeMin + magnitudeMax)
      cost = cost * 0.1 * baseCost
      cost = cost * math.max( duration, 1 )
      cost = cost + 0.05 * math.max(1, area) * baseCost
      
      if range == 2 then
        cost = cost * 1.5
      end
    end
    
    local priceMult = settings:get("priceMult")
    
    cost = cost * priceMult
    cost = math.ceil(cost)
    
    local barHeight = barSize
    local barWidth = entryWidth - borderWidth
    
    local fSpellMakingValueMult = core.getGMST("fSpellMakingValueMult")
    
    local basePrice = cost * fSpellMakingValueMult
    
    --print(fSpellMakingValueMult)
    
    --local transcribePrice = math.floor( basePrice * ((200 - playerMercantile + mercantile - disposition)/200))

    local transcribePrice = basePrice

    local iconColor = rgb(1,1,1)
    local chargeColor = getColorFromGameSettings("FontColor_color_magic")
    local titleColor = morrowindGold
    local condTextColor = getColorFromGameSettings("FontColor_color_count")
    
    if (playerGold < transcribePrice) then
      local disabled = rgb(0,0,0)
      
      iconColor = mixColors(disabled, iconColor, 0.5)
      titleColor = mixColors(disabled, titleColor, 0.5)
    end
    
    ---------
    --Entry--
    ---------
    
    local entryBox = ui.create {
      template = I.MWUI.templates.box,
      type = ui.TYPE.Container,
      props = {
        position = v2(0,0),
        anchor = v2(0,0),
      },
      content = ui.content {}
    }
    entryObjectWrapperFlex.content:add(entryBox)
    
    local entryFlexH = {
      type = ui.TYPE.Flex,
      props = {
        position = v2(0,0),
        anchor = v2(0,0),
        autoSize = false,
        size = v2(entryWidth+entryHeight+buttonWidth,entryHeight),
        arrange = ui.ALIGNMENT.Start,
        horizontal = true,
      },
      content = ui.content {}
    }
    entryBox.layout.content:add(entryFlexH)
    
    -----------------
    --Repair Button--
    -----------------
    
    local repairBox = ui.create {
      template = I.MWUI.templates.box,
      type = ui.TYPE.Container,
      props = {
        relativePosition = v2(0,0),
        anchor = v2(0,0),
      },
      content = ui.content {},
    }
    
    local repairImg = {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture { path = 'icons/k/magic_enchant.dds' },
        tileH = false,
        tileV = false,
        relativePosition = v2(0,0),
        size = v2(entryHeight-4,entryHeight-borderWidth),
        alpha = 1.0,
        color = rgb(1,1,1),
      },
    }
    
    if playerGold >= transcribePrice then
      repairImg.events = {
        focusGain = async:callback(function(data, elem)
          repairImg.props.alpha = 0.5
          if infoActive == 0 then
            createInfo(record, enchant)
          end
          repairBox:update()
        end),
        focusLoss = async:callback(function(data, elem)
          repairImg.props.alpha = 1.0
          destroyInfo()
          repairBox:update()
        end),
        mousePress = async:callback(function(data, elem)
        repairImg.props.alpha = 0.2
          repairBox:update()
        end),
        mouseRelease = async:callback(function(data, elem)
          repairImg.props.alpha = 0.5
          ambient.playSoundFile('sound/fx/magic/enchant.wav', {volume =0.9})
          
          destroyUI()
          core.sendGlobalEvent('TRAN_doTranscribe', { actor = self.object, item = v, gold = playerGoldObj, price = transcribePrice, name = name, enchantid = enchant.id })
        end),
        mouseMove = async:callback(function(data, elem)
          if infoActive == 1 then
            infoPanel.layout.props.position = data.position
            infoPanel:update()
          end
        end),
      }
    else
      --repairImg.props.resource = ui.texture { path = 'icons/m/tx_gold_001.dds' }
      repairImg.props.color = rgb(0.2,0.2,0.2)
    end
    
    entryFlexH.content:add(repairBox)
    repairBox.layout.content:add(repairImg)
    
    local entryFlexV = {
      type = ui.TYPE.Flex,
      props = {
        autoSize = false,
        size = v2(entryWidth,entryHeight),
        arrange = ui.ALIGNMENT.Start,
        horizontal = false,
      },
      content = ui.content {}
    }
    entryFlexH.content:add(entryFlexV)
    
    local entryTitle = ui.create {
      template = I.MWUI.templates.textHeader,
      type = ui.TYPE.Text,
      props = {
        text = tostring(name) .. '\n' .. transcribePrice .. ' gp',
        relativePosition = util.vector2(0,0),
        textColor = titleColor,
        multiline = true,
      },
    }
    entryFlexV.content:add(entryTitle)
    
    --------
    --icon--
    --------
    
    local imgBox = ui.create {
      template = I.MWUI.templates.box,
      type = ui.TYPE.Container,
      props = {
        relativePosition = v2(0,0),
        anchor = v2(0,0),
      },
      content = ui.content {}
    }
    entryFlexH.content:add(imgBox)
    
    local iconImgEnch = {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture { path = 'textures/menu_icon_magic_mini.dds' },
        tileH = false,
        tileV = false,
        relativePosition = v2(0,0),
        size = v2(entryHeight-4,entryHeight-4),
        alpha = 1.0,
        color = iconColor,
      },
    }
    imgBox.layout.content:add(iconImgEnch)
    
    local iconImg = {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture { path = record.icon },
        tileH = false,
        tileV = false,
        relativePosition = v2(0,0),
        size = v2(entryHeight-4,entryHeight-4),
        alpha = 1.0,
        color = iconColor,
      },
    }
    imgBox.layout.content:add(iconImg)
  end
  
  -----------
  -- Stats --
  -----------
  
  local statColor = getColorFromGameSettings("FontColor_color_count")
  
  local statsWrapperBox = ui.create {
    template = I.MWUI.templates.box,
    type = ui.TYPE.Container,
    props = {
      relativePosition = v2(0.5,0.45),
      anchor = v2(0.5,0.5),
    },
    content = ui.content {}
  }
  mainFlex.content:add(statsWrapperBox)
  
  local statsHeight = 60
  
  local statsWrapperBoxFlex = {
    type = ui.TYPE.Flex,
    props = {
      autoSize = true,
      size = v2(entryWidth+entryHeight+buttonWidth+scrollWidth+4, statsHeight),
      arrange = ui.ALIGNMENT.Start,
      horizontal = false,
    },
    content = ui.content {}
  }
  statsWrapperBox.layout.content:add(statsWrapperBoxFlex)
  
  -----------------
  --Smith Display--
  -----------------
  
  local smithBox = ui.create {
    type = ui.TYPE.Container,
    props = {
      relativePosition = v2(0.5,0.45),
      anchor = v2(0.5,0.5),
    },
    content = ui.content {}
  }
  
  statsWrapperBoxFlex.content:add(smithBox)
  
  local smithFlex = {
    type = ui.TYPE.Flex,
    props = {
      autoSize = true,
      arrange = ui.ALIGNMENT.Start,
      horizontal = true,
    },
    content = ui.content {}
  }
  smithBox.layout.content:add(smithFlex)
  
  local smithInfo = ui.create {
    template = I.MWUI.templates.textNormal,
    type = ui.TYPE.Text,
    props = {
      multiline = true,
      text = "Enchanter: \nSkill:",
      relativePosition = util.vector2(0.5,1),
      textSize = 16
    },
  }
  smithFlex.content:add(smithInfo)
  
  local smithInfoNum = ui.create {
    template = I.MWUI.templates.textNormal,
    type = ui.TYPE.Text,
    props = {
      multiline = true,
      text = enchanterName .. '\n' .. enchantSkill,
      relativePosition = util.vector2(0.5,1),
      textColor = statColor,
      textSize = 16
    },
  }
  smithFlex.content:add(smithInfoNum)
  
  local statsSpacer = {
    type = ui.TYPE.Image,
    props = {
      resource = ui.texture { path = 'white' },
      tileH = false,
      tileV = false,
      relativePosition = v2(0,0),
      size = v2(entryWidth+entryHeight+buttonWidth+scrollWidth+4,1),
      alpha = 0.0,
      color = util.color.rgb(1,1,1),
    },
  }
  statsWrapperBoxFlex.content:add(statsSpacer)
  
  --------
  --Gold--
  --------
  
  local goldBox = ui.create {
    type = ui.TYPE.Container,
    props = {
    },
    content = ui.content {}
  }
  statsWrapperBoxFlex.content:add(goldBox)
  
  local goldFlex = {
    type = ui.TYPE.Flex,
    props = {
      autoSize = false,
      size = v2(entryWidth+entryHeight+entryHeight+scrollWidth,20),
      arrange = ui.ALIGNMENT.Start,
      horizontal = true,
    },
    content = ui.content {}
  }
  goldBox.layout.content:add(goldFlex)
  
  local goldPad = ui.create {
    template = I.MWUI.templates.textNormal,
    type = ui.TYPE.Text,
    props = {
      multiline = true,
      text = ' ',
      relativePosition = util.vector2(0.5,1),
      textColor = util.color.rgb(1,1,1),
      textSize = 16
    },
  }
  goldFlex.content:add(goldPad)
  
  local goldIcon = {
    type = ui.TYPE.Image,
    props = {
    resource = ui.texture { path = 'icons/m/tx_gold_001.dds' },
    tileH = false,
    tileV = false,
    relativePosition = v2(0,0),
    size = v2(16,16),
    alpha = 1.0,
    color = util.color.rgb(1,1,1),
    },
  }
  goldFlex.content:add(goldIcon)
  
  local goldInfo = ui.create {
    template = I.MWUI.templates.textNormal,
    type = ui.TYPE.Text,
    props = {
      multiline = true,
      text = ' Your Gold: ',
      relativePosition = util.vector2(0.5,1),
      textColor = statColor,
      textSize = 16
    },
  }
  goldFlex.content:add(goldInfo)
  
  local goldInfoNum = ui.create {
    template = I.MWUI.templates.textNormal,
    type = ui.TYPE.Text,
    props = {
      multiline = true,
      text = tostring(playerGold) .. ' gp',
      relativePosition = util.vector2(0.5,1),
      textColor = statColor,
      textSize = 16
    },
  }
  goldFlex.content:add(goldInfoNum)
end

function handleUiModeChanged(data)
  --destroyUI()
  if data.newMode == "Dialogue" and data.arg then
		currentDialogueNPC = data.arg
  end
  --[[
  if data.oldMode == "Dialogue" then
    local hasDummySpell = false
		for _, spell in pairs(types.Actor.spells(self)) do
			if spell.id == "recharge_dummy" then
				hasDummySpell = true
			end
		end
		if hasDummySpell then
			--types.Actor.spells(self):remove("recharge_dummy")
      createUI()
      I.UI.setMode('Interface')
		end
  end
  ]]
end

local function handleResponse(data)
  destroyUI()
  
  local actor = data.actor
  local id = core.dialogue[data.type].records[data.recordId].id;
  if id == "- transcribe" then
    --I.UI.setMode('Interface')
    createUI()
  end
end

local function init()
  --types.Actor.spells(self):remove("recharge_dummy")
  --hasDummySpell = false
  destroyUI()
end

return {
  engineHandlers = {
    onInit = init,
    onLoad = init,
    
    onKeyPress = function(key)
      if key.code == input.KEY.Escape then
        destroyUI()
      end
    end,
      
    onMouseButtonPress = function(key)
      if key == 3 then
        destroyUI()
      end
    end,
  },
  eventHandlers = {
    DialogueResponse = handleResponse,
    UiModeChanged = handleUiModeChanged,
    TRAN_createUI = createUI,
    TRAN_destroyUI = destroyUI,
  },
}