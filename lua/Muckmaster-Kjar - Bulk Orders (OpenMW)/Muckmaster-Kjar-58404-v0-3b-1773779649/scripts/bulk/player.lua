local self                      = require('openmw.self')
local types                     = require('openmw.types')
local core                      = require('openmw.core')
local input                     = require('openmw.input')
local async                     = require('openmw.async')
local ui                        = require('openmw.ui')
local store                     = require('openmw.storage')
local util                      = require('openmw.util')
local I                         = require('openmw.interfaces')
local ambient                   = require('openmw.ambient')
local auxUi                     = require('openmw_aux.ui')
local storage                   = require('openmw.storage')
local calendar                  = require('openmw_aux.calendar')
local time                      = require('openmw_aux.time')

local v2 = util.vector2
local rgb = util.color.rgb


local TypeToService = {
  ["Weapon"] = "Weapon",
  ["Armor"] = "Armor",
  ["Clothing"] = "Clothing",
  ["Book"] = "Books",
  ["Ingredient"] = "Ingredients",
  ["Lockpick"] = "Picks",
  ["Probe"] = "Probes",
  ["Light"] = "Lights",
  ["Apparatus"] = "Apparatus",
  ["Repair"] = "RepairItems",
  ["Miscellaneous"] = "Misc",
  ["Potion"] = "Potions",
  ["Magic"] = "MagicItems",
}

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
  for k,v in pairs(tab) do
    print(tostring(k) .. ":" .. tostring(v))
  end
end

local morrowindGold = getColorFromGameSettings("fontColor_color_normal")
local goldenMix =  mixColors(getColorFromGameSettings("fontColor_color_normal_over"), morrowindGold)

local fontNormal = getColorFromGameSettings("FontColor_color_normal")
local fontOver = getColorFromGameSettings("FontColor_color_normal_over")
local fontPressed = getColorFromGameSettings("FontColor_color_normal_pressed")

local fontCount = getColorFromGameSettings("FontColor_color_count")

local fontMagic = getColorFromGameSettings("FontColor_color_magic")
local fontFatigue = getColorFromGameSettings("FontColor_color_fatigue")
local fontNegative = getColorFromGameSettings("FontColor_color_negative")

local currentDialogueNPC

local itemsCurrent = {}
local qtyCurrent = {}
local qtyKeys = 0

local buttonSound = "menu click"

local uiMain = {}

local uiActive = false

local scrollPosition = 0

local function getMerchantItems(npc)

  print("getmerchantitems")
  local unfiltered = {}
  --local carried = npc.type.inventory(npc):getAll()
  --for _, item in ipairs(carried) do
  --  table.insert(unfiltered, item)
  --end
  local success, nearby = pcall(require, 'openmw.nearby')
  if success then
    for _, item in ipairs(nearby.items) do
      if item.owner.recordId == npc.recordId then
        table.insert(unfiltered, item)
      end
    end
    for _, container in ipairs(nearby.containers) do
      if container.owner.recordId == npc.recordId then
        local inv = container.type.inventory(container)
        local contItems = inv:getAll()
        for _, item in ipairs(contItems) do
          table.insert(unfiltered, item)
        end
      end
    end
  end
  
  --printTable(unfiltered)
  
  local npcRecord = types.NPC.record(currentDialogueNPC)
  local services = npcRecord.servicesOffered
  
  --printTable(services)
  
  local filtered = {}
  
  for _,v in ipairs(unfiltered) do
    
    if types.Miscellaneous.objectIsInstance(v) and v.type.record(v).isKey then
        --break
    end
  
    local valid = true
    for __,vv in ipairs(filtered) do
      if v.type.record(v).name == vv.type.record(vv).name then
        --print("dup")
        valid = false
      end
    end
    
    if string.find(v.type.record(v).id, "Generated") then
      valid = false
    end
    
    
    if valid then
      if services.MagicItems and v.enchant then
        table.insert(filtered,v)
      else
        for t, serviceName in pairs(TypeToService) do
          if t ~= "Magic" then
            if types[t].objectIsInstance(v) then
              if services[serviceName] then
                
                table.insert(filtered,v)
                break
              end
            end
          end
        end 
      end
    end
  end
  
  return filtered
end

local function isGold(item)
    local id = item.recordId:lower()
    return id == 'gold_001' or id == 'gold_005' or id == 'gold_010' or id == 'gold_025' or id == 'gold_100'
