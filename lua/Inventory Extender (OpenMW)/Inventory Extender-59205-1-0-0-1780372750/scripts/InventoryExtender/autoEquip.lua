local types = require('openmw.types')
local self = require('openmw.self')
local core = require('openmw.core')
local I = require('openmw.interfaces')

local helpers = require('scripts.InventoryExtender.util.helpers')

local function getSkillValue(skill)
    if not types.NPC.objectIsInstance(self) then
        return 0
    end

    local skillGetter = types.NPC.stats.skills[skill]
    if not skillGetter then
        return 0
    end

    local stat = skillGetter(self)
    return stat and stat.modified or 0
end

local function getItemCondition(item)
    local itemData = types.Item.itemData(item)
    if itemData and itemData.condition ~= nil and itemData.condition ~= -1 then
        return itemData.condition
    end

    local itemRecord = item.type.record(item)
    return itemRecord.health or itemRecord.maxCondition or itemRecord.duration or 0
end

local function autoEquipWeapon(slots)
    if not types.NPC.objectIsInstance(self) then
        local services = self.type.record(self).servicesOffered or {}
        if services['Weapon'] or services['MagicItems'] then
            return
        end
    end

    local weaponSkills = {
        'longblade',
        'axe',
        'spear',
        'shortblade',
        'marksman',
        'bluntweapon',
    }

    local weaponSkillVisited = {}
    local arrowMax = 0
    local boltMax = 0
    local bestArrow = nil
    local bestBolt = nil
    local inventory = types.Actor.inventory(self)

    for _, item in ipairs(inventory:getAll()) do
        if types.Weapon.objectIsInstance(item) then
            local weaponRecord = item.type.record(item)
            if weaponRecord.type == types.Weapon.TYPE.Arrow then
                if weaponRecord.chopMaxDamage >= arrowMax then
                    arrowMax = weaponRecord.chopMaxDamage
                    bestArrow = item
                end
            elseif weaponRecord.type == types.Weapon.TYPE.Bolt then
                if weaponRecord.chopMaxDamage >= boltMax then
                    boltMax = weaponRecord.chopMaxDamage
                    bestBolt = item
                end
            end
        end
    end

    for _ = 1, #weaponSkills do
        local maxSkill = -1
        local maxWeaponSkill = nil

        for i, skill in ipairs(weaponSkills) do
            local skillValue = getSkillValue(skill)
            if skillValue > maxSkill and not weaponSkillVisited[i] then
                maxSkill = skillValue
                maxWeaponSkill = i
            end
        end

        if not maxWeaponSkill then
            break
        end

        local bestWeapon = nil
        local bestDamage = 0
        for _, item in ipairs(inventory:getAll()) do
            if types.Weapon.objectIsInstance(item) then
                local weaponInfo = helpers.getWeaponInfo(item)
                local weaponType = item.type.record(item).type
                local damage = helpers.getWeaponDamage(item) or 0
                if weaponInfo
                    and weaponType ~= types.Weapon.TYPE.Arrow
                    and weaponType ~= types.Weapon.TYPE.Bolt
                    and weaponInfo.skill == weaponSkills[maxWeaponSkill] then
                    if damage >= bestDamage then
                        bestDamage = damage
                        bestWeapon = item
                    end
                end
            end
        end

        if bestWeapon then
            local hasAmmo = true
            local weaponRecord = bestWeapon.type.record(bestWeapon)
            if weaponRecord.type == types.Weapon.TYPE.MarksmanBow then
                if bestArrow then
                    slots[types.Actor.EQUIPMENT_SLOT.Ammunition] = bestArrow
                else
                    hasAmmo = false
                end
            elseif weaponRecord.type == types.Weapon.TYPE.MarksmanCrossbow then
                if bestBolt then
                    slots[types.Actor.EQUIPMENT_SLOT.Ammunition] = bestBolt
                else
                    hasAmmo = false
                end
            end

            if hasAmmo then
                slots[types.Actor.EQUIPMENT_SLOT.CarriedRight] = bestWeapon
                if weaponRecord.type ~= types.Weapon.TYPE.MarksmanBow and weaponRecord.type ~= types.Weapon.TYPE.MarksmanCrossbow then
                    slots[types.Actor.EQUIPMENT_SLOT.Ammunition] = nil
                end
                break
            end
        end

        weaponSkillVisited[maxWeaponSkill] = true
    end
end

local function autoEquipArmor(slots)
    local actorIsNpc = types.NPC.objectIsInstance(self)
    local unarmoredRating = 0

    if actorIsNpc then
        local fUnarmoredBase1 = core.getGMST('fUnarmoredBase1')
        local fUnarmoredBase2 = core.getGMST('fUnarmoredBase2')
        local unarmoredSkill = getSkillValue('unarmored')
        unarmoredRating = math.max((fUnarmoredBase1 * unarmoredSkill) * (fUnarmoredBase2 * unarmoredSkill), 0)
    end

    local function shouldEquipClothing(item, oldItem, slot)
        if not types.Clothing.objectIsInstance(oldItem) then
            return false
        end

        if slot == types.Actor.EQUIPMENT_SLOT.LeftRing then
            local rightRing = slots[types.Actor.EQUIPMENT_SLOT.RightRing]
            if not rightRing then
                return false
            end
            if helpers.getItemValue(rightRing) <= helpers.getItemValue(oldItem) then
                return false
            end
        end

        return helpers.getItemValue(item) > helpers.getItemValue(oldItem)
    end

    local function shouldEquipArmor(item, oldItem)
        if not types.Armor.objectIsInstance(oldItem) then
            return true
        end

        local oldArmorType = oldItem.type.record(oldItem).type
        local newArmorType = item.type.record(item).type
        if oldArmorType == newArmorType then
            if actorIsNpc then
                return (I.Combat.getEffectiveArmorRating(item, self) or 0) > (I.Combat.getEffectiveArmorRating(oldItem, self) or 0)
            end
            return getItemCondition(item) > getItemCondition(oldItem)
        end

        return oldArmorType >= newArmorType
    end

    for _, item in ipairs(types.Actor.inventory(self):getAll()) do
        local isArmor = types.Armor.objectIsInstance(item)
        local isClothing = actorIsNpc and types.Clothing.objectIsInstance(item)

        if isArmor or isClothing then
            if isArmor then
                local armorRecord = item.type.record(item)
                if actorIsNpc then
                    if (I.Combat.getEffectiveArmorRating(item, self) or 0) <= unarmoredRating then
                        goto continue
                    end
                elseif armorRecord.type ~= types.Armor.TYPE.Shield then
                    goto continue
                end
            end

            local itemSlots = helpers.getEquipmentSlots(item) or {}
            for _, slot in ipairs(itemSlots) do
                local oldItem = slots[slot]
                local canEquip = true

                if oldItem then
                    if isArmor then
                        canEquip = shouldEquipArmor(item, oldItem)
                    else
                        canEquip = shouldEquipClothing(item, oldItem, slot)
                    end
                end

                if canEquip then
                    slots[slot] = item
                    break
                end
            end
        end

        ::continue::
    end
end

local function autoEquip(player)
    local slots = types.Actor.getEquipment(self)
    autoEquipWeapon(slots)
    autoEquipArmor(slots)
    types.Actor.setEquipment(self, slots)

    if player then
        player:sendEvent('IE_Update')
    end
end

return {
    engineHandlers = {
        onInit = function(data)
            autoEquip(data and data.player)
        end,
    },
}