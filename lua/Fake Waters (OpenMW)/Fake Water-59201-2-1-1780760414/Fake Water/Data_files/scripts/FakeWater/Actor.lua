local types = require('openmw.types')
local I = require('openmw.interfaces')
local anim = require('openmw.animation')
local self = require('openmw.self')
local core = require('openmw.core')
local async = require('openmw.async')
local nearby = require('openmw.nearby')
local util = require('openmw.util')
local time = require('openmw_aux.time')



local InWater=false
local Idle=false
local FakeWaters






local Steps={	footbareleft={"FootWaterLeft",false},
				footbareright={"FootWaterRight",false},
				FootLightLeft={"FootWaterLeft",false},
				FootLightRight={"FootWaterRight",false},
				FootMedLeft={"FootWaterLeft",false},
				FootMedRight={"FootWaterRight",false},
				FootHeavyLeft={"FootWaterLeft",false},
				FootHeavyRight={"FootWaterRight",false},
				DefaultLand={"DefaultLandWater",false},

			}

            
local function IgnoreRipplesForRay()
	local Ripples={}
		for i, Activator in pairs(nearby.activators) do
			if string.find(Activator.type.records[Activator.recordId].model,"meshes/waterripp") then
				table.insert(Ripples,Activator)
			end
		end
	table.insert(Ripples,self)
	return(Ripples)
end


local function StepSoundWater()
	for step, state in pairs(Steps) do
		if core.sound.isSoundPlaying(step,self)==true and state[2]==false then
			state[2]=true
--		    core.sound.stopSound3d(step,self)
			core.sound.playSound3d(state[1],self,{volume=0.1})
		elseif state[2]==true and core.sound.isSoundPlaying(step,self)==false then
			state[2]=false
		end
	end
end




time.runRepeatedly(function() 	

	if InWater==true and types.Actor.isDead(self)==false then
		nearby.asyncCastRenderingRay(async:callback(function(Ray)
			
																if Ray.hitObject and FakeWaters[Ray.hitObject.id] then
                                                                    if Idle==false then
																	    core.sendGlobalEvent('CreateRipple',{position=Ray.hitPos+util.vector3(0,0,3), rotation=Ray.hitObject.rotation, cell=self.cell.name})
                                                                    end
																end
													end), 
                                    self.position+util.vector3(0,0,self:getBoundingBox().halfSize.z*2), 
									self.position,
									{ignore=IgnoreRipplesForRay()})   
	end   

end
,0.2*time.second)


local Animations={	idle="idle",
                    idle1h="idle",
                    idlecrossbow="idle",
                    idlehh="idle",
                    idlesneak="idle",
                    idlespell="idle",
                    idlestorm="idle",
                    jump="stop",
                    jump1h="stop",  
                    jump2c="stop", 
                    jump2w="stop", 
                    jumphh="stop",
                    runback="loop start",   
                    runback1h="loop start",     
                    runback2c="loop start",     
                    runback2w ="loop start",    
                    runbackhh ="loop start",    
                    runforward="loop start",    
                    runforward1h="loop start",  
                    runforward2c="loop start",  
                    runforward2w="loop start",  
                    runforwardhh="loop start",
                    runleft="loop start",   
                    runleft1h="loop start",     
                    runleft2c="loop start",     
                    runleft2w="loop start", 
                    runlefthh="loop start",   
                    runright="loop start",      
                    runright1h="loop start",    
                    runright2c ="loop start",   
                    runright2w="loop start",    
                    runrighthh="loop start",
                    sneakback ="loop start",    
                    sneakback1h="loop start",   
                    sneakback2c ="loop start",  
                    sneakback2w ="loop start",  
                    sneakbackhh ="loop start",  
                    sneakforward ="loop start", 
                    sneakforward1h ="loop start",   
                    sneakforward2c ="loop start",   
                    sneakforward2w  ="loop start",
                    sneakforwardhh ="loop start",   
                    sneakleft ="loop start",    
                    sneakleft1h ="loop start",  
                    sneakleft2c ="loop start",  
                    sneakleft2w ="loop start",  
                    sneaklefthh ="loop start",  
                    sneakright ="loop start",   
                    sneakright1h ="loop start", 
                    sneakright2c ="loop start", 
                    sneakright2w ="loop start", 
                    sneakrighthh="loop start",
                    walkback ="loop start", 
                    walkback1h  ="loop start",
                    walkback2c  ="loop start",
                    walkback2w  ="loop start",
                    walkbackhh ="loop start",   
                    walkforward="loop start",   
                    walkforward1h="loop start",     
                    walkforward2c ="loop start",    
                    walkforward2w="loop start",     
                    walkforwardhh ="loop start",    
                    walkleft ="loop start", 
                    walkleft1h  ="loop start",
                    walkleft2c ="loop start",   
                    walkleft2w  ="loop start",
                    walklefthh  ="loop start",
                    walkright   ="loop start",
                    walkright1h ="loop start",  
                    walkright2c     ="loop start",
                    walkright2w ="loop start",  
                    walkrighthh="loop start",


}



I.AnimationController.addTextKeyHandler('', function(groupname, key)

	if Animations[groupname] and types.Actor.isDead(self)==false then 
		  	nearby.asyncCastRenderingRay(async:callback(function(Ray)
               --print(self,Ray.hitObject)
															if Ray.hitObject and FakeWaters[Ray.hitObject.id] then
																if InWater==false then
                                                                    core.sendGlobalEvent('SetInWaterMwscript',{actor=self,value=1})
																	InWater=true
																end
                                                                core.sendGlobalEvent('CreateRipple',{position=Ray.hitPos+util.vector3(0,0,3), rotation=Ray.hitObject.rotation, cell=self.cell.name})
                                                                if Animations[groupname]=="idle" then
                                                                    Idle=true
                                                                else
                                                                    Idle=false
                                                                end
                                                            
                                                            else 
																if InWater==true then
																	if types.Player.objectIsInstance(self) then
																	end
																	InWater=false
                                                                    core.sendGlobalEvent('SetInWaterMwscript',{actor=self,value=0})
																end

															end
												end),
								self.position+util.vector3(0,0,self:getBoundingBox().halfSize.z*2), 
								self.position,
								{ignore=IgnoreRipplesForRay()})   
	end
end)


local function Died()
    InWater=false
end

local function onUpdate(dt)
	if dt>0	then
		if InWater==true then
			StepSoundWater()
		end
	end
end


local function InFakeWater()
	return(InWater)
end


local function DeclareFakeWater(data)
    FakeWaters=data.FakeWaters
end


return {
    interfaceName = "FakeWater",
    interface = {
        version = 1,
        InFakeWater=InFakeWater
    },


	eventHandlers = {   Died=Died,
                        DeclareFakeWater=DeclareFakeWater	},
	engineHandlers = {
		onUpdate=onUpdate,
	}

}