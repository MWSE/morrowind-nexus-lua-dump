local core = require('openmw.core')
local ui = require('openmw.ui')
local util = require('openmw.util')
local I = require('openmw.interfaces')
local async = require('openmw.async')
local types = require('openmw.types')
local self = require('openmw.self')
local storage = require('openmw.storage')
local nearby = require('openmw.nearby')

local v2 = util.vector2
local screenSize = ui.screenSize()
local uiSize = v2(screenSize.x*0.8,screenSize.y*0.75)
local uiInnerSize = v2(uiSize.x*0.72,uiSize.y*0.9)
local uiListSize = v2(uiInnerSize.x*0.47,uiInnerSize.y)
local arrowSize = v2(uiSize.x*0.01,uiSize.y*0.02)
local buttonSize = v2(uiSize.x*0.5,uiSize.y*0.1)

local bgTexture = ui.texture{
  path = "textures/tx_menubook.dds"
}

local ritualHeader = {
  type = ui.TYPE.TextEdit,
  name = "Search",
  template = I.MWUI.templates.textEditList,
  props = {
    text = "Search rituals",
    textSize = 32,
    textColor = util.color.rgb(0,0,0),
    autoSize = false,
    size = v2(32,32),
    relativeSize = v2(1,0),
    relativePosition = v2(0.08,0.5),
    anchor = v2(0,0.5),
  },
  events = {
    textChanged = async:callback(
      function(t,layout)
      -- is there any better way? YEAH PROBABLY
        layout.props.text = t
        self:sendEvent('R_UpdateRitualList',{pattern = t})
      end
    ),
  },
}

local text = {
  type = ui.TYPE.Text,
  template = I.MWUI.templates.textHeader,
  props = {
    text = "TESTTEXT",
    textSize = 27,
    textColor = util.color.rgb(0,0,0),
    relativePosition = v2(0.1,0)
  },
}

local function addName(id,name)
  return {
    type = ui.TYPE.Text,
    props = {
      text = name,
      textSize = 27,
      textColor = util.color.rgb(0,0,0),
      relativePosition = v2(0.1,0),
      id = id,
    },
    events = {
      mouseClick = async:callback(
        function(_,layout)
          layout.props.textColor = util.color.hex("bf2a24")
          self:sendEvent('R_RitualSelected',{id=layout.props.id})
          return true
         end
        ),
    },
  }
end

--local function testing()
--  local list = {ritualHeader}
--  for i=1,30 do
--    table.insert(list,text)
--  end
--  return list
--end

local ritualListFlex = {
  name = "RitualListInner",
  type = ui.TYPE.Flex,
  props = {
    autoSize = false,
    position = v2(0,0),
--    relativePosition = v2(0,0.05),
--    size = v2(uiListSize.x,uiListSize.y-uiListSize.y*0.1),
    relativeSize = v2(1,10),
    selectedIndex = nil,
  },
  events = {
  -- nice arrow >>>
    mouseClick = async:callback(
      function(_,layout)
        if layout.props.selectedIndex ~= nil and layout.props.selectedIndex > #layout.content then layout.props.selectedIndex = nil end
        for i,l in ipairs(layout.content) do
          if l.props.textColor == util.color.hex("bf2a24") then
            if layout.props.selectedIndex == nil then
              layout.props.selectedIndex = i
              break
            else
              if layout.props.selectedIndex ~= i then
                local prev = layout.props.selectedIndex
                if prev ~= nil and layout.content[prev] ~= nil then
                  layout.content[layout.props.selectedIndex].props.textColor = util.color.rgb(0,0,0)
                end
                layout.props.selectedIndex = i
                break
              end
            end
          end
        end
        ui.updateAll()
      end
    ),
    focusGain = async:callback(function() self:sendEvent('R_FocusEvent',{ui='ritualList',focus=true}) end),
    focusLoss = async:callback(function() self:sendEvent('R_FocusEvent',{ui='ritualList',focus=false}) end)
  },
  content = ui.content{},
}

