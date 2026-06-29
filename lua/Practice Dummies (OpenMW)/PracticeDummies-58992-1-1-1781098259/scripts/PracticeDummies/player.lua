---@diagnostic disable: invisible, param-type-mismatch
local I = require("openmw.interfaces")
local self = require("openmw.self")
local types = require("openmw.types")
local storage = require("openmw.storage")
local time = require("openmw_aux.time")
local core = require("openmw.core")
local async = require("openmw.async")

local dummies = require("scripts.PracticeDummies.dummies")
local pq = require("scripts.PracticeDummies.model.priorityQueue")
local messageFactory = require("scripts.PracticeDummies.utils.messages")
local settingsCache = require("scripts.PracticeDummies.utils.settingsCache")

local settings = settingsCache.new(storage.playerSection("SettingsPracticeDummies"), async)
local messages = messageFactory(core.l10n("PracticeDummies"))
local fWeaponDamageMult = core.getGMST("fWeaponDamageMult")
local strength = self.type.stats.attributes.strength(self)
local wType = types.Weapon.TYPE
local weaponTypeToSkillId = {
    [wType.AxeOneHand]        = "axe",
    [wType.AxeTwoHand]        = "axe",
    [wType.BluntOneHand]      = "bluntweapon",
    [wType.BluntTwoClose]     = "bluntweapon",
    [wType.BluntTwoWide]      = "bluntweapon",
    [wType.LongBladeOneHand]  = "longblade",
    [wType.LongBladeTwoHand]  = "longblade",
    [wType.MarksmanBow]       = "marksman",
    [wType.MarksmanCrossbow]  = "marksman",
    [wType.MarksmanThrown]    = "marksman",
    [wType.ShortBladeOneHand] = "shortblade",
    [wType.SpearTwoWide]      = "spear",
    h2h                       = "handtohand",
}
local weaponTypeToCustomSkills = {
    -- Staves https://www.nexusmods.com/morrowind/mods/58592
    [wType.BluntTwoWide]   = { id = "staves_staves", useType = "hit" },
    -- Throwing https://www.nexusmods.com/morrowind/mods/58705
    [wType.MarksmanThrown] = { id = "throwing", useType = "hit" },
}
local rangedWeaponTypes = {
    [wType.MarksmanBow]      = true,
    [wType.MarksmanCrossbow] = true,
    [wType.MarksmanThrown]   = true,
}
local timestamps = pq:new()

---@param weaponType WeaponTYPE|string
local function attackedDummy(weaponType)
    local vanillaSkillId = weaponTypeToSkillId[weaponType]
    local customSkill = weaponTypeToCustomSkills[weaponType]
    local customSkillUsed = I.SkillFramework
        and customSkill
        and I.SkillFramework.getSkillRecord(customSkill.id)

    -- level cap check
    local skill = customSkillUsed
        and I.SkillFramework.getSkillStat(customSkill.id)
        or self.type.stats.skills[vanillaSkillId](self)
    if skill.base >= settings.maxSkill then
        messages.show(self, "msg_limitReached")
        return
    end

    -- hit cap check
    local maxHits = settings.maxHits
    if timestamps:size() >= maxHits and maxHits ~= -1 then
        local now = core.getGameTime()
        local cooldown = timestamps:peek() + settings.cooldown * time.hour
        if cooldown > now then
            messages.show(self, "msg_maxHits")
            return
        end

        while timestamps:size() >= maxHits do
            timestamps:pop()
        end
        timestamps:push(now)
    elseif maxHits ~= -1 then
        timestamps:push(core.getGameTime())
    end

    -- skill raise
    local skillUsedOptions = {
        skillGain = settings.skillGain ~= 0
            and settings.skillGain
            or nil,
        scale = settings.scale,
        useType = customSkillUsed
            and customSkill.useType
            or I.SkillProgression.SKILL_USE_TYPES.Weapon_SuccessfulHit
    }
    if customSkillUsed then
        I.SkillFramework.skillUsed(customSkill.id, skillUsedOptions)
    else
        I.SkillProgression.skillUsed(vanillaSkillId, skillUsedOptions)
    end

    -- Time Flies interop
    core.sendGlobalEvent("TimeFlies_passMinutes", settings.timePassed)
end

---@param obj GameObject
---@param var any
---@param res RayCastingResult
local function meleeWeaponHandler(obj, var, res)
    if not dummies.isDummy(obj) then return end

    local eqWeapon = self.type.getEquipment(self, self.type.EQUIPMENT_SLOT.CarriedRight)
    local eqWeaponType

    if eqWeapon then
        local record = eqWeapon.type.records[eqWeapon.recordId]
        eqWeaponType = record.type
        -- weapon wearing
        if not rangedWeaponTypes[eqWeaponType] then
            local damageMax = math.max(record.chopMaxDamage, record.slashMaxDamage, record.thrustMaxDamage)
            local itemData = eqWeapon.type.itemData(eqWeapon)
            -- swing is considered to be always max, so it's a bit simplified
            -- https://wiki.openmw.org/index.php?title=Research:Combat#Damage
            local rawDamage = damageMax * (0.5 + 0.01 * strength.modified) * (itemData.condition / record.health)
            core.sendGlobalEvent("ModifyItemCondition", {
                actor = self,
                item = eqWeapon,
                amount = -math.max(fWeaponDamageMult * rawDamage, 1)
            })
        end
    else
        eqWeaponType = "h2h"
    end

    attackedDummy(eqWeaponType)
end

if I.impactEffects then
    I.impactEffects.addHitObjectHandler(meleeWeaponHandler)
end

local function onLoad(data)
    if not data then return end
    timestamps._heap = data.heap or timestamps._heap
    timestamps._size = data.size or timestamps._size
end

local function onSave()
    return {
        heap = timestamps._heap,
        size = timestamps._size,
    }
end

return {
    engineHandlers = {
        onLoad = onLoad,
        onSave = onSave,
    },
    eventHandlers = {
        PracticeDummies_rangedAttack = attackedDummy
    }
}
