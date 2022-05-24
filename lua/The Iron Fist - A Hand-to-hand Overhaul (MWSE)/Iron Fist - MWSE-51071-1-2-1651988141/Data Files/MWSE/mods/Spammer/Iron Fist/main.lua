local cf = mwse.loadConfig("Iron Fist", {random = 20, dmg = 10, onOff = true, onOff2 = false})
local weightLeft = -1
local weightRight = -1
local leffect = {}
local reffect = {}
local lmagn = {}
local rmagn = {}
local lharm = false
local rharm = false
local ldur = 0
local rdur = 0
local lcon = 10
local rcon = 10
local leftRight = 0
local result = 0
local mresult = 0
local lspell
local rspell

local function newSpell(enchantment)
    local spell = tes3.createObject{objectType = tes3.objectType.spell, getIfExists = false}
    tes3.setSourceless(spell)
    spell.alwaysSucceeds = true
    spell.castType = tes3.spellType.spell
    spell.magickaCost = 0
        for index = 1, #enchantment.effects do
            local effect = spell.effects[index]
            local enchantmentEffect = enchantment.effects[index]
            effect.id = enchantmentEffect and enchantmentEffect.id
            effect.min = enchantmentEffect and enchantmentEffect.min or 0
            effect.max = enchantmentEffect and enchantmentEffect.max or 0
            effect.radius = enchantmentEffect and enchantmentEffect.radius or 0
            effect.rangeType = enchantmentEffect and enchantmentEffect.rangeType or tes3.effectRange.self
            effect.duration = enchantmentEffect and enchantmentEffect.duration or 0
            effect.attribute = enchantmentEffect and enchantmentEffect.attribute or -1
            effect.skill = enchantmentEffect and enchantmentEffect.skill or -1 end
    return spell
end

local function onLoad()
    local equippedLeft = tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.armor, slot = 6 }) or tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.clothing, slot = 6 })
    local equippedRight = tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.armor, slot = 7 }) or tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.clothing, slot = 5 })

    if equippedLeft and equippedLeft.object and equippedLeft.object.enchantment then
        lspell = newSpell(equippedLeft.object.enchantment)
    else lspell = nil
    end
    if equippedRight and equippedRight.object and equippedRight.object.enchantment then
        rspell = newSpell(equippedRight.object.enchantment)
    else rspell = nil
    end
end

local function onEquip(e)
    if e.reference ~= tes3.player then return end
    local item = e.item
    if (item.objectType == tes3.objectType.armor or item.objectType == tes3.objectType.clothing) and item.slot == 6 then
        if item.enchantment then
        lspell = newSpell(item.enchantment)
        else lspell = nil
        end
    end
    if (item.objectType == tes3.objectType.armor and item.slot == 7) or (item.objectType == tes3.objectType.clothing and item.slot == 5) then
        if item.enchantment then
        rspell = newSpell(item.enchantment)
        else rspell = nil
        end
    end
end


