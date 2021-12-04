local interop = {}

interop.offsetValue = 360

interop.wearableSlots = {
    [interop.offsetValue + 0] = "Facepaint",
    [interop.offsetValue + 1] = "Eyewear",
    [interop.offsetValue + 2] = "Facewear",
    [interop.offsetValue + 3] = "Earwear",
    [interop.offsetValue + 4] = "Lipwear",
    [interop.offsetValue + 5] = "Nosewear",
    [interop.offsetValue + 6] = "Headwear"
}

interop.wearables = {}

interop.types = {
    facepaint   = interop.offsetValue + 0,
    eyewear  = interop.offsetValue + 1,
    facewear = interop.offsetValue + 2,
    earwear  = interop.offsetValue + 3,
    lipwear  = interop.offsetValue + 4,
    nosewear = interop.offsetValue + 5,
    headwear = interop.offsetValue + 6
}

function interop.registerWearable(id, type, raceSub, racePos, raceScale)
    interop.wearables[id] = { id = id, type = type, raceSub = raceSub, racePos = racePos, raceScale = raceScale, mesh = {} }
end

function interop.registerSubstitute(id, wearableId, racePos, raceScale)
    interop.substitutes[wearableId] = { id = id, wearableId = wearableId, racePos = racePos, raceScale = raceScale, mesh = {} }
end

function interop.registerAll()
    pcall(function()
        for k, v in pairs(interop.wearableSlots) do
            tes3.addArmorSlot { slot = k, name = v }
        end
    end)
    for k, v in pairs(interop.wearables) do
        -- remap slot to custom wearableSlot
        local wearable = tes3.getObject(k)
        wearable.slot = v.type
        -- get mesh files for male and female body parts
        interop.wearables[k].mesh[1] = wearable.parts[1].male.mesh
        if (wearable.parts[1].female) then
            interop.wearables[k].mesh[2] = wearable.parts[1].female.mesh
        end
        wearable.parts[1].type = 255
        for ks, vs in pairs(v.raceSub) do
            -- remap slot to custom wearableSlot
            local substitute = tes3.getObject(vs)
            if not substitute then
                goto continue
            end
            substitute.slot = v.type
            -- get mesh files for male and female body parts
            v.raceSub[ks] = { id = vs, mesh = {} }
            v.raceSub[ks].mesh[1] = substitute.parts[1].male.mesh
            if (substitute.parts[1].female) then
                v.raceSub[ks].mesh[2] = substitute.parts[1].female.mesh
            end
            substitute.parts[1].type = 255
            ::continue::
        end
        mwse.log("[Onion - Layered Equipment]: Registered wearable: %s (slot = [%s]_%s)", k, wearable.slot, interop.wearableSlots[wearable.slot])
    end
end

return interop