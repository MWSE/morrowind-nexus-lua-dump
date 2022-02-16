-- slow water marker ID "0s_wc_s"
-- fast water marker ID "0s_wc_f"

local powerMap = {
    f = { range = 512, force = 100 },
    s = { range = 1024, force = 20 },
    }

local function waterCurrent(e)
    for _, activeCell in ipairs(tes3.getActiveCells()) do
        for stat in activeCell:iterateReferences(tes3.objectType.static) do
            local id = stat.baseObject.id:lower()
            if string.match(id, "0s_wc_") then
                local power = id:sub(-1, -1)
                local speed = powerMap[power].force
                local markerPosition = stat.position
                local mobileList = tes3.findActorsInProximity{
                    reference = stat,
                    range = powerMap[power].range,
                }
                for _, mobile in ipairs(mobileList) do
                    if mobile.isSwimming then
                        local swimmerPosition = mobile.position
                        local proximity = markerPosition:distance(swimmerPosition)
                        local half = (powerMap[power].range / 2)
                        if proximity >= half then
                            speed = (speed * ((powerMap[power].range - proximity) / half ))
                        end
                        mobile.position = mobile.position + (stat.sceneNode.rotation:transpose().y * speed * e.delta)
                    end
                end
            end
        end
    end
end

  local function onLoaded()
    event.register("simulate", waterCurrent)
  end

  local function initialized()
      if tes3.isModActive("WaterCurrent.ESP") then
          event.register("loaded", onLoaded)
      else
          mwse.log("WaterCurrent.ESP not detected")
      end
  end
  event.register("initialized", initialized)