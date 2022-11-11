local locData = {
    ["ossuary of ayem"] = {
        exMarker = {
            position = tes3vector3.new(2037, 63236, 5073),
            orientation = tes3vector3.new(0, 0, -0.46)
        },
        inMarker = {
            cell = "Ossuary of Ayem, Great Hall",
            position = tes3vector3.new(6352, 5584, 17152),
            orientation = tes3vector3.new(0, 0, -3.14)
        }
    },
    ["ossuary of seht"] = {
        exMarker = {
            position = tes3vector3.new(56140, 59148, 776),
            orientation = tes3vector3.new(0, 0, -1.4)
        },
        inMarker = {
            cell = "Ossuary of Seht",
            position = tes3vector3.new(-960, 10560, 16320),
            orientation = tes3vector3.new(0, 0, -1.57)
        }
    },
    ["ossuary of vehk"] = {
        exMarker = {
            position = tes3vector3.new(11509, 100113, 9788),
            orientation = tes3vector3.new(0, 0, 1.37)
        },
        inMarker = {
            cell = "Ossuary of Vehk, Hall of the Order",
            position = tes3vector3.new(1804, 3715, 14093),
            orientation = tes3vector3.new(0, 0, -1.57)
        }
    },
    ["eastern catacombs"] = {
        inMarker = {
            cell = "Ghostfence, Eastern Catacombs",
            position = tes3vector3.new(-320, 128, 0),
            orientation = tes3vector3.new(0, 0, 0)
        }
    },
    ["southern catacombs"] = {
        inMarker = {
            cell = "Ghostfence, Southern Catacombs",
            position = tes3vector3.new(-384, 0, -48),
            orientation = tes3vector3.new(0, 0, 1.55)
        }
    },
    ["western catacombs"] = {
        inMarker = {
            cell = "Ghostfence, Western Catacombs",
            position = tes3vector3.new(1539, 14790, 1298),
            orientation = tes3vector3.new(0, 0, -3.12)
        }
    }
}

event.register("UIEXP:sandboxConsole", function(e)
    e.sandbox.coc = function(locName, exOrIn)
        local isEx = (exOrIn == "ex")
        local isIn = (exOrIn == "in") or not exOrIn
        if not ((isEx and locData[locName:lower()].exMarker) or
            (isIn and locData[locName:lower()].inMarker)) then
            tes3.messageBox("invalid location data")
            return
        end
        local executed
        if isEx then
            executed = tes3.positionCell({
                position = locData[locName:lower()].exMarker.position,
                orientation = locData[locName:lower()].exMarker.orientation
            })
        else
            executed = tes3.positionCell({
                cell = locData[locName:lower()].inMarker.cell,
                position = locData[locName:lower()].inMarker.position,
                orientation = locData[locName:lower()].inMarker.orientation
            })
        end
        if not executed then tes3.messageBox("command failed") end
    end
end)

-- lua console command examples:
-- coc "southern catacombs"
-- coc("ossuary of ayem","ex")
-- coc "ossuary of seht"
-- coc("ossuary of vehk","in")
