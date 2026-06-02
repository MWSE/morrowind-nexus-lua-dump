--- Boost Durability: 
--- Increases max durability of Weapons and Armor based on your Armorer skill.
--- Adds repair tool requirement with quality  based on recipe level and amount based on boost provided.
--- If Artisan's touch enabled - quality also affects durability, but repair tool cost doubles.

local isGlobal, _ = pcall(function() require('openmw.world') end)
if isGlobal then return end
if not registerTouch then return end -- Crafting Framework not detected, abort

local core = require('openmw.core')
local ui = require('openmw.ui')
local util = require('openmw.util')
local l10n = core.l10n('TPA_CF_ExtraTouches')
local v2 = util.vector2

local H = require('scripts.TPABOBAP.helpers')

local touchID = "condition"
local touchModId = "touch:" .. touchID

------------------------------ helpers ------------------------------

-- x1 at 20, x1.5 at ~32, x2 at 50, x3 at 100, x4 at 170
local function conditionMultiplier()
    local skill = getModifiedSkill("armorer") or 0
    if skill <= 20 then
        return skill / 20
    else
        return math.sqrt((skill - 10) / 10)
    end
end

local function conditionMultiplierText(quality)
    return "x" .. math.floor((quality or 1) * 100 * conditionMultiplier()) / 100
end

local function getToolForRecipe(recipe)
    local level = recipe.level or 0
    if level < 25 then
        return "repair_prongs"
    elseif level < 50 then
        return "hammer_repair"
    elseif level < 75 then
        return "repair_journeyman_01"
    else
        return "repair_master_01"
    end
end


------------------------------ touch registration ------------------------------

registerTouch {
    id = touchID,
    label = "Boost Condition",
    priority = 11,
    gate = function(recipe)
        return (recipe.type == "Weapon" or recipe.type == "Armor") and not recipe.preserveRecordId
    end,
}

registerIngredientsModifier {
    id = touchModId,
    global = true,
    priority = -1,
    func = function(recipe, ctx)
        if not (ctx.touches and ctx.touches[touchID]) then return end
        local cost = util.round(3 * conditionMultiplier())
        if ctx.touches.artisan then
            cost = cost * 2
        end
        H.addIngredient(ctx, getToolForRecipe(recipe), "Repair", cost)
    end,
}

registerStatsModifier {
    id = touchModId,
    global = true,
    priority = -1,
    func = function(recipe, ctx)
        if not (ctx.touches and ctx.touches[touchID]) then return end
        if ctx.recordType == "Weapon" or ctx.recordType == "Armor" then
            local m = ctx.modified or {}
            print("CF:", 'health', m.health, ctx.base.health, ctx.record.health)
            
            local condition = m.health or ctx.base.health or ctx.record.health
            if not condition then return end

            local qualityMult = ctx.touches.artisan and ctx.qualityMult or 1
            local armorerMult = conditionMultiplier()

            m.health = util.round(condition * armorerMult * qualityMult)
            ctx.modified = m;
        end
    end,
}
local supportedInfoTypes = { weapon = true, armor = true }

registerTooltipModifier {
    id = touchModId,
    priority = 100,
    global = true,
    func = function(recipe, ctx)
        if not recipe or not (activeTouches and activeTouches[touchID]) then return end
        if not (ctx.info and supportedInfoTypes[ctx.info.type]) then return end
        if recipe.preserveRecordId then return end
        
        local qualityMult = ctx.touches.artisan and ctx.qualityMult or 1
        local row = {
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
                autoSize = true,
                anchor = v2(0.5, 0),
                relativePosition = v2(0.5, 0),
                size = v2(0, S_FONT_SIZE)
            },
            content = ui.content {
                {
                    type = ui.TYPE.Image,
                    props = {
                        resource = getTexture("textures/CraftingFramework/condition.png"),
                        size = v2(S_FONT_SIZE, S_FONT_SIZE),
                        relativePosition = v2(0, 0.5),
                        anchor = v2(0, 0.5),
                        alpha = 0.8,
                    },
                },
                { props = { size = v2(2, 2) } },
                {
                    type = ui.TYPE.Text,
                    props = {
                        text = l10n("ConditionBoost") .. " " .. conditionMultiplierText(qualityMult),
                        textSize = S_FONT_SIZE - 2,
                        relativePosition = v2(0, 0.52),
                        anchor = v2(0, 0.5),
                        textColor = morrowindGold,
                        autoSize = true,
                    },
                },
            },
        }
        ctx.flex.content:add(row)
    end,
}

------------------------------ button ------------------------------

local conditionButton

local function applyButtonState()
    if not conditionButton then return end
    if activeTouches[touchID] then
        conditionButton.content.background.props.color = morrowindGold
        conditionButton.content.clickbox.userData.customColor = morrowindGold
    else
        conditionButton.content.background.props.color = util.color.rgb(0, 0, 0)
        conditionButton.content.clickbox.userData.customColor = nil
    end
end

registerWindowBuilder {
    id = touchModId,
    priority = 10,
    func = function(ctx)
        conditionButton = makeIconButton(
                "textures/CraftingFramework/condition.png",
                v2(S_FONT_SIZE * 1, S_FONT_SIZE * 1),
                function() toggleTouch(touchID) end,
                nil,
                touchModId
        )
        applyButtonState()
        ctx.topBarButtonFlex.content:add(conditionButton)
        addTooltip(conditionButton.content.clickbox, H.makeTextTooltip(l10n("ConditionButtonTipTitle") .. " " .. conditionMultiplierText(), l10n("ConditionButtonTipBody")))
    end,
}

onTouchToggled(function(data)
    if data.id == touchID then applyButtonState() end
end)