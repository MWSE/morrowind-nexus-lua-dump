-- Declare Static Variables --
local unitsPerFoot = 21.3
local whitelistedCreaturesAsNpcs = {
  ["vivec_god"] = true,
  ["almalexia"] = true,
  ["Almalexia_warrior"] = true,
  ["BM_werewolf_ritual"] = true,
  ["BM_werewolf_default"] = true,
  ["OJ_ME_Werewolf"] = true,
}
----------------------------

-- Declare Controllers --
local timerController = nil
local stateControllers = nil
local referenceControllers = nil
----------------------------

-- Declare Data Structures --
local StateController = {
  new = function(self, o)
    o = o or {}   -- create object if user does not provide one
    setmetatable(o, self)
    self.__index = self
    return o
  end,

  effect = nil,
  active = nil,
  magnitude = nil,
  update = function(self)
    self.active = tes3.isAffectedBy({
      reference = tes3.player,
      effect = self.effect
    })
    self.magnitude = nil

    if (self.active == true) then
      stateControllers.active = true
      self.magnitude = tes3.getEffectMagnitude({
        reference = tes3.player,
        effect = self.effect
      })
    end
  end
}

local VisualController = {
  new = function(self, o)
    o = o or {}   -- create object if user does not provide one
    setmetatable(o, self)
    self.__index = self
    return o
  end,

  vfxName = nil,
  vfxPath = nil,
  vfxCenter = nil,
  vfx = nil,

  load = function(self)
    self.vfx = tes3.loadMesh(self.vfxPath)
  end,
  attach = function (self, ref)
    if (ref.sceneNode) then
      local node = self.vfx:clone()
      if (self.vfxCenter) then
        local boundingBox = ref.object.boundingBox
        if (boundingBox) then
          node.translation = (boundingBox.min + boundingBox.max) * 0.5
        end
      end

      if (ref.object.race) then
        if (ref.object.race.weight and ref.object.race.height) then
          local weight = ref.object.race.weight.male
          local height = ref.object.race.height.male
          if (ref.object.female == true) then
            weight = ref.object.race.weight.female
            height = ref.object.race.height.female
          end

          local weightMod = 1 / weight
          local heightMod = 1/ height

          local r = node.rotation
          local s = tes3vector3.new(weightMod, weightMod, heightMod)
          node.rotation = tes3matrix33.new(r.x * s, r.y * s, r.z * s)
        end
      end
  
      ref.sceneNode:attachChild(node, true)
      ref.sceneNode:update()
      ref.sceneNode:updateNodeEffects()
    end
  end,
  detach = function(self, ref)
    if (ref.sceneNode) then
      local node = ref.sceneNode:getObjectByName(self.vfxName)
      if (node ~= nil) then
          node.parent:detachChild(node)
      end
      ref.sceneNode:update()
      ref.sceneNode:updateNodeEffects()
    end
  end
}

local ReferenceController = {
  new = function(self, o)
    o = o or {}   -- create object if user does not provide one
    setmetatable(o, self)
    self.__index = self
    return o
  end,

  references = nil,
  visualController = nil,
  stateController = nil,

  conditional = nil,

  handler = function (self, ref, playerPosition)
    if (self:conditional(ref) == true) then
      self:handlerSub(ref, playerPosition, self.stateController.magnitude)
    end
  end,
  handlerSub = function(self, ref, playerPosition, magnitude) 
    local radius = magnitude * unitsPerFoot

    local contains = self.references[ref] or false
    local distance = ref.position:distance(playerPosition)
    if (ref.mobile) then
      if (contains == false and distance <= radius and ref.mobile.isDead == false) then
        self.visualController:attach(ref)
        self.references[ref] = true
      elseif (contains == true and distance > radius) then
        self.visualController:detach(ref)
        self.references[ref] = nil
      elseif (contains == true and ref.mobile.isDead == true) then
        self.visualController:detach(ref)
        self.references[ref] = nil
      end
    else
      if (contains == false and distance <= radius) then
        self.visualController:attach(ref)
        self.references[ref] = true  
      elseif (contains == true and distance > radius) then
        self.visualController:detach(ref)
        self.references[ref] = nil
      end
    end
  end,

  clean = function(self)
    self:cleanSub(self.stateController.active)
  end,
  cleanSub = function(self, active)
    if (active == false) then
      for ref, _ in pairs(self.references) do
        self.visualController:detach(ref)
        self.references[ref] = nil
      end
    end
  end
}
-------------------------

