-- Make sure we're kinda sorta up to date
if (mwse.buildDate == nil) or (mwse.buildDate < 20210101) then
  event.register("initialized", function()
      tes3.messageBox(
          "[Molag Mar Temple Apartment] Your MWSE is out of date!"
          .. " You will need to update to a more recent version to use this mod."
      )
  end)
  return
end

local ids = {
  item = "ALAN_TA_ring of recall",
}

local coordinates = {
  position = tes3vector3.new(3854.492, 4095.973, 14912.646),
  -- TODO: Why on nirn can't we just face. the. wall.
  orientation = tes3vector3.new(0, 0, 90.0),
  cell = "Molag Mar, Temple Apartment"
}

local function onEquip(e)
  if (e.item.id == ids.item) then

    local canTeleport = not tes3.worldController.flagTeleportingDisabled
    if canTeleport then
      tes3ui.leaveMenuMode()

      tes3.playSound({
        sound = "mysticism hit",
        reference = tes3.player
      })

      timer.delayOneFrame(
        function()
          tes3.positionCell({
            reference = tes3.player,
            position = coordinates.position,
            orientation = coordinates.orientation,
            cell = coordinates.cell
          })
        end
      )

      return
    end
    -- Cannot teleport

    tes3.messageBox("Ring of apartment recall has failed.")
    return false
  end

end


local function onInitialized()
  if (tes3.isModActive("Molag Mar Temple Apartment.esp") == true) then
    event.register("equip", onEquip)
    mwse.log("[Molag Mar Temple Apartment] Initialized")
  end
end
event.register("initialized", onInitialized)
