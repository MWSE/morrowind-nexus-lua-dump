local dataManager = {}
function dataManager.setValue(valueName, value)
    tes3.player.data[valueName] = value
end

function dataManager.getValue(valueName,default)
    
    local val =  tes3.player.data[valueName]
    if not val and default then
        return default
    end
    return  val
end

local function getNextIDToUse()
local nextVal = dataManager.getValue("npcIDStage",0) + 1
dataManager.setValue("npcIDStage",nextVal)
local NPCID = "zhac_clonenpc_" .. string.format("%04d",nextVal)
return NPCID
end



local function uiObjectTooltipCallback(e)
    if e.object.id == "zhac_dagger_blood" then
        local idcheck = dataManager.getValue("daggerBloodID")
        if idcheck then
            local obj = tes3.getObject(idcheck)
            e.tooltip:createLabel { text = "Blood Contained: " ..  obj.name}
        end
        
    end
end
event.register(tes3.event.uiObjectTooltip, uiObjectTooltipCallback)
local function setDaggerName(baseObj)
    dataManager.setValue("daggerBloodID",baseObj.id)
end
local function damageCallback(e)
    --TODO: make sure clones can't give blood
    if e.attacker and e.attacker.readiedWeapon then
        local id = e.attacker.readiedWeapon.object.id
        if string.sub(e.reference.baseObject.id,1,4):lower() == "zhac" then
            tes3ui.showNotifyMenu("You can't get blood from a clone")
            return
        else
            print(string.sub(e.reference.baseObject.id,1,4):lower())
        end
        if id == "zhac_dagger_blood" then
            setDaggerName(e.reference.baseObject)
        end
    end
end
event.register(tes3.event.damage, damageCallback)


local function createNPCClone(sourceRecord)
    local newRecord = getNextIDToUse()
    local cloneRecord = tes3.getObject(newRecord)
        cloneRecord.hair = sourceRecord.hair
        cloneRecord.race = sourceRecord.race
        cloneRecord.female = sourceRecord.female
        cloneRecord.class = sourceRecord.class
        cloneRecord.head = sourceRecord.head
        cloneRecord.name = "Clone of " ..sourceRecord.name
        cloneRecord.modified = true
        local rotation = tes3vector3.new(0, 0, math.rad(-90))
        local position = tes3.player.position
        position = tes3vector3.new(position.x, position.y, position.z)

        return cloneRecord
    
end
return{getNextIDToUse = getNextIDToUse, createNPCClone = createNPCClone}