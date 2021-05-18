local bow_auriel = "ebony_bow_auriel"
local bow_ammo = "sb_auriel_shot"

local function replaceUI(e)
    if (e.object.id:find(bow_auriel)) then
        local weaponData = e.itemData.data
        if (weaponData["sb_recharge"] == nil or weaponData["sb_shots"] == nil) then
            weaponData["sb_recharge"] = tes3.getSimulationTimestamp() - 24
            weaponData["sb_shots"] = 3
        end

        local tooltip = e.tooltip:findChild(tes3ui.registerID("PartHelpMenu_main")) or nil
        local rechargeTime = tes3.getSimulationTimestamp() - weaponData["sb_recharge"]
        if (rechargeTime < 24) then
            tooltip:createDivider()
            local recharge = tooltip:createFillBar { current = tonumber(string.format("%.2f", tes3.getSimulationTimestamp() - weaponData["sb_recharge"])), max = 24 }
            recharge.widget.fillColor = { 1.0, 1.0, 1.0 }
        elseif (weaponData["sb_shots"] == 0) then
            weaponData["sb_shots"] = 3
        else
            tooltip:createLabel { text = "Shots: " .. tostring(weaponData["sb_shots"]) }
        end
    end
end

local function unequipWhenUncharged(e)
    if (e.reference == tes3.player) then
        local bow = e.item.id:find(bow_auriel)
        if (bow) then
            local startChargeTime = e.itemData.data["sb_recharge"]
            if (startChargeTime) then
                if (tes3.getSimulationTimestamp() - startChargeTime < 24) then
                    return false
                else
                    timer.frame.delayOneFrame(function()
                        tes3.addItem { reference = e.reference, item = bow_ammo, count = e.itemData.data["sb_shots"] }
                        e.reference.mobile:equip { item = bow_ammo }
                    end)
                end
            end
        end
    end
end

local function removeShots(e)
    if (e.reference == tes3.player) then
        local bow = e.item.id:find(bow_auriel)
        if (bow) then
            timer.frame.delayOneFrame(function()
                tes3.removeItem { reference = e.reference, item = bow_ammo, count = e.itemData.data["sb_shots"] }
            end)
        end
    end
end

local function calcDamage(e)
    if (e.projectile.reference.id:find(bow_ammo)) then
        e.mobile.health.current = 0
        tes3.playSound { sound = "mysticism cast", reference = e.mobile }
    end
end

local function calcHitChance(e)
    if (e.attacker == tes3.player) then
        if (e.attacker.mobile.readiedWeapon) then
            if (e.attacker.mobile.readiedAmmo) then
                if (e.attacker.mobile.readiedAmmo.object.id:find(bow_ammo)) then
                    e.hitChance = 100
                end
            end
        end
    end
end

local function updateShots(e)
    if (e.reference == tes3.player) then
        if (e.mobile.readiedWeapon) then
            if (e.mobile.readiedWeapon.object.id:find(bow_auriel)) then
                local weaponData = e.mobile.readiedWeapon.variables.data
                if (weaponData["sb_shots"] > 1) then
                    weaponData["sb_shots"] = weaponData["sb_shots"] - 1
                else
                    weaponData["sb_recharge"] = tes3.getSimulationTimestamp()
                    weaponData["sb_shots"] = 0
                    timer.frame.delayOneFrame(function()
                        e.mobile:unequip { item = bow_auriel }
                    end)
                    tes3.playSound { sound = "Spell Failure Mysticism" }
                end
            end
        end
    end
end

--------------------------------------------------

local function init()
    event.register("uiObjectTooltip", replaceUI)
    event.register("equip", unequipWhenUncharged)
    event.register("damaged", calcDamage)
    event.register("calcHitChance", calcHitChance)
    event.register("attack", updateShots)
    event.register("unequipped", removeShots)
end

event.register("initialized", init)