--- Boost Enchant Capacity
--- Increases enchant capacity of Weapons and Armor based on your Enchant skill.
--- Adds souls gem requirement with quality based on recipe level.
---  If Artisan's Touch is enabled - quality also affects enchant capacity, but doubles soul gem cost.

local isGlobal, _ = pcall(function() require('openmw.world') end)
if isGlobal then return end
if not registerTouch then return end -- Crafting Framework not detected, abort

local core = require('openmw.core')
local ui = require('openmw.ui')
local util = require('openmw.util')
local l10n = core.l10n('TPA_CF_ExtraTouches')
local v2 = util.vector2

local H = require('scripts.TPABOBAP.helpers')

local touchID = "capacity"
local touchModId = "touch:" .. touchID

------------------------------ helpers ------------------------------

-- sin ease in-out from x1 to ~x1.45 for skill <80, after that sqrt(x/100) (shifted up to match with end of previous curve) 
-- x1.1 at ~30 skill, x1.25 at ~50 skill, x1.45 at ~80, x1.55 at 100 skill, x2 at ~208 skill
local function enchantMultiplier()
    local skill = getModifiedSkill("enchant") or 0
    if skill < 80 then
        return 1.25 - 0.25 * (math.cos(math.pi * skill / 100.0));
    else
        return 0.558 + math.sqrt(skill / 100.0);
    end
end

-- flat bonus to add after multiplying - skill/10, capped at 15
local function enchantBonus()
    return math.min(15, (getModifiedSkill("enchant") or 0) / 10)
end

local function enchantMultiplierText(quality)
    return "x" .. math.floor((quality or 1) * 100 * enchantMultiplier()) / 100 .. " +" .. enchantBonus()
end

local function getSoulGemForRecipe(recipe)
    local level = recipe.level or 0
    if level <= 19 then
        return "Misc_SoulGem_Petty"
    elseif level <= 39 then
        return "Misc_SoulGem_Lesser"
    elseif level <= 59 then
        return "Misc_SoulGem_Common"
    elseif level <= 79 then
        return "Misc_SoulGem_Greater"
    else
        return "Misc_SoulGem_Grand"
    end
end


------------------------------ touch registration ------------------------------

registerTouch {
    id = touchID,
    label = "Add Capacity",
    priority = 10,
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
        -- double the cost if artisan enabled
        H.addIngredient(ctx, getSoulGemForRecipe(recipe), "Miscellaneous",ctx.touches.artisan and 2 or 1)
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
            local capacity = m.enchantCapacity or ctx.base.enchantCapacity or ctx.record.enchantCapacity
            if not capacity then return end

            local qualityMult = ctx.touches.artisan and ctx.qualityMult or 1
            local enchantMult = enchantMultiplier()

            m.enchantCapacity = math.floor(0.5 + capacity * qualityMult * enchantMult + enchantBonus())
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
                        resource = getTexture("textures/CraftingFramework/capacity.png"),
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
                        text = l10n("EnchantCapacity") .. enchantMultiplierText(qualityMult),
                        textSize = S_FONT_SIZE - 2,
                        relativePosition = v2(0, 0.52),
                        anchor = v2(0, 0.5),
                        textColor = morrowindBlue3,
                        autoSize = true,
                    },
                },
            },
        }
        ctx.flex.content:add(row)
    end,
}

------------------------------ button ------------------------------

local capacityButton

local function applyButtonState()
    if not capacityButton then return end
    if activeTouches[touchID] then
        capacityButton.content.background.props.color = morrowindGold
        capacityButton.content.clickbox.userData.customColor = morrowindGold
    else
        capacityButton.content.background.props.color = util.color.rgb(0, 0, 0)
        capacityButton.content.clickbox.userData.customColor = nil
    end
end

registerWindowBuilder {
    id = touchModId,
    priority = 10,
    func = function(ctx)
        capacityButton = makeIconButton(
                "textures/CraftingFramework/capacity.png",
                v2(S_FONT_SIZE * 1, S_FONT_SIZE * 1),
                function() toggleTouch(touchID) end,
                nil,
                touchModId
        )
        applyButtonState()
        ctx.topBarButtonFlex.content:add(capacityButton)
        addTooltip(capacityButton.content.clickbox, H.makeTextTooltip(l10n("CapacityButtonTipTitle") .. " " .. enchantMultiplierText(), l10n("CapacityButtonTipBody")))
    end,
}

onTouchToggled(function(data)
    if data.id == touchID then applyButtonState() end
end)