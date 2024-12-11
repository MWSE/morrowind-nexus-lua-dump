local storage = require("openmw.storage")
local self = require("openmw.self")
local types = require("openmw.types")
local Actor = types.Actor
local playerSettings = storage.globalSection("SettingsDebugMode")
local util = require("openmw.util")
local core = require("openmw.core")
local I = require("openmw.interfaces")
local badInv = nil
local badWait = -1
local nearby = require ("openmw.nearby")
local eqCache = nil

local startAttack = false
local attemptJump = false
local controlled = false

local function WriteToConsole(string,error)
    local player = nil
    for index, value in ipairs(nearby.actors) do
        if(value.type == types.Player) then
            player = value
        end
    end
        player:sendEvent("WriteToConsoleEvent", { text = string, error = error })
    end


local function onInit(initData)
    if (initData ~= nil) then
        for key, value in pairs(initData) do
            print(value)
        end
        for key, value in ipairs(initData) do
            print(value)
        end
        eqCache = initData
        badWait = 10
        return
    end
    if (playerSettings:get("DisableActorAI") == true) then
        self:enableAI(false)
    end
end

local function setStat(data)
    local value = data.stat
    local num
    if(data.value ~= nil) then
        num = tonumber(data.value)

    end
    local attribute = core.stats.Attribute.records
    local skill = core.stats.Skill.records
    for index, skill in pairs(skill) do
        local name = skill.name
        if (value == "set" .. name) then
                  types.NPC.stats.skills[name](self).base = num
                  local val = types.NPC.stats.skills[name](self)
                      .modified
                  print(val)
                  WriteToConsole(skill .. ": " .. tostring(val))
             
        end
        if (value == "get" .. name) then
             local val = types.NPC.stats.skills[name](self)
                 .modified
             print(val)
             WriteToConsole(name .. ": " .. tostring(val))
        end
   end
   for index, attrib in pairs(attribute) do
    local name = attrib.name
        if (value == "set" .. name) then
             --if (myTarget.type == self.type) then
             types.Actor.stats.attributes[name](self).base = num
             local val = types.Actor.stats.attributes[name](self)
                 .base
             WriteToConsole(name .. ": " .. tostring(val))
             -- end
        elseif (value == "get" .. name) then
           
             local val = types.Actor.stats.attributes[name](self)
                 .modified
             print(val)
             WriteToConsole(name .. ": " .. tostring(val))
        end
   end
   local dynamicName = "health"
   if (value == "get" .. dynamicName) then
        local dynamic = types.Actor.stats.dynamic[dynamicName](self)
        WriteToConsole(dynamicName .. ": " .. tostring(dynamic.base))
   elseif (value == "set" .. dynamicName) then

        local dynamic = types.Actor.stats.dynamic[dynamicName](self)

        dynamic.current = num
        local val = dynamic.base
        WriteToConsole(dynamicName .. ": " .. tostring(val))
   end

   dynamicName = "fatigue"
   if (value == "get" .. dynamicName) then
        local dynamic = types.Actor.stats.dynamic[dynamicName](self)
        WriteToConsole(dynamicName .. ": " .. tostring(dynamic.base))
   elseif (value == "set" .. dynamicName) then

        local dynamic = types.Actor.stats.dynamic[dynamicName](self)

        dynamic.current = num
        local val = dynamic.base
        WriteToConsole(dynamicName .. ": " .. tostring(val))
   end

   dynamicName = "magicka"
   if (value == "get" .. dynamicName) then
        local dynamic = types.Actor.stats.dynamic[dynamicName](self)
        WriteToConsole(dynamicName .. ": " .. tostring(dynamic.base))
   elseif (value == "set" .. dynamicName) then
     

        local dynamic = types.Actor.stats.dynamic[dynamicName](self)

        dynamic.current  = num
        local val = dynamic.base
        WriteToConsole(dynamicName .. ": " .. tostring(val))
   end


    if (data.type == "health") then
        types.Actor.stats.dynamic.health(self).current = data.value
    end
