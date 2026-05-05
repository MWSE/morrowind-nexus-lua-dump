local core = require('openmw.core')
local types = require('openmw.types')
local self = require('openmw.self')
local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')
local auxUi = require('openmw_aux.ui')
local storage = require('openmw.storage')
local I = require('openmw.interfaces')
local calendar = require('openmw_aux.calendar')

local v2 = util.vector2

local skillId = "sky_astronomy"
local useTypes = {
  DiscoverConstellation = 1,
  DiscoverPlanet = 2,
  Stargaze = 3,
  SelectedObject = 4,
}

I.SkillFramework.registerSkill(skillId,{
  name = "Astronomy",
  description = "Astronomy is the study of the Firmament - the stars, planets and constellations. A skilled astronomer can discern their patterns, spot the planets and chart their movements.",
  attribute = "intelligence",
  icon = {fgr="textures/astronomy.dds"},
  skillGain = {
    [useTypes.DiscoverConstellation] = 40,
    [useTypes.DiscoverPlanet] = 60,
    [useTypes.Stargaze] = 5,
    [useTypes.SelectedObject] = 5,
  },
  --temp v
  startLevel = 10,
  statsWindowProp = {
    subsection = I.SkillFramework.STATS_WINDOW_SUBSECTIONS.Misc
  },
})

-- :)
local function getPrettyName(id)
  local MAP = {
      -- Attributes
      strength     = "Strength",
      intelligence = "Intelligence",
      willpower    = "Willpower",
      agility      = "Agility",
      speed        = "Speed",
      endurance    = "Endurance",
      personality  = "Personality",
      luck         = "Luck",

      -- Skills
      block        = "Block",
      armorer      = "Armorer",
      mediumarmor  = "Medium Armor",
      heavyarmor   = "Heavy Armor",
      bluntweapon  = "Blunt Weapon",
      longblade    = "Long Blade",
      axe          = "Axe",
      spear        = "Spear",
      athletics    = "Athletics",
      enchant      = "Enchant",

      destruction  = "Destruction",
      alteration   = "Alteration",
      illusion     = "Illusion",
      conjuration  = "Conjuration",
      mysticism    = "Mysticism",
      restoration  = "Restoration",
      alchemy      = "Alchemy",
      unarmored    = "Unarmored",

      security     = "Security",
      sneak        = "Sneak",
      acrobatics   = "Acrobatics",
      lightarmor   = "Light Armor",
      shortblade   = "Short Blade",
      marksman     = "Marksman",
      mercantile   = "Mercantile",
      speechcraft  = "Speechcraft",
      handtohand   = "Hand-to-Hand",
  }

  return MAP[id] or id
end

local starStorage = storage.playerSection('StarStorage')
starStorage:setLifeTime(storage.LIFE_TIME.Temporary)

local knownConstellations = starStorage:getCopy('constellations') or {}
local knownObjects = starStorage:getCopy('objects') or {}

local lastPos = nil
local screenSize = ui.layers[ui.layers.indexOf("Windows")].size
local infoSize = v2(screenSize.x*0.3,screenSize.y*0.3)

local skyMap = nil
local infoW = nil
local attune = nil
local attunedToday = false
local rawStored = false
local currentBuff = nil

local starSpawned = false

local skyCopy = nil
local drawMode = false
local startPos = nil
local endPos = nil

local objects = require('scripts.Stargazer.objects')
local constellations = require('scripts.Stargazer.constellations')
local scale = 3
local screenScale = 5
local const_dif = 25
local guard_dif = 10
local planet_dif = 60

local function skillCheck(difficulty,buff)
  local skill = I.SkillFramework.calcStatFactor('sky_astronomy')
  if buff ~= nil then skill = skill + buff end
  local scale = 10
  local successChance = (1 / (1 + math.exp(-(skill - difficulty) / scale))) * 100
  successChance = math.max(1, math.min(100, successChance))
  return math.random(1,100) <= successChance
end

local function deepCopyConstellation(tbl)
  if type(tbl) ~= "table" then
    return tbl
  end
  local copy = {}
  for k, v in pairs(tbl) do
    if k == "const" and type(v) == "table" and v.type == ui.TYPE.Widget then
      copy[k] = auxUi.deepLayoutCopy(v)
    else
      copy[k] = deepCopyConstellation(v)
    end
  end
  return copy
end

local function scaleConst(const,scale)
  local layout = const.const
  local points = const.points
  layout.props.size = layout.props.size * scale
  for _,content in pairs(layout.content) do
    if content.props and content.props.size then
      content.props.size = content.props.size * scale
      content.props.position = content.props.position * scale
    end
  end
  
  for id,point in pairs(points) do
    point.pos = point.pos * scale
  end
  