local function shaolinMonk(e)
    local dest = tes3.mobilePlayer.handToHand.current
    local boom = e.fatigueDamage
    local armorR = 1
    local armorL = 1
    local equippedLeft = tes3.getEquippedItem({ actor = e.attackerReference, objectType = tes3.objectType.armor, slot = 6 }) or tes3.getEquippedItem({ actor = e.attackerReference, objectType = tes3.objectType.clothing, slot = 6 })
    local equippedRight = tes3.getEquippedItem({ actor = e.attackerReference, objectType = tes3.objectType.armor, slot = 7 }) or tes3.getEquippedItem({ actor = e.attackerReference, objectType = tes3.objectType.clothing, slot = 5 })
    if (not equippedLeft) and (not equippedRight) then
        return
    end
    if equippedLeft then
        weightLeft = equippedLeft.object.weightClass or 0.1
    else weightLeft = -1
    end
    if equippedRight then
        weightRight = equippedRight.object.weightClass or 0.1
    else weightRight = -1
    end

    if weightLeft == 0 then
        armorL = e.attacker.lightArmor.current/5
        weightLeft = 0.5
    elseif weightLeft == 1 then
        armorL = e.attacker.mediumArmor.current/5
    elseif weightLeft == 2 then
        armorL = e.attacker.heavyArmor.current/5
        weightLeft = 1.5
    end

    if weightRight == 0 then
        armorR = e.attacker.lightArmor.current/5
        weightRight = 0.5
    elseif weightRight == 1 then
        armorR = e.attacker.mediumArmor.current/5
    elseif weightRight == 2 then
        armorR = e.attacker.heavyArmor.current/5
        weightRight = 1.5
    end

    if equippedLeft and (equippedLeft.itemData.condition ~= 0) then
        lcon = math.clamp(equippedLeft.itemData.condition, -1 , 100)
    else lcon = 10
    end
    if equippedRight and (equippedRight.itemData.condition ~= 0) then
        rcon = math.clamp(equippedRight.itemData.condition, -1, 100)
    else rcon = 10
    end

    if leftRight == 0 then
        result = e.mobile:applyDamage({damage = ((boom*(weightLeft+1)*lcon*cf.dmg*armorL/30000)), applyArmor = true, resistAttribute = 12, playerAttack = true, applyDifficulty = true})
       -- tes3.playAnimation({reference = e.reference, group = 23, loopCount = 0})
        leftRight = 1
    elseif leftRight == 1 then
        result = e.mobile:applyDamage({damage = ((boom*(weightRight+1)*rcon*cf.dmg*armorR/30000)), applyArmor = true, resistAttribute = 12, playerAttack = true, applyDifficulty = true})
       -- tes3.playAnimation({reference = e.reference, group = 23, loopCount = 0})
        leftRight = 0
    end

    if equippedLeft or equippedRight then
        local menu = tes3ui.findMenu("MenuMulti")
		if menu then
            local healthBar = menu:findChild("MenuMulti_npc_health_bar")
            healthBar.visible = true
            timer.start({duration = 5, callback = function() healthBar.visible = false end})
        end
    end

    local random = math.random(1, 100)
    if random <= cf.random then
        if ((equippedLeft) and (equippedLeft.itemData.condition) and (leftRight == 1)) then equippedLeft.itemData.condition = (equippedLeft.itemData.condition - result) end
        if ((equippedRight) and (equippedRight.itemData.condition) and (leftRight == 0)) then equippedRight.itemData.condition = (equippedRight.itemData.condition - result) end
    end

    if equippedLeft and equippedLeft.itemData.condition and equippedLeft.itemData.condition <= 0 then
        equippedLeft.itemData.condition = 0
        e.attacker:unequip({armorSlot = 6})
    end
    if equippedRight and equippedRight.itemData.condition and equippedRight.itemData.condition <= 0 then
        equippedRight.itemData.condition = 0
        e.attacker:unequip({armorSlot = 7})
    end

    if e.attackerReference ~= tes3.player then
        return
    end
    if equippedLeft then
        local encantol = equippedLeft.object
        if encantol and encantol.enchantment then
        if (equippedLeft.itemData.charge >= equippedLeft.object.enchantment.chargeCost) and (equippedLeft.object.enchantment.castType ~= 3) then
            if cf.onOff and leftRight == 1 and lspell then
        tes3.cast({ reference = e.attackerReference, target = e.reference, spell = lspell, instant = true, alwaysSucceeds = true, bypassResistances = false})
        equippedLeft.itemData.charge = ((equippedLeft.itemData.charge)-(equippedLeft.object.enchantment.chargeCost)) end
        end
        for _, leftEffect in pairs(equippedLeft.object.enchantment.effects) do
            leffect = leftEffect.id
            lmagn = leftEffect.max
            ldur = leftEffect.duration
            if tes3.getMagicEffect(leffect) then lharm = tes3.getMagicEffect(leffect).isHarmful end

                if leffect == 14 then mresult = e.mobile:applyDamage({damage = (lmagn*dest/200), applyArmor = true, resistAttribute = 3})
                elseif leffect == 15 then mresult = e.mobile:applyDamage({damage = (lmagn*dest/200), applyArmor = true, resistAttribute = 5})
                elseif leffect == 16 then mresult = e.mobile:applyDamage({damage = (lmagn*dest/200), applyArmor = true, resistAttribute = 4})
                elseif leffect == 27 then mresult = e.mobile:applyDamage({damage = (lmagn*dest/200), applyArmor = true, resistAttribute = 9})
                elseif leffect == 45 then mresult = e.mobile:applyDamage({damage = (ldur*dest/200), applyArmor = true, resistAttribute = 2})
                elseif (leffect ~= -1 and lharm and lmagn ~= 0) then mresult = e.mobile:applyDamage({damage = (lmagn*dest/200), applyArmor = true, resistAttribute = 2})
                elseif (leffect ~= -1 and lharm and ldur ~= 0) then mresult = e.mobile:applyDamage({damage = (ldur*dest/200), applyArmor = true, resistAttribute = 2})
                end
            end
        end
    end

    if equippedRight then
        local encantor = equippedRight.object
        if encantor and encantor.enchantment then
        if equippedRight.itemData.charge >= equippedRight.object.enchantment.chargeCost and (equippedRight.object.enchantment.castType ~= 3) then
            if cf.onOff and leftRight == 0 and rspell then
                tes3.cast({ reference = e.attackerReference, target = e.reference, spell = rspell, instant = true, alwaysSucceeds = true, bypassResistances = false})
                equippedRight.itemData.charge = ((equippedRight.itemData.charge)-(equippedRight.object.enchantment.chargeCost))
            end
        end
        for _, rightEffect in pairs(equippedRight.object.enchantment.effects) do
            reffect = rightEffect.id
            rmagn = rightEffect.max
            rdur = rightEffect.duration
            if tes3.getMagicEffect(reffect) then rharm = tes3.getMagicEffect(reffect).isHarmful end

                if reffect == 14 then mresult = e.mobile:applyDamage({damage = (rmagn*dest/200), applyArmor = true, resistAttribute = 3})
                elseif reffect == 15 then mresult = e.mobile:applyDamage({damage = (rmagn*dest/200), applyArmor = true, resistAttribute = 5})
                elseif reffect == 16 then mresult = e.mobile:applyDamage({damage = (rmagn*dest/200), applyArmor = true, resistAttribute = 4})
                elseif reffect == 27 then mresult = e.mobile:applyDamage({damage = (rmagn*dest/200), applyArmor = true, resistAttribute = 9})
                elseif reffect == 45 then mresult = e.mobile:applyDamage({damage = (rdur*dest/200), applyArmor = true, resistAttribute = 2})
                elseif (reffect ~= -1 and rharm and rmagn ~= 0) then mresult = e.mobile:applyDamage({damage = (rmagn*dest/200), applyArmor = true, resistAttribute = 2})
                elseif (reffect ~= -1 and rharm and rdur ~= 0) then mresult = e.mobile:applyDamage({damage = (rdur*dest/200), applyArmor = true, resistAttribute = 2})
                end
            end
        end
    end
    if cf.onOff2 then
                if (equippedRight and equippedRight) then
            if ((result == 0) and (mresult == 0)) then tes3.messageBox("Your attack causes no damage.") end
        end
    end