-- Initialize Controllers --
timerController = {
  callback = function()
    -- Update state of magic effects.
    stateControllers:update()

    -- If state is inactive, exit.
    if (stateControllers.active == false) then
        -- Check if there are also no active references and stop timer if so.
      local count = 0
      for _, referenceController in pairs(referenceControllers) do
        for ref, _ in pairs(referenceController.references) do
          count = count + 1
        end
      end

      if (count == 0) then
        timerController:cancel()
      end

      return
    end

    -- Update references based on effect state and distance.
    local playerPosition = tes3.player.position
    local cells = tes3.getActiveCells()
    for _, cell in pairs(cells) do
        for ref in cell:iterateReferences() do
          if (ref.disabled == false and ref.sceneNode) then 
            for _, referenceController in pairs(referenceControllers) do
              referenceController:handler(ref, playerPosition)
            end
          end
        end
    end

    -- Clean list of references. This removes vfx from all references when the effect ends.
    for _, referenceController in pairs(referenceControllers) do
      referenceController:clean()
    end
  end,
  active = false,
  timer = nil,

  start = function(self)
    self.active = true
    self.timer = timer.start({
      iterations = -1,
      duration = 0.5,
      callback = self.callback
    })
  end,
  cancel = function(self)
    self.active = false
    self.timer = self.timer:cancel()
    self.timer = nil
  end,
}

stateControllers = {
  active = false,
  update = function(self)
    active = false
    self.animal:update()
    self.key:update()
    self.enchantment:update()
    self.daedra:update()
    self.automaton:update()
    self.humanoid:update()
    self.dead:update()
    self.undead:update()
    self.door:update()
    self.trap:update()
  end,

  animal = StateController:new({effect = tes3.effect.detectAnimal}),
  key = StateController:new({effect = tes3.effect.detectKey}),
  enchantment = StateController:new({effect = tes3.effect.detectEnchantment}),
  daedra = StateController:new({effect = tes3.effect.detectDaedra}),
  automaton = StateController:new({effect = tes3.effect.detectAutomaton}),
  humanoid = StateController:new({effect = tes3.effect.detectHumanoid}),
  dead = StateController:new({effect = tes3.effect.detectDead}),
  undead = StateController:new({effect = tes3.effect.detectUndead}),
  door = StateController:new({effect = tes3.effect.detectDoor}),
  trap = StateController:new({effect = tes3.effect.detectTrap}),
}