local ritualListWidget = {
  name = "RitualListOuter",
  type = ui.TYPE.Widget,
  props = {
    size = v2(uiListSize.x,uiListSize.y-uiListSize.y*0.15),
    relativePosition = v2(0,0.0505),
    textSize = 27,
  },
  events = {
    mouseClick = async:callback(
      function(_,layout)
        if layout.content.DescArrowUp.props.clicked then
          local pos = layout.content.RitualListInner.props.position
          if pos.y < 0 then
            pos = v2(pos.x,pos.y+layout.props.textSize)
          end
          layout.content.RitualListInner.props.position = pos
          layout.content.DescArrowUp.props.clicked = false
          ui.updateAll()
        elseif layout.content.DescArrowDown.props.clicked then
          local pos = layout.content.RitualListInner.props.position
          pos = v2(pos.x,pos.y-layout.props.textSize)
          layout.content.RitualListInner.props.position = pos
          layout.content.DescArrowDown.props.clicked = false
          ui.updateAll()
        end
      end
    ),
  },
  content = ui.content{
  ritualListFlex,
      {
      type = ui.TYPE.Image,
      name = "DescArrowUp",
      props = {
        resource = ui.texture{path="textures/omw_menu_scroll_up.dds"},
        size = arrowSize,
        relativePosition = v2(0.92,0),
        clicked = false,
      },
      events = {
        mouseClick = async:callback(
          function(_,layout)
            layout.props.clicked = true
            return true
          end
        ),
      },
    },
    
    {
      type = ui.TYPE.Image,
      name = "DescArrowDown",
      props = {
        resource = ui.texture{path="textures/omw_menu_scroll_down.dds"},
        size = arrowSize,
        relativePosition = v2(0.92,0.97),
      },
      events = {
        mouseClick = async:callback(
          function(_,layout)
            layout.props.clicked = true
            return true
          end
        ),
      },
    },
  },
}

local descTitle = {
  type = ui.TYPE.Text,
  template = I.MWUI.templates.textHeader,
  name = "Title",
  props = {
    text = "RITUAL TITLE THAT IS REALLY LONG AND EXPANSIVE",
    textSize = 31,
    textColor = util.color.rgb(0,0,0),
    wordWrap = true,
    autoSize = false,
    relativeSize = v2(1,0.2)
  },
}

local descDesc = {
  type = ui.TYPE.Widget,
--  template = I.MWUI.templates.textHeader,
  name = "Desc",
  props = {
    relativePosition = v2(0,0.2),
    textSize = 27,
    textColor = util.color.rgb(0,0,0),
    wordWrap = true,
    autoSize = false,
    relativeSize = v2(1,0.3)
  },
  events = {
    mouseClick = async:callback(
      function(_,layout)
        if layout.content.DescArrowUp.props.clicked then
          local pos = layout.content.TextDescription.props.position
          if pos.y < 0 then
            pos = v2(pos.x,pos.y+layout.props.textSize)
          end
          layout.content.TextDescription.props.position = pos
          layout.content.DescArrowUp.props.clicked = false
          ui.updateAll()
        elseif layout.content.DescArrowDown.props.clicked then
          local pos = layout.content.TextDescription.props.position
          pos = v2(pos.x,pos.y-layout.props.textSize)
          layout.content.TextDescription.props.position = pos
          layout.content.DescArrowDown.props.clicked = false
          ui.updateAll()
        end
      end
    ),
    focusGain = async:callback(function() self:sendEvent('R_FocusEvent',{ui='desc',focus=true}) end),
    focusLoss = async:callback(function() self:sendEvent('R_FocusEvent',{ui='desc',focus=false}) end)
  },
  content = ui.content{
    {
      type = ui.TYPE.Text,
      template = I.MWUI.templates.textHeader,
      name = "TextDescription",
      props = {
        text = "Ritual description can be pretty long so i do have toa ccount for this by writing a really long description that will test if it will fit nicely but what it doesnt and somone makes even longer one? No one knows. But i will keep writing to make it as long as possible for the science or something... This fits a lot of text and i didint even start on ingredients page or ingridients?",
        textSize = 27,
        textColor = util.color.rgb(0,0,0),
        wordWrap = true,
        autoSize = false,
        -- Why not
        relativeSize = v2(0.9,5),
        position = v2(0,0),
      },
    },
    
    {
      type = ui.TYPE.Image,
      name = "DescArrowUp",
      props = {
        resource = ui.texture{path="textures/omw_menu_scroll_up.dds"},
        size = arrowSize,
        relativePosition = v2(0.92,0),
        clicked = false,
      },
      events = {
        mouseClick = async:callback(
          function(_,layout)
            layout.props.clicked = true
            return true
          end
        ),
      },
    },
    
    {
      type = ui.TYPE.Image,
      name = "DescArrowDown",
      props = {
        resource = ui.texture{path="textures/omw_menu_scroll_down.dds"},
        size = arrowSize,
        relativePosition = v2(0.92,0.92),
      },
      events = {
        mouseClick = async:callback(
          function(_,layout)
            layout.props.clicked = true
            return true
          end
        ),
      },
    },
    
  },
}