end

--[[local function shaolinTooltip(e)
    local equippedLeft = tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.armor, slot = 6 }) or tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.clothing, slot = 6 })
    local equippedRight = tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.armor, slot = 7 }) or tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.clothing, slot = 5 })
    if equippedLeft then weightLeft = equippedLeft.object.weightClass or 0 else weightLeft = -1 end
    if equippedRight then weightRight = equippedRight.object.weightClass or 0 else weightRight = -1 end
    if equippedLeft and (equippedLeft.itemData.condition ~= 0) then lcon = math.clamp(equippedLeft.itemData.condition, -1 , 100) else lcon = 10 end
    if equippedRight and (equippedRight.itemData.condition ~= 0) then rcon = math.clamp(equippedRight.itemData.condition, -1, 100) else rcon = 10 end

    if equippedLeft and e.object == equippedLeft.object then
        local text = string.format("Attack: %d - %d", ((weightLeft+1)*cf.dmg*lcon/150), ((weightLeft+1)*cf.dmg*lcon/50))
        local block = e.tooltip:createBlock()
        block.minWidth = 1
        block.maxWidth = 230
        block.autoWidth = true
        block.autoHeight = true
        block.paddingAllSides = -1
        local label = block:createLabel{text = text}
        label.wrapText = true
		block.parent:reorderChildren(1, -1, 1)
    end

    if equippedRight and e.object == equippedRight.object then
        local text = string.format("Attack: %d - %d", ((weightRight+1)*cf.dmg*rcon/150), ((weightRight+1)*cf.dmg*rcon/50))
        local block = e.tooltip:createBlock()
        block.minWidth = 1
        block.maxWidth = 230
        block.autoWidth = true
        block.autoHeight = true
        block.paddingAllSides = -1
        local label = block:createLabel{text = text}
        label.wrapText = true
        block.parent:reorderChildren(1, -1, 1)
    end
    --[[local gauntlet = tes3armor
    local test = false
    if gauntlet.slot == 6 or gauntlet.slot == 7 then test = true else test = false end
    if test and e.object == gauntlet then
        local text = string.format("Attack: %d - %d", (gauntlet.weightClass+1), (gauntlet.weightClass+1))
        local block = e.tooltip:createBlock()
        block.minWidth = 1
        block.maxWidth = 230
        block.autoWidth = true
        block.autoHeight = true
        block.paddingAllSides = -1
        local label = block:createLabel{text = text}
        label.wrapText = true
        -
    end
end]]