end
local function findSlot(item)

    --Finds a equipment slot for an inventory item, if it has one,
    if item.type == types.Armor then
        if (types.Armor.records[item.recordId].type == types.Armor.TYPE.RGauntlet) then
            return types.Actor.EQUIPMENT_SLOT.RightGauntlet
        elseif (types.Armor.records[item.recordId].type == types.Armor.TYPE.LGauntlet) then
            return types.Actor.EQUIPMENT_SLOT.LeftGauntlet
        elseif (types.Armor.records[item.recordId].type == types.Armor.TYPE.Boots) then
            return types.Actor.EQUIPMENT_SLOT.Boots
        elseif (types.Armor.records[item.recordId].type == types.Armor.TYPE.Cuirass) then
            return types.Actor.EQUIPMENT_SLOT.Cuirass
        elseif (types.Armor.records[item.recordId].type == types.Armor.TYPE.Greaves) then
            return types.Actor.EQUIPMENT_SLOT.Greaves
        elseif (types.Armor.records[item.recordId].type == types.Armor.TYPE.LBracer) then
            return types.Actor.EQUIPMENT_SLOT.RightGauntlet
        elseif (types.Armor.records[item.recordId].type == types.Armor.TYPE.RBracer) then
            return types.Actor.EQUIPMENT_SLOT.LeftGauntlet
        elseif (types.Armor.records[item.recordId].type == types.Armor.TYPE.RPauldron) then
            return types.Actor.EQUIPMENT_SLOT.LeftGauntlet
        elseif (types.Armor.records[item.recordId].type == types.Armor.TYPE.LPauldron) then
            return types.Actor.EQUIPMENT_SLOT.LeftPauldron
        elseif (types.Armor.records[item.recordId].type == types.Armor.TYPE.RPauldron) then
            return types.Actor.EQUIPMENT_SLOT.RightPauldron
        end
    elseif item.type == types.Clothing then
        if (types.Clothing.records[item.recordId].type == types.Clothing.TYPE.Amulet) then
            return types.Actor.EQUIPMENT_SLOT.Amulet
        elseif (types.Clothing.records[item.recordId].type == types.Clothing.TYPE.Belt) then
            return types.Actor.EQUIPMENT_SLOT.Belt
        elseif (types.Clothing.records[item.recordId].type == types.Clothing.TYPE.LGlove) then
            return types.Actor.EQUIPMENT_SLOT.LeftGauntlet
        elseif (types.Clothing.records[item.recordId].type == types.Clothing.TYPE.RGlove) then
            return types.Actor.EQUIPMENT_SLOT.RightGauntlet
        elseif (types.Clothing.records[item.recordId].type == types.Clothing.TYPE.Ring) then
            return types.Actor.EQUIPMENT_SLOT.RightRing
        elseif (types.Clothing.records[item.recordId].type == types.Clothing.TYPE.Skirt) then
            return types.Actor.EQUIPMENT_SLOT.Skirt
        elseif (types.Clothing.records[item.recordId].type == types.Clothing.TYPE.Shirt) then
            return types.Actor.EQUIPMENT_SLOT.Shirt
        elseif (types.Clothing.records[item.recordId].type == types.Clothing.TYPE.Shoes) then
            return types.Actor.EQUIPMENT_SLOT.Boots
        elseif (types.Clothing.records[item.recordId].type == types.Clothing.TYPE.Robe) then
            return types.Actor.EQUIPMENT_SLOT.Robe
        elseif (types.Clothing.records[item.recordId].type == types.Clothing.TYPE.Pants) then
            return types.Actor.EQUIPMENT_SLOT.Pants
        end
    elseif item.type == types.Weapon then
        if (item.type.records[item.recordId].type == types.Weapon.TYPE.Arrow or item.type.records[item.recordId].type == types.Weapon.TYPE.Bolt) then
            return types.Actor.EQUIPMENT_SLOT.Ammunition
        end
        return types.Actor.EQUIPMENT_SLOT.CarriedRight
    end
    print("Couldn't find slot for " .. item.recordId)
    return false
end
local function setBadItems(table)
    badInv = table
    badWait = 10
end
local function sendToPos(destination)

I.AI.startPackage({type='Travel', destPosition=destination})
end