end

local drawLine = {
  type = ui.TYPE.Image,
  props = {
    resource = ui.texture{path="textures/vfx_alt_star.dds"},
    position = v2(0,0),
    size = v2(15,15),
    anchor = v2(0.5,0.5),
  },
}

-- layout with constellation stars, start,end

local objCounter = {
  template = I.MWUI.templates.textNormal,
  props = {
    position = v2(0,0),
    text = "Objects spotted: ",
    textSize = 27,
  },
}

local star = {
  type = ui.TYPE.Image,
  props = {
    resource = ui.texture{path="textures/star.dds"},
    position = v2(0,0),
    size = v2(80,80),
    anchor = v2(0.5,0.5),
  },
}

local shooting_star = {
  type = ui.TYPE.Image,
  props = {
    resource = ui.texture{path="textures/shooting_star.dds"},
    position = v2(0,0),
    size = v2(300,32),
    anchor = v2(0.5,0.5),
  },
}

local blackBg = {
  type = ui.TYPE.Image,
  props = {
    resource = ui.texture{path="white"},
    color = util.color.rgb(0,0,0),
    position = v2(0,0),
    relativeSize = v2(1,1),
  },
}

local drawingBoard = {
  name = 'drawingBoard',
  type = ui.TYPE.Widget,
  props = {
    relativeSize = v2(1,1)
  },
  content = ui.content{},
}

local sky = {
  type = ui.TYPE.Image,
  name = "Sky",
  props = {
    resource = ui.texture{path="textures/sg_sky.jpg"},
    position = v2(0,0),
    relativeSize = v2(5,5),
    tileV=true,
    tileH=true,
  },
  content = ui.content{drawingBoard},
}

local root = {
  type = ui.TYPE.Widget,
  layer = 'Windows',
  props = {
    position = v2(0,0),
    relativeSize = v2(1,1),
  },
  content = ui.content{blackBg,sky,objCounter}
}

--aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
local function getBuffString(id, count)
  local count = 0
  if type(id) == 'number' then
    count = knownConstellations[id].count
  else
    count = knownObjects[id].count
  end
  
  count = count + 1
  
  local obj = constellations[id] or objects[id]
  
  local buffs = obj.data.buffs
  
  local result = {}
  
  for _, buff in ipairs(buffs) do
    local val = math.min(buff.max, count)
    local scale = buff.scale or 1
    local power = val * scale

    if type(buff.name) == 'table' then
      for i, name in ipairs(buff.name) do
        local extraTable = buff.extra or {}
        local extra = extraTable[i] or ""
        if extra ~= "" then extra = " "..getPrettyName(extra) end
        local name = core.magic.effects.records[name].name
        table.insert(result, name..extra..": " .. power)
      end
    else
      local name = core.magic.effects.records[buff.name].name
      local extra = buff.extra or ""
      if extra ~= "" then extra = " "..getPrettyName(extra) end
      table.insert(result, name..extra..": " .. power)
    end

    count = count - 25
    if count < 1 then break end
  end

  return table.concat(result, "\n")
end

local function applyBuff(id,count)
  local obj = nil
  if type(id) == 'number' then
    obj = constellations[id]
  else
    obj = objects[id]
  end
  
  local buffs = obj.data.buffs
  local effects = types.Actor.activeEffects(self)
  
  if currentBuff ~= nil then
    for i,buff in ipairs(currentBuff) do
    --print("Removing buff: "..buff.name..": "..buff.val)
      if buff.extra ~= nil then
        if buff.name == 'fortifyattribute' then
          local stat = types.NPC.stats.attributes[buff.extra](self)
          stat.modifier = stat.modifier - buff.val
        elseif buff.name == 'fortifyskill' then
          local stat = types.NPC.stats.skills[buff.extra](self)
          stat.modifier = stat.modifier - buff.val
        end
      else
        effects:modify(-buff.val,buff.name,buff.extra)
      end
    end
  end
  
  currentBuff = {}
  
  for _,buff in ipairs(buffs) do
    local val = math.min(buff.max,count)
    local scale = buff.scale or 1
    
    for i,name in ipairs(buff.name) do
      --print("Applying buff: "..name.." "..val*scale)
      if buff.extra == nil then
        effects:modify(val*scale,name)
        table.insert(currentBuff,{name=name,extra=nil,val=val*scale})
      else
        local extra = buff.extra[i]
        if name == 'fortifyattribute' then
          local stat = types.NPC.stats.attributes[extra](self)
          stat.modifier = stat.modifier + val*scale
          table.insert(currentBuff,{name=name,extra=extra,val=val*scale})
        elseif name == 'fortifyskill' then
          local stat = types.NPC.stats.skills[extra](self)
          stat.modifier = stat.modifier + val*scale
          table.insert(currentBuff,{name=name,extra=extra,val=val*scale})
        end
      end
    end
    count = count - 25
    if count < 1 then break end
  end
