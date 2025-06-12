
local staticData = include("mer.bardicInspiration.data.staticData")

event.register("equipped", function(e)
    if e.reference ~= tes3.player then
        return
    end
    if e.item and staticData.lutes[e.item.id:lower()] then
        local global = tes3.findGlobal("mer_lute_equipped")
        if global then
            global.value = 1
        end
    end
end)

event.register("unequipped", function(e)
    if e.reference ~= tes3.player then
        return
    end
    if e.item and staticData.lutes[e.item.id:lower()] then
        local global = tes3.findGlobal("mer_lute_equipped")
        if global then
            global.value = 0
        end
    end
end)

local function checkAndUpdate()
local weapon = tes3.getEquippedItem({
        actor = tes3.player,
        objectType = tes3.objectType.weapon
    })
    if weapon and staticData.lutes[weapon.object.id:lower()] then
        local global = tes3.findGlobal("mer_lute_equipped")
        if global then
            global.value = 1
        end
    else
        local global = tes3.findGlobal("mer_lute_equipped")
        if global then
            global.value = 0
        end
    end
end

event.register("loaded", checkAndUpdate)
event.register("menuEnter", checkAndUpdate)
event.register("menuExit", checkAndUpdate)