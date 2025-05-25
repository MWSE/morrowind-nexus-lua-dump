local function isPlayerVampire()
    return tes3.isAffectedBy({reference = tes3.player, effect = tes3.effect.telekinesis})
end

local function isPlayerSneaking()
    return tes3.mobilePlayer.isSneaking
end

local function onActivate(e)
    if e.activator == tes3.player then
        if e.target.baseObject.objectType == tes3.objectType.npc  then
            if isPlayerSneaking() and isPlayerVampire() then
                -- Do something when a vampire player sneaks and activates an actor
                -- Replace the following line with your desired code
                if e.target.mobile.isDead == true then
		    tes3.addSpell({reference = tes3.player, spell = "Bloodthirst_Drink_Option"})
		    return false
		    end
            end
        end
    end
end
event.register("activate", onActivate)