end

local function attuneObj(id)
  local obj = nil
  if type(id) == 'number' then
    obj = knownConstellations[id]
  else
    obj = knownObjects[id]
  end
  
  local count = obj.count
  obj.count = count + 1
  --print("Object count:",obj.count)
  --print("new constellation attunement count:",count+1)
  attunedToday = true
  I.SkillFramework.skillUsed(skillId,{useType = useTypes.SelectedObject})
  applyBuff(id,count+1)
end

local function attunePopup(id)
  
  local obj = constellations[id] or objects[id]
  local popupText = string.format("Attune to %s? Only one object can be attuned at a time.",obj.data.name)
  local newBuffs = getBuffString(id)
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
        size = v2(screenSize.x*0.2,screenSize.y*0.2),
      },
      content = ui.content{
        {
          type = ui.TYPE.Text,
          template = I.MWUI.templates.textNormal,
          props = {
            text = popupText,
            wordWrap = true,
            multiline = true,
            autoSize = false,
            relativeSize = v2(0.9,0.3),
            relativePosition = v2(0.5,0.1),
            anchor = v2(0.5,0.1),
          },
        },
        {
          type = ui.TYPE.Text,
          template = I.MWUI.templates.textNormal,
          props = {
            text = newBuffs,
            wordWrap = true,
            multiline = true,
            autoSize = false,
            relativeSize = v2(0.9,0.4),
            relativePosition = v2(0.5,0.3),
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
              events = {mouseClick = async:callback(function() if attune then attune:destroy() end end)}
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
              events = {mouseClick = async:callback(function() if attune then attune:destroy() end attuneObj(id) end)}
            },
          },
        },
      }
    },
    
    },
  }
  return popup
end

local function createInfo(layout)
  local discovered = false
  local const = type(layout.props.nLines) == 'number'
  local id = layout.props.id
  if const then
    discovered = knownConstellations[id] ~= nil
  elseif layout.name == 'eye' then
    discovered = knownObjects[layout.props.eyeId] ~= nil
  else
    discovered = knownObjects[id] ~= nil
  end
  
  local title = "Unkown object"
  local desc = "Discover the object first to gain insight."
  local buff = "Boon: Unknown"
  
  local buffs = ""
  if discovered then
    local object = nil
    if const then
      object = constellations[id]
    elseif layout.name == 'eye' then
      object = objects[layout.props.eyeId]
    else
      object = objects[id]
    end
    
    title = object.data.name
    desc = object.data.desc
    
    for _, buff in ipairs(object.data.buffs) do
      if type(buff.name) == "table" then
        local extra = buff.extra or {}
        for i, name in ipairs(buff.name) do
          local strExtra = extra[i] or ""
          buffs = buffs .. core.magic.effects.records[name].name
          if strExtra ~= "" then
              buffs = buffs .. " " .. getPrettyName(strExtra)
          end
          buffs = buffs .. ", "
        end
      else
        local extra = buff.extra or ""
        buffs = buffs .. core.magic.effects.records[buff.name].name
        if extra ~= "" then
            buffs = buffs .. " " .. getPrettyName(extra)
        end
        buffs = buffs .. ", "
        end
    end
    
    buffs = buffs:sub(1, -3)
    buff = "Boons: "..buffs
  end
  
  local infoWidget = {
    template = I.MWUI.templates.boxSolidThick,
    layer = 'Modal',
    props = {
      position = v2(0,screenSize.y),
      anchor = v2(0,1),
      downLeft = true,
      id = id,
    },
    content = ui.content{
      {
        type = ui.TYPE.Flex,
        name = "main",
        props = {
          autoSize = false,
          position = v2(0,0),
          size = infoSize,
        },
        content = ui.content{
          {
            template = I.MWUI.templates.textHeader,
            props = {
              text = title,
              autoSize = false,
              relativeSize = v2(1,0.2),
              textSize = 30,
              textAlignH = ui.ALIGNMENT.Center,
            },
          },
          {
            template = I.MWUI.templates.textNormal,
            props = {
              text = desc,
              wordWrap = true,
              autoSize = false,
              textColor = util.color.rgb(1,1,1),
              relativeSize = v2(1,0.65),
              textSize = 23,
              textAlignH = ui.ALIGNMENT.Center,
            },
          },
          {
            template = I.MWUI.templates.textNormal,
            props = {
              text = buff,
              wordWrap = true,
              autoSize = false,
              relativeSize = v2(1,0.2),
              textSize = 25,
              textAlignH = ui.ALIGNMENT.Center,
            },
          },
        },
      },
    },
  }
  
  infoWidget.events = {
    focusGain = async:callback(
    function(_,layout)
      if layout.props.downLeft then
        layout.props.position = v2(screenSize.x,0)
        layout.props.anchor = v2(1,0)
        layout.props.downLeft = false
        --print("Moved to topright")
      else
        layout.props.position = v2(0,screenSize.y)
        layout.props.anchor = v2(0,1)
        layout.props.downLeft = true
        --print("Moved to downleft")
      end
      ui.updateAll()
    end
  )}
  
  return infoWidget
