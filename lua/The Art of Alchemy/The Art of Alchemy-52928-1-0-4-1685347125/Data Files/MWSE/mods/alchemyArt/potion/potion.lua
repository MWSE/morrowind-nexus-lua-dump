local common = require("alchemyArt.common")
local ui = require("alchemyArt.ui")
local specialPotion = require("alchemyArt.potion.special")

local potion = {}

local function randomString(length)
	local res = ""
	for i = 1, length do
		res = res .. string.char(math.random(97, 122))
	end
	return res
end

local function getPotionName(effectArray)
    local effectName = common.getEffectName(tes3.getMagicEffect(effectArray[1].id), effectArray[1].attribute)
    return effectName..common.dictionary.potionNamePostfix
end

local function getStrongestEffect(effectArray)
    local maxPower = 0
    local strongestIndex = 0
    for i, effect in ipairs(effectArray) do
        if effect.power > maxPower then
            maxPower = effect.power
            strongestIndex = i
        end
    end
    return effectArray[strongestIndex]
end

local function getPotionMeshIcon(effectArray)
    local strongestEffect = getStrongestEffect(effectArray)
    if strongestEffect.power >= 1200 then
        return "m\\Misc_Potion_Exclusive_01.nif", "m\\Tx_potion_exclusive_01.tga"
    elseif strongestEffect.power >= 625 then
        return "m\\Misc_Potion_Quality_01.nif", "m\\Tx_potion_quality_01.tga"
    elseif strongestEffect.power >= 300 then
        return "m\\Misc_Potion_Standard_01.nif", "m\\Tx_potion_standard_01.tga"
    elseif strongestEffect.power >= 120 then
        return "m\\Misc_Potion_Cheap_01.nif", "m\\Tx_potion_cheap_01.tga"
    else
        return "m\\Misc_Potion_Bargain_01.nif", "m\\Tx_potion_bargain_01.tga"
    end
end

local function getPotionValue(effectArray)
    local powerHarmful = 0
    local powerBenevalent = 0
    for i, effect in ipairs(effectArray) do
        local magicEffect = tes3.getMagicEffect(effect.id)
        if magicEffect.isHarmful then
            powerHarmful = powerHarmful + effect.power
        else
            powerBenevalent = powerBenevalent + effect.power
        end
    end
    local power = math.abs(powerBenevalent - powerHarmful)
    return power/8
end

local function getPotionWeight(effectArray)
    local weight = 0
    for i, effect in ipairs(effectArray) do
        if effect.power >= 1200 then
            weight = weight + 0.25
        elseif effect.power >= 675 then
            weight = weight + 0.5
        elseif effect.power >= 300 then
            weight = weight + 0.75
        elseif effect.power >= 120 then
            weight = weight + 1
        else
            weight = weight + 1.5
        end
    end
    return weight
end

potion.findExistent = function(effectArray)

    local special = specialPotion.find(effectArray)
    if special then
        return special
    end

    local same
    local count = #effectArray
    -- mwse.log("Searching for Potion, count = %s", count)
    for alch in tes3.iterateObjects(tes3.objectType.alchemy) do
        same = 0
        if alch:getActiveEffectCount() == count then
        -- mwse.log(alch.id)
            for i, effect in ipairs(alch.effects) do
                if effect.id < 0 then
                    -- mwse.log("Exiting on %s", i)
                    break
                end
                if effect.id ~= effectArray[i].id then
                    -- mwse.log("effect.id = %s, effectArray[i].id = %s", effect.id, effectArray[i].id)
                    break
                end
                if effect.attribute ~=  effectArray[i].attribute then
                    break
                end
                if effect.duration ~= effectArray[i].duration then
                    -- mwse.log("effect.duration = %s, effectArray[i].duration = %s", effect.id, effectArray[i].id)
                    break
                end
                if effect.min ~= effectArray[i].magnitude or effect.max ~= effectArray[i].magnitude then
                    -- mwse.log("effect.max = %s, effectArray[i].magnitude = %s", effect.max, effectArray[i].magnitude)
                    break
                end
                same = same + 1
                -- mwse.log("Found same effect: %s %s %s", effect.name, effect.attribute, effect.min)
            end
        end
        if same == count then
            -- mwse.log("returning existent potion %s", alch.id)
            return alch
        end
    end
    return nil
end

potion.createNew = function(effectsArray)
    local id = "AA_"..randomString(20) -- generateNewPotionID
    -- mwse.log("creating new potion %s", id)
    local newPotion = tes3.createObject{objectType = tes3.objectType.alchemy, id = id}
    newPotion.name = getPotionName(effectsArray)
    newPotion.mesh, newPotion.icon = getPotionMeshIcon(effectsArray)
    newPotion.value = getPotionValue(effectsArray)
    newPotion.weight = getPotionWeight(effectsArray)
    for i, effectTable in ipairs(effectsArray) do
        newPotion.effects[i].id = effectTable.id
        newPotion.effects[i].min = effectTable.magnitude
        newPotion.effects[i].max = effectTable.magnitude
        newPotion.effects[i].duration = effectTable.duration
        newPotion.effects[i].attribute = effectTable.attribute
        newPotion.effects[i].skill = effectTable.attribute
    end
    return newPotion
