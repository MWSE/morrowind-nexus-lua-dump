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

local settings = storage.playerSection('Settings_Entropy')

local scrollPosition = 0
local entryOffset = 0

local uiActive = 0

local currentDialogueNPC

local v2 = util.vector2
local rgb = util.color.rgb

local specialItems = {
  "wraithguard",
  "wraithguard_jury_rig",
  "keening",
  "sunder",
}

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

morrowindGold = getColorFromGameSettings("fontColor_color_normal")
goldenMix =  mixColors(getColorFromGameSettings("fontColor_color_normal_over"), morrowindGold)
uiMain = {}

local function doNothing()
end

local function addItem(data)
  
  local actor = data.actor
  local new = data.new
  local old = data.old
  
  world.createObject(new.id):moveInto(actor)

  core.sendGlobalEvent('FUJI_RemoveObject', old)
end

local function createUI(data)
  uiActive = 1
  
  local lossMult = settings:get("lossMult")
  local lossMin = settings:get("lossMin")
  local skillCapMult = settings:get("skillCapMult")
  
  local selfRepair = 1
  local isSpecial = 0

  local actor = data.actor
  
  if data.actor == nil then
    selfRepair = 0
    actor = currentDialogueNPC
  end
  
  local armorer = types.NPC.stats.skills.armorer(actor).modified
  local mercantile = types.NPC.stats.skills.mercantile(actor).modified
  local disposition = types.NPC.getDisposition(actor, self.object)
  local smithName = actor.type.record(actor).name
  
  local playerMercantile = types.NPC.stats.skills.mercantile(self).modified
  local playerGoldObj = self.type.inventory(self):find("gold_001")
  local playerGold = 0
  
  if playerGoldObj then
    playerGold = playerGoldObj.count
  end

  local weapons = self.type.inventory(self):getAll(T.Weapon)
  local armor = self.type.inventory(self):getAll(T.Armor)
  
  local tool = data.tool
  local toolRecord = {}
  
  if tool then
    toolRecord = tool.type.record(tool)
  end
  
  local items = {}
  
  for k,v in ipairs(weapons) do
    local record = v.type.record(v)
    local cond = T.Item.itemData(v).condition
    local maxCond = record.health
    
    if cond and maxCond and cond < maxCond then
      table.insert(items, v)
    end
  end
  
  for k,v in ipairs(armor) do
    local record = v.type.record(v)
    local cond = T.Item.itemData(v).condition
    local maxCond = record.health
    
    if cond and maxCond and cond < maxCond then
      table.insert(items, v)
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
  
  local hammerImg
  local hammerName
  local hammerQual = 1
  local hammerUses
  local hammerStrength
  local hammerMult = 100
  
  if selfRepair == 1 then
    hammerImg = toolRecord.icon
    hammerName = toolRecord.name
    hammerQual = math.ceil(toolRecord.quality * 100) / 100
    hammerUses = T.Item.itemData(tool).condition
    hammerStrength = hammerMult * hammerUses
  end
  
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
  
  local mainFlex = {
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
    local itemValue = record.value
    
    local cond = T.Item.itemData(v).condition
    local maxCond = record.health
    
    local barHeight = barSize
    local barWidth = entryWidth - borderWidth
    
    local condPerc = cond / maxCond
    local barSize = condPerc * barWidth
    
    local potentialAmt
    local potentialPerc
    
    local lossPerc = 0  -- |  ||
    local lossAmt = 0   -- || |-
    local lossSize = 0
    local potentialSize
    
    local repairPrice = 0
    
    if selfRepair == 1 then
      local maxAmt = maxCond * math.min(armorer / (100 * skillCapMult), 1)
      
      potentialAmt = math.min((maxAmt - cond), hammerStrength)
      
      potentialAmt = math.max(potentialAmt, 0)
    else
      potentialAmt = maxCond - cond
    end
    
    potentialPerc = potentialAmt / maxCond
    
    for kk,vv in ipairs(specialItems) do
      if record.id == vv then
        lossPerc = 0
        lossAmt = 0
        lossSize = 0
        isSpecial = 1
      end
    end
  
    if isSpecial ~= 1 then
      local maxArmorer = math.min(armorer, 100)
      local armorerMod = math.max(1 - ((maxArmorer * hammerQual) / 100), 0)
      lossPerc = potentialPerc * math.max(armorerMod, lossMin) * lossMult
      lossAmt = lossPerc * maxCond
      lossSize = lossPerc * barWidth
    end
  
    potentialSize = (potentialPerc - lossPerc) * barWidth
    
    if selfRepair == 0 then
      repairPrice = math.floor((potentialPerc-lossPerc) * itemValue * ((200 - playerMercantile + mercantile - disposition)/200))
      
      if cond ~= maxCond then
        repairPrice = math.max(1, repairPrice)
      end
    end

    local iconColor = rgb(1,1,1)
    local condColor = getColorFromGameSettings("FontColor_color_positive")
    local lossColor = getColorFromGameSettings("FontColor_color_negative")
    local potentialColor = getColorFromGameSettings("FontColor_color_magic")
    local titleColor = morrowindGold
    local condTextColor = getColorFromGameSettings("FontColor_color_count")
    
    if (selfRepair == 0 and playerGold < repairPrice) or potentialAmt <= 0 then
      local disabled = rgb(0,0,0)
      
      iconColor = mixColors(disabled, iconColor, 0.5)
      condColor = mixColors(disabled, condColor, 0.5)
      lossColor = mixColors(disabled, lossColor, 0.5)
      potentialColor = mixColors(disabled, potentialColor, 0.5)
      titleColor = mixColors(disabled, titleColor, 0.5)
      condTextColor = mixColors(disabled, condTextColor, 0.5)
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
        resource = ui.texture { path = 'icons/k/combat_armor.dds' },
        tileH = false,
        tileV = false,
        relativePosition = v2(0,0),
        size = v2(entryHeight-4,entryHeight-borderWidth),
        alpha = 1.0,
        color = rgb(1,1,1),
      },
    }
    
    if (selfRepair == 1 or playerGold >= repairPrice) and potentialAmt > 0 then
      repairImg.events = {
        focusGain = async:callback(function(data, elem)
          repairImg.props.alpha = 0.5
          repairBox:update()
        end),
        focusLoss = async:callback(function(data, elem)
          repairImg.props.alpha = 1.0
          repairBox:update()
        end),
        mousePress = async:callback(function(data, elem)
        repairImg.props.alpha = 0.2
          repairBox:update()
        end),
        mouseRelease = async:callback(function(data, elem)
          repairImg.props.alpha = 0.5
          ambient.playSound("repair", {volume =0.9})
          
          core.sendGlobalEvent('FUJI_doRepair', { actor = self.object, smith = actor, item = v, damage = lossAmt, repair = potentialAmt, tool = tool, toolMult = hammerMult, gold = playerGoldObj, price = repairPrice })
          
          local repairSkillGain = potentialAmt / 100
          if selfRepair == 1 then
            I.SkillProgression.skillUsed("armorer", {skillGain = repairSkillGain, useType = 0})
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
        text = tostring(name),
        relativePosition = util.vector2(0,0),
        textColor = titleColor,
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
    
    if record.enchant ~= nil then
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
    end
    
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
    
    -----------------
    --Condition Bar--
    -----------------
        
    local condBox = ui.create {
      template = I.MWUI.templates.box,
      type = ui.TYPE.Container,
      props = {
        relativePosition = v2(0,0),
        anchor = v2(0,0),
      },
      content = ui.content {}
    }
    entryFlexV.content:add(condBox)
    
    local condFlex = {
      type = ui.TYPE.Flex,
      props = {
        autoSize = false,
        size = v2(barWidth,barHeight),
        arrange = ui.ALIGNMENT.Start,
        horizontal = true,
      },
      content = ui.content {}
    }
    condBox.layout.content:add(condFlex)
    
    local condPad = 4
    local condT = string.format('%-' .. condPad .. 's',tostring(math.floor(cond)))
    local maxCondT = string.format('%-' .. condPad .. 's',tostring(maxCond))
    
    local newAmtT = string.format('%-' .. 12 .. 's',' (' .. tostring(math.floor(maxCond - lossAmt)) .. ') ')
    
    local condString = tostring(condT .. ' / ' .. maxCondT .. newAmtT)
    
    if selfRepair == 0 then
      condString = condString .. repairPrice .. ' gp'
    else
      local hammerDamage = math.ceil(potentialAmt/100)
      
      condString = condString .. hammerDamage .. ' hu'
    end
    
    local condText = ui.create {
      template = I.MWUI.templates.textNormal,
      type = ui.TYPE.Text,
      props = {
        text = condString,
        relativePosition = util.vector2(0.5,1),
        textColor = condTextColor,
        textSize = barHeight
      },
    }
    condBox.layout.content:add(condText)
    
    local condBar = {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture { path = 'white' },
        tileH = false,
        tileV = false,
        relativePosition = v2(0,0),
        size = v2(barSize,barHeight),
        alpha = 0.625,
        color = condColor,
      },
    }
    condFlex.content:add(condBar)
    
    local condBarLoss = {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture { path = 'white' },
        tileH = false,
        tileV = false,
        relativePosition = v2(0,0),
        size = v2(lossSize,barHeight),
        alpha = 0.625,
        color = lossColor,
      },
    }
    condFlex.content:add(condBarLoss)
    
    local condBarPotential = {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture { path = 'white' },
        tileH = false,
        tileV = false,
        relativePosition = v2(0,0),
        size = v2(potentialSize,barHeight),
        alpha = 0.625,
        color = potentialColor,
      },
    }
    condFlex.content:add(condBarPotential)
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
  
  local statsHeight = 90
  
  if selfRepair == 0 then
    statsHeight = 60
  end
  
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
      text = "Smith: \nSkill: ",
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
      text = tostring(smithName) .. '\n' .. tostring(armorer),
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
  
  if tool ~= nil then
    
    ----------
    --Hammer--
    ----------
    
    local hammerBox = ui.create {
      type = ui.TYPE.Container,
      props = {
      },
      content = ui.content {}
    }
    statsWrapperBoxFlex.content:add(hammerBox)
    
    local hammerFlex = {
      type = ui.TYPE.Flex,
      props = {
        autoSize = true,
        --size = v2(entryWidth+entryHeight+entryHeight+scrollWidth,entryHeight),
        arrange = ui.ALIGNMENT.Start,
        horizontal = true,
      },
      content = ui.content {}
    }
    hammerBox.layout.content:add(hammerFlex)
    
    local hammerPad = ui.create {
      template = I.MWUI.templates.textNormal,
      type = ui.TYPE.Text,
      props = {
        multiline = true,
        text = ' ',
        relativePosition = util.vector2(0.5,1),
        textSize = 8
      },
    }
    hammerFlex.content:add(hammerPad)
    
    local hammerIcon = {
      type = ui.TYPE.Image,
      props = {
      resource = ui.texture { path = hammerImg },
      tileH = false,
      tileV = false,
      relativePosition = v2(0,0),
      size = v2(32,32),
      alpha = 1.0,
      color = util.color.rgb(1,1,1),
      },
    }
    hammerFlex.content:add(hammerIcon)
    
    local hammerInfo = ui.create {
      template = I.MWUI.templates.textNormal,
      type = ui.TYPE.Text,
      props = {
        multiline = true,
        text = hammerName .. '\nRepair Points: \nQuality: ',
        relativePosition = util.vector2(0.5,1),
        textColor = statColor,
        textSize = 16
      },
    }
    hammerFlex.content:add(hammerInfo)
    
    local hammerInfoNum = ui.create {
      template = I.MWUI.templates.textNormal,
      type = ui.TYPE.Text,
      props = {
        multiline = true,
        text = '\n' .. hammerMult .. ' x ' .. hammerUses .. ' hu' .. ' (' .. hammerStrength .. ')\n' .. hammerQual,
        relativePosition = util.vector2(0.5,1),
        textColor = statColor,
        textSize = 16
      },
    }
    hammerFlex.content:add(hammerInfoNum)
    
    statsWrapperBoxFlex.content:add(statsSpacer)
  else
  
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
end

local function destroyUI()
  if uiActive == 1 then
    uiMain:destroy()
    --[[
    if I.UI.getMode() == "Repair" then
      I.UI.setMode('Interface')
    end
    ]]
    uiActive = 0
  end
end

function handleUiModeChanged(data)
  if data.newMode == "Dialogue" and data.arg then
		currentDialogueNPC = data.arg
	elseif data.oldMode == "Repair" then
    destroyUI()
  end
end



local function init()
  I.UI.registerWindow("Repair", doNothing, doNothing)
  I.UI.registerWindow("MerchantRepair", createUI, destroyUI)
  
  modSettings = storage.globalSection("Settings_Entropy")

  print("####################Entropy Init Done######################")
end

return {
  engineHandlers = {
    onInit = init,
    onLoad = init,
    --[[
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
    ]]
  },
  eventHandlers = {
    UiModeChanged = handleUiModeChanged,
    FUJI_addItem = addItem,
    FUJI_createUI = createUI,
    FUJI_destroyUI = destroyUI,
  },
}