end

local pickedConsts = {}
local pickedObjs = {}

local allPositions = {}

local function pickConst(buff)
  local gameTime = calendar.gameTime()
  local month = calendar.formatGameTime("%m",gameTime)
  month = tonumber(month)
  --print("Current month: ",month)
  --print("Current const:",constellations[month].data.name)
  local const = deepCopyConstellation(constellations[month])
  --print("main const:",const.data.name)
  local charge = constellations[month].data.chargeOf
  local skill = I.SkillFramework.calcStatFactor('sky_astronomy')
  if buff ~= nil then skill = skill + buff end
  --print("ASTRONOMY SKILL:",skill)
  
  if charge then
    --print("Charge")
    if skill > const_dif then
      --print("Charge threshold passed")
      table.insert(pickedConsts,const)
    else
      if skillCheck(const_dif,buff) then table.insert(pickedConsts,const) end 
    end
    
    local guardian = deepCopyConstellation(constellations[charge])
    if skill > guard_dif then
      --print("Guardian threshold passed")
      table.insert(pickedConsts,guardian)
    else 
      if skillCheck(guard_dif,buff) then table.insert(pickedConsts,guardian) end 
    end
  else
    --print("Guardian")
    if skill > guard_dif then
      --print("Const threshold passed")
      table.insert(pickedConsts,const)
    else
      if skillCheck(guard_dif,buff) then table.insert(pickedConsts,const) end 
    end
  end
end

local function addRandomObjects(buff)
  local used = {}
  for k,v in pairs(pickedConsts) do
    used[v.data.month.id] = true
  end
  
  local unused = {}
  for k,v in pairs(constellations) do
    if not used[k] then
      table.insert(unused,v)
    end
  end
  