end

local function getItemValue(item)
    if isGold(item) then
        return 1
    end

    if item.type.record(item).isKey then
        return 0
    end

    local soul = item.type.itemData(item).soul
    local baseValue = item.type.record(item).value
    if not soul then return baseValue end

    local soulRecord = types.Creature.records[soul]
    local soulValue = soulRecord and soulRecord.soulValue or 0
    if configGlobal.gameplay.b_SoulGemValueRebalance then
        soulValue = 0.0001 * (soulValue ^ 3) + 2 * soulValue

        if item.recordId:lower() == 'misc_soulgem_azura' then
            return baseValue + math.modf(soulValue)
        else
            return math.modf(soulValue)
        end
    else
        return baseValue * soulValue
    end
end

local function getEffectiveValue(item, count)
    local basePrice = getItemValue(item)

    local itemData = item.type.itemData(item)
    local itemRecord = item.type.record(item)

    local x = basePrice
    return x * count
end

local function getBarterOffer(merchant, basePrice, buying)
    if (basePrice == 0 or types.Creature.objectIsInstance(merchant)) then
        return basePrice
    end

    local clampedDisposition = util.clamp(merchant.type.getDisposition(merchant, self), 0, 100)
    local a = math.min(self.type.stats.skills.mercantile(self).modified, 100)
    local b = math.min(0.1 * self.type.stats.attributes.luck(self).modified, 10)
    local c = math.min(0.2 * self.type.stats.attributes.personality(self).modified, 10)
    local d = math.min(merchant.type.stats.skills.mercantile(merchant).modified, 100)
    local e = math.min(0.1 * merchant.type.stats.attributes.luck(merchant).modified, 10)
    local f = math.min(0.2 * merchant.type.stats.attributes.personality(merchant).modified, 10)
    local pcTerm = (clampedDisposition - 50 + a + b + c)
    local npcTerm = (d + e + f)
    local buyTerm = 0.01 * (100 - 0.5 * (pcTerm - npcTerm))
    local sellTerm = 0.01 * (50 - 0.5 * (npcTerm - pcTerm))
    local offerPrice = math.modf(basePrice * (buying and buyTerm or sellTerm))
    return math.max(1, offerPrice)
end

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

local function inBox(layout, template)
  return {
    template = template,
    content = ui.content {
      layout
    }
  }
end

local function textButton(text, size, sound, func, args)
  local box = ui.create {
    type = ui.TYPE.Container,
    props = {},
    content = ui.content {}
  }
  local flex = {
    type = ui.TYPE.Flex,
    props = {
      autoSize = false,
      size = size,
      align = ui.ALIGNMENT.Center,
      horizontal = true,
    },
    content = ui.content {}
  }
  box.layout.content:add(flex)
  local button = {
    template = I.MWUI.templates.textNormal,
    type = ui.TYPE.Text,
    props = {
      multiline = true,
      text = tostring(text),
      relativePosition = util.vector2(0.5,1),
      textSize = 16,
      textColor = fontNormal,
    },
  }
  flex.events = {
    focusGain = async:callback(function(data, elem)
      button.props.textColor = fontOver    

      if uiActive then
        box:update()
      end
    end),
    focusLoss = async:callback(function(data, elem)
      button.props.textColor = fontNormal
      if uiActive then
        box:update()
      end
    end),
    mousePress = async:callback(function(data, elem)
      button.props.textColor = fontPressed
      if uiActive then
        box:update()
      end
    end),
    mouseRelease = async:callback(function(data, elem)
      button.props.textColor = fontNormal
      ambient.playSound(sound, {volume =0.9})
      
      func(args)
      
      if uiActive then
        box:update()
      end
    end),
  }
  flex.content:add(button)
  return box
end