local function addIngred(name,current,max)
  local countStr = tostring(current).."/"..tostring(max)
  local color = util.color.hex("C71818")
  if current >= max then
    color = util.color.hex("0EC242")
  end
  return {
    type = ui.TYPE.Flex,
    props = {
      autoSize = false,
      horizontal = true,
      relativePosition = v2(0,0.52),
      relativeSize = v2(1,0.1),
    },
    content = ui.content{
      {
        type = ui.TYPE.Text,
        template = I.MWUI.templates.textHeader,
        props = {
          text = name,
          textSize = 21,
          textColor = util.color.rgb(0,0,0),
          autoSize = false,
          size = v2(0,25),
          relativeSize = v2(0.8,0),
          relativePosition = v2(0,0),
        },
      },
      {
        type = ui.TYPE.Text,
        template = I.MWUI.templates.textHeader,
        props = {
          text = countStr,
          textSize = 21,
          textColor = color,
          autoSize = false,
          size = v2(0,25),
          relativeSize = v2(0.2,0),
        },
      },
    },
  }
end

local function testLoop()
  local list = {}
  
  for i=1,20 do
    table.insert(list,ingredientLayout("Ingredient "..tostring(i)))
  end
  print(list[1].content[1].props.text)
  return list
end

local descIng = {
  type = ui.TYPE.Widget,
  name = "ingWidget",
  props = {
    relativePosition = v2(0,0.52),
    relativeSize = v2(0.92,0.35),
  },
  content = ui.content{
    {
      type = ui.TYPE.Flex,
      name = "ingList",
      props = {
        autoSize = false,
        relativePosition = v2(0,0),
        relativeSize = v2(1,1),
      },
      content = ui.content({}),
    },
  },
}

local function addEffect(name)
  -- Hey, as long as it works right? Too bad for other aspect ratios i think...
  local tSize = 27
  local diff = string.len(name) - 39
  if diff > 0 then
    tSize = tSize - diff * 0.675
  end
  return {
    type = ui.TYPE.Text,
    template = I.MWUI.templates.textNormal,
    props = {
      text=name,
      textSize = tSize,
      textColor = util.color.rgb(0,0,0),
      relativePosition = v2(0.1,0)
    },
  }
end

local descEffects = {
  type = ui.TYPE.Flex,
  name = "descEffects",
  props = {
    autoSize = false,
    relativePosition = v2(0,0.87),
    relativeSize = v2(1,0.2),
  },
  content = ui.content{},
}

local test = {
    type = ui.TYPE.Text,
    template = I.MWUI.templates.textNormal,
    props = {
    text="AAAAAAAAAAAAAAAAAAAAAA",
    textSize = 27,
    textColor = util.color.rgb(0,0,0),
    relativePosition = v2(0,0.87),
    relativeSize = v2(1,0.2),
    },
  }

local tempList = {
  type = ui.TYPE.Container,
  template = I.MWUI.templates.boxSolid,
  content = ui.content{
    {
      type = ui.TYPE.Widget,
      props = {
        size = uiListSize
      },
    }
  }
}

local descStart = {
  type = ui.TYPE.Widget,
  name = "Begin",
  props = {
    relativeSize = v2(0.45,0.15),
    relativePosition = v2(0,1),
    anchor = v2(0,0.5),
  },
  content = ui.content{
    {
      type = ui.TYPE.Text,
      name = "BeginButton",
      template = I.MWUI.templates.textNormal,
      props = {
        text = "Begin ritual",
        textSize = 31,
        textColor = util.color.rgb(0,0,0),
        relativePosition = v2(0.5,0.1),
        anchor = v2(0.5,0),
      },
      events = {
        mouseClick = async:callback(
          function(_,layout)
            print("BEGIN RITUAL")
            layout.props.textColor = util.color.hex("bf2a24")
            self:sendEvent('R_RitualBegin',{})
            ui.updateAll()
          end
        ),
      },
    },
  },
}

