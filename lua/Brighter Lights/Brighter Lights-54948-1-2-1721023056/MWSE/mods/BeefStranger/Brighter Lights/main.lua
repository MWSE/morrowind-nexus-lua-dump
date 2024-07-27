local cfg = require("BeefStranger.Brighter Lights.config")
local lightKey = {}
local lights = {}
local saveWeap   --save last equipped weapon
local saveShield --save last equipped shield
local midnightOil


local function getDefaultRadius()
    ---Get all lights default radius
    for object in (tes3.iterateObjects(tes3.objectType.light)) do
        ---@cast object tes3light
        if object.canCarry then
            lights[object.id] = object.radius
        end
    end
end

event.register("initialized", function(e)
    print("[MWSE:Brighter Lights] initialized")
    midnightOil = tes3.isLuaModActive("mer.midnightOil")
    debug.log(midnightOil)
    getDefaultRadius()
end)

--- @param e equipEventData
local function radiusChange(e)
    if e.reference == tes3.player then
        -- debug.log(e.item.id)

        if lights[e.item.id] then
            local light = e.item
            -- debug.log(lights[light.id])
            e.item.radius = lights[light.id] * cfg.multi

            timer.delayOneFrame(function(e)
                -- debug.log(light.radius)
                if tes3.player.light then
                    tes3.player.light:setRadius(light.radius)
                end
            end, timer.real)
        end
    end
end
event.register(tes3.event.equip, radiusChange)


function lightKey.getLights()
    for _, stack in pairs(tes3.mobilePlayer.inventory) do
        if stack.object.canCarry and stack.variables then
            if midnightOil and stack.variables[1].timeLeft > 1 then
                return stack.object
            elseif not midnightOil then
                return stack.object
            end
        end
    end
end

function lightKey.saveEquip()
    local shield = tes3.getEquippedItem({actor = tes3.player, objectType = tes3.objectType.armor, slot = tes3.armorSlot.shield})
    if shield then
        saveShield = shield.object
    end

    local weapon = tes3.getEquippedItem({actor = tes3.player, objectType = tes3.objectType.weapon})
    if (weapon and weapon.object.isTwoHanded) or (weapon and weapon.object.isRanged) then
        saveWeap = weapon.object
    end
end

---@param e keyDownEventData
function lightKey.equip(e)
    if not tes3.menuMode() and e.keyCode == cfg.lightKey.keyCode and cfg.enableLK then
        local lightEquipped = tes3.getEquippedItem({actor = tes3.player, objectType = tes3.objectType.light})
        if lightEquipped then
            tes3.mobilePlayer:unequip({ type = tes3.objectType.light })
            if saveWeap then
                tes3.mobilePlayer:equip { item = saveWeap }
                saveWeap = nil
            elseif saveShield then
                tes3.mobilePlayer:equip { item = saveShield }
                saveShield = nil
            end
        else
            lightKey.saveEquip()
            tes3.mobilePlayer:equip { item = lightKey.getLights() }
        end

        return
    end
end
event.register(tes3.event.keyDown, lightKey.equip)
