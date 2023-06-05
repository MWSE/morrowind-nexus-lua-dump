local common = require("alchemyArt.common")
local ingredType = require("alchemyArt.ingredients.ingredType")
local ui = require("alchemyArt.ui")

local ingredients = {}

ingredients.same = {
    food_kwama_egg_01 = {
        food_kwama_egg_02 = true,
    },
    ingred_6th_corprusmeat_01 = {
        ingred_6th_corprusmeat_02 = true,
        ingred_6th_corprusmeat_03 = true,
        ingred_6th_corprusmeat_04 = true,
        ingred_6th_corprusmeat_05 = true,
        ingred_6th_corprusmeat_06 = true,
        ingred_6th_corprusmeat_07 = true,
    },
    AB_IngFood_KwamaEggCentCut ={
        AB_IngFood_KwamaEggCentWrap = true,
    },
}


local function assignSame()
    for ingred1 in tes3.iterateObjects(tes3.objectType.ingredient) do
        for ingred2 in tes3.iterateObjects(tes3.objectType.ingredient) do
            local similarity = 0
            local sameEffects = 0
            if ingred1.id ~= ingred2.id then
                if ingred1.name == ingred2.name then
                    similarity = similarity + 1
                elseif ingred1.icon == ingred2.icon then
                    similarity = similarity + 1
                --elseif string.gsub(ingred1.id, "_[^_]+$", "_") == string.gsub(ingred2.id, "_[^_]+$", "_") then
                --	similarity = similarity + 1
                end
                if similarity > 0 then 
                    for i = 1,4 do
                        if ingred1.effects[i] == ingred2.effects[i] then
                            local magicEffect = tes3.getMagicEffect(ingred1.effects[i])
                            if magicEffect then
                                if magicEffect.targetsAttributes then
                                    if ingred1.effectAttributeIds[i] == ingred2.effectAttributeIds[i] then 
                                        sameEffects = sameEffects + 1
                                    else
                                        sameEffects = 0
                                    end
                                elseif magicEffect.targetsSkills then
                                    if ingred1.effectSkillIds[i] == ingred2.effectSkillIds[i] then
                                        sameEffects = sameEffects + 1
                                    else
                                        sameEffects = 0
                                    end
                                else
                                    sameEffects = sameEffects + 1
                                end
                            end
                        else
                            sameEffects = 0
                        end
                    end
                    if sameEffects > 0 then
                        ingredients.same[ingred1.id] = ingredients.same[ingred1.id] or {}
                        ingredients.same[ingred1.id][ingred2.id] = true
                    end
                end
            end
        end
    end
end




ingredients.getEffectList = function(inventory)
	local effectSet = {}
	if common.filteredEffect then
		effectSet[common.filteredEffect.id] = true
	end
	local count = common.getVisibleEffectsCount()
	
    tes3.player.data.alchemyKnowledge = tes3.player.data.alchemyKnowledge or {}

	-- Iterating over ingreds in the inventory
	
	for _, stack in pairs(inventory) do
		if stack.object.objectType == tes3.objectType.ingredient then
            if ingredType.insoluble[stack.object.id] then
                -- pass
            else
                for i, effect in ipairs(stack.object.effects) do
                    if i > 1 and ingredType.poorlySoluble[stack.object.id] then
                        break
                    end
                    if i <= count or (tes3.player.data.alchemyKnowledge[stack.object.id] and tes3.player.data.alchemyKnowledge[stack.object.id][i]) then
                        if effect >= 0 then
                            effectSet[effect] = true
                        end
                    end
                end
            end
		end
	end

	return common.setToList(effectSet)
end

ingredients.getGrindableEffectList = function(inventory)
	local effectSet = {}
	if common.filteredEffect then
		effectSet[common.filteredEffect.id] = true
	end
	local count = common.getVisibleEffectsCount()
	
    tes3.player.data.alchemyKnowledge = tes3.player.data.alchemyKnowledge or {}

	-- Iterating over ingreds in the inventory
	
	for _, stack in pairs(inventory) do
		if stack.object.objectType == tes3.objectType.ingredient then
            if ingredType.insoluble[stack.object.id] or ingredType.poorlySoluble[stack.object.id] then
                for i, effect in ipairs(stack.object.effects) do
                    if tes3.player.data.alchemyKnowledge[stack.object.id] and tes3.player.data.alchemyKnowledge[stack.object.id][i] then
                        if effect >= 0 then
                            effectSet[effect] = true
                        end
                    end
                end
            end
		end
	end

	return common.setToList(effectSet)
end