local description = {
      type = ui.TYPE.Widget,
      name = "Description",
      props = {
        relativePosition = v2(0.53,0),
        size = uiListSize,
      },
      content = ui.content{descTitle,descDesc,descIng,descEffects}
    }

local headerRibbon = {
  type = ui.TYPE.Image,
  name = "Ribbon",
  props = {
    relativePosition = v2(0.11,0.045),
    relativeSize = v2(0.4,0.05),
--    anchor = v2(0.03,0),
    resource = ui.texture{path="textures/ribbon.dds"},
  },
  content = ui.content{ritualHeader},
}

local chance = {
  template = I.MWUI.templates.textNormal,
  name = "chance",
  props = {
    text="Success chance: ",
    textSize = 27,
    textColor = util.color.rgb(0,0,0),
    relativePosition = v2(0.225,0.97),
    anchor = v2(0,1),
  },
}

local mainLayout = {
  name = "MainLayout",
  type = ui.TYPE.Widget,
  props = {
    autoSize = false,
    horizontal = true,
    relativePosition = v2(0.15,0.05),
    size = uiInnerSize,
  },
  content = ui.content{ritualListWidget,description,descStart},
}

local bgImage = {
  name = "bgImg",
  type = ui.TYPE.Image,
  props = {
    resource = bgTexture,
    relativeSize = v2(1,1),
    anchor = v2(0.5,0.5),
    relativePosition = v2(0.5,0.5),
  },
}


local function showBook()
  local root = ui.create{
    name = "root",
    type = ui.TYPE.Widget,
    layer = 'Windows',
    props = {
      size = uiSize,
      relativePosition = v2(0.5,0.5),
      anchor = v2(0.5,0.5),
    },
    content = ui.content({bgImage,mainLayout,headerRibbon,chance}),
  }
  
  
  
  return root
end

--eh why not
local function displayRituals(book,ritualList,pattern)
  local knownRituals = storage.playerSection('RitualsMod'):get('KnownRituals') or {}
  book.layout.content.MainLayout.content.RitualListOuter.content.RitualListInner.content = ui.content{}
  book.layout.content.MainLayout.content.RitualListOuter.content.RitualListInner.props.position = v2(0,0)
  book.layout.content.MainLayout.content.RitualListOuter.content.RitualListInner.selectedIndex = nil
  --reset the begin button while here
  book.layout.content.MainLayout.content.Begin.content.BeginButton.props.textColor = util.color.rgb(0,0,0)
  book.layout.content.chance.props.text = ""
  
  if pattern ~= nil then
    pattern = pattern:lower()
    for id,ritual in pairs(knownRituals) do
      local data = ritualList[id]
      if data ~= nil then
--        if string.match(data.name:lower(),pattern) then
        if string.find(data.name:lower(),pattern:lower(),1,true) then
          book.layout.content.MainLayout.content.RitualListOuter.content.RitualListInner.content:add(addName(id,data.name))
        end
      end
    end
  ui.updateAll()
  else
    for id,ritual in pairs(knownRituals) do
      local data = ritualList[id]
      if data ~= nil then
        book.layout.content.MainLayout.content.RitualListOuter.content.RitualListInner.content:add(addName(id,data.name))
      end
    end
  end
end

--center - center of ritual circle (position)
--item - item gameobject
-- amount - amount required by ingred
-- consumed -if the ingred is consumed
-- count - current count of item
-- table - item added to here
-- return: updated count   
local function addToTable(item,amount,consumed,count,iTable)
  local newCount = count + item.count
  if count >= amount then return newCount end
  
  if consumed then
    if newCount > amount then
      table.insert(iTable,{item=item,amount=amount-count})
    else
      table.insert(iTable,{item=item,amount=0})
    end
  end
  
  return newCount
end

local function checkOwnership(item)
  if item.owner.recordId ~= nil then
    print("Ingredient belongs to someone else!")
    return false
  end
  
  if item.owner.factionId ~= nil then
    local rank = item.owner.factionRank
    local pRank = types.NPC.getFactionRank(self,item.owner.factionId)
    if pRank == 0 or pRank < rank then
      print("Ingredient belongs to a faction too low rank to pick up!")
      return false
    end
  end
  
  return true
