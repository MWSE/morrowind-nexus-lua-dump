local curseSpell = tes3.getObject("ek_bdc_curseSpell")
local curseLevel = tes3.findGlobal("ek_bdc_curseLevel")


local function refreshCurse()
    if curseLevel.value ~= 0 then

        tes3.removeSpell{reference=tes3.player, spell=curseSpell}

        for i, effect in pairs(curseSpell.effects) do
            effect.min = curseLevel.value
            effect.max = curseLevel.value
        end

        tes3.addSpell{reference=tes3.player, spell=curseSpell}
    end
end
event.register("loaded", refreshCurse)


local function applyCurse(e)
    if e.reference ~= tes3.player then
        return
    elseif e.item.id:lower() ~= "nuccius_ring" then
        return
    end

    tes3.messageBox("The curse drains your attributes!")

    curseLevel.value = 1
    refreshCurse()

    timer.start({
        type = timer.game,
        duration = 1,
        iterations = -1,
        callback = "BDC:CurseTimer",
        persist = true,
    })
end
event.register("equipped", applyCurse)


local function forceEquipped(e)
    if curseLevel.value == 0 then
        return
    elseif e.reference ~= tes3.player then
        return
    elseif e.item.id:lower() ~= "nuccius_ring" then
        return
    end

    timer.frame.delayOneFrame(function()
        e.mobile:equip({item=e.item, addItem=true})
    end)

    tes3.messageBox("The curse prevents you from removing this ring from your body.")
end
event.register("unequipped", forceEquipped)


local function curseMessage(e)
    if curseLevel.value == 0 then
        return
    elseif e.item.id:lower() ~= "nuccius_ring" then
        return
    end

    if e.menu.name == "MenuInventory" then
        e.element:register("mouseClick", function(e)
            if tes3ui.findMenu("MenuBarter") then
                tes3.messageBox("That ring gives me a bad feeling, I won't buy it.")
            else
                tes3.messageBox("The curse prevents you from removing this ring from your body.")
            end
        end)
    end

    if e.menu.name == "MenuContents" then
        local owner = e.menu:getPropertyObject("MenuContents_ObjectRefr")
        if owner and owner ~= tes3.player then
            tes3.removeItem{reference=owner, item=e.item}
        end
    end
end
event.register("itemTileUpdated", curseMessage)


local function curseTimer(e)
    if curseLevel.value == 0 then
        e.timer:cancel()
    else
        tes3.messageBox("The curse progresses its affliction on your attributes!")
        curseLevel.value = curseLevel.value + 1
        refreshCurse()
    end
end
timer.register("BDC:CurseTimer", curseTimer)


local function travelDiscount(e)
    if e.reference.object.name == "Darvame Hleran" then
        local index = tes3.getJournalIndex{id="ek_bdc_vodunius"}
        if (index >= 20) and (index < 45) then
            e.price = e.price * 0.5
        end
    end
end
event.register("calcTravelPrice", travelDiscount)