end

potion.showNamingMenu = function(source, count)
    local menu = tes3ui.createMenu{id = "PotionNamingMenu", fixedFrame = true}
	menu.minWidth = 50
	menu.maxWidth = 1920
	menu.autoHeight = true
	menu.autoWidth = true
    menu.flowDirection = "top_to_bottom"
    local main = menu:findChild(1111)
    main.childAlignX = 0.5
    main.childAlignY = 0.5
    main.paddingAllSides = 6
    local titleBlock = ui.createAutoBlock(main, "HelpMenu_TitleBlock")
    titleBlock.flowDirection = "left_to_right"
    titleBlock.borderAllSides = 3
    titleBlock.borderBottom = 7
    titleBlock.childAlignX = 0.5
    titleBlock.childAlignY = 0.5
    local image = titleBlock:createImage{id = "HelpMenu_icon", path = "Icons\\"..source.icon}
    image.borderAllSides = 8
    if count > 1 then
        local countLabel = image:createLabel{id = "Item_count", text = tostring(count)}
        countLabel.color = {0.875,0.788,0.624}
        countLabel.absolutePosAlignX = 1
        countLabel.absolutePosAlignY = 1
    end
	local name = titleBlock:createTextInput{id = "PotionNameInput", text = source.name, placeholderText = source.name, autoFocus = true}--menu:createLabel{text=source.name}
	name.color = tes3ui.getPalette("header_color")
    --tes3ui.acquireTextInput(name)
	local effects = source.effects
    for i, effect in ipairs(effects) do
        local magicEffect = tes3.getMagicEffect(effect.id)
        if not magicEffect then
            break
        end
        local block = ui.createAutoBlock(main, "HelpMenu_effectBlock")
        block.flowDirection = "left_to_right"
        block.borderLeft = 7
        block.borderRight = 7
        block.borderAllSides = 1
        block.widthProportional = 1
        local image = block:createImage{path=("icons\\" .. magicEffect.icon)}
        image.wrapText = false
        image.borderLeft = 4
        local text = common.getEffectText(effect)
        local label = block:createLabel{text=text}
        label.wrapText = false
        label.borderLeft = 4
    end
    local okButton = main:createButton{id = "PotionNamingMenu_ok_button", text = common.dictionary.ok}
    okButton.borderTop = 10
    okButton:register("mouseClick", function()
        if name.text and name.text ~= "" and name.text ~= " " then
            source.name = name.text
        end
        menu:destroy()
		tes3ui.leaveMenuMode()
	end)
    local function clickOk(e)
        okButton:triggerEvent("mouseClick")
        
    end 
    event.register(tes3.event.keyDown, clickOk, { filter = tes3.scanCode.enter } )
    timer.delayOneFrame(function ()
        timer.delayOneFrame(function ()
            event.unregister(tes3.event.keyDown, clickOk, { filter = tes3.scanCode.enter } )
        end)
    end)
	menu:updateLayout()
    tes3ui.enterMenuMode("PotionNamingMenu")
    --event.trigger("uiObjectTooltip", {tooltip = menu, object = source})
end

potion.learnEffects = function(alchemy, ingredArray)

    local effectCount = common.getVisibleEffectsCount()
	local effectLearned = nil
	for _, ingred in ipairs(ingredArray) do
        ingred = tes3.getObject(ingred)
		for i, ingredEffect in ipairs(ingred.effects) do
			for _, potionEffect in ipairs(alchemy.effects) do
				if ingredEffect == potionEffect.id then
					tes3.player.data.alchemyKnowledge[ingred.id] = tes3.player.data.alchemyKnowledge[ingred.id] or {}
					if not tes3.player.data.alchemyKnowledge[ingred.id][i] then
						tes3.player.data.alchemyKnowledge[ingred.id][i] = true
						if effectCount < i then
							effectLearned = true
                            common.practiceAlchemy(0.5)
						end
					end
				end
			end
		end
	end
	
	if effectLearned then
		tes3.messageBox(common.dictionary.effectLearned)
	end
end

potion.onTooltip = function(e)

    local effects = {}
    local toColor = {}

    for i, effect in ipairs(e.object.effects) do
        local magicEffect = tes3.getMagicEffect(effect.id)
        if not magicEffect then
            break
        end
        effects[i] = effect
        for slotName, effectAttribute in pairs(common.selectedEffects) do
            if slotName ~= e.menuSlot then
                for effectId, attributes in pairs(effectAttribute) do
                    if effectId == effect.id then
                        for attributeId, _ in pairs(attributes) do
                            if attributeId == effect.attribute then
                                toColor[i] = true
                            end
                        end
                    end
                end
            end
        end
    end

    local i = 0

    local main = e.tooltip:findChild("PartHelpMenu_main")
    for _, block in ipairs(main.children) do
        if block.name == "HelpMenu_effectBlock" then
            i = i + 1
            local label = block:findChild("HelpMenu_effectLabel")
            local magicEffect = tes3.getMagicEffect(effects[i].id)
            if toColor[i] then
                label.color = ui.selectedEffectColor
            elseif magicEffect.isHarmful then
                label.color = ui.negativeEffectColor
            else
                label.color = ui.positiveEffectColor
            end
        end
    end
end


return potion