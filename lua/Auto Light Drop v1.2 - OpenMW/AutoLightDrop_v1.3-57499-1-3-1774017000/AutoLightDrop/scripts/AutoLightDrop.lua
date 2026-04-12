local self=require('openmw.self')
local types = require('openmw.types')
local core = require('openmw.core')
local util = require('openmw.util')
local ui = require('openmw.ui')

-- Camera import like physics engine
local cstatus, camera = pcall(require, 'openmw.camera')

local CarriedLight
local CarriedLeft


local function onUpdate()

    
    local CarriedLeft=types.Actor.getEquipment(self,types.Actor.EQUIPMENT_SLOT.CarriedLeft)
    local CarriedRight=types.Actor.getEquipment(self,types.Actor.EQUIPMENT_SLOT.CarriedRight)
    if CarriedLeft and CarriedLeft.type==types.Light then
        CarriedLight=types.Actor.getEquipment(self,types.Actor.EQUIPMENT_SLOT.CarriedLeft)
    elseif CarriedLeft==nil then
        CarriedLight=nil 
    end



    if CarriedLight and (types.Actor.stance(self)==types.Actor.STANCE.Spell or  
                        (CarriedLeft and CarriedLeft.type~=types.Light) or 
                        (types.Actor.stance(self)==types.Actor.STANCE.Weapon and CarriedRight and  (CarriedRight.type.records[CarriedRight.recordId].type==types.Weapon.TYPE.AxeTwoHand or
                                                                                                    CarriedRight.type.records[CarriedRight.recordId].type==types.Weapon.TYPE.BluntTwoClose or
                                                                                                    CarriedRight.type.records[CarriedRight.recordId].type==types.Weapon.TYPE.BluntTwoWide or
                                                                                                    CarriedRight.type.records[CarriedRight.recordId].type==types.Weapon.TYPE.LongBladeTwoHand or
                                                                                                    CarriedRight.type.records[CarriedRight.recordId].type==types.Weapon.TYPE.MarksmanBow or
                                                                                                    CarriedRight.type.records[CarriedRight.recordId].type==types.Weapon.TYPE.SpearTwoWide or
                                                                                                    CarriedLeft.type.records[CarriedLeft.recordId].type==types.Armor.TYPE.Shield or
                                                                                                    CarriedRight.type.records[CarriedRight.recordId].type==types.Weapon.TYPE.MarksmanCrossbow ))) then
        

        
        -- Only add camera aiming to the position calculation
        if camera and cstatus then
            local cameraPos = camera.getPosition()
            -- Get center direction first
            local centerDirection = camera.viewportToWorldVector(util.vector2(0.5, 0.5)):normalize()
            
            -- Calculate offset direction by tilting the center direction downward
            local pitchOffset = math.rad(1) -- 3 degrees downward tilt
            local aimDirection = util.vector3(
                centerDirection.x,
                centerDirection.y * math.cos(pitchOffset) - centerDirection.z * math.sin(pitchOffset),
                centerDirection.y * math.sin(pitchOffset) + centerDirection.z * math.cos(pitchOffset)
            ):normalize()
            
            -- Use only X,Y from aimed position, ignore Z to avoid terrain issues
            local aimPos = cameraPos + aimDirection * 100
            local safeAimPos = util.vector3(aimPos.x, aimPos.y, self.position.z) -- Use player Z
            
            core.sendGlobalEvent("DropLight",{Light=CarriedLight, Actor=self, Position=safeAimPos})
        else
            -- EXACT original working call
            core.sendGlobalEvent("DropLight",{Light=CarriedLight, Actor=self})
        end
        
        CarriedLight=nil 
    end

end

return {
	eventHandlers = {
                        

					},
	engineHandlers = {
                        onUpdate=onUpdate,
                        

	}

}