end

local function matchActor(actor,ingred)
  --Ignore player
  if actor.recordId == 'player' then return false end
  
  --Match dead
  if ingred.dead ~= nil then
    if ingred.dead ~= types.Actor.isDead(actor) then return false end
  end

  --Match ID
  if ingred.id ~= nil then
    if ingred.id ~= actor.recordId then return false end
  end
  
  --Match type
  if ingred.type ~= nil then
    if actor.type ~= types[ingred.type] then return false end
  end

  --Match patterns only
  if ingred.patterns ~= nil then
    local match = false
    for _,pattern in pairs(ingred.patterns) do
      if string.match(item.recordId,pattern) then match = true break end
    end
    if not match then return false end
  end

  return true
end

local function matchIngred(item,ingred)
  --Check ownership 
  if not checkOwnership(item) then return false end

  --Match ID
  if ingred.id ~= nil then
    if ingred.id ~= item.recordId then return false end
  end
  
  --Match type only
  if ingred.type ~= nil then
    if type(ingred.type) == 'table' then
      local match = false
      for _,t in pairs(ingred.type) do
        if item.type == types[t] then match = true break end
      end
      if not match then return false end
    else
      if item.type ~= types[ingred.type] then return false end
    end
  end
  
  --Match patterns only
  if ingred.patterns ~= nil then
    local match = false
    for _,pattern in pairs(ingred.patterns) do
      if string.match(item.recordId,pattern) then match = true break end
    end
    if not match then return false end
  end
  
  --Match soulTypes
  if ingred.soulTypes ~= nil then
    local soulVal = types.Item.itemData(item).soul
    if soulVal == nil then return false end
    local match = false
    for _,soul in pairs(ingred.soulTypes) do
      if string.match(soulVal,soul) then match = true break end
    end
    if not match then return false end
  end
  
  return true
end

local function ritualChance(dif)
  local myst = types.NPC.stats.skills.mysticism(self).modified
  if myst >= dif then
  return 1
  else
    local will = types.NPC.stats.attributes.willpower(self).modified
    local skill = (myst + will*0.1)
    local chance = 0.8735 + (skill - dif) * 0.02353
    return math.max(0.01,chance)
  end
end

local function showDescription(book,id,ritualList,circleObject)

--reset description position
  book.layout.content.MainLayout.content.Description.content.Desc.content.TextDescription.props.position = v2(0,0)
  book.layout.content.MainLayout.content.Begin.content.BeginButton.props.textColor = util.color.rgb(0,0,0)

  local data = ritualList[id]
  local chance = ritualChance(data.difficulty)
  chance = string.format("%.2f%%", chance * 100)
  book.layout.content.chance.props.text = "Success chance: "..chance
  
  if data.actors == nil then data.actors = {} end
  if data.ingredients == nil then data.ingredients = {} end
  if data.effects == nil then data.effects = {} end
  if data.effectsDesc == nil then data.effectsDesc = {} end
  
  --stores objects pretaining to the ritual
  local presentIngreds = {}
  
  ---TODO: sort and pick maxSouls of soulgems to check if enough
  --probably include different message in the popup to make it clear
  local presentSoulgems = {}
  
  local presentActors = {}
  
  local counts = {}
  local actorCounts = {}
  counts["soul"] = 0

  for _,ingred in pairs(data.ingredients) do
      counts[ingred.name] = 0
  end
  
  for _,actor in pairs(data.actors) do
    counts[actor.name] = 0
  end
  
  --get local ingredients  
  for _,item in pairs(nearby.items) do
    if (circleObject.position - item.position):length() <= 250 then
      local match = false
      for i,ingred in pairs(data.ingredients) do
        match = matchIngred(item,ingred)
        if match then
          counts[ingred.name] = addToTable(item,ingred.amount,ingred.consumed,counts[ingred.name],presentIngreds)
          break
        end
      end
      if not match and string.match(item.recordId,"^misc_soulgem_") then
        if checkOwnership(item) then
          local soul = types.Item.itemData(item).soul
          if soul ~= nil then
            local soulValue = types.Creature.record(soul).soulValue
            if counts["soul"] < data.soulPower then
              table.insert(presentSoulgems,item)
            end
            counts["soul"] = counts["soul"] + soulValue
          end
        end
      end
    end
  end
  
  --get local actors
  for _,actor in pairs(nearby.actors) do
    if (circleObject.position - actor.position):length() <= 150 then
      local match = false
      for i,ingred in pairs(data.actors) do
        match = matchActor(actor,ingred)
        if match then
          if counts[ingred.name] < ingred.count then
            if ingred.consumed then
              table.insert(presentActors,actor)
            end
          end
          counts[ingred.name] = counts[ingred.name] + 1
        end
      end
    end
  end
  