--  local skill = I.SkillFramework.calcStatFactor('sky_astronomy')
  local rawSkill = I.SkillFramework.getSkillStat('sky_astronomy').modified
  if buff ~= nil then rawSkill = rawSkill + buff end
  local picks = math.floor(rawSkill/10)
  --print("Rolling "..picks.." constellations")
  
  for i=1,picks do
    local rand = math.random(1,#unused)
    if skillCheck(const_dif*2,buff) then
      --print("Check passed, adding constellation")
      local const = deepCopyConstellation(unused[rand])
      table.insert(pickedConsts,const)
      table.remove(unused,rand)
      if #unused <= 0 then break end
    end
  end
  
  local objPicks = math.floor(rawSkill/12.5)
  --print("Rolling "..objPicks.." planets")
  local unusedObjs = {}
  
  for k,v in pairs(objects) do
    table.insert(unusedObjs,v.layout.props.id)
  end
 
  
  for i=1,objPicks do
    local rand = math.random(1,#unusedObjs)
    if skillCheck(planet_dif,buff) then
      local obj = objects[unusedObjs[rand]]
      table.insert(pickedObjs,obj)
      table.remove(unusedObjs,rand)
      --print("Check passed, adding planet")
      --print(obj.data.name)
    end
  end
end

local function isOverlap(rect1, rect2)
  local margin = 50
  return rect1.position.x < rect2.position.x + rect2.size.x + margin and
         rect1.position.x + rect1.size.x > rect2.position.x - margin and
         rect1.position.y < rect2.position.y + rect2.size.y + margin and
         rect1.position.y + rect1.size.y > rect2.position.y - margin
end

local function placeConst(i,const,ignore)
  local min = v2(200,200)
  local max = v2((screenSize.x*screenScale-1)-min.x,(screenSize.y*screenScale-1)-min.y)
  
  
  local attempts = 0
  while attempts < 5 do
    local randPos = v2(min.x + math.random() * (max.x-min.x),min.y + math.random() * (max.y-min.y))
    const.const.props.position = randPos
    -- allows serpent to mess up stuff
    if ignore then
      table.insert(allPositions,const.const.props)
      return
    end
    local valid = true
    
    for _,pos in ipairs(allPositions) do
      if isOverlap(const.const.props,pos) then
        valid = false
        break
      end
    end
    if valid then
      table.insert(allPositions,const.const.props)
      return
    end
    attempts = attempts + 1
  end
  
  table.remove(pickedConsts,i)
  print("[Stargazer] Constellation did not fit in the sky, removing it.")
end

local function placeObj(i,obj)
  local min = v2(200,200)
  local max = v2((screenSize.x*screenScale-1)-min.x,(screenSize.y*screenScale-1)-min.y)
  
  local attempts = 0
  while attempts < 10 do
    attempts = attempts + 1
    local randPos = v2(min.x + math.random() * (max.x-min.x),min.y + math.random() * (max.y-min.y))
    obj.layout.props.position = randPos
    local valid = true
    
    for _,pos in ipairs(allPositions) do
      if isOverlap(obj.layout.props,pos) then
        valid = false
        break
      end
    end
    if valid then
      table.insert(allPositions,obj.layout.props)
      return
    end
  end
  
  table.remove(pickedObjs,i)
end

local function randomPos()
  for i,const in ipairs(pickedConsts) do
--    scaleConst(const,scale)
    if const.const.props.id == 13 then
      placeConst(i,const,true)
    else
      placeConst(i,const)
    end
  end
  
  for i,obj in ipairs(pickedObjs) do
    placeObj(i,obj)
  end
end

local function scaleObjects()
  for i,const in ipairs(pickedConsts) do
    scaleConst(const,scale)
  end
end

local function mouseMove(mouse)
  if drawMode then
    if mouse.button == 1 then
      local box = auxUi.deepLayoutCopy(drawLine)
      box.props.position = mouse.offset
      root.content.Sky.content.drawingBoard.content:add(box)
      --ui.updateAll()
      skyMap:update()
    end

  else
    if mouse.button == 1 then
      if lastPos == nil then
        lastPos = mouse.position
      else
        local diff = lastPos - mouse.position
        local pos = root.content.Sky.props.position
        pos = pos + (diff * -1)

        pos = v2(
          math.max(-screenSize.x * (screenScale-1), math.min(pos.x, 0)),
          math.max(-screenSize.y * (screenScale-1), math.min(pos.y, 0))
        )
        root.content.Sky.props.position = pos
        lastPos = mouse.position
        --ui.updateAll()
        -- THIS EXISTS???
        skyMap:update()
      end
    else
      lastPos = nil
    end
  end
end

local function checkLine(const, startPos, endPos)
--    print("StartPos: ", startPos)
--    print("EndPos: ", endPos)

    local margin = 50
    local closestStartStar = nil
    local closestEndStar = nil
    local minStartDist = margin
    local minEndDist = margin
    
    local layout = const.const

    for i, v in ipairs(layout.content) do
--      if v.name and string.find(v.name, "star", 1, true) then
      if v.props.id ~= nil then
        local pos = v.props.position
        --print(v.id, "Local pos:", pos)

        -- Distance to start point
        local startDiff = (pos - startPos):length()
        if startDiff <= margin and startDiff < minStartDist then
          closestStartStar = v
          minStartDist = startDiff
        end

        -- Distance to end point
        local endDiff = (pos - endPos):length()
        if endDiff <= margin and endDiff < minEndDist then
          closestEndStar = v
          minEndDist = endDiff
        end
      end
    end

--    print("-------------------------------------")
--    print("Closest Start Star:", closestStartStar and closestStartStar.name or "nil")
--    print("Closest End Star:", closestEndStar and closestEndStar.name or "nil")
    
    if closestEndStar == nil or closestStartStar == nil then return end
    local points = const.points
    
    local p1 = closestStartStar.props.id
    local p2 = closestEndStar.props.id
    
    local line = nil
    
    local points1 = points[p1].lineIdx
    local points2 = points[p2].lineIdx
    
    for _,p1 in pairs(points1) do
      for _,p2 in pairs(points2) do
        if p1 == p2 then
          line = p1
          break
        end
      end
    end
    
    if line ~= nil then
      --print("Stars are next to each other")
      local l = layout.content[line]
      if not l.props.visible then
        --print("Discovered line: ",line)
        layout.content[line].props.visible = true
        layout.props.nLines = layout.props.nLines - 1
        --print("nLines:",layout.props.nLines)
        
        if layout.props.nLines == 0 then
          --print("COMPLETED")
          knownConstellations[layout.props.id] = {discovered=true,count=0}
          starStorage:set('constellations',knownConstellations)
          I.SkillFramework.skillUsed(skillId,{useType=useTypes.DiscoverConstellation})
          --print("DISCOVERED CONSTELLATION")
          if infoW then infoW:destroy() end
          core.sendGlobalEvent('Unpause', 'ui')
          local art = layout.content[1]
          for i=1,10 do
            async:newUnsavableSimulationTimer(i/10,
              function()
                local alpha = art.props.alpha
                if alpha < 1 then
                  alpha = alpha + 0.1
                  art.props.alpha = alpha
                  --ui.updateAll()
                  skyMap:update()
                end
                --print("alpha:",alpha)
                if alpha >= 0.9 then
                  core.sendGlobalEvent('Pause', 'ui')
                  --skyMap:destroy()
                  --I.UI.removeMode(I.UI.MODE.Interface)
                end
              end)
          end
        end
      end
    end
end

local function mousePress(mouse)
  if mouse.button == 1 then
    startPos = mouse.offset
    drawMode = true
  end
end

local function mouseRelease(mouse,layout,const)
  if mouse.button == 1 then
    endPos = mouse.offset
    checkLine(const,startPos,endPos)
    endPos = nil
    startPos = nil
    root.content.Sky.content.drawingBoard.content = ui.content{}
    --ui.updateAll()
    skyMap:update()
    drawMode = false
  end
end

-----TODO: Attach to every constellation that makes it
--picked_const.const.events = {
--  mousePress = async:callback(mousePress),
--  mouseRelease = async:callback(mouseRelease),
--}


local function placeStars(const)
  local layout = const.const
  local points = const.points
  for id,point in pairs(points) do
    local s = auxUi.deepLayoutCopy(star)
    s.props.position = point.pos
    s.props.id = id
    if point.eye then
      s.name = 'eye'
    end
    layout.content:add(s)
  end
end

local function showInfo(_,layout)
  local id = layout.props.id
  local new = false
  if infoW == nil then
    new = true
  else
    --print(infoW)
    --print(infoW.layout)
    --print(infoW.props)
    if infoW.layout == nil then
      new = true
    elseif infoW.layout.props.id ~= id then
      new = true
    end
  end
  
  if new then
    local widget = createInfo(layout)
    if infoW then infoW:destroy() end
    infoW = ui.create(widget)
  end
end

local function clickObject(_,layout)
  local id = layout.props.id
  if layout.props.eyeId ~= nil then id = layout.props.eyeId end
  if id == nil then return end
  local discovered = false
  if type(id) == 'number' then
    discovered = knownConstellations[id] ~= nil
  else
    discovered = knownObjects[id] ~= nil
  end
  --print("Object clicked, is attuned today:",attunedToday)
  if discovered then
    if attunedToday then
      I.UI.showInteractiveMessage("You already performed attunement today!")
      return
    end
    --print("Attuning with id:",id)
    attune = attunePopup(id)
  end
end

local function planetClick(_,layout)
  --print("Clicked planet:",layout.props.id)
  local discovered  = false
  local id = layout.props.id
  if layout.props.eyeId ~= nil then
    id = layout.props.eyeId
  end
  
  discovered = knownObjects[id] ~= nil
  
  if not discovered then
    knownObjects[id] = {discovered=true,count=0}
    I.SkillFramework.skillUsed(skillId,{useType = useTypes.DiscoverPlanet})
    if infoW then infoW:destroy() end
    infoW = nil
    showInfo(_,layout)
  else
    clickObject(_,layout)
  end
end

-----TODO: Attach to every constellation that makes it too
--placeStars(picked_const)

local function initConsts()
--  sky.content = ui.content{}
  for i,const in ipairs(pickedConsts) do
    local thisConst = const
    const.const.events = {
      mousePress = async:callback(mousePress),
      mouseClick = async:callback(clickObject),
      mouseRelease = async:callback(function(mouse,layout) mouseRelease(mouse,layout,thisConst) end),
      focusGain = async:callback(showInfo),
--      focusLoss = async:callback(function() if infoW then infoW:destroy() end end)
    }
    placeStars(const)
    if knownConstellations[const.const.props.id] ~= nil then
      --print("CONSTELLATION ALREADY DISCOVERED")
      const.const.props.alpha = 1
      const.const.props.nLines = 0
      for k,v in pairs(const.const.content) do
        if v.props then
          v.props.visible = true
          v.props.alpha = 1
        end
      end
    end
    sky.content:add(const.const)
    --print("added layout of: ",const.data.name)
  end
end

local function initObjs()
  for i,obj in ipairs(pickedObjs) do
    --print("Initing planet:",obj)
    obj.layout.events = {
      focusGain = async:callback(showInfo),
--      focusLoss = async:callback(function() if infoW then infoW:destroy() end end),
      mouseClick = async:callback(planetClick),
    }
    sky.content:add(obj.layout)
    --print("added layout of: ",obj.data.name)
  end
end

local function handleEyes()
  local eyes = {}
  local ids = {}
  for id,obj in ipairs(pickedObjs) do
    if obj.data.eye then
      --print("Eye present in sighted objects",obj.data.name)
      eyes[obj.data.eye] = obj
      ids[obj.data.eye] = id
    end
  end
  
  local guardians = {}
  for _,const in ipairs(pickedConsts) do
    if const.data.guardian then
      --print("Guardian present in sighted objects",const.data.name)
      guardians[const.data.month.id] = const
    end
  end
  -- i (heart) for loops
  for id,eye in pairs(eyes) do
    local guard = guardians[eye.data.eye]
    if guard then
      --print("Guard and eye match",guard.data.name,eye.data.name)
      --print("looking for the star")
      for i,l in pairs(sky.content) do
        --print(i,l)
        if l.props.id == eye.data.eye then
          --print("Found the eye")
          --for k,v in pairs(l.props) do print(k,v) end
          l.content.eye.props.size = l.content.eye.props.size * (1/scale)
          l.content.eye.props.resource = eye.layout.props.resource
          l.content.eye.props.eyeId = eye.layout.props.id
          l.content.eye.events = {
            mouseClick = async:callback(planetClick),
            focusGain = async:callback(showInfo),
--            focusLoss = async:callback(function() if infoW then infoW:destroy() end end),
          }
          --print("Removing original eye",eye.data.eye)
          table.remove(pickedObjs,ids[eye.data.eye])
          --print("replaced the eye")
          break
        end
      end
    end
  end
  
end

local function updateCounter()
  objCounter.props.text = "Spotted objects: "..(#pickedConsts+#pickedObjs)
end

-- wrap this in a function
--pickConst()
--addRandomObjects()
--randomPos()
--initConsts()
--handleEyes()
--initObjs()
--updateCounter()

--root.events = {mouseMove = async:callback(mouseMove)}
sky.events = {
  mouseMove = async:callback(mouseMove),
--  mousePress = async:callback(mousePress),
--  mouseRelease = async:callback(function() ui.updateAll() end),
}

--skyCopy = auxUi.deepLayoutCopy(sky)

local function uiChange(data)
  if data.oldMode == 'Interface' then
    if skyMap ~= nil then skyMap:destroy() end
    if infoW ~= nil then infoW:destroy() end
    if attune ~= nil then attune:destroy() end
  end
end



---
--sky.content = ui.content{}
--local pos = v2(0,500)
--for k,v in ipairs(constellations) do
--  scaleConst(v)
--  local const = v.const
--  const.props.position = pos
--  pos = pos + v2(400,0)
--  sky.content:add(const)
--end
--ui.updateAll()
---

--local nearby = require('openmw.nearby')
--for k,v in pairs(nearby.items) do
--  print("Object:",v.recordId)
--  print("Ownership:")
--  print("Owner:",v.owner.recordId)
--  print("Faction:",v.owner.factionId)
--  print("Rank:",v.owner.factionRank)
--  print("---------")
--end

--for k,v in pairs(nearby.actors) do
--  print("ID:",v.recordId)
--  print("TYPE:",v.type)
--end

---THE PLAN
-- stargaze once per day
-- stargazing itself gives some xp
-- some xp if things spawned in
-- big xp if solved constellation
-- some xp for "attuning" to constellation/planet (add coutner to stack buffs if keep watching certain constellation)
-- 

---TODO:
--Store ids of learned constellations to not redo them again
--reset the sky on new day

local function onSave()
--  print("Save")
  starStorage:set('constellations',knownConstellations)
  starStorage:set('objects',knownObjects)
  local knownConsts = starStorage:getCopy('constellations')
  local knownObjects = starStorage:getCopy('objects')
--  print("SAVING ATTUNED TODAY:",attunedToday)
  
  -- Save objects
  local saveConsts = {}
  for _,const in ipairs(pickedConsts) do
    table.insert(saveConsts,const.const.props.id)
  end
  
  local saveObjs = {}
  for _,obj in ipairs(pickedObjs) do
    table.insert(saveObjs,obj.layout.props.id)
  end
  
  return {attuned=attunedToday,
          buff=currentBuff,
          consts = saveConsts,
          objs = saveObjs,
          knownConsts = knownConsts,
          knownObjects = knownObjects,
          starSpawned = starSpawned
         }
end

local function onLoad(save)
--  print("Load")
  local save = save or {}
  attunedToday = save.attuned or false
--  print("LOADING ATTUNED TODAY:",attunedToday)
  currentBuff = save.buff or nil
  
  -- Reconstruct objects  
  local consts = save.consts
  local objs = save.objs
  
  local kConsts = save.knownConsts or {}
  local kObjs = save.knownObjects or {}
  
  -- Why do i even use storage
  starStorage:set('constellations',kConsts)
  starStorage:set('objects',kObjs)
  knownConstellations = kConsts
  knownObjects = kObjs
  starSpawned = save.starSpawned
  
  if objs ~= nil then
  pickedObjs = {}
    for _,id in ipairs(objs) do
      table.insert(pickedObjs,objects[id])
    end
  end
  
  if consts ~= nil then
    pickedConsts = {}
    allPositions = {}
    for _,id in ipairs(consts) do
      table.insert(pickedConsts,deepCopyConstellation(constellations[id]))
    end
    scaleObjects()
    randomPos()
    initConsts()
    handleEyes()
    initObjs()
    updateCounter()
  end
end

local function spawnShootingStar()
  local pos = self.position
  local distance = math.random(20000, 100000)
--  local distance = math.random(1000,5000)
  local directions = {"north", "south", "east", "west"}
  local choice = directions[math.random(#directions)]

  local offset = util.vector3(0, 0, 0)

  if choice == "north" then
    offset = util.vector3(0, distance, 0)
  elseif choice == "south" then
    offset = util.vector3(0, -distance, 0)
  elseif choice == "east" then
    offset = util.vector3(distance, 0, 0)
  elseif choice == "west" then
    offset = util.vector3(-distance, 0, 0)
  end
  pos = pos + offset
  I.UI.showInteractiveMessage("You see a shooting star falling to the "..choice.."!")
--  print("Shooting star spawned " .. choice .. " by " .. distance .. " units")
  
  core.sendGlobalEvent('SG_SpawnShootingStar',{pos=pos,actor=self})
  sky.content[#sky.content] = {}
  ui.updateAll()
  starSpawned = true
end

local function starRoll()
  if starSpawned then return end
  local roll = math.random()
--  print("Shooting star roll:",roll)
  if roll < 0.09 then
--    print("SPAWNING SHOOTING STAR")
    shooting_star.events = {
      mouseClick = async:callback(function() spawnShootingStar() end)
    }
    local min = v2(200,200)
    local max = v2((screenSize.x*screenScale-1)-min.x,(screenSize.y*screenScale-1)-min.y)
    local randPos = v2(min.x + math.random() * (max.x-min.x),min.y + math.random() * (max.y-min.y))
    shooting_star.props.position = randPos
    sky.content:add(shooting_star)
  end
end

local function onInit()
--  print("Init")
  knownConstellations = {}
  knownObjects = {}
--  core.sendGlobalEvent('SG_GiveToPlayer',{actor=self,item='bk_sg_firmament_ex'})
--  core.sendGlobalEvent('SG_GiveToPlayer',{actor=self,item='t_com_spyglass01'})
end

local function startGazing(data)
  local date = calendar.formatGameTime("%d",calendar.gameTime())
  allPositions = {}
  
  if data.new then
    pickedConsts = {}
    pickedObjs = {}
    
    attunedToday = false
    sky.content = ui.content{drawingBoard}
    I.SkillFramework.skillUsed(skillId,{useType=useTypes.Stargaze})
    
    pickConst(data.buff)
    addRandomObjects(data.buff)
    scaleObjects()
    randomPos()
    
    initConsts()
    handleEyes()
    initObjs()
    if data.buff == nil then
      starRoll()
    end
    updateCounter()
  end

  if data.popup then
    I.UI.addMode(I.UI.MODE.Interface,{windows={}})
  end

  skyMap = ui.create(root)
end

--local function onKey(key)
--  if key.symbol == 'z' then
--    spawnShootingStar()
--  end
--end

return {
  eventHandlers = {
    UiModeChanged = uiChange,
    SG_StartGazing = startGazing,
  },
  engineHandlers = {
--    onKeyPress = onKey,
    onSave = onSave,
    onLoad = onLoad,
    onInit = onInit,
  }
}