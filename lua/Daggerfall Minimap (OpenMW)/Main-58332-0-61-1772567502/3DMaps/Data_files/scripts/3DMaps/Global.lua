--global

local I = require('openmw.interfaces')
local types = require('openmw.types')
local world = require('openmw.world')
local time = require('openmw_aux.time')
local core = require('openmw.core')
local util = require('openmw.util')

local MapStatics={}
local MapLight
local AppearDistance=500
local StaticList={}
local MagnitudeDistanceRatio=30


local function Stop3DMap()
--  print("stop3DMapG")
  for i, static in pairs(MapStatics) do
    if static.count>0 then
      static:remove()
    end
  end
  if MapLight and MapLight.count>0 then
    MapLight:remove()
  end
end

local function onSave(data)
  Stop3DMap()
	return{SavedStaticList=StaticList}
end

local function onLoad(data)
	if data and data.SavedStaticList then
    print("LOAD")
		StaticList=data.SavedStaticList
	end
end


local function SetAppearDistance(data)
  AppearDistance=tonumber(data.Distance)
end

local function DetectInCell(type,player,position)
	for i, object in pairs(player.cell:getAll(type)) do
    if StaticList[player.id][player.cell.id][object.id] then
      local Object=world.createObject(object.recordId,1)
      Object:setScale(object.scale*0.005)
      Object:teleport(player.cell,position+(object.position-player.position)/200,object.rotation)
      table.insert(MapStatics,Object)
    end
  end
end






local function DetectKeyEchantInCell(typeChecked,player,position,effect,checker)
  local CursorId="keycursor"
  if checker=="enchant" then CursorId="enchantcursor" end
  if effect.magnitude>0 then
    for i, item in pairs(player.cell:getAll(typeChecked)) do
      if (item.type.records[item.recordId][checker]==true or type(item.type.records[item.recordId][checker])=="string") and (item.position-player.position):length()<effect.magnitude*MagnitudeDistanceRatio then
        local Object=world.createObject(CursorId,1)
        Object:setScale(0.005)
        Object:teleport(player.cell,position+(item.position-player.position)/200)
        table.insert(MapStatics,Object)
      end
    end


    
    for i, npc in pairs(player.cell:getAll(types.NPC)) do
      if npc~=player and (npc.position-player.position):length()<effect.magnitude*MagnitudeDistanceRatio then
        for j, item in pairs(types.Actor.inventory(npc):getAll(typeChecked)) do
          if (item.type.records[item.recordId][checker]==true or type(item.type.records[item.recordId][checker])=="string") then
            local Object=world.createObject(CursorId,1)
            Object:setScale(0.005)
            Object:teleport(player.cell,position+(npc.position-player.position)/200)
            table.insert(MapStatics,Object)
            break
          end
        end
      end
    end

    for i, creature in pairs(player.cell:getAll(types.Creature)) do
      if (creature.position-player.position):length()<effect.magnitude*MagnitudeDistanceRatio then
        for j, item in pairs(types.Actor.inventory(creature):getAll(typeChecked)) do
          if (item.type.records[item.recordId][checker]==true or type(item.type.records[item.recordId][checker])=="string") then
            local Object=world.createObject(CursorId,1)
            Object:setScale(0.005)
            Object:teleport(player.cell,position+(creature.position-player.position)/200)
            table.insert(MapStatics,Object)
            break
          end
        end
      end
    end

    
    for i, container in pairs(player.cell:getAll(types.Container)) do
      if (container.position-player.position):length()<effect.magnitude*MagnitudeDistanceRatio then
        for j, item in pairs(types.Container.inventory(container):getAll(type)) do
          if (item.type.records[item.recordId][checker]==true or type(item.type.records[item.recordId][checker])=="string") then
            local Object=world.createObject(CursorId,1)
            Object:setScale(0.005)
            Object:teleport(player.cell,position+(container.position-player.position)/200)
            table.insert(MapStatics,Object)
            break
          end
        end
      end
    end
  end
end