--  table.sort(presentSoulgems,
--  function(a,b)
--    local aSoul = types.Creature.record(types.Item.itemData(a).soul).soulValue
--    local bSoul = types.Creature.record(types.Item.itemData(b).soul).soulValue
--    return aSoul > bSoul
--  end
--   )
  
  local enough = true
  
  -- Evaluate dynamic effect values
  local evalEffects = {}
  if data.effectsEval ~= nil then
    for _,e in ipairs(data.effectsEval) do
      evalEffects[e.id] = e.eval()
    end
  end
  
  --Set the title
  book.layout.content.MainLayout.content.Description.content.Title.props.text = data.name
  --Set description
  book.layout.content.MainLayout.content.Description.content.Desc.content.TextDescription.props.text = data.desc
  
  --Set ingredients
  book.layout.content.MainLayout.content.Description.content.ingWidget.content.ingList.content = ui.content{}
  for i,ingred in pairs(data.ingredients) do
--    book.layout.content.MainLayout.content.Description.content.ingWidget.content.ingList.content:add(addIngred(ingred.name,counts[(ingred.id or ingred.name)],ingred.amount))
    book.layout.content.MainLayout.content.Description.content.ingWidget.content.ingList.content:add(addIngred(ingred.name,counts[ingred.name],ingred.amount))
--    if counts[(ingred.id or ingred.name)] < ingred.amount then enough = false end
    if counts[ingred.name] < ingred.amount then enough = false end
  end
  
  --set actors
  for i,actor in pairs(data.actors) do
    book.layout.content.MainLayout.content.Description.content.ingWidget.content.ingList.content:add(addIngred(actor.name,counts[actor.name],actor.count))
  end
  
  --aaand soul
  book.layout.content.MainLayout.content.Description.content.ingWidget.content.ingList.content:add(addIngred("Soul power",counts["soul"],data.soulPower))
  if counts["soul"] < data.soulPower then enough = false end
  
  --Set effects
  book.layout.content.MainLayout.content.Description.content.descEffects.content = ui.content{}
  for i,effect in pairs(data.effectsDesc) do
    if evalEffects[i] ~= nil then
      effect = string.format(effect,table.unpack(evalEffects[i]))
    end
    book.layout.content.MainLayout.content.Description.content.descEffects.content:add(addEffect(effect))
  end
  
  ui.updateAll()
  
  return {ingredients = presentIngreds, souls = presentSoulgems, actors=presentActors, enough = enough}
end

local function clearDescription(book)
  book.layout.content.MainLayout.content.Description.content.Title.props.text = ""
  book.layout.content.MainLayout.content.Description.content.Desc.content.TextDescription.props.text = ""
  book.layout.content.MainLayout.content.Description.content.ingWidget.content.ingList.content = ui.content{}
  book.layout.content.MainLayout.content.Description.content.descEffects.content = ui.content{}
end

local function getRitualId(book)
  local id = book.layout.content.MainLayout.content.RitualListOuter.content.RitualListInner.props.selectedIndex
  if id == nil then return nil end
  return book.layout.content.MainLayout.content.RitualListOuter.content.RitualListInner.content[id].props.id
end

local popupSize = v2(screenSize.x*0.1,screenSize.y*0.05)
local overPopupSize = v2(screenSize.x*0.2,screenSize.y*0.2)