local function findGrinded(ingred)
    ingred = string.gsub(ingred, "_Dae_cursed_", "_")
    if string.startswith(ingred, 'T_Ing') then
        local possibleIngred = string.gsub(ingred, "Dae_", "_")
        if tes3.getObject(possibleIngred) then
            ingred = possibleIngred
        end
    end
    local grinded = string.gsub(ingred, "_[%d%w]+$", "_g")
    if tes3.getObject(grinded) then
        ingredType.wholeToGrinded[ingred] = grinded
        ingredType.grindedToWhole[grinded] = ingredType.grindedToWhole[grinded] or {}
        table.insert(ingredType.grindedToWhole[grinded], ingred)
        return true
    else
        grinded = ingred.."g"
        if tes3.getObject(grinded) then
            ingredType.wholeToGrinded[ingred] = grinded
            ingredType.grindedToWhole[grinded] = ingredType.grindedToWhole[grinded] or {}
            table.insert(ingredType.grindedToWhole[grinded], ingred)
            return true
        end
    end
end

ingredients.effectsToChange = {
    ingred_kagouti_hide_g = {
        [3] = {
            effect = tes3.effect.resistBlightDisease,
        }
    },
    ingred_snowbear_pelt_uniqueg = {
        [2] = {
            effect = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.strength
        },
        [3] = {
            effect = tes3.effect.resistFrost,
        }
    },
    ingred_snowwolf_pelt_uniqueg = {
        [3] = {
            effect = tes3.effect.resistFrost,
        }
    },
    ingred_russula_01 = {
        [4] = {
            effect = tes3.effect.light,
        }
    },
    ingred_ectoplasm_01 = {
        [1] = {
            effect =  tes3.effect.sanctuary,
        }
    },
    ingred_raw_glass_g = {
        [4] = {
            effect = tes3.effect.sanctuary,
        }
    },
    ingred_vampire_dust_01 = {
        [4] = {
            effect = tes3.effect.resistNormalWeapons,
        }
    },
    ingred_daedra_skin_g = {
        [2] = {
            effect = tes3.effect.resistNormalWeapons,
        }
    },
    ingred_raw_ebony_g = {
        [3] = {
            effect = tes3.effect.shield,
        }
    },
    ingred_corkbulb_root_01 = {
        [3] = {
            effect = tes3.effect.shield
        }
    },
    ingred_netch_leather_g = {
        [1] = {
            effect = tes3.effect.poison,
            attribute = -1
        },
        [2] = {
            effect = tes3.effect.fortifyAttribute,
            attribute = tes3.attribute.endurance
        }
    },
    ingred_bittergreen_petals_01 = {
        [1] = {
            effect = tes3.effect.poison,
            attribute = -1
        },
    },
    ingred_treated_bittergreen_uniq = {
        [1] = {
            effect = tes3.effect.poison,
            attribute = -1
        },
    }
}

local function overhaulIngredient(ingredId, ingredEffects)
    local ingred = tes3.getObject(ingredId)
    if ingred then
        for i, effect in pairs(ingredEffects) do
            ingred.effects[i] = effect.effect or ingred.effects[i]
            ingred.effectAttributeIds[i] = effect.attribute or ingred.effectAttributeIds[i]
        end
    end
end

ingredients.init = function()

    for ingred, _ in pairs(ingredType.insoluble) do
        findGrinded(ingred)
    end
    for ingred, _ in pairs(ingredType.poorlySoluble) do
        findGrinded(ingred)
    end

    if common.config.overhaulIngredients then
        for ingredId, ingredEffects in pairs(ingredients.effectsToChange) do
            overhaulIngredient(ingredId, ingredEffects)
            if ingredType.grindedToWhole[ingredId] then
                for _, wholeId in pairs(ingredType.grindedToWhole[ingredId]) do
                    overhaulIngredient(wholeId, ingredEffects)
                end
            end
        end
    end
    assignSame()
end

ingredients.getVisibleEffectsCount = function()
    local skill = tes3.mobilePlayer.alchemy.current
    local gmst = tes3.findGMST(tes3.gmst.fWortChanceValue)
    return math.clamp(math.floor(skill / gmst.value), 0, 4)
end

ingredients.isSame = function(item1, item2)
    if ingredType.wholeToGrinded[item1.id] == item2.id then
        return true
    elseif ingredType.wholeToGrinded[item2.id] == item1.id then
        return true
    elseif ingredType.wholeToGrinded[item1.id] and ingredType.wholeToGrinded[item1.id] == ingredType.wholeToGrinded[item2.id] then
        return true
    elseif ingredients.same[item1.id] and ingredients.same[item1.id][item2.id] then
        return true
    elseif ingredients.same[item2.id] and ingredients.same[item2.id][item1.id] then
        return true
    end
    return false