referenceControllers = {
  animal = ReferenceController:new({
    references = {},
    visualController = VisualController:new({ 
      vfxName = "ED_RFD_DetectAnimal",
      vfxPath = "OJ\\ED\\ED_RFD_DetectAnimal.nif",
      vfxCenter = true
    }),
    stateController = stateControllers.animal,

    conditional = function (self, ref)
      if (self.stateController.active == true) then
        if (ref.object.objectType == tes3.objectType.creature and ref.object.type == tes3.creatureType.normal and ref.object.actorFlags) then
          -- Check if metal bloodtype is not set to exclude automatons.
          if (bit.band(ref.object.actorFlags, 0x800) == 0) then
            return true
          end
        end
      end
      return false
    end,
  }),

  key = ReferenceController:new({
    references = {},
    visualController = VisualController:new({ 
      vfxName = "ED_RFD_DetectKey",
      vfxPath = "OJ\\ED\\ED_RFD_DetectKey.nif",
      vfxCenter = true
    }),
    stateController = stateControllers.key,
    
    conditional = function (self, ref)
      if (self.stateController.active == true) then
        if (ref.object.isKey == true) then
          return true
        end

        if (ref.object.inventory) then
          for _, stack in pairs(ref.object.inventory) do
            if (stack.object.isKey == true) then
              return true
            end
          end
        end
      end
      return false
    end,
  }),

  enchantment = ReferenceController:new({
    references = {},
    visualController = VisualController:new({ 
      vfxName = "ED_RFD_DetectEnchantment",
      vfxPath = "OJ\\ED\\ED_RFD_DetectEnchantment.nif",
      vfxCenter = true
    }),
    stateController = stateControllers.enchantment,
    
    conditional = function (self, ref)
      if (self.stateController.active == true) then
        if (ref.object.enchantment) then
          return true
        end
        if (ref.object.isSoulGem) then
          return true
        end

        if (ref.object.inventory) then
          for _, stack in pairs(ref.object.inventory) do
            if (stack.object.enchantment) then
              return true
            end

            if (stack.object.isSoulGem) then
              return true
            end
          end
        end
      end
      return false
    end,
  }),

  daedra = ReferenceController:new({
    references = {},
    visualController = VisualController:new({ 
      vfxName = "ED_RFD_DetectDaedra",
      vfxPath = "OJ\\ED\\ED_RFD_DetectDaedra.nif",
      vfxCenter = true
    }),
    stateController = stateControllers.daedra,
    
    conditional = function (self, ref)
      if (self.stateController.active == true) then
        if (ref.object.objectType == tes3.objectType.creature and ref.object.type == tes3.creatureType.daedra and whitelistedCreaturesAsNpcs[ref.object.id] == nil) then
          return true
        end
      end
      return false
    end,
  }),

  automaton = ReferenceController:new({
    references = {},
    visualController = VisualController:new({ 
      vfxName = "ED_RFD_DetectAutomaton" ,
      vfxPath = "OJ\\ED\\ED_RFD_DetectAutomaton.nif",
      vfxCenter = true
    }),
    stateController = stateControllers.automaton,
    
    conditional = function (self, ref)
      if (self.stateController.active == true) then
        if (ref.object.objectType == tes3.objectType.creature and  ref.object.type == tes3.creatureType.normal and ref.object.actorFlags) then
          -- Check if metal bloodtype is set.
          if (bit.band(ref.object.actorFlags, 0x800) ~= 0) then
            return true
          end
        end
      end
      return false
    end,
  }),

  humanoid = ReferenceController:new({
    references = {},
    visualController = VisualController:new({ 
      vfxName = "ED_RFD_DetectHumanoid" ,
      vfxPath = "OJ\\ED\\ED_RFD_DetectHumanoid.nif",
      vfxCenter = true
    }),
    stateController = stateControllers.humanoid,
    
    conditional = function (self, ref)
      if (self.stateController.active == true) then
        if (ref.object.objectType == tes3.objectType.npc) then
          return true
        end
        if (ref.object.objectType == tes3.objectType.creature and ref.object.type == tes3.creatureType.humanoid) then
          return true
        end
        if (ref.object.objectType == tes3.objectType.creature and whitelistedCreaturesAsNpcs[ref.object.id]) then
          return true
        end
      end
      return false
    end,
  }),

  dead = ReferenceController:new({
    references = {},
    visualController = VisualController:new({ 
      vfxName = "ED_RFD_DetectDead" ,
      vfxPath = "OJ\\ED\\ED_RFD_DetectDead.nif"
    }),
    stateController = stateControllers.dead,
    
    conditional = function (self, ref)
      if (self.stateController.active == true) then
        if (ref.object.objectType == tes3.objectType.npc or ref.object.objectType == tes3.objectType.creature) then
          if (ref.mobile.isDead == true) then
            return true
          end
        end
      end
      return false
    end,
    handler = function (self, ref, playerPosition)
      if (self:conditional(ref) == true) then
        local radius = stateControllers.dead.magnitude * unitsPerFoot

        local contains = self.references[ref] or false
        local distance = ref.position:distance(playerPosition)
        if (contains == false and distance <= radius) then
          self.visualController:attach(ref)
          self.references[ref] = true
        elseif (contains == true and distance > radius) then
          self.visualController:detach(ref)
          self.references[ref] = nil
        end
      end
    end,
  }),

  undead = ReferenceController:new({
    references = {},
    visualController = VisualController:new({ 
      vfxName = "ED_RFD_DetectUndead" ,
      vfxPath = "OJ\\ED\\ED_RFD_DetectUndead.nif",
      vfxCenter = true
    }),
    stateController = stateControllers.undead,
    
    conditional = function (self, ref)
      if (self.stateController.active == true) then
        if (ref.object.objectType == tes3.objectType.creature and ref.object.type == tes3.creatureType.undead) then
          return true
        end
      end
      return false
    end,
  }),

  door = ReferenceController:new({
    references = {},
    visualController = VisualController:new({ 
      vfxName = "ED_RFD_DetectDoor" ,
      vfxPath = "OJ\\ED\\ED_RFD_DetectDoor.nif",
      vfxCenter = true
    }),
    stateController = stateControllers.door,
    
    conditional = function (self, ref)
      if (self.stateController.active == true) then
        if (ref.object.objectType == tes3.objectType.door) then
          return true
        end
      end
      return false
    end,
  }),

  trap = ReferenceController:new({
    references = {},
    visualController = VisualController:new({ 
      vfxName = "ED_RFD_DetectTrap" ,
      vfxPath = "OJ\\ED\\ED_RFD_DetectTrap.nif",
      vfxCenter = true
    }),
    stateController = stateControllers.trap,
    
    conditional = function (self, ref)
      if (self.stateController.active == true) then
        if (ref.object.objectType == tes3.objectType.door or
            ref.object.objectType == tes3.objectType.container) then
          if (tes3.getTrap({reference = ref})) then
            return true
          end
        end
      end
      return false
    end,
  }),
}
-------------------------

return {
  referenceControllers = referenceControllers, 
  timerController = timerController
}