local function setEquipment(equip)
    eqCache = equip
 --   for key, value in pairs(equip) do
  --      print(value)
   -- end
    types.Actor.setEquipment(self, equip)
end
local function onLoadEvent()
    --    print("loaded")
    if (playerSettings:get("DisableActorAI") == true) then
        self:enableAI(false)
    end
end
local function test(x)
    print(x)
end

local function setAIState(ai)
self:enableAI(ai)
end
local function processMovement(data)
    controlled = true
    local MFBA = data.MFBA                 --input.CONTROLLER_AXIS.MoveForwardBackward
    local CSM = data.CSM                   --input.getAxisValue(input.CONTROLLER_AXIS.MoveLeftRight)
    local moveLeft = data.moveLeft         -- input.isActionPressed(input.ACTION.MoveLeft )
    local moveRight = data.moveRight        -- input.isActionPressed(input.ACTION.MoveLeft )
    local moveBackward = data.moveBackward -- input.isActionPressed(input.ACTION.MoveLeft )
    local moveForward = data.moveForward   -- input.isActionPressed(input.ACTION.MoveLeft )
    local jumping = data.jumping           --input.getControlSwitch(input.CONTROL_SWITCH.Jumping)
    local sneaking = data.sneaking         -- input.isActionPressed(input.ACTION.Sneak)
    local controllerMovement = MFBA---input.getAxisValue(input.CONTROLLER_AXIS.MoveForwardBackward)
    local controllerSideMovement = CSM--input.getAxisValue(input.CONTROLLER_AXIS.MoveLeftRight)
    if controllerMovement ~= 0 or controllerSideMovement ~= 0 then
        -- controller movement
        if util.vector2(controllerMovement, controllerSideMovement):length2() < 0.25
            and not self.controls.sneak and types.Actor.isOnGround(self) and not types.Actor.isSwimming(self) then
            self.controls.run = false
            self.controls.movement = controllerMovement * 2
            self.controls.sideMovement = controllerSideMovement * 2
        else
            self.controls.run = true
            self.controls.movement = controllerMovement
            self.controls.sideMovement = controllerSideMovement
        end
    else
        --   if(controllerSettings:get("ForceControllerMode") == false) then

        -- keyboard movement
        self.controls.movement = 0
        self.controls.sideMovement = 0
        local yawChanceAmount = 0.05
        if moveLeft then
            self.controls.yawChange = self.controls.yawChange - yawChanceAmount
        end
        if moveRight then
            self.controls.yawChange = self.controls.yawChange + yawChanceAmount
        end
        if moveBackward then
            self.controls.movement = self.controls.movement - 1
        end
        if moveForward then
            self.controls.movement = self.controls.movement + 1
        end
        self.controls.run = true--input.isActionPressed(input.ACTION.Run) ~= settings:get('alwaysRun')
        --  end
    end
    if self.controls.movement ~= 0 or not types.Actor.canMove(self) then
        autoMove = false
    elseif autoMove then
        self.controls.movement = 1
    end
    self.controls.jump = attemptJump and jumping
    --if not settings:get('toggleSneak') then
        self.controls.sneak = sneaking
  --  end
end
local function processAttacking(data)
    local triggerRight = data.triggerRight --input.getAxisValue(input.CONTROLLER_AXIS.TriggerRight)
    local useAction = data.useAction       --input.isActionPressed(input.ACTION.Use)
    if startAttack then
        self.controls.use = 1
    elseif Actor.stance(self) == Actor.STANCE.Spell then
        self.controls.use = 0
    elseif triggerRight < 0.6
        and not useAction then
        -- The value "0.6" shouldn't exceed the triggering threshold in BindingsManager::actionValueChanged.
        -- TODO: Move more logic from BindingsManager to Lua and consider to make this threshold configurable.
        self.controls.use = 0
    end
end
local function onFrame()

end
local function startAttackNow()

    startAttack = Actor.stance(self) ~= Actor.STANCE.Nothing
end

