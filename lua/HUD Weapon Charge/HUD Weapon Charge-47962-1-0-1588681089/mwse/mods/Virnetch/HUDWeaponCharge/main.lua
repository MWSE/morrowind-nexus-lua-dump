local chargeBlockId = tes3ui.registerID("vir_hudcharge:chargeBlock")
local chargeFillbarId = tes3ui.registerID("vir_hudcharge:chargeFillbar")
local lastEquipped

local function createChargeFillbar(e)
    if not e.newlyCreated then return end

    local multiMenu = e.element
    local weaponLayout = multiMenu:findChild(tes3ui.registerID("MenuMulti_weapon_layout"))
    local chargeBlock = weaponLayout:createBlock{ id = chargeBlockId }
    chargeBlock.autoWidth = true
    chargeBlock.autoHeight = true

    local chargeFillbar = chargeBlock:createFillBar{ id = chargeFillbarId }
    chargeFillbar.widget.fillColor = tes3ui.getPalette("magic_color")
    chargeFillbar.widget.showText = false
    chargeFillbar.width = 36
    chargeFillbar.height = 6
end
event.register("uiActivated", createChargeFillbar, { filter = "MenuMulti" })

local function update()
    if not tes3.player then return end
    --Only update if player has an enchanted weapon equipped
    local weapon = tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.weapon, enchanted = true})
    if weapon then
        lastEquipped = true

        local multiMenu = tes3ui.findMenu(tes3ui.registerID("MenuMulti"))
        if multiMenu then
            local chargeFillbar = multiMenu:findChild(chargeFillbarId)
            if chargeFillbar then
                chargeFillbar.parent.visible = true
                chargeFillbar.widget.max = weapon.object.enchantment.maxCharge
                chargeFillbar.widget.current = weapon.variables and weapon.variables.charge or weapon.object.enchantment.maxCharge
            end
        end
    elseif lastEquipped then
        lastEquipped = false

        --Hide fillbar if player doesn't have an enchanted weapon equipped
        local multiMenu = tes3ui.findMenu(tes3ui.registerID("MenuMulti"))
        if multiMenu then
            local chargeFillbar = multiMenu:findChild(chargeFillbarId)
            if chargeFillbar then
                chargeFillbar.parent.visible = false
            end
        end
    end
end
event.register("enterFrame", update)
event.register("loaded", function()
    --Reset when loaded
    lastEquipped = true
end)