end

local function learnWholeEffects(ingred, count)
    local wholes = ingredType.grindedToWhole[ingred.id]
    if wholes then
        for _, whole in ipairs(wholes) do
            -- mwse.log("Found whole ingred: %s, count = %s", whole, count)
            tes3.player.data.alchemyKnowledge = tes3.player.data.alchemyKnowledge or {}
            tes3.player.data.alchemyKnowledge[whole] = tes3.player.data.alchemyKnowledge[whole] or {}
            for i = 1, count do
                -- mwse.log(i)
                tes3.player.data.alchemyKnowledge[whole][i] = true
            end
        end
    end
    -- mwse.log(inspect(tes3.player.data.alchemyKnowledge))
end

local function getEffectsToColor(e, ingred)
    local toColor = {}
    -- mwse.log(inspect(common.selectedEffects))

    for i, effect in ipairs(ingred.effects) do
        local magicEffect = tes3.getMagicEffect(effect)
        if not magicEffect then
            break
        end
        local attribute
        if magicEffect.targetsAttributes then
            attribute = ingred.effectAttributeIds[i]
        elseif magicEffect.targetsSkills then
            attribute = ingred.effectSkillIds[i]
        else
            attribute = -1
        end
        for slotName, effectAttribute in pairs(common.selectedEffects) do
            if slotName ~= e.menuSlot then
                for effectId, attributes in pairs(effectAttribute) do
                    if effectId == effect then
                        for attributeId, _ in pairs(attributes) do
                            if attributeId == attribute then
                                toColor[i] = true
                            end
                        end
                    end
                end
            end
        end
    end

    return toColor
end

local function disableEffects(parent)
    for _, child in ipairs(parent.children) do
		local i = 0
		if child.name == "HelpMenu_effectBlock" then
			child.visible = false
		end
	end
end

local function getIngredEffectCount(ingred)
    local count
    if ingredType.insoluble[ingred.id] then
        count = 0
    elseif ingredType.poorlySoluble[ingred.id] then
        count = 1
    else
        count = ingredients.getVisibleEffectsCount()
    end
    return count
end

ingredients.onTooltip = function(e)
    local ingred = e.object
    local count = getIngredEffectCount(ingred)
    local toColor = getEffectsToColor(e, ingred)
    learnWholeEffects(ingred, count)
    local parent = e.tooltip:findChild("PartHelpMenu_main")
	disableEffects(parent)
    local known = tes3.player.data.alchemyKnowledge and tes3.player.data.alchemyKnowledge[ingred.id]
    local known234 = known and ( known[2] or known[3] or known[4] )
    local effects = ingred.effects
    local attributes = ingred.effectAttributeIds
    local skills = ingred.effectSkillIds

    if ingredType.insoluble[ingred.id] and not known then
        return
    end

	local parent = e.tooltip:createBlock{id="Effects_Block"}
	parent.flowDirection = "top_to_bottom"
	parent.childAlignX = 0.5
	parent.autoHeight = true
	parent.autoWidth = true
	for i = 1, 4 do
        if i > 1 and ingredType.poorlySoluble[ingred.id] and not known234 then
            return
        end

		local effect = tes3.getMagicEffect(effects[i])
		local target = math.max(attributes[i], skills[i])

		local block = parent:createBlock{id="HelpMenu_effectBlock"}
		block.autoHeight = true
		block.autoWidth = true
        known = known or {}

		if effect == nil then
			-- pass
		elseif i > count and not known[i] then
			local label = block:createLabel{text="?"}
			label.wrapText = true
            if ingredType.insoluble[ingred.id] or ( i > 1 and ingredType.poorlySoluble[ingred.id] ) then
                label.color = tes3ui.getPalette("journal_finished_quest_color")
            end
		else
			local image = block:createImage{path=("icons\\" .. effect.icon)}
			image.wrapText = false
			image.borderLeft = 4

			local label = block:createLabel{text=common.getEffectName(effect, target)}
			label.wrapText = false
			label.borderLeft = 4
            if ingredType.insoluble[ingred.id] or ( i > 1 and ingredType.poorlySoluble[ingred.id] ) then
                image.color = tes3ui.getPalette("journal_finished_quest_color")
                label.color = tes3ui.getPalette("journal_finished_quest_color")
            elseif toColor[i] then
                label.color = ui.selectedEffectColor
            end
		end
	end
end

return ingredients