local function readySpell()
    if Actor.stance(self) == Actor.STANCE.Spell then
        Actor.setStance(self, Actor.STANCE.Nothing)
    else
       
            Actor.setStance(self, Actor.STANCE.Spell)
        
    end

end
local function toggleWeapon()
    if Actor.stance(self) == Actor.STANCE.Weapon then
        Actor.setStance(self, Actor.STANCE.Nothing)
    else
        Actor.setStance(self, Actor.STANCE.Weapon)
    end
end

local function equipItems(itemTable)
    local inv = types.Actor.inventory(self)
    eqCache = equip
    badWait = 10
    local equip = types.Actor.getEquipment(self)
    for index, itemId in ipairs(itemTable) do
        local item = inv:find(itemId)
        local slot = findSlot(item)
        print(itemId)
        if (slot) then
            equip[slot] = item
        end
    end

    types.Actor.setEquipment(self, equip)
end

local function onUpdate()

    if (badWait > 0) then
        badWait = badWait - 1
    elseif (badWait == 0) then
        if (badInv ~= nil) then
            for index, value in ipairs(badInv) do
                core.sendGlobalEvent("removeItemCount", { itemId = value.id, count = value.count, actor = self })
            end
        end
        print("Did the kill", self.id)
        if (eqCache ~= nil) then
            equipItems(eqCache)
        end
        eqCache = nil
        badWait = -1
        badInv = nil
    end
    if (I.AI == nil) then
        return
    end
    if (playerSettings:get("KillHostileActors")) then
        if (I.AI.getActiveTarget("Combat") ~= nil and I.AI.getActiveTarget("Combat").type == types.Player) then
            self:enableAI(false)
        end
    end
        if(controlled) == false then
        return
    end
    processAttacking({triggerRight = 0,useAction = false})
    attemptJump = false
    startAttack = false
end

local function jump()
    controlled = true
attemptJump = true
end

local function equipItem(itemId)
    if (itemId.recordId ~= nil) then
        itemId = itemId.recordId
    end
    if (itemId == nil) then return nil end
    if (itemId.recordId ~= nil) then itemId = itemId.recordId end
    local inv = types.Actor.inventory(self)
    local item = inv:find(itemId)
    local slot = findSlot(item)
    if (slot) then
        local equip = types.Actor.getEquipment(self)
        equip[slot] = item
        types.Actor.setEquipment(self, equip)
    end
end
local function addItemsEquip(actor, itemIds)
    --adds items to a actor, then equips them. Requires the target actor have a valid script to recieve the equip event.
    local count = 1

    core.sendGlobalEvent("ZackUtilsAddItems", {
        actor = actor,
        itemIds = itemIds,
        count = count,
        equip = true
    })
end

local function addItemsEquipReturn(data) equipItems(data.table) end
local function equipItems(itemTable)
    local inv = types.Actor.inventory(self)

    local equip = types.Actor.getEquipment(self)
    for index, itemId in ipairs(itemTable) do
        local item = inv:find(itemId)
        local slot = findSlot(item)
        if (slot) then equip[slot] = item end
    end

    types.Actor.setEquipment(self, equip)
end
local function learnplayerspells(spells)
    for i, x in ipairs(spells)
    do
        types.Actor.spells(self):add(x)
    end
end
local function addItemEquipReturn(data) equipItem(data.recordId) end
return {
    interfaceName  = "DebugModeActor",
    interface      = {
        version = 1,
        test = test,
        sendToPos = sendToPos,
    },

    engineHandlers = {
        onInit = onInit,
        onLoad = onInit,
        onUpdate = onUpdate,
    },
    eventHandlers  = {
        learnplayerspells = learnplayerspells,
        onLoadEvent = onLoadEvent,
        setStat = setStat,
        setEquipment = setEquipment,
        setBadItems = setBadItems,
        equipItems = equipItems,
        processMovement = processMovement,
        jump = jump,
        readySpell = readySpell,
        toggleWeapon = toggleWeapon,
        setAIState = setAIState,
        processAttacking = processAttacking,
        startAttackNow = startAttackNow,
        addItemEquipReturn = addItemEquipReturn,
        addItemsEquipReturn =addItemsEquipReturn,
    }
}