local function removeCirclePopup(object)
  local popup = ui.create{
    type = ui.TYPE.Container,
    template = I.MWUI.templates.boxSolidThick,
    layer = 'Modal',
    props = {
      relativeSize = v2(0.2,0.1),
      relativePosition = v2(0.5,0.5),
      anchor = v2(0.5,0.5),
    },
    content = ui.content{
    {
      type = ui.TYPE.Widget,
      props = {
        size = popupSize,
      },
      content = ui.content{
        {
          type = ui.TYPE.Text,
          template = I.MWUI.templates.textNormal,
          props = {
            text = "Remove ritual circle?",
            relativePosition = v2(0.5,0.1),
            anchor = v2(0.5,0.1),
          },
        },
        {
          type = ui.TYPE.Container,
          template = I.MWUI.templates.boxSolidThick,
          props = {
            relativePosition = v2(0.1,0.9),
            anchor = v2(0,1),
          },
          content = ui.content{
            {
              type = ui.TYPE.Text,
              template = I.MWUI.templates.textNormal,
              props = {
                text = "No"
              },
              events = {mouseClick = async:callback(function() self:sendEvent('R_DestroyPopup',{}) end)}
            },
          },
        },
        
        {
          type = ui.TYPE.Container,
          template = I.MWUI.templates.boxSolidThick,
          props = {
            relativePosition = v2(0.9,0.9),
            anchor = v2(1,1),
          },
          content = ui.content{
            {
              type = ui.TYPE.Text,
              template = I.MWUI.templates.textNormal,
              props = {
                text = "Yes"
              },
              events = {mouseClick = async:callback(function() core.sendGlobalEvent('R_RemoveRitualCircle',{object=object}) self:sendEvent('R_DestroyPopup',{}) end)}
            },
          },
        },
      }
    },
    
    },
  }
  return popup
end

local function overwriteEffectPopup(conflict)
  print(conflict)
  local conflictStr = ""
  for id,_ in pairs(conflict) do
    if id ~= nil then
      local spell = core.magic.spells.records[id]
      if spell ~= nil then
        conflictStr = conflictStr..spell.name..",\n"
      else
        conflictStr = conflictStr..id..",\n"
      end
    end
  end
  
  local overwrite = false

  local popup = ui.create{
    type = ui.TYPE.Container,
    template = I.MWUI.templates.boxSolidThick,
    layer = 'Modal',
    props = {
      relativeSize = v2(0.2,0.1),
      relativePosition = v2(0.5,0.5),
      anchor = v2(0.5,0.5),
    },
    content = ui.content{
    {
      type = ui.TYPE.Widget,
      props = {
        size = overPopupSize,
      },
      content = ui.content{
        {
          type = ui.TYPE.Text,
          template = I.MWUI.templates.textNormal,
          props = {
            text = "There is already active ritual that will be lost if continued. Following effects will be removed: \n"..conflictStr,
            autoSize = false,
            relativeSize = v2(0.8,0.8),
            wordWrap = true,
            multiline = true,
            relativePosition = v2(0.5,0.1),
            anchor = v2(0.5,0.1),
          },
        },
        {
          type = ui.TYPE.Container,
          template = I.MWUI.templates.boxSolidThick,
          props = {
            relativePosition = v2(0.1,0.9),
            anchor = v2(0,1),
          },
          content = ui.content{
            {
              type = ui.TYPE.Text,
              template = I.MWUI.templates.textNormal,
              props = {
                text = "No"
              },
              events = {mouseClick = async:callback(function() self:sendEvent('R_OverwriteProceed',{overwrite=false}) end)}
            },
          },
        },
        
        {
          type = ui.TYPE.Container,
          template = I.MWUI.templates.boxSolidThick,
          props = {
            relativePosition = v2(0.9,0.9),
            anchor = v2(1,1),
          },
          content = ui.content{
            {
              type = ui.TYPE.Text,
              template = I.MWUI.templates.textNormal,
              props = {
                text = "Yes"
              },
              events = {mouseClick = async:callback(function() self:sendEvent('R_OverwriteProceed',{overwrite=true}) end)}
            },
          },
        },
      }
    },
    
    },
  }
  return popup
end

local teleSize = v2(screenSize.x*0.4,screenSize.y*0.6)

