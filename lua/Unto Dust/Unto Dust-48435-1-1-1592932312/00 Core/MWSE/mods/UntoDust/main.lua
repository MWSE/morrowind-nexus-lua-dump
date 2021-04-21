local re = require("re")

-- note: make sure any pattern additions are lowercase
local pattern = re.compile[[ "tomb" / "barrow" / "crypt" / "catacomb" / "burial" ]]

local root = nil
local dust = nil


local function onCellChanged()
    local cell = tes3.player.cell

    if cell.isInterior then
        dust.appCulled = re.find(cell.id:lower(), pattern) == nil
    else
        dust.appCulled = true
    end

    if dust.appCulled == false then
        local t = root.worldTransform
        local p = tes3.getPlayerEyePosition()
        dust.translation = (t.rotation * t.scale):invert() * (p - t.translation)
    end

    dust:update{controller=true}
    dust:updateProperties()
    dust:updateNodeEffects()
end
event.register("cellChanged", onCellChanged)


local function onLoaded(e)
    root = tes3.worldController.worldCamera.cameraRoot

    dust = root:getObjectByName("AttachDust")
    if dust == nil then
        dust = tes3.loadMesh("dust\\dust.nif")
        assert(dust.name == "AttachDust")
        root:attachChild(dust)
    end

    onCellChanged()
end
event.register("loaded", onLoaded)