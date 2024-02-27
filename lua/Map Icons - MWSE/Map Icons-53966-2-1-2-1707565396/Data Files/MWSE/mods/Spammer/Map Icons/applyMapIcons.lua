local mod = require("Spammer\\Map Icons\\mod")
local skyIcons = require("Spammer\\Map Icons\\skyIcons")
local vanillaIcons = require("Spammer\\Map Icons\\vanillaIcons")
local cf = mwse.loadConfig(mod.name, mod.cf)
---@param menu tes3uiElement
---@param config table|nil
return function(menu, config)
    cf = config or cf
    --if not (cf.onOff or tes3ui.menuMode()) then return end
    local map = menu:findChild("MenuMap_local")
    if not map then return end
    local icons = (cf.switch and skyIcons) or vanillaIcons
    local multiplier = (cf.switch and 2) or 1
    --mwse.log(map and map.visible)
    ---@param child tes3uiElement
    for child in table.traverse(map.children) do
        if child.name == "MenuMap_active_door" then
            local doorRef = child:getPropertyObject("MenuMap_object")
            --debug.log(doorRef.tempData and doorRef.tempData.spa_MapIcons)
            --debug.log(doorRef.tempData and lfs.fileexists("Data Files\\" .. doorRef.tempData.spa_MapIcons))
            if doorRef and doorRef.destination and cf.blocked[doorRef.destination.cell.id] then
                if child.contentPath ~= cf.blocked[doorRef.destination.cell.id] then
                    child.contentPath = cf.blocked[doorRef.destination.cell.id]
                end
            else
                if (doorRef and doorRef.tempData and doorRef.tempData.spa_MapIcons) and (child.contentPath ~= doorRef.tempData.spa_MapIcons) and (lfs.fileexists("Data Files\\" .. doorRef.tempData.spa_MapIcons)) then
                    --debug.log(doorRef.tempData.spa_MapIcons)
                    child.contentPath = doorRef.tempData.spa_MapIcons
                elseif doorRef and not (doorRef.supportsLuaData or (child.contentPath == icons["active_door"])) then
                    child.contentPath = icons["active_door"]
                end
            end
            child.scaleMode = true
            child.height = 3 * cf.slider * multiplier
            child.width = 3 * cf.slider * multiplier

            if cf.skyrim and doorRef and doorRef.position.z > (tes3.player.position.z + 256) then
                child.color = tes3ui.getPalette(tes3.palette.fatigueColor)
            elseif cf.skyrim and doorRef and doorRef.position.z < (tes3.player.position.z - 256) then
                child.color = tes3ui.getPalette(tes3.palette.healthColor)
            elseif child.color ~= tes3ui.getPalette(tes3.palette.activeColor) then
                child.color = tes3ui.getPalette(tes3.palette.normalColor)
            end
        end
    end
    --menu:updateLayout()
end
