local bow_id = "vss_crossbow_pistol"
local ammo_id = "vss_stake_bolt"

local function removeIncorrectAmmo(e)
    if (e.reference == tes3.player) then
        timer.delayOneFrame( function()
            -- if player has a weapon and ammo equipped
            if (e.mobile.readiedWeapon and e.mobile.readiedAmmo) then
                -- if the weapon is the bow
                if (e.mobile.readiedWeapon.object.id:find(bow_id)) then
                    -- if the ammo is not the bolts
                    if (e.mobile.readiedAmmo.object.id:find(ammo_id) == nil) then
                        -- unequip the ammo
                        e.mobile:unequip { item = e.mobile.readiedAmmo.object.id }
                    end
                end
            end
        end )
    end
end


local function init()
    event.register("equipped", removeIncorrectAmmo)
end

event.register("initialized", init)