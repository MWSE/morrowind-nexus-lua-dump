local seph = require("seph")

local compatibility = seph.Module()

compatibility.mods = {
    ["Aleist3r\\Clock Block"] = {
        name = "Aleist3r:ClockBlock",
        displayName = "Clock Block",
        defaults = {
            visible = true,
            width = 96,
            height = 20
        },
        options = {
            size = true,
            visibility = true
        }
    },
    ["stealth"] = {
        name = "Stealth:LightbarBlock",
        displayName = "Stealth Improved Lightbar",
        defaults = {
            positionX = 0.5,
            positionY = 1.0
        },
        options = {
            position = true
        }
    },
    ["Memory Monitor"] = {
        name = "NullC:MemoryUsage",
        displayName = "Memory Monitor",
        defaults = {
            visible = true,
            width = 96,
            height = 12
        },
        options = {
            size = true,
            visibility = true
        }
    },
    ["OperatorJack\\EncumbranceBar"] = {
        name = "EncumbranceBar:FillbarBlock",
        displayName = "Encumbrance Bar",
        defaults = {
            visible = true,
            positionX = 0.0,
            positionY = 0.94,
            width = 80,
            height = 14
        },
        options = {
            position = true,
            size = true,
            visibility = true
        },
        sizeUpdated = {
            callback = function(eventData)
                local fillBar = eventData.element:findChild(tes3ui.registerID("EncumbranceBar:Fillbar"))
                if fillBar then
                    fillBar.width = eventData.width
                    fillBar.height = eventData.height
                end
            end
        }
    },
    ["Map and Compass"] = {
        name = "CompassFace",
        displayName = "Map and Compass",
        defaults = {
            visible = true
        },
        options = {
            visibility = true
        },
        sizeUpdated = {
            filter = "MenuMap_panel",
            callback = function(eventData)
                local compassFace = eventData.element:findChild(tes3ui.registerID("CompassFace"))
                if compassFace then
                    compassFace.scaleMode = true
                    compassFace.width = eventData.width * 0.95
                    compassFace.height = eventData.height * 0.95
                    compassFace.absolutePosAlignX = 0.5
                    compassFace.absolutePosAlignY = 0.5
                end
            end
        }
    }
}

function compatibility:doesModExist(modFolder)
    return lfs.directoryexists(string.format("Data Files\\MWSE\\mods\\%s", modFolder))
end

function compatibility:onMorrowindInitialized(eventData)
	for modFolder, modRegistration in pairs(self.mods) do
        if self:doesModExist(modFolder) then
            self.mod.modules.interop:registerElement(
                modRegistration.name,
                modRegistration.displayName,
                modRegistration.defaults,
                modRegistration.options
            )
            if modRegistration.positionUpdated then
                event.register("seph.hudCustomizer:positionUpdated", modRegistration.positionUpdated.callback, {filter = modRegistration.positionUpdated.filter or modRegistration.name})
            end
            if modRegistration.sizeUpdated then
                event.register("seph.hudCustomizer:sizeUpdated", modRegistration.sizeUpdated.callback, {filter = modRegistration.sizeUpdated.filter or modRegistration.name})
            end
            if modRegistration.visibilityUpdated then
                event.register("seph.hudCustomizer:visibilityUpdated", modRegistration.visibilityUpdated.callback, {filter = modRegistration.visibilityUpdated.filter or modRegistration.name})
            end
            if modRegistration.alphaUpdated then
                event.register("seph.hudCustomizer:alphaUpdated", modRegistration.alphaUpdated.callback, {filter = modRegistration.alphaUpdated.filter or modRegistration.name})
            end
        end
    end
end

return compatibility