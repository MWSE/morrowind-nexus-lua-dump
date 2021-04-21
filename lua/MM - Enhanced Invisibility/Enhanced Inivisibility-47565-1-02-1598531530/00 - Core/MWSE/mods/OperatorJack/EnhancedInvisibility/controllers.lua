-- Declare Static Variables --
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
  update = function(self)
    self.active = tes3.isAffectedBy({
      reference = tes3.player,
      effect = self.effect
    })

    if (self.active == true) then
      stateControllers.active = true
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

  handler = function (self, ref)
    if (self:conditional(ref) == true) then
      self:handlerSub(ref)
    end
  end,
  handlerSub = function(self, ref) 
    local contains = self.references[ref] or false
    if (ref.mobile) then
      if (contains == false and ref.mobile.isDead == false) then      
        self.visualController:attach(ref)
        self.references[ref] = true
      elseif (contains == true and ref.mobile.isDead == true) then
        self.visualController:detach(ref)
        self.references[ref] = nil
      end
    else
      if (contains == false) then
        self.visualController:attach(ref)
        self.references[ref] = true  
      elseif (contains == true) then
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
local shaderActive = false
timerController = {
  callback = function()
    -- Update state of magic effects.
    stateControllers:update()

    -- If state is inactive, exit.
    if (stateControllers.active == false) then  
        -- Check if there are also no active references and stop timer if so.
        local count = 0
        for _, referenceController in pairs(referenceControllers) do
          referenceController:clean()
          for ref, _ in pairs(referenceController.references) do
            count = count + 1
          end
        end
  
        if (count == 0) then
          -- Disable shaders.
          --print("Disabling shader.")
          mge.disableShader({shader="Invisibility"})
          shaderActive = false

          timerController:cancel()
        end
  
        return
    end

    if (stateControllers.active == true and shaderActive == false) then
      -- Enable shaders.
      --print("Enabling shader.")
      mge.enableShader({shader="Invisibility"})
      shaderActive = true
    end

    -- Update references based on effect state.
    local cells = tes3.getActiveCells()
    for _, cell in pairs(cells) do
        for ref in cell:iterateReferences() do
          if (ref.disabled == false and ref.sceneNode) then 
            for _, referenceController in pairs(referenceControllers) do
              referenceController:handler(ref)
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

  init = function(self)  
    -- Update state of magic effects.
    stateControllers:update()
    if (stateControllers.active == false) then
      -- Disable shader.
      timer.start({
        iterations = 100,
        duration = 0.01,
        callback = function()
          --print("Disabling shader.")
          mge.disableShader({shader="Invisibility"})
          shaderActive = false
        end
      })
      -- Disable shader.
      timer.start({
        iterations = 1,
        duration = 1,
        callback = function()
          self:start()
        end
      })
    else
      self:start()
    end
  end,
  start = function(self)
    self.active = true
    self.timer = timer.start({
      iterations = -1,
      duration = 0.1,
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
    self.active = false
    self.daedra:update()
    self.undead:update()
  end,

  daedra = StateController:new({effect = tes3.effect.invisibility}),
  undead = StateController:new({effect = tes3.effect.invisibility}),
}

referenceControllers = {
  daedra = ReferenceController:new({
    references = {},
    visualController = VisualController:new({ 
      vfxName = "EI_DaedraVfx",
      vfxPath = "OJ\\EI\\EI_DaedraVfx.nif",
      vfxCenter = false
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

  undead = ReferenceController:new({
    references = {},
    visualController = VisualController:new({ 
      vfxName = "EI_UndeadVfx" ,
      vfxPath = "OJ\\EI\\EI_UndeadVfx.nif",
      vfxCenter = false
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
}
-------------------------

return {
  referenceControllers = referenceControllers, 
  timerController = timerController
}