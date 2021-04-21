local ids = {
    bag = "OJ_BOH_BagOfHolding",
    container = "OJ_BOH_BagOfHoldingCont"
}
local containerRef = nil
local function onEquip(e)
    if (e.item.id == ids.bag) then
        if (containerRef == nil) then
            containerRef = tes3.getReference(ids.container)
        end

        timer.delayOneFrame(
            function() 
                tes3.player:activate(containerRef)
            end,
            timer.real     
        )

        return false
    end
end
event.register("equip", onEquip)