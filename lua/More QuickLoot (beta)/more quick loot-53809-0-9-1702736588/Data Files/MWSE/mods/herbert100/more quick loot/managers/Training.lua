local Class= require("herbert100.Class")

-- living manager, ensures that `Training` will die as soon as we start sneaking or the target becomes nil
local Living = require("herbert100.more quick loot.managers.abstract.Living")
local Items = require("herbert100.more quick loot.Item")

local Training_Item = Items.Training


local log = require("herbert100").Logger(require("herbert100.more quick loot.defns"))

---@class MQL.Manager.Training : MQL.Managers.Living
---@field disposition integer the disposition of the seller
---@field items MQL.Item.Training[] the skills that can be trained
local Training = Class.new({name="Training Manager", parents={Living}}, {loot_verb = "Trained"})


function Training:_get_key_btn_info()
    return {
        take = {label = "Train", pos = 0.05},
        open = {label = "Talk", pos = 0.95},
        -- take_all = {label = "Services", pos = 0.5}
    }

end

function Training:_make_items()
    -- special thanks to Hrnchamd for telling me how to determine which skills NPCs offer training in

    -- get the three highest skills. start each value off at an impossibly low value, just so we can compare them
    local first, second, third = -100, - 100, -100
    local first_id, second_id, third_id
    -- local skills = table_concat(self.ref.object.skills, {})
    if log > 2 then log:trace(("TRAINING: printing %s's skills."):format(self.ref.object.name)) end
    for id, value in ipairs(self.ref.object.skills) do
        id = id - 1
        if log > 2 then log:trace(("TRAINING: %12s: %i"):format(tes3.getSkillName(id), value)) end
        -- if value is bigger than first, bump up second and third, then update first
        if first < value then
            third_id, third = second_id, second
            second_id, second = first_id, first
            first_id, first = id, value
        elseif second < value then 
            third_id, third = second_id, second
            second_id, second = id, value
        elseif third < value then 
            third_id, third = id, value
        end

    end
    if log > 1 then 
        log(string.format("TRAINING: %s's highest skills are:\n\t\z
            %s: %i\n\t\z
            %s: %i\n\t\z
            %s: %i\n\t\z
            ",
            self.ref.object.name,
            tes3.getSkillName(first_id), first,
            tes3.getSkillName(second_id), second,
            tes3.getSkillName(third_id), third
        ))
    end


    -- i could probably write this in a for loop, but it's nice to take a break from for loops every once in a while

    self.items[1] = Training_Item{
        skill_id = first_id, 
        max_lvl = first,
        cost = tes3.calculatePrice{ merchant=self.ref.mobile, skill=first_id, training=true }
    }
    self.items[2] = Training_Item{
        skill_id = second_id, 
        max_lvl = second,
        cost = tes3.calculatePrice{ merchant=self.ref.mobile, skill=second_id, training=true }
    }
    self.items[3] = Training_Item{
        skill_id = third_id, 
        max_lvl = third,
        cost = tes3.calculatePrice{ merchant=self.ref.mobile, skill=third_id, training=true }
    }

end



function Training:take_item(modifier_pressed)
    log "TRAINING: trying to train"
    local gold = tes3.getPlayerGold()

    local i = self.gui.index
    local item = self.items[i]
    local skill_id = item.skill_id
    local skill = tes3.getSkill(skill_id)

    local max_lvl = item.max_lvl
    local player_skill = tes3.mobilePlayer:getSkillStatistic(skill_id)

    local related_attr_id = skill.attribute

    log(string.format("TRAINING: skill: %s. related attr_id: %i", skill.name, related_attr_id))
    local player_attr = tes3.mobilePlayer.attributes[related_attr_id+1]


    if gold < item.cost then 
        tes3.messageBox{message="You don't have enough gold to train this skill. :("}
    -- skill level must be `<= max_lvl` and also `< 100`. in order to receive training
    elseif player_skill.base > max_lvl or player_skill.base >= 100 then 
        tes3.messageBox{message="Your skill level is too high."}
    elseif player_attr.current <= player_skill.base then -- trainers are okay with `fortify attribute`
        tes3.messageBox{message=("Your %s is too low."):format(tes3.getAttributeName(related_attr_id))}
    else
        -- special thanks to Hrnchamd for telling me how to remove gold from the player's inventory
        tes3.removeItem{ reference = tes3.player, item = "Gold_001", count = item.cost }
        tes3.playSound{ reference = tes3.player, sound = "Item Gold Down"}

        --do this after returning so we make sure the menu gets blocked. the player probably wont notice the delay.
        timer.delayOneFrame(function (e) 
            tes3.mobilePlayer:progressSkillToNextLevel(skill_id)
            -- tes3.messageBox{message="Training successful."}
            self.items[i].cost = tes3.calculatePrice{training = true,
                merchant=self.ref.mobile,
                skill=skill_id,
            }
            self.items[i]:make_label()
            self.gui:update_item_labels{[i]=self.items[i].label}
            
        end)
    end
    return true
end
function Training:take_all_items(modifier_pressed) 
    return self:take_item(modifier_pressed)
end

return Training