local function imgButton(img, size, sound, func, args)
  local box = ui.create {
    type = ui.TYPE.Container,
    props = {},
    content = ui.content {}
  }
  local flex = {
    type = ui.TYPE.Flex,
    props = {
      autoSize = false,
      size = size,
      align = ui.ALIGNMENT.Center,
      horizontal = true,
    },
    content = ui.content {}
  }
  box.layout.content:add(flex)
  local button = {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture { path = img },
        tileH = false,
        tileV = false,
        relativePosition = v2(0,0),
        size = size,
        alpha = 1.0,
        color = iconColor,
      },
    }
  flex.events = {
    focusGain = async:callback(function(data, elem)
      button.props.textColor = fontOver    

      if uiActive then
        box:update()
      end
    end),
    focusLoss = async:callback(function(data, elem)
      button.props.textColor = fontNormal
      if uiActive then
        box:update()
      end
    end),
    mousePress = async:callback(function(data, elem)
      button.props.textColor = fontPressed
      if uiActive then
        box:update()
      end
    end),
    mouseRelease = async:callback(function(data, elem)
      button.props.textColor = fontNormal
      ambient.playSound(sound, {volume =0.9})
      
      func(args)
      
      if uiActive then
        box:update()
      end
    end),
  }
  flex.content:add(button)
  return box
end

local function modIndex(data)
  local tab, key, amt = data.tab, data.key, data.amt
  
  tab[key] = tab[key] + amt
  
  --print(key .. "|" .. tab[key])
  
  self:sendEvent('BIB_destroyUI', {})
  self:sendEvent('BIB_createUI', "")
  
  --uiMain:update()
end

local function getBulkDiscount(value, amt)
  if value == 0 or amt == 0 then
    return 0
  end

  return math.floor(value - (value * math.log10(amt) * 0.1))
end

local function createInvoice(data)
  local trader, value, discount = data.trader, data.value, data.discount

  local items = {}
  
  --print("test1")
  
  local num = 0
  
  for k,v in pairs(qtyCurrent) do
    if v > 0 then
      items[k] = v
      --print(k..":"..v)
      num = num + v
    end
  end
  
  local playerGoldObj = self.type.inventory(self):find("gold_001")
  local playerGold = 0
  
  if playerGoldObj then
    playerGold = playerGoldObj.count
  end
  
  if playerGold < value then
    ambient.playSound("enchant fail", {volume =0.9})
    self:sendEvent('BIB_destroyUI', {})
    self:sendEvent('BIB_createUI', "Not enough gold")
  else
    if num > 0 then
      ambient.playSound("item gold up", {volume =0.9})
      ambient.playSound("item book up", {volume =0.9})
      
      I.SkillProgression.skillUsed("mercantile", {skillGain = discount * 0.1, useType = 0})
      
      core.sendGlobalEvent('BIB_CreateInvoice', {self = self, trader = trader, items = items})
      core.sendGlobalEvent('BIB_PayGold', {gold = playerGoldObj, price = value})
      self:sendEvent('BIB_destroyUI', {})
    else
      ambient.playSound("enchant fail", {volume =0.9})
      self:sendEvent('BIB_destroyUI', {})
      self:sendEvent('BIB_createUI', "No items selected")
    end
  end
end

local function doPickup()
  local books = self.type.inventory(self):getAll(types.Book)
  
  local invoice
  
  local message = ""
  
  for k,v in ipairs(books) do
    local record = v.type.record(v)
    local id = record.id
    
    if string.find(id, "Generated") then
      local name = record.name

      if string.find(name, "Merchant Invoice, ") and not string.find(name, "FILLED") then
      
        local startindex, endindex = string.find(name, "Merchant Invoice, ")
        local nextString = string.sub(name,endindex+1,string.len(name))
        
        startindex, endindex = string.find(nextString, ", ")
        
        --NAME
        local traderNameParsed = string.sub(nextString,1,startindex-1)
        
        local traderRecord = currentDialogueNPC.type.record(currentDialogueNPC)
        local traderName = traderRecord.name
        
        if traderNameParsed == traderName then
          invoice = v
          break
        end 
      end
    end
  end

  if invoice then
    local record = types.Book.record(invoice)
    local nextString = record.text

    --DATE
    local startindex, endindex = string.find(nextString, "### mnemospore data ###>\n")
    
    nextString = string.sub(nextString,endindex+1,string.len(nextString))
    startindex, endindex = string.find(nextString, ":")
    local timestamp = string.sub(nextString,1,startindex-1)

    local gameTime = calendar.gameTime()
    
    local timeNum = tonumber(timestamp)
    
    --print(timeNum)
    --print(gameTime)
    
    --print(timeNum < gameTime)
    
    if timeNum < gameTime then
      local items = {}
    
      while string.len(nextString) > 0 do
        nextString = string.sub(nextString,endindex+1,string.len(nextString))
        startindex, endindex = string.find(nextString, ",")
        local itemId
        local itemAmt
        if startindex then
          itemId = string.sub(nextString,1,startindex-1)
          --print("id: " .. itemId)
        
          nextString = string.sub(nextString,endindex+1,string.len(nextString))
          startindex, endindex = string.find(nextString, ":")
          itemAmt = string.sub(nextString,1,startindex-1)
          
          --print("amt: " .. itemAmt)
          
          items[itemId] = itemAmt
        else
          nextString = ""
        end
      end
      
      --printTable(items)
      
      ambient.playSound("item misc up", {volume =0.9})
      
      core.sendGlobalEvent('BIB_FillInvoice', {self = self, items = items, invoice = invoice})
      self:sendEvent('BIB_destroyUI', {})
      
      return
    else
      message = "Pickup not ready"
    end
  else
    message = "Invoice not found"
  end
  
  ambient.playSound("enchant fail", {volume =0.9})
  self:sendEvent('BIB_destroyUI', {})
  self:sendEvent('BIB_createUI', message)
