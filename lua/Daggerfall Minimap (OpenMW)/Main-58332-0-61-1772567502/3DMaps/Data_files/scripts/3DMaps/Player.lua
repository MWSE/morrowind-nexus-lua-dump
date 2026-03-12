local self=require('openmw.self')
local anim = require('openmw.animation')
local types = require('openmw.types')
local core = require('openmw.core')
local camera=require('openmw.camera')
local I=require('openmw.interfaces')
local input=require('openmw.input')
local util=require('openmw.util')
local ui=require('openmw.ui')
local nearby=require('openmw.nearby')
local async = require('openmw.async')
local storage = require('openmw.storage')
local time = require('openmw_aux.time')
local MWUI= require('openmw.interfaces').MWUI

local Map=false


local PlayerStaticList={}


local function onUpdate(dt)
  if Map==true then
    if I.UI.getMode()==nil then
      core.sendGlobalEvent("Stop3DMap")
      Map=false
    end

    if input.getBooleanActionValue('MoveMap')==true then
      local RotZ = self.rotation:getPitch()
			local RotX = self.rotation:getYaw()
--      core.sendGlobalEvent("Move3DMap",{Vector=util.vector3(math.cos(RotZ)*math.sin(RotX), math.cos(RotZ) * math.cos(RotX), -math.sin(RotZ))})

      core.sendGlobalEvent("Move3DMap",{Player=self, Vector=util.vector3(input.getMouseMoveX(),0,-input.getMouseMoveY())})
    elseif input.getBooleanActionValue('RotateMap')==true then
      
      core.sendGlobalEvent("Rotate3DMap",{Player=self, Yaw=input.getMouseMoveX(),Pitch=input.getMouseMoveY(),Position=camera.getPosition()+camera.viewportToWorldVector(util.vector2(0.5, 0.5))*10})

      
    end
  end
end



input.registerTriggerHandler("Open", async:callback(function ()
  if self.cell.isExterior==true then
    ui.showMessage("You can't open this maps in exterior.")
  else
    if camera.getMode()~=camera.MODE.FirstPerson then
      ui.showMessage("You need to set in first person to view this maps.")
    else
      if Map==false then
        I.UI.setMode('Interface', {windows = {}})
        Map=true
        core.sendGlobalEvent("Create3DMap",{Player=self,Position=camera.getPosition()+camera.viewportToWorldVector(util.vector2(0.5, 0.5))*10, PlayerStatics=PlayerStaticList})
      elseif Map==true then
        I.UI.removeMode("Interface")
        core.sendGlobalEvent("Stop3DMap")
         Map=false
      end
    end
  end
end))  


input.registerTriggerHandler("ZoomIn", async:callback(function ()
--  print("PlayerZoomIn")
	  if Map==true and input.getBooleanActionValue('MoveMap')==false and input.getBooleanActionValue('RotateMap')==false then
      core.sendGlobalEvent("ZoomIn3DMap",{Position=camera.getPosition()+camera.viewportToWorldVector(util.vector2(0.5, 0.5))*10})
    end
end))  


input.registerTriggerHandler("ZoomOut", async:callback(function ()
--  print("PlayerZoomOut")
	  if Map==true and input.getBooleanActionValue('MoveMap')==false and input.getBooleanActionValue('RotateMap')==false then
      core.sendGlobalEvent("ZoomOut3DMap",{Position=camera.getPosition()+camera.viewportToWorldVector(util.vector2(0.5, 0.5))*10})
    end
end))  





local function CheckObjectsForMap()
  core.sendGlobalEvent("SetAppearDistance",{Distance=storage.playerSection('3DMapWindowcontrols'):get('Distance')})
  if self.cell.isExterior==false then
    if PlayerStaticList[self.cell.id]==nil then
      PlayerStaticList[self.cell.id]={}
    end
    local ViewDistance=camera.getViewDistance()
    local Directions={util.vector3(1,0,0),util.vector3(-1,0,0),util.vector3(0,1,0),util.vector3(0,-1,0),util.vector3(0,0,1),util.vector3(0,0,-1)}

    for i, direction in pairs(Directions) do
      local Ray=nearby.castRay(self.position,self.position+direction*ViewDistance,{ignore=self})
      if Ray.hitObject and PlayerStaticList[self.cell.id][Ray.hitObject.id]==nil then
        PlayerStaticList[self.cell.id][Ray.hitObject.id]=true
       -- print(Ray.hitObject)
      end
    end
  end
end



local function onSave(data)
	return{SavedStaticList=PlayerStaticList}
end

local function onLoad(data)
	if data and data.SavedStaticList then
		PlayerStaticList=data.SavedStaticList
	end
end



time.runRepeatedly(CheckObjectsForMap,1)

return {
  engineHandlers = {onUpdate=onUpdate,
                    onSave=onSave,
                    onLoad=onLoad,


  },
  eventHandlers={GetSimulationTime=GetSimulationTime,



  }
}