local function teleporterList(tele)
  local uiList = ui.create{
    type = ui.TYPE.Widget,
    layer = 'Modal',
    props = {
      size = teleSize,
      relativePosition = v2(0.5,0.5),
      anchor = v2(0.5,0.5),
    },
    content = ui.content{
      {
        type = ui.TYPE.Image,
        name = "scroll",
        props = {
          resource = ui.texture{path="textures/scroll.dds"},
          relativeSize = v2(1,1),
        },
        events = {
          focusGain = async:callback(function() self:sendEvent('R_FocusEvent',{ui='teleporter',focus=true}) end),
          focusLoss = async:callback(function() self:sendEvent('R_FocusEvent',{ui='teleporter',focus=false}) end)
        },
        content = ui.content{
          {
            type = ui.TYPE.Widget,
            name = "listWidget",
            props = {
              relativePosition = v2(0.1,0.2),
              relativeSize = v2(0.8,0.8),
            },
            content = ui.content{
               {
                  type = ui.TYPE.Flex,
                  name = "list",
                  props = {
                    autoSize = false,
                    position = v2(0,0),
                    relativePosition = v2(0,0),
                    relativeSize = v2(1,10),
                  },
                  external = {
                    grow = 1,
                  },
                },
            },
          },
          
          {
          type = ui.TYPE.Image,
          name = "DescArrowUp",
          props = {
            resource = ui.texture{path="textures/omw_menu_scroll_up.dds"},
            size = arrowSize,
            relativePosition = v2(0.92,0.2),
            clicked = false,
          },
        },
        
        {
          type = ui.TYPE.Image,
          name = "DescArrowDown",
          props = {
            resource = ui.texture{path="textures/omw_menu_scroll_down.dds"},
            size = arrowSize,
            relativePosition = v2(0.92,0.8),
          },
        },
          
        },
      },
    },
  }
  
--            events = {
--            mouseClick = async:callback(
--              function(_,layout)
--                layout.props.clicked = true
--                return true
--              end
--            ),
--          },
  uiList.layout.content.scroll.content.DescArrowUp.events = {
    mouseClick = async:callback(
      function(_,layout)
        local pos = uiList.layout.content.scroll.content.listWidget.content.list.props.position
        if pos.y + 27 <= 0 then
          pos = pos + v2(0,27)
        end
        uiList.layout.content.scroll.content.listWidget.content.list.props.position =  pos
        ui.updateAll()
      end
    ),
  }
  
    uiList.layout.content.scroll.content.DescArrowDown.events = {
    mouseClick = async:callback(
      function(_,layout)
        local pos = uiList.layout.content.scroll.content.listWidget.content.list.props.position
        pos = pos + v2(0,-27)
        uiList.layout.content.scroll.content.listWidget.content.list.props.position =  pos
        ui.updateAll()
      end
    ),
  }
  
  local teleporters = storage.globalSection('RitualsModGlobal'):get('Teleporters')
  local list = {}
  local currentId = tele.id
  for i,tele in pairs(teleporters) do
    if i ~= currentId then
      table.insert(list,
      {
        type = ui.TYPE.Text,
        props = {
          textSize = 27,
          text = tele.name,
          autoSize = false,
          size = v2(27,27),
          relativeSize = v2(1,0),
          anchor = v2(0.5,0),
          textAlignH = ui.ALIGNMENT.Center,
        },
--        content = ui.content{{type = ui.TYPE.Image,props={resource=ui.texture{path="texture/"},relativeSize=v2(1,1)}}},
        events = {
          mouseClick = async:callback(
          function()
            core.sendGlobalEvent('R_Teleport',{cell=tele.cell,pos=tele.pos,actor=self})
            I.UI.removeMode(I.UI.MODE.Interface)
          end)
        },
      })
    end
  end
  
  if #list == 0 then
    table.insert(list,
      {
        type = ui.TYPE.Text,
        props = {
          textSize = 27,
          text = "No desitnations",
          autoSize = false,
          size = v2(27,27),
          relativeSize = v2(1,0),
          anchor = v2(0.5,0),
          textAlignH = ui.ALIGNMENT.Center,
        },
      })
  end
  
  uiList.layout.content.scroll.content.listWidget.content.list.content = ui.content(list)
  
  I.UI.addMode(I.UI.MODE.Interface,{windows={}})
  return uiList
end

return {
  book = showBook,
  displayRituals = displayRituals,
  removeCirclePopup = removeCirclePopup,
  overwriteEffectPopup = overwriteEffectPopup,
  showDescription = showDescription,
  getRitualId = getRitualId,
  clearDescription = clearDescription,
  teleporterList = teleporterList,
}