end

local spacer = ui.create {
  template = I.MWUI.templates.textNormal,
  type = ui.TYPE.Text,
  props = {
    multiline = false,
    text = " ",
    textSize = 16
  },
}

local function createUI(message)

  uiActive = true

  local items = {}
  
  local traderRecord = currentDialogueNPC.type.record(currentDialogueNPC)
  local trader = traderRecord.name
  
  if #itemsCurrent == 0 then
    items = getMerchantItems(currentDialogueNPC)
    itemsCurrent = items
  else
    items = itemsCurrent
  end

  if qtyKeys == 0 then
    for k,v in ipairs(items) do
      local record = v.type.record(v)
      local id = record.id
      qtyCurrent[id] = 0
      qtyKeys = qtyKeys + 1
    end
  end

  uiMain = ui.create {
    template = I.MWUI.templates.boxSolidThick,
    layer = 'Modal',
    type = ui.TYPE.Container,
    props = {
      anchor = v2(0.5,0.5),
      relativePosition = v2(0.5,0.5),
    },
    content = ui.content {}
  }
  
  uiPadding = ui.create {
    template = I.MWUI.templates.padding,
    type = ui.TYPE.Container,
    props = {},
    content = ui.content {}
  } 
  uiMain.layout.content:add(uiPadding)
  
  local width = 800
  
  local mainFlex = {
    type = ui.TYPE.Flex,
    props = {
      autoSize = true,
      --size = v2(width,600),
      arrange = ui.ALIGNMENT.Center,
      align = ui.ALIGNMENT.Center,
      horizontal = false,
    },
    content = ui.content {}
  }
  uiPadding.layout.content:add(paddedBox(mainFlex, I.MWUI.templates.boxSolid))
  
  local windowWidth = 600
  
  local scrollWidth = 12
  local entryHeight = 32
  local numEntries = 10
  local entryWidth = windowWidth - scrollWidth - 4
  
  local inventorySize = v2(windowWidth,(entryHeight * numEntries) + 4)
  
  local inventoryWrapperBox = ui.create {
    --template = I.MWUI.templates.box,
    type = ui.TYPE.Container,
    props = {
      relativePosition = v2(0,0),
      anchor = v2(0,0),
    },
    content = ui.content {}
  }
  mainFlex.content:add(inventoryWrapperBox)
  
  local inventoryWrapperFlex = {
    type = ui.TYPE.Flex,
    props = {
      autoSize = false,
      size = inventorySize,
      arrange = ui.ALIGNMENT.Start,
      align = ui.ALIGNMENT.Start,
      horizontal = true,
    },
    content = ui.content {}
  }
  inventoryWrapperBox.layout.content:add(inventoryWrapperFlex)
  
  local inventoryObjectWrapperBox = ui.create {
    type = ui.TYPE.Container,
    props = {
      relativePosition = v2(0,0),
      anchor = v2(0,0),
    },
    content = ui.content {}
  }
  inventoryWrapperFlex.content:add(inventoryObjectWrapperBox)
  
  local inventoryObjectWrapperFlex = {
    type = ui.TYPE.Flex,
    props = {
      position = v2(0,(-1*scrollPosition) * math.max(#items-numEntries,1) * (entryHeight+4)),
      anchor = v2(0,0),
      autoSize = false,
      size = v2(entryWidth,(entryHeight * numEntries)*100),
      arrange = ui.ALIGNMENT.Start,
      horizontal = false,
    },
    content = ui.content {}
  }
  inventoryObjectWrapperBox.layout.content:add(inventoryObjectWrapperFlex)
  
  --------------
  --Scroll Bar--
  --------------
  
  local barHeight = ((entryHeight) * numEntries)
  
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
  inventoryWrapperFlex.content:add(entryScrollBox)
  
  local entryScroll = {
    props = {
      autoSize = false,
      size = v2(scrollWidth,barHeight),
    },
    content = ui.content {}
  }
  entryScrollBox.layout.content:add(entryScroll)
  
  local thumbY = math.min(1, (numEntries / #items)) * barHeight 
  
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
				local scrollContainerHeight = entryHeight * numEntries
				local thumbHeight = elem.props.size.y
				local availableScrollDistance = scrollContainerHeight - thumbHeight
        
				if availableScrollDistance > 0 then
					local deltaY = data.position.y - elem.userData.dragStartY
					local newThumbY = math.max(0, math.min(availableScrollDistance, elem.userData.dragStartThumbY + deltaY))
					
					local newScrollPosition = math.max(0, math.min(1, newThumbY / availableScrollDistance))
          
          
          scrollPosition = newScrollPosition
          
          entryScrollThumb.props.position = v2(0,scrollPosition*(barHeight-thumbHeight))
          
          entryScrollBox:update()
          
          inventoryObjectWrapperFlex.props.position = v2(0,(-1*scrollPosition) * math.max(#items-numEntries,1) * (entryHeight+4))
          inventoryObjectWrapperBox:update()
          
				end
			end
		end),
  }
  
  for k,v in ipairs(items) do
  
    local spacer = ui.create {
      template = I.MWUI.templates.textNormal,
      type = ui.TYPE.Text,
      props = {
        multiline = false,
        text = " ",
        textSize = 16
      },
    }
  
    ---------
    --Entry--
    ---------
    
    local record = v.type.record(v)
    local id = record.id
    local name = record.name
    local itemValue = math.max(1,getBarterOffer(currentDialogueNPC, getEffectiveValue(v, 1), true))
    
    local entryBox = ui.create {
      template = I.MWUI.templates.box,
      type = ui.TYPE.Container,
      props = {
        position = v2(0,0),
        anchor = v2(0,0),
      },
      content = ui.content {}
    }
    inventoryObjectWrapperFlex.content:add(entryBox)
    
    local entryFlex = {
      type = ui.TYPE.Flex,
      props = {
        position = v2(0,0),
        anchor = v2(0,0),
        autoSize = false,
        size = v2(entryWidth,entryHeight),
        arrange = ui.ALIGNMENT.Center,
        align = ui.ALIGNMENT.Start,
        horizontal = true,
      },
      content = ui.content {}
    }
    entryBox.layout.content:add(entryFlex)
    
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
    entryFlex.content:add(imgBox)
    
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
    
    local entryTitleFlex = {
      type = ui.TYPE.Flex,
      props = {
        position = v2(0,0),
        anchor = v2(0,0),
        autoSize = false,
        size = v2(240,entryHeight),
        arrange = ui.ALIGNMENT.Center,
        align = ui.ALIGNMENT.Start,
        horizontal = true,
      },
      content = ui.content {}
    }
    entryFlex.content:add(paddedBox(entryTitleFlex,I.MWUI.templates.box))
    
    local entryTitle = ui.create {
      template = I.MWUI.templates.textHeader,
      type = ui.TYPE.Text,
      props = {
        text = tostring(name),
        relativePosition = util.vector2(0,0),
        textColor = fontNormal,
      },
    }
    entryTitleFlex.content:add(entryTitle)
    
    local entryValueFlex = {
      type = ui.TYPE.Flex,
      props = {
        position = v2(0,0),
        anchor = v2(0,0),
        autoSize = false,
        size = v2(60,entryHeight),
        arrange = ui.ALIGNMENT.Center,
        align = ui.ALIGNMENT.Start,
        horizontal = true,
      },
      content = ui.content {}
    }
    entryFlex.content:add(paddedBox(entryValueFlex,I.MWUI.templates.box))
    
    local entryValue = ui.create {
      template = I.MWUI.templates.textNormal,
      type = ui.TYPE.Text,
      props = {
        text = itemValue .. " gp",
        relativePosition = util.vector2(0,0),
        textColor = fontNormal,
      },
    }
    entryValueFlex.content:add(entryValue)
    
    local entryAmtFlex = {
      type = ui.TYPE.Flex,
      props = {
        position = v2(0,0),
        anchor = v2(0,0),
        autoSize = false,
        size = v2(140,entryHeight),
        arrange = ui.ALIGNMENT.Center,
        align = ui.ALIGNMENT.Start,
        horizontal = true,
      },
      content = ui.content {}
    }
    entryFlex.content:add(paddedBox(entryAmtFlex, I.MWUI.templates.box))
    
    local entryAmtFlexOne = {
      type = ui.TYPE.Flex,
      props = {
        position = v2(0,0),
        anchor = v2(0,0),
        autoSize = true,
        arrange = ui.ALIGNMENT.Center,
        align = ui.ALIGNMENT.Start,
        horizontal = false,
      },
      content = ui.content {}
    }
    entryAmtFlex.content:add(entryAmtFlexOne)
    
    entryAmtFlexOne.content:add(imgButton("textures/menu_scroll_up.dds", v2(12,12), buttonSound, modIndex, {tab = qtyCurrent, key = id, amt = 1}))
    entryAmtFlexOne.content:add(imgButton("textures/menu_scroll_down.dds", v2(12,12), buttonSound, modIndex, {tab = qtyCurrent, key = id, amt = -1}))
    
    local entryAmtOne = ui.create {
      template = I.MWUI.templates.textNormal,
      type = ui.TYPE.Text,
      props = {
        text = "1",
        relativePosition = util.vector2(0,0),
        textColor = fontNormal,
      },
    }
    entryAmtFlex.content:add(entryAmtOne)
    
    entryAmtFlex.content:add(spacer)
    
    local entryAmtFlexTen = {
      type = ui.TYPE.Flex,
      props = {
        position = v2(0,0),
        anchor = v2(0,0),
        autoSize = true,
        arrange = ui.ALIGNMENT.Center,
        align = ui.ALIGNMENT.Start,
        horizontal = false,
      },
      content = ui.content {}
    }
    entryAmtFlex.content:add(entryAmtFlexTen)
    
    entryAmtFlexTen.content:add(imgButton("textures/menu_scroll_up.dds", v2(12,12), buttonSound, modIndex, {tab = qtyCurrent, key = id, amt = 10}))
    entryAmtFlexTen.content:add(imgButton("textures/menu_scroll_down.dds", v2(12,12), buttonSound, modIndex, {tab = qtyCurrent, key = id, amt = -10}))
    
    local entryAmtTen = ui.create {
      template = I.MWUI.templates.textNormal,
      type = ui.TYPE.Text,
      props = {
        text = "10",
        relativePosition = util.vector2(0,0),
        textColor = fontNormal,
      },
    }
    entryAmtFlex.content:add(entryAmtTen)
    
    entryAmtFlex.content:add(spacer)
    
    local entryAmtFlexHun = {
      type = ui.TYPE.Flex,
      props = {
        position = v2(0,0),
        anchor = v2(0,0),
        autoSize = true,
        arrange = ui.ALIGNMENT.Center,
        align = ui.ALIGNMENT.Start,
        horizontal = false,
      },
      content = ui.content {}
    }
    entryAmtFlex.content:add(entryAmtFlexHun)
    
    entryAmtFlexHun.content:add(imgButton("textures/menu_scroll_up.dds", v2(12,12), buttonSound, modIndex, {tab = qtyCurrent, key = id, amt = 100}))
    entryAmtFlexHun.content:add(imgButton("textures/menu_scroll_down.dds", v2(12,12), buttonSound, modIndex, {tab = qtyCurrent, key = id, amt = -100}))
    
    local entryAmtHun = ui.create {
      template = I.MWUI.templates.textNormal,
      type = ui.TYPE.Text,
      props = {
        text = "100",
        relativePosition = util.vector2(0,0),
        textColor = fontNormal,
      },
    }
    entryAmtFlex.content:add(entryAmtHun)
    
    entryAmtFlex.content:add(spacer)
    entryAmtFlex.content:add(spacer)
    
    local entryAmtTotal = ui.create {
      template = I.MWUI.templates.textNormal,
      type = ui.TYPE.Text,
      props = {
        text = tostring(qtyCurrent[id]),
        relativePosition = util.vector2(0,0),
        textSize = 20,
        textColor = fontCount,
      },
    }
    entryAmtFlex.content:add(entryAmtTotal)
    
    local entryValueTotalText = ui.create {
      template = I.MWUI.templates.textHeader,
      type = ui.TYPE.Text,
      props = {
        text = "Value: \nBulk: ",
        relativePosition = util.vector2(0,0),
        textColor = fontNormal,
        textSize = 12,
        multiline = true,
      },
    }
    entryFlex.content:add(entryValueTotalText)
    
    local subTotalValue = itemValue * qtyCurrent[id]
    
    local totalValue = getBulkDiscount(subTotalValue, qtyCurrent[id])
    
    local entryValueTotalText = ui.create {
      template = I.MWUI.templates.textHeader,
      type = ui.TYPE.Text,
      props = {
        text = subTotalValue .. " gp\n" .. totalValue .. " gp",
        relativePosition = util.vector2(0,0),
        textColor = fontCount,
        textSize = 12,
        multiline = true,
      },
    }
    entryFlex.content:add(entryValueTotalText)
  end
  
  local footerFlex = {
    type = ui.TYPE.Flex,
    props = {
      position = v2(0,0),
      anchor = v2(0,0),
      autoSize = false,
      size = v2(inventorySize.x-8,256),
      arrange = ui.ALIGNMENT.Center,
      align = ui.ALIGNMENT.Center,
      horizontal = false,
    },
    content = ui.content {}
  }
  mainFlex.content:add(paddedBox(footerFlex, I.MWUI.templates.box))
  
  local footerFlexH = {
    type = ui.TYPE.Flex,
    props = {
      position = v2(0,0),
      anchor = v2(0,0),
      autoSize = false,
      size = v2(inventorySize.x-8,128),
      arrange = ui.ALIGNMENT.Start,
      align = ui.ALIGNMENT.Start,
      horizontal = true,
    },
    content = ui.content {}
  }
  footerFlex.content:add(footerFlexH)
  
  local statsFlex = {
    type = ui.TYPE.Flex,
    props = {
      position = v2(0,0),
      anchor = v2(0,0),
      autoSize = false,
      size = v2(340,128),
      arrange = ui.ALIGNMENT.Start,
      align = ui.ALIGNMENT.Start,
      horizontal = true,
    },
    content = ui.content {}
  }
  footerFlexH.content:add(statsFlex)
  
  local statsText = ui.create {
    template = I.MWUI.templates.textHeader,
    type = ui.TYPE.Text,
    props = {
      text = "Trader: \nFaction: \n\nYour Gold: ",
      relativePosition = util.vector2(0,0),
      textColor = fontNormal,
      multiline = true,
    },
  }
  statsFlex.content:add(statsText)
  
  
  local faction
  local factionName = "None"
  
  local playerGoldObj = self.type.inventory(self):find("gold_001")
  local playerGold = 0
  
  if playerGoldObj then
    playerGold = playerGoldObj.count
  end
  
  if traderRecord.primaryFaction then
    faction = core.factions.records[traderRecord.primaryFaction]
    factionName = faction.name
  end
  
  local statsTextNum = ui.create {
    template = I.MWUI.templates.textHeader,
    type = ui.TYPE.Text,
    props = {
      text = trader .. '\n' .. factionName .. '\n\n' .. playerGold .. ' gp',
      relativePosition = util.vector2(0,0),
      textColor = fontCount,
      multiline = true,
    },
  }
  statsFlex.content:add(statsTextNum)
  
  -----------
  -- TOTAL --
  -----------
  
  local tariffsRate = 0.1
  
  local playerFactions = types.NPC.getFactions(self)
  
  local shippingRate = 2
  local processingFee = 10
  
  local subtotal = 0
  local tariffs = 0
  local shipping = 0
  local total = 0
  local weight = 0
  
  local discount = 0
  
  if faction then
    for k,v in ipairs(playerFactions) do 
      if v == faction.id and types.NPC.getFactionRank(self, v) >= 4 then
        tariffsRate = 0
        --break
      end
      
    end
  end
  
  --print(faction.id)
  --printTable(playerFactions)
  
  for k,v in ipairs(items) do
    local record = v.type.record(v)
    local id = record.id
    local itemValue = math.max(1,getBarterOffer(currentDialogueNPC, getEffectiveValue(v, 1), true))
    
    local qty = qtyCurrent[id]
    
    local newValue = getBulkDiscount(itemValue * qty, qty)
    
    discount = discount + ((itemValue * qty) - newValue)
    
    subtotal = subtotal + newValue
    
    tariffs = tariffs + newValue * tariffsRate
    
    local itemWeight = record.weight * qty
    
    weight = weight + itemWeight 
    
    shipping = shipping + (itemWeight * shippingRate)
  end
  
  --print(discount)
  
  tariffs = math.floor(tariffs)
  shipping = math.floor(shipping)
  
  total = subtotal + tariffs + shipping
  
  if total > 0 then
    total = total + processingFee
  end
  
  local totalFlex = {
    type = ui.TYPE.Flex,
    props = {
      position = v2(0,0),
      anchor = v2(0,0),
      autoSize = false,
      size = v2(inventorySize.x-8,128),
      arrange = ui.ALIGNMENT.Start,
      align = ui.ALIGNMENT.Start,
      horizontal = true,
    },
    content = ui.content {}
  }
  footerFlexH.content:add(totalFlex)
  
  local totalText = ui.create {
    template = I.MWUI.templates.textHeader,
    type = ui.TYPE.Text,
    props = {
      text = "Subtotal: \nTariffs (" .. tariffsRate * 100 .. "%): \nShipping (".. string.format("%.2f", weight) .." lbs): \nProcessing: \n                             \nTotal: ",
      relativePosition = util.vector2(0,0),
      textColor = fontNormal,
      multiline = true,
    },
  }
  totalFlex.content:add(totalText)
  
  local totalTextNum = ui.create {
    template = I.MWUI.templates.textHeader,
    type = ui.TYPE.Text,
    props = {
      text = subtotal .. " gp\n" .. tariffs .. " gp\n" .. shipping .. " gp\n" .. processingFee .. " gp\n\n" .. total .. " gp",
      relativePosition = util.vector2(0,0),
      textColor = fontNormal,
      multiline = true,
    },
  }
  totalFlex.content:add(totalTextNum)
  
  local buttonFlex = {
    type = ui.TYPE.Flex,
    props = {
      position = v2(0,0),
      anchor = v2(0,0),
      autoSize = false,
      size = v2(inventorySize.x-8,64),
      arrange = ui.ALIGNMENT.Center,
      align = ui.ALIGNMENT.Center,
      horizontal = true,
    },
    content = ui.content {}
  }
  footerFlex.content:add(buttonFlex)
  
  local buyButtonSize = v2(128,20)
  
  buttonFlex.content:add(paddedBox(textButton("Pickup Order", buyButtonSize, buttonSound, doPickup, {}), I.MWUI.templates.boxSolidThick))
  
  buttonFlex.content:add(spacer)
  buttonFlex.content:add(spacer)
  buttonFlex.content:add(spacer)
  
  buttonFlex.content:add(paddedBox(textButton("Place Order", buyButtonSize, buttonSound, createInvoice, {trader = traderRecord.id, value = total, discount = discount}), I.MWUI.templates.boxSolidThick))
  
  local endMessage = ui.create {
    template = I.MWUI.templates.textNormal,
    type = ui.TYPE.Text,
    props = {
      text = message,
      relativePosition = util.vector2(0,0),
      textColor = fontNegative,
      multiline = true,
    },
  }
  footerFlex.content:add(endMessage)
end

local function destroyUI()
  if uiActive and uiMain then
    uiActive = false
    uiMain:destroy()
    uiMain = {}
  end
end

function handleUiModeChanged(data)
  destroyUI()
  
  if data.newMode == "Dialogue" and data.arg then
		currentDialogueNPC = data.arg
    --createUI()
	end
  
  if data.oldMode == "Dialogue" then
    itemsCurrent = {}
    qtyCurrent = {}
    qtyKeys = 0
  end
end

local function handleResponse(data)
  destroyUI()
  
  local actor = data.actor
  local id = core.dialogue[data.type].records[data.recordId].id;
  if id == "- order" then
    createUI("")
  end
end

return {
  engineHandlers = {
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
    BIB_createUI = createUI,
    BIB_destroyUI = destroyUI,
  },
}