local function shaolinTooltip(e)
    local armorCheck = tes3.objectType.armor
    local clothCheck = tes3.objectType.clothing
    local weight = 0
    local con = -1
    local armor = 1
    local text = " "

    if (e.object.objectType == armorCheck and (e.object.slot == 6 or e.object.slot == 7)) then
        if e.itemData then
            con = math.clamp(e.itemData.condition, 0, 100)
            weight = e.object.weightClass
        else
            con = -1
            weight = 0.1
        end

        if weight == 0 then
            armor = tes3.mobilePlayer.lightArmor.current/10
            weight = 0.5
        elseif weight == 1 then
            armor = tes3.mobilePlayer.mediumArmor.current/30
        elseif weight == 2 then
            armor = tes3.mobilePlayer.heavyArmor.current/30
            weight = 1.5
        end

        local text1 = "Type: Hand-to-hand"
        local block1 = e.tooltip:createBlock({id = "HelpMenu_weaponType"})
        block1.minWidth = 1
        block1.maxWidth = 230
        block1.autoWidth = true
        block1.autoHeight = true
        block1.paddingAllSides = -1
        local label1 = block1:createLabel{text = text1}
        label1.wrapText = true
        if con == -1 then
            text = "Attack: ?"
        else
            text = string.format("Attack: %d - %d", ((weight+1)*cf.dmg*con*armor/300), ((weight+1)*cf.dmg*con*armor/100)) end
        local block = e.tooltip:createBlock({id = "HelpMenu_thrust"})
        block.minWidth = 1
        block.maxWidth = 230
        block.autoWidth = true
        block.autoHeight = true
        block.paddingAllSides = -1
        local label = block:createLabel{text = text}
        label.wrapText = true
		block.parent:reorderChildren(1, -2, 2)

    elseif (e.object.objectType == clothCheck and (e.object.slot == 5 or e.object.slot == 6)) then
        local text1 = "Type: Hand-to-hand"
        local block1 = e.tooltip:createBlock({id = "HelpMenu_weaponType"})
        block1.minWidth = 1
        block1.maxWidth = 230
        block1.autoWidth = true
        block1.autoHeight = true
        block1.paddingAllSides = -1
        local label1 = block1:createLabel{text = text1}
        label1.wrapText = true
        text = string.format("Attack: %d - %d", (cf.dmg/30), (cf.dmg/10))
        local block = e.tooltip:createBlock({id = "HelpMenu_thrust"})
        block.minWidth = 1
        block.maxWidth = 230
        block.autoWidth = true
        block.autoHeight = true
        block.paddingAllSides = -1
        local label = block:createLabel{text = text}
        label.wrapText = true
		block.parent:reorderChildren(1, -2, 2)
    else return
    end
