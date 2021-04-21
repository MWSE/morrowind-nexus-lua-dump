local function traverse(roots)
  local function iter(nodes)
      for i, node in ipairs(nodes or roots) do
          if node then
              coroutine.yield(node)
              if node.children then
                  iter(node.children)
              end
          end
      end
  end
  return coroutine.wrap(iter)
end

local function removeLight(ref) 
  ref:deleteDynamicLightAttachment()

  for node in traverse{ref.sceneNode} do
    -- Kill particles
    if node.RTTI.name == "NiBSParticleNode" then
        node.appCulled = true
    end
    
    -- Kill materialProperty 
    local materialProperty = node:getProperty(0x2)
    if materialProperty then
      if (materialProperty.emissive.r > 1e-5 or materialProperty.emissive.g > 1e-5 or materialProperty.emissive.b > 1e-5 or materialProperty.controller) then
        local materialProperty = node:detachProperty(0x2):clone()
        node:attachProperty(materialProperty)

        -- Kill controllers
        materialProperty:removeAllControllers()
        
        -- Kill emissives
        local emissive = materialProperty.emissive
        emissive.r, emissive.g, emissive.b = 0,0,0
        materialProperty.emissive = emissive

        node:updateProperties()
      end
    end

    --[[ -- Kill glowmaps
    local texturingProperty = node:getProperty(0x4)
    local newTextureFilepath = "Textures\\Blank.dds"
    if (texturingProperty and texturingProperty.maps[4]) then
      texturingProperty.maps[4].texture = niSourceTexture.createFromPath(newTextureFilepath)
    end
    if (texturingProperty and texturingProperty.maps[5]) then
        texturingProperty.maps[5].texture = niSourceTexture.createFromPath(newTextureFilepath)
    end ]]
  end
end

local function onProjectileHit(e)
  if (e.firingWeapon == nil) then
    return
  end

  if (e.firingWeapon.objectType ~= tes3.objectType.ammunition and e.firingWeapon.objectType ~= tes3.objectType.weapon) then
    return
  end

  if (e.target and e.target.light) then
    removeLight(e.target)
  elseif (e.target and e.collisionPoint) then
    for ref in e.target.cell:iterateReferences() do
      if (ref.light) then
        if (ref.position:distance(e.collisionPoint) < 100) then
          removeLight(ref)
        end
      end
    end
  elseif (e.firingReference and e.collisionPoint) then
    for ref in e.firingReference.cell:iterateReferences() do
      if (ref.light) then
        if (ref.position:distance(e.collisionPoint) < 100) then
          removeLight(ref)
        end
      end
    end
  end
end

event.register("projectileHitObject", onProjectileHit)
event.register("projectileHitActor", onProjectileHit)
event.register("projectileHitTerrain", onProjectileHit)