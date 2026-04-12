local types = require('openmw.types')
local I = require('openmw.interfaces')
local calendar = require('openmw_aux.calendar')
local world = require('openmw.world')
local core = require('openmw.core')
local util = require('openmw.util')

local telescopes = {
{id="t_com_spyglass01",bonus=nil}
}

local cells = {
  ["Arkngthand, Heaven's Gallery"] = true,
  ["Galom Daeus, Observatory"] = true,
  ["Nchuleftingth, Upper Levels"] = true,
  ["Hendor-Stardumz, Observatory"] = true,
  ["Kemel-Ze, Skywatch Gallery"] = true,
  ["Mvelthngth-Schel, Observatory"] = true,
  ["Barzamthuand, Observatory"] = true,
  ["Bthangthamuzand, Entrance Hall"] = true,
  ["Bthung"] = true,
}

local statics = {
  ["sg_replaced_telescope_01a"] = 10,
  ["sg_replaced_telescope_01b"] = 10,
}

local lastDate = nil

local shard_position = nil

local function telescopeHandler(object,actor)
  --print("oID:",object.recordId)
  local match = false
  for id,item in pairs(telescopes) do
    if item.id == object.recordId then
      match = true
      break
    end
  end
  --print("MATCH:",match)
  if not match then return end
  
  if shard_position then
    local direction = actor.position - shard_position
    local angle = math.atan2(direction.x,direction.y)
    if angle < 0 then
      angle = angle + 2 * math.pi
    end
    
    angle = angle + math.pi
    angle = util.normalizeAngle(angle)
    if angle < 0 then
        angle = angle + 2 * math.pi
    end
    
    local sector = math.floor((angle + math.pi / 8) / (math.pi / 4)) % 8
    local directions = {
      "north",
      "north east",
      "east",
      "south east",
      "south",
      "south west",
      "west",
      "north west"
    }
    local str = "You spot shooting star trail "..directions[sector+1].." from here!"
    actor:sendEvent("ShowMessage",{message=str})
  end
  
  local buff = nil
  --print("Cell name:",actor.cell.name)
  if not actor.cell.isExterior then
    if actor.cell.name ~= "Arkngthand, Heaven's Gallery" then
      actor:sendEvent("ShowMessage",{message="You can not stargaze indoors."})
      return
    else
      buff = 30
    end
  end
  
  local time = calendar.gameTime()
  
  local hour = tonumber(calendar.formatGameTime("%H",time))
  
  if hour >= 5 and hour < 20 then
    actor:sendEvent("ShowMessage",{message="It's too bright to stargaze!"})
    return
  end
  
  local date = calendar.formatGameTime("%d",time)
  if date == lastDate then
    actor:sendEvent("SG_StartGazing",{new=false,buff=buff})
  else
    actor:sendEvent("SG_StartGazing",{new=true,buff=buff})
    lastDate = date
  end
  
  -- check buff
  -- call the player script
end

local function shardHandler(object,actor)
  if object.recordId == 'sg_skyshard' then
      -- convert charge to magicka
    local maxMagicka = types.Actor.stats.dynamic.magicka(actor).base
    local magicka = types.Actor.stats.dynamic.magicka(actor).current
    local charge = types.Item.itemData(object).enchantmentCharge
    local missing = maxMagicka-magicka
    
    if charge == 0 then return false end
    if missing <= 0 then return false end
    
    local final = math.min(charge,missing)
    
  --  types.Actor.stats.dynamic.magicka(actor).current = magicka + final
    actor:sendEvent('ModifyStat', {stat = 'magicka', amount = final})
    types.Item.itemData(object).enchantmentCharge = charge - final
    
    return false
  end
end

-- for portable items
I.ItemUsage.addHandlerForType(types.Miscellaneous,telescopeHandler)

I.ItemUsage.addHandlerForType(types.Clothing,shardHandler)

local function giveToPlayer(data)
  if data.item == 'sg_skyshard' then
    shard_position = nil
  end
  world.createObject(data.item):moveInto(data.actor)
  if data.sound ~= nil then
    core.sound.playSoundFile3d(data.sound,data.actor)
  end
end

local function teleportObj(data)
  data.obj:teleport(data.cell,data.pos,{rotation=data.rot})
  data.obj:removeScript('scripts/Stargazer/placeStar.lua')
  data.obj:addScript('scripts/Stargazer/star.lua')
end

local function spawnStar(data)
  local star = world.createObject('sg_shooting_star')
  local height = core.land.getHeightAt(data.pos,data.actor.cell)
  height = height + 1000
  local pos = util.vector3(data.pos.x,data.pos.y,height)
  star:teleport(data.actor.cell,pos)
  star:addScript('scripts/Stargazer/placeStar.lua')
  shard_position = pos
  
--  data.actor:teleport(data.actor.cell,pos)
end

local function activationHandler(object,actor)
  print("activation handler")
  print(object.recordId)
  if statics[object.recordId] == nil then return end
  
  local buff = statics[object.recordId]
  
  local time = calendar.gameTime()
  local hour = tonumber(calendar.formatGameTime("%H",time))
  if hour >= 5 and hour < 20 then
    actor:sendEvent("ShowMessage",{message="It's too bright to stargaze!"})
    return
  end
  
  local date = calendar.formatGameTime("%d",time)
  if date == lastDate then
    actor:sendEvent("SG_StartGazing",{new=false,buff=buff,popup=true})
  else
    actor:sendEvent("SG_StartGazing",{new=true,buff=buff,popup=true})
    lastDate = date
  end
end

local function vendorItems(object,actor)
  if types.Actor.isDead(object) then return true end
  
  if object.type.record(object).class == 'trader service' or object.type.record(object).class == 'trader' then
    local count = types.Actor.inventory(object):countOf('t_com_spyglass01')
    if count == 0 then
      world.createObject('t_com_spyglass01',1):moveInto(object)
    end
  elseif object.type.record(object).class == 'bookseller' then
    local count = types.Actor.inventory(object):countOf('bk_sg_firmament_ex')
    if count == 0 then
      world.createObject('bk_sg_firmament_ex',1):moveInto(object)
    end
  end
end

I.Activation.addHandlerForType(types.Activator,activationHandler)
I.Activation.addHandlerForType(types.NPC,vendorItems)

local function onSave()
  return {date=lastDate,position=shard_position}
end

local function onLoad(save)
  save = save or {}
  lastDate = save.date or nil
  shard_position = save.position or nil
end

return {
  eventHandlers = {
    SG_SpawnShootingStar = spawnStar,
    SG_TeleportObj = teleportObj,
    SG_GiveToPlayer = giveToPlayer,
  },
  engineHandlers = {
    onSave = onSave,
    onLoad = onLoad,
  }
}