end

local function registerModc()
    local template = mwse.mcm.createTemplate("Iron Fist")
    template:saveOnClose("Iron Fist", cf)
    template:register()

    local page = template:createSideBarPage({label = "\"Iron Fist\" Settings"})
    page.sidebar:createInfo{ text = "Welcome to \"Iron Fist\" Configuration Menu. \n \n \n A mod by Spammer."}
    page.sidebar:createHyperLink{ text = "Spammer's Nexus Profile", url = "https://www.nexusmods.com/users/140139148?tab=user+files" }

    local category = page:createCategory("Cast on Use becomes Cast on Strike")
    category:createOnOffButton({label = "On/Off", description = "Toggles whether \"Cast on Use\" enchantments on gauntlets/gloves will behave as \"Cast on Strike\". [Default: On]", variable = mwse.mcm.createTableVariable{id = "onOff", table = cf}})

    local category1 = page:createCategory("Deterioration Rate")
    category1:createSlider{label = "Rate", description = "The rate in % of the gauntlets deterioration. e.g Setting it to 50 will remove some gauntlet health every two hits in average. Setting it to 100 will damage your gauntlets for every single hit. [Default: 20]", min = 0, max = 100, step = 1, jump = 10, variable = mwse.mcm.createTableVariable{id = "random", table = cf}}

    local category2 = page:createCategory("Damage per Hit")
    category2:createSlider{label = "Damage Multiplier", description = "Multiplier used for calculating the damage done by the gauntlets/gloves per hit. The higher you set it, the more damage it will do. [Default: 10]", min = 0, max = 50, step = 1, jump = 5, variable = mwse.mcm.createTableVariable{id = "dmg", table = cf}}

    page:createOnOffButton({label = "Debug mode", description = "Toggles a messagebox whenever a hand-to-hand attack does no health damage. For debug purposes. [Default: Off]", variable = mwse.mcm.createTableVariable{id = "onOff2", table = cf}})
end event.register("modConfigReady", registerModc)

--[[local function message(e)
    if e.keyCode == tes3.scanCode.u then tes3.messageBox("Welcome to the \"Iron Fist\" mod showcase.") end
    if e.keyCode == tes3.scanCode.o then tes3.messageBox("Hand to Hand combat now deals Health Damage if you have gauntlets equipped.") end
    if e.keyCode == tes3.scanCode.i then tes3.messageBox("If your gauntlet is enchanted with 'cast-on-use', it can be treated as 'cast-on-strike'.") end
    if e.keyCode == tes3.scanCode.k then tes3.messageBox("The more damage you do, the more your gauntlets lose condition. When they break, they are automatically unequipped.") end
end]]


local function initialized()
    event.register("damageHandToHand", shaolinMonk)
    event.register("equipped", onEquip)
    event.register("uiObjectTooltip", shaolinTooltip)
    event.register("loaded", onLoad)
    print("[Iron Fist : A Hand-to-Hand Overhaul, by Spammer] 1.2 Initialized!")
    --event.register("keyDown", message)
end event.register("initialized", initialized)
