-- Make sure we have an up-to-date version of MWSE.
if (mwse.buildDate == nil) or (mwse.buildDate < 20200521) then
  event.register("initialized", function()
      tes3.messageBox(
          "[Dwemer Teleportation Box] Your MWSE is out of date!"
          .. " You will need to update to a more recent version to use this mod."
      )
  end)
  return
end

local ids = {
  box = "OJ_DTB_DwrTeleBox",
  marker = "OJ_DTB_DwemerMarker"
}

local function onEquip(e)
  if (e.item.id == ids.box) then

		local canTeleport = not tes3.worldController.flagTeleportingDisabled
    if canTeleport then    
      local reference = tes3.findClosestExteriorReferenceOfObject({
        object = ids.marker,
      })

      if (reference) then
        tes3ui.leaveMenuMode()

        tes3.playSound({
          sound = "mysticism hit",
          reference = tes3.player
        })

        timer.delayOneFrame(
          tes3.positionCell({
            reference = tes3.player,
            position = reference.position,
            orientation = reference.orientation,
            cell = reference.cell
          })
        )
        return
      end
      -- No reference
    end
    -- Cannot teleport


    tes3.messageBox("The Dwemer Teleportation Box fails to function.")
    return false
  end
end


local function onInitialized()
  if (tes3.isModActive("Dwemer Teleportation Box.esp") == true) then
    event.register("equip", onEquip)
  end
end
event.register("initialized", onInitialized)