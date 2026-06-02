local vanillaDialog = {}


--- Update the status bars in the vanilla dialogue window
--- @param npcRef tes3actor The actor
function vanillaDialog.updateVanillaDialog(actor)
    local menu = nil
    
    local dialogMenu = tes3ui.findMenu(tes3ui.registerID("MenuDialog"))
    local shareMenu = tes3ui.findMenu(tes3ui.registerID("MenuContents"))

    if shareMenu then
        menu = shareMenu
    elseif dialogMenu then
        menu = dialogMenu
    end
    local targetElement = menu:findChild(tes3ui.registerID("PartDragMenu_main"))
    if not menu or not targetElement then return end


    local activeEffects = actor.activeMagicEffectList  --- @type tes3activeMagicEffect[]
    if not activeEffects then return end
    
    if #activeEffects ~= 0 then

        local parent = targetElement.parent

        -- Create/update status effect list
        local containerBlock = menu:findChild(tes3ui.registerID("companion_effects_list"))
        if containerBlock then
            containerBlock:destroy()
        end
        
        containerBlock = parent.parent:createBlock{ id = "companion_effects_list" }
        containerBlock:reorder({ after = parent })
        containerBlock.autoWidth = true
        containerBlock.autoHeight = true
        containerBlock.borderLeft = 5
        containerBlock.borderBottom = 4

        local effectTotals = {}

        for _, activeEffect in pairs(activeEffects) do
            if effectTotals[activeEffect.effectId] == nil then
                effectTotals[activeEffect.effectId] = { }
            end
            
            table.insert(effectTotals[activeEffect.effectId], activeEffect)
        end

        -- Create row of status effect icons with tooltip
        for k, v in pairs(effectTotals) do
            local effectDef = tes3.getMagicEffect(k)
        
            local image = containerBlock:createImage{id="Effect_Icon_" .. k, path=string.format("icons/%s", effectDef.icon)}
            image.width = 16
            image.height = 16
            image.scaleMode = true

            -- Add tooltip
            image:register("help", function()
                local tooltip = tes3ui.createTooltipMenu()
                local block = tooltip:createBlock{ id = "effect_instance_list" }
                block.autoWidth = true
                block.autoHeight = true
                block.flowDirection = "top_to_bottom"
                block.childAlignX = 0.5

                --header
                local block2 = block:createBlock{ id = "effect_instance_list_hdr" }
                --block2.widthProportional = 1.0
                block2.autoWidth = true
                block2.autoHeight = true
                block2.flowDirection = "left_to_right"

                local headerImage = block2:createImage{id="Effect_Hdr_Icon_" .. k, path=string.format("icons/%s", effectDef.icon)}
                headerImage.width = 16
                headerImage.height = 16
                headerImage.borderRight = 5
                headerImage.scaleMode = true
              
                local effectName
                if effectDef.targetsAttributes then
                    effectName = tes3.findGMST(1283 + effectDef.id).value:match("%S+") .. " Attribute"
                elseif effectDef.targetsSkills then
                    effectName = tes3.findGMST(1283 + effectDef.id).value:match("%S+") .. " Skill"
                else
                    effectName = effectDef.name
                end
                block2:createLabel{ text = effectName }


                --instance list
                for i, activeEffect in ipairs(v) do
                    local effectSourceInstance = activeEffect.instance
                    local magnitude = activeEffect.effectInstance.magnitude

                    local target = math.max(activeEffect.attributeId, activeEffect.skillId)
                    
                    local targetName
                    if effectDef.targetsAttributes then
                        targetName = tes3.findGMST(888 + target).value
                    elseif effectDef.targetsSkills then
                        targetName = tes3.findGMST(896 + target).value
                    end
 
                    if targetName then
                        block:createLabel{ text = (effectSourceInstance.item or effectSourceInstance.source).name .. " (" .. targetName .. "): " .. string.format("%d", magnitude) }
                    else
                        if (k >= 90 and k <= 99) or (k >= 28 and k <= 36) or k == 40 then
                            block:createLabel{ text = (effectSourceInstance.item or effectSourceInstance.source).name .. ": " .. string.format("%d%%", magnitude) }
                        else
                            block:createLabel{ text = (effectSourceInstance.item or effectSourceInstance.source).name .. ": " .. string.format("%d", magnitude) }
                        end
                    end
                end
            end)
        end
    end
end


return vanillaDialog
