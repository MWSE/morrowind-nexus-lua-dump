local function showMessageBoxOnWeaponReadied(e)
    if (e.reference ~= tes3.player) then
        return
    end
    if (tes3.mobilePlayer.cell.restingIsIllegal == false) then
        return
    end
    if (tes3.mobilePlayer.cell.isOrBehavesAsExterior == false and not (string.startswith(tes3.mobilePlayer.cell.id, "Vivec"))) then
        return
    end
    if (tes3.mobilePlayer.inCombat == true) then
        return
    end
    local weaponStack = e.weaponStack
    if (weaponStack and weaponStack.object) then
        tes3.messageBox({
        message = "This is a civilized area. Sheathe back that " .. weaponStack.object.name .. "!", 
        buttons = { "Ok.", "Make me!" },
        callback = function(e)
                if (e.button == 0) then
                    tes3.mobilePlayer.weaponReady = false
            elseif (e.button == 1) then 
                    tes3.triggerCrime({ type = tes3.crimeType.theft, victim = nil, value = 500, })
            end
        end
        })
    end
end
local skip = false
local function showMessageBoxOnSpellCast(e)
    if (e.caster ~= tes3.player) then
        return
    end
    if (tes3.mobilePlayer.cell.restingIsIllegal == false) then
        return
    end
    if (tes3.mobilePlayer.cell.isOrBehavesAsExterior == false and not (string.startswith(tes3.mobilePlayer.cell.id, "Vivec"))) then
        return
    end
    if (tes3.mobilePlayer.inCombat == true) then
        return
    end

    if not e.effect.object.isHarmful then return end
    
    if skip then 
        skip = false
        return 
    end
    e.castChance = 0
    tes3.messageBox({ 
        message = "This is a civilized area. No spells !", 
        buttons = { "Ok.", "Or else?" },
        callback = function(f)
            if (f.button == 1) then 
                skip = true
                tes3.triggerCrime({ type = tes3.crimeType.theft, victim = nil, value = 500, })
                tes3.cast({ reference = e.caster, spell = e.source, instant = true })
            end
        end
        })
end

local function initialized()
    event.register("weaponReadied", showMessageBoxOnWeaponReadied)
    event.register("spellCast", showMessageBoxOnSpellCast)
    print("[Civilized Tamriel] Civilized Tamriel initialized")
end
event.register("initialized", initialized)
