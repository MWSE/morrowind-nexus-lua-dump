local logPrefix = "[Companion Compass] "
local companionCheckTimer


local function drawCompass()
  local menu = tes3ui.findMenu("MenuMulti")
  if not menu then return end
  local parent = menu:findChild("CompanionHealthBars:Menu")

  if not parent then return end
  if not parent.children then return end

--Iterate player's current followers
  for mobileActor in tes3.iterate(tes3.mobilePlayer.friendlyActors) do

--find label/block to validate companions
    local companionBar_id = "CompanionHealthBars:"..mobileActor.reference.id..".label"
    local companionBar = parent:findChild(companionBar_id)

--not found? Skip
    if not companionBar then goto continue end

--find compass in label/block
    local compass = companionBar:findChild("CompanionCompass")

--not found? update block to (compass, label) and attach click event to label
    if compass == nil then
      local nameplate = companionBar.children[1]
      
--original CHB by mesafoo
      if not nameplate then
        --create block
        local labelMenuID = tes3ui.registerID(companionBar_id)
        local labelMenu = parent:createBlock({id = labelMenuID})
        labelMenu.autoWidth = true
        labelMenu.autoHeight = false
        labelMenu.height = 24
        labelMenu.flowDirection = "left_to_right"

        --recreate nameplate in block
        nameplate = labelMenu:createLabel{
          text = mobileActor.reference.object.name
        }
        nameplate.height = 18
        nameplate.autoWidth = true

        --replace original label with block
        labelMenu:reorder({ before = companionBar })
        companionBar:destroy()
        companionBar = labelMenu
      end
      
      nameplate:registerAfter("mouseDown", function()
        tes3.runLegacyScript({ reference = mobileActor.reference, command = "ForceGreeting" })
      end)
      
      --create compass
      compass = companionBar:createImage({id = "CompanionCompass", path = "Textures\\compass.dds"})
      compass.scaleMode = true
      compass.width = 14
      compass.height = 14
      compass.borderTop = 6
      compass.borderLeft = 6
      compass.absolutePosAlignY = 0.5
      compass:reorder({ before = nameplate })

      menu:updateLayout()
    end

--update compass
    if compass.sceneNode then
      local comp = mobileActor.reference
      if not comp then goto continue end
      if not comp.sceneNode then goto continue end
      
      local p = tes3.player.sceneNode.worldTransform
      local f = comp.sceneNode.worldTransform

      local direction = p.rotation:transpose() * (f.translation - p.translation)
      local angle = -math.atan2(direction.x, direction.y)

      local m = tes3matrix33.new()
      m:toRotationY(angle)

      --origin is actually the center of the texture - Greatness7
      local trishape = compass.sceneNode.children[1]
      if trishape.name ~= "modified" then
          trishape.name = "modified"
          trishape.data.vertices[1] = tes3vector3.new(-9,0,9)
          trishape.data.vertices[2] = tes3vector3.new(-9,0,-9)
          trishape.data.vertices[3] = tes3vector3.new(9,0,9)
          trishape.data.vertices[4] = tes3vector3.new(9,0,-9)
          trishape.data:markAsChanged()
          trishape:update()
      end
      
      compass.sceneNode.rotation = m

      compass.sceneNode:update()
    end

    ::continue::
  end
end

local function companionCheck()
	--Only update if not in menu mode.
	if tes3ui.menuMode() == false then
    drawCompass()
	end
end

--Function for reinitializing our timer and events. Called on initial game loaded event and after our mcm menu is closed to reflect any potential option changes
function updateOptions()
	if companionCheckTimer ~= nil then
		companionCheckTimer:cancel()
	end
	companionCheckTimer = timer.start({ duration = 0.25, callback = companionCheck, iterations = -1 })
end

--Register for the events we'll be using
event.register("loaded", updateOptions)
mwse.log("%sInitialized", logPrefix)
