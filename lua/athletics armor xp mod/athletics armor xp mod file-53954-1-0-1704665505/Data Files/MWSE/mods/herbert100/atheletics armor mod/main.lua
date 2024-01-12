--[[ armor weight mod:
- you get 33 "armor points" (11 slots of armor, times 3)
- light armor eats up 1 point
- medium armor eats up 1.5 points
- heavy armor eats up 2 points
- all these get summed up, and each get a proportion of your athletics xp (you get less athletics xp the more armor you have)
]]


local cfg = mwse.loadConfig("herbert athletics armor mod", {lf=3,mf=4.5,hf=6})

-- uncommented so herbert lib isnt a requirement again
-- local log = require("herbert100.logger")("LIVECODING")
-- log:set_level(4)


local totally_armored = 100

-- initialize these to numbers so we dont go crazy with the error messages if something unexpected happens
local light_ratio, medium_ratio, heavy_ratio, athletics_ratio = 0, 0, 0, 1

-- recalculate the armor total.
-- the athletics `exerciseSkill` event happens pretty much all the time, so we'll instead calculate the armor totals
-- when the game loads, and then again each time equipment is changed
local function recalculate_armor_total()
    local lc, mc, hc = 0, 0, 0 -- count for light, medium, and heavy, each weighted differently
    for _, item in pairs(tes3.player.object.equipment) do
        local obj = item.object
        -- log("item %s is equipped. objtype: %s", obj.name, table.find(tes3.objectType,obj.objectType))
        if obj.objectType == tes3.objectType.armor  then
            -- log("%s has armor type %s",  obj.name, obj.weightClass)
            local wc = obj.weightClass
            if wc == tes3.armorWeightClass.light then 
                lc = lc + cfg.lf
            elseif wc == tes3.armorWeightClass.medium then
                 mc = mc + cfg.mf
            else -- its heavy
                hc = hc + cfg.hf
            end

            light_ratio = lc/totally_armored
            medium_ratio = mc/totally_armored
            heavy_ratio = hc/totally_armored
            athletics_ratio = 1 - (lc + mc + hc)/totally_armored
            -- log("lr:%s\n\tmr:%s\n\thr:%s\n\tar:%s", light_ratio,medium_ratio,heavy_ratio,athletics_ratio)
        end
    end
end

local athletics = tes3.skill.athletics
local light_armor = tes3.skill.lightArmor
local medium_armor = tes3.skill.mediumArmor
local heavy_armor = tes3.skill.heavyArmor

---@param e exerciseSkillEventData
local function skill_exercised(e)
    if e.skill ~= athletics then return end

    e.progress = e.progress * athletics_ratio

    local player = tes3.mobilePlayer
    if light_ratio > 0 then
        player:exerciseSkill(light_armor,e.progress*light_ratio)
    end
    if medium_ratio > 0 then
        player:exerciseSkill(medium_armor,e.progress*medium_ratio)
    end
    if heavy_ratio > 0 then
        player:exerciseSkill(heavy_armor, e.progress*heavy_ratio)
    end
end

event.register(tes3.event.modConfigReady,function (e)
    local template=mwse.mcm.createTemplate{name="armor athletics skill mod"}
    local page = template:createSideBarPage{label="settings",description='you get 100 "armor points". \n\t\z
        each piece of equipped armor will consume a certain amount of points.\n\t\z
        these will all be tallied up, and then whenever you gain athletics experience, it will be proportionally distributed among your armor skills,\z
            depending on how much armor you\'re wearing and how many "armor points" each piece is worth.\n\n\z
            for example, if you\'re wearing heavy greaves and a medium helmet, you\'ll have (by default) 4.5 medium points and 6 heavy points.\n\n\z
            this will result in 4.5% of your athletics xp going towards medium armor and 6% going towards heavy armor. (so, you\'ll get 89.5% of the athletics xp you normally would, but the "lost" xp is going towards other skills.)'}

    page:createDecimalSlider{label="light armor factor",description="i.e., how many points is each piece of light armor worth?",
        decimalPlaces=1,min=0,max=100/11,
        variable=mwse.mcm.createTableVariable{id="lf",table=cfg}
    }
    page:createDecimalSlider{label="medium armor factor",description="i.e., how many points is each piece of medium armor worth?",
        decimalPlaces=1,min=0,max=100/11,
        variable=mwse.mcm.createTableVariable{id="mf",table=cfg}
    }
    page:createDecimalSlider{label="heavy armor factor",description="i.e., how many points is each piece of heavy armor worth?",
        decimalPlaces=1,min=0,max=100/11,
        variable=mwse.mcm.createTableVariable{id="hf",table=cfg}
    }
    template.onClose = function (modConfigContainer)
        mwse.saveConfig("herbert athletics armor mod",cfg)
        recalculate_armor_total()
    end
    -- template:saveOnClose("herbert athletics armor mod",cfg)
    template:register()
end)

event.register(tes3.event.initialized, function()
    require("logging.logger").new{name="cool athletics armor mod"}:info("initialized") -- hell yea
    
    event.register(tes3.event.loaded,recalculate_armor_total)

    ---@param e equippedEventData
    event.register(tes3.event.equipped, function (e)
        if e.reference ~= tes3.player then return end
        recalculate_armor_total()
    end)
   
    event.register(tes3.event.exerciseSkill,skill_exercised)
end)