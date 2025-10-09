local self=require('openmw.self')
local types = require('openmw.types')
local core = require('openmw.core')
local util = require('openmw.util')
local ui = require('openmw.ui')

-- Camera import like physics engine
local cstatus, camera = pcall(require, 'openmw.camera')

local storage = require('openmw.storage')
local settings = storage.playerSection('SettingsAutoLightDrop')

local CarriedLight
local CarriedLeft

local function splitString(inputstr, sep)
if sep == nil then
sep = "%s"
end
local t={}
for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
table.insert(t, str)
end
return t
end

local exceptionItemIDs = {}
local function loadExceptionItemIDs()
local rawIDs = settings:get("exceptionItemIDs")
if type(rawIDs) == "userdata" then
-- Convert userdata (table) to string list
local ids = {}
for _, v in ipairs(rawIDs) do
table.insert(ids, tostring(v))
end
rawIDs = table.concat(ids, ",")
elseif type(rawIDs) ~= "string" then
rawIDs = ""
end
local ids = splitString(rawIDs, ",")
exceptionItemIDs = {}
for _, id in ipairs(ids) do
local trimmed = id:match("^%s*(.-)%s*$") -- trim spaces
if trimmed ~= "" then
exceptionItemIDs[trimmed] = true
end
end
end

loadExceptionItemIDs()

local function onUpdate()
    local hardcoreMode = settings:get("hardcoreMode")

    local CarriedLeft=types.Actor.getEquipment(self,types.Actor.EQUIPMENT_SLOT.CarriedLeft)
    local CarriedRight=types.Actor.getEquipment(self,types.Actor.EQUIPMENT_SLOT.CarriedRight)
    if CarriedLeft and CarriedLeft.type==types.Light then
        CarriedLight=types.Actor.getEquipment(self,types.Actor.EQUIPMENT_SLOT.CarriedLeft)
    elseif CarriedLeft==nil then
        CarriedLight=nil
    end

    if CarriedLight then
        -- Check if throwing light source is allowed based on hardcoreMode setting and player feet in water
        local waterLevel = self.cell and self.cell.waterLevel
        -- Adjust inWater to detect if player is even 1% touching water (e.g., allow small margin)
        local inWater = false
        if waterLevel then
            local playerFeetZ = self.position.z - 0.5 -- approximate feet position slightly below player position
            inWater = playerFeetZ < waterLevel
        end

        if hardcoreMode == false and inWater then
            -- Skip the drop logic entirely, return early without modifying carried equipment variables
            return
        end

        -- Only drop light if hardcoreMode is true or hardcoreMode is false and player is NOT in water
        if hardcoreMode == true or (hardcoreMode == false and not inWater) then
            if types.Actor.stance(self) == types.Actor.STANCE.Spell or
               (CarriedLeft and CarriedLeft.type ~= types.Light) or
               (types.Actor.stance(self) == types.Actor.STANCE.Weapon and CarriedRight and (
                    CarriedRight.type.records[CarriedRight.recordId].type == types.Weapon.TYPE.AxeTwoHand or
                    CarriedRight.type.records[CarriedRight.recordId].type == types.Weapon.TYPE.BluntTwoClose or
                    CarriedRight.type.records[CarriedRight.recordId].type == types.Weapon.TYPE.BluntTwoWide or
                    CarriedRight.type.records[CarriedRight.recordId].type == types.Weapon.TYPE.LongBladeTwoHand or
                    CarriedRight.type.records[CarriedRight.recordId].type == types.Weapon.TYPE.MarksmanBow or
                    CarriedRight.type.records[CarriedRight.recordId].type == types.Weapon.TYPE.SpearTwoWide or
                    CarriedLeft.type.records[CarriedLeft.recordId].type == types.Armor.TYPE.Shield or
                    CarriedRight.type.records[CarriedRight.recordId].type == types.Weapon.TYPE.MarksmanCrossbow
                )) then

                core.sendGlobalEvent("DebugDropLight", { Actor = self, Light = CarriedLight })

                -- Only add camera aiming to the position calculation
                if camera and cstatus then
                    local cameraPos = camera.getPosition()
                    -- Get center direction first
                    local centerDirection = camera.viewportToWorldVector(util.vector2(0.5, 0.5)):normalize()
                    
                    -- Simple aim direction - just use the camera direction
                    local aimDirection = centerDirection
                    
                    -- Use only X,Y from aimed position, ignore Z to avoid terrain issues
                    local aimPos = cameraPos + aimDirection * 100
                    local safeAimPos = util.vector3(aimPos.x, aimPos.y, self.position.z) -- Use player Z

                    core.sendGlobalEvent("DropLight",{Light=CarriedLight, Actor=self, Position=safeAimPos})
                else
                    -- EXACT original working call
                    core.sendGlobalEvent("DropLight",{Light=CarriedLight, Actor=self})
                end

                CarriedLight=nil
            else
            end
        end
    end
end

return {
engineHandlers = {
onUpdate = onUpdate,
}
}