local function Create3DMap(data)
  for i, _ in pairs(data.PlayerStatics[data.Player.cell.id]) do
    if StaticList[data.Player.id][i]==nil then
      print(i)
      StaticList[data.Player.id][i]=true
    end
  end

  MapStatics={}
  DetectInCell(types.Static,data.Player,data.Position)
  DetectInCell(types.Door,data.Player,data.Position)
  DetectInCell(types.Activator,data.Player,data.Position)

  local DetectCretureEffect=types.Actor.activeEffects(data.Player):getEffect(core.magic.EFFECT_TYPE.DetectAnimal)
  if DetectCretureEffect.magnitude>0 then
    for i, object in pairs(data.Player.cell:getAll(types.Creature)) do
      if (object.position-data.Player.position):length()<DetectCretureEffect.magnitude*MagnitudeDistanceRatio then
        local Object=world.createObject("creaturecursor",1)
        Object:setScale(0.005)
        Object:teleport(data.Player.cell,data.Position+(object.position-data.Player.position)/200)
        table.insert(MapStatics,Object)
      end
    end   
  end




  DetectKeyEchantInCell(types.Miscellaneous,data.Player,data.Position,types.Actor.activeEffects(data.Player):getEffect(core.magic.EFFECT_TYPE.DetectKey),"isKey")
  DetectKeyEchantInCell(nil,data.Player,data.Position,types.Actor.activeEffects(data.Player):getEffect(core.magic.EFFECT_TYPE.DetectEnchantment),"enchant")



  local Player=world.createObject("playercursor",1)
  Player:setScale(0.003)
  Player:teleport(data.Player.cell,data.Position+(data.Player.position-data.Player.position)/200)
  table.insert(MapStatics,Player)

  MapLight=world.createObject("maplight",1)
  MapLight:teleport(data.Player.cell,data.Position)
end


local function Move3DMap(data)
  for i, static in pairs(MapStatics) do
    static:teleport(static.cell,static.position+data.Player.rotation*data.Vector/500)
  end
end


local function Rotate3DMap(data)
  local AddedYaw=data.Yaw/360
  local AddedPitch=data.Pitch/360
  local ZeroPosition=data.Position
  for i, static in pairs(MapStatics) do
    local Vector=static.position-ZeroPosition
    static:teleport(static.cell,
    util.transform.rotateZ(AddedYaw)*util.transform.rotateY(AddedPitch)*Vector+ZeroPosition,
    util.transform.rotateZ(AddedYaw)*util.transform.rotateY(AddedPitch)*static.rotation)
  end
end



local function ZoomIn3DMap(data)
  for i, static in pairs(MapStatics) do
    static:setScale(static.scale*1.1)
    static:teleport(static.cell,data.Position+(static.position-data.Position)*1.1,static.rotation)
  end
end

local function ZoomOut3DMap(data)
  for i, static in pairs(MapStatics) do
    static:setScale(static.scale*0.9)
    static:teleport(static.cell,data.Position+(static.position-data.Position)*0.9,static.rotation)
  end
end




local function CheckObjectsForMap()
  for j, player in pairs(world.players) do
    if player.cell.isExterior==false then
      if StaticList[player.id]==nil then
        StaticList[player.id]={}
      end
      if StaticList[player.id][player.cell.id]==nil then
        StaticList[player.id][player.cell.id]={}
      end
      for i,static in pairs(player.cell:getAll(types.Static)) do
          if StaticList[player.id][player.cell.id][static.id]==nil then
            if (static.position-player.position):length()<AppearDistance then
              StaticList[player.id][player.cell.id][static.id]=true
            end
          end
      end
      for i,door in pairs(player.cell:getAll(types.Door)) do
          if StaticList[player.id][player.cell.id][door.id]==nil then
            if (door.position-player.position):length()<AppearDistance then
              StaticList[player.id][player.cell.id][door.id]=true
            end
          end
      end
      for i,activator in pairs(player.cell:getAll(types.Activator)) do
          if StaticList[player.id][player.cell.id][activator.id]==nil and types.Activator.records[activator.recordId].model~="meshes/editormarker.nif" and types.Activator.records[activator.recordId].model~="" then
            if (activator.position-player.position):length()<AppearDistance then
              StaticList[player.id][player.cell.id][activator.id]=true
            end
          end
      end
    end
  end
end

time.runRepeatedly(CheckObjectsForMap,1)






return {
    eventHandlers = {
      Create3DMap=Create3DMap,
      Stop3DMap=Stop3DMap,
      Move3DMap=Move3DMap,
      ZoomIn3DMap=ZoomIn3DMap,
      ZoomOut3DMap=ZoomOut3DMap,
      SetAppearDistance=SetAppearDistance,
      Rotate3DMap=Rotate3DMap,


    },
    engineHandlers = {onSave=onSave,
                      onLoad=onLoad,
  
  
  }
  }

