local mod = '[Bestow Binding]'
local version = '1.2'

local function Log(s, ...)
    mwse.log(mod .. ' ' .. tostring(s), ...)
end

local function OutOfDate()
    local msg = 'MWSE is out of date! Update to use this mod.'
    tes3.messageBox(mod .. '\n' .. msg)
    Log(msg)
end

if mwse.buildDate == nil or mwse.buildDate < 20201201 then
    event.register('initialized', OutOfDate)
    return
end

local me = include('OperatorJack.MagickaExpanded.magickaExpanded')
local is_mod_enabled = false
local is_me_present = false
local new_summon_id = 'merz_skeleton_summon'

-- Cache variables - these will be set on initialization
local new_summon
local arrow
local sounds
local bound_shield
local bound_weapons
local summons
local bound_effects

local function ResistBoundArmor(e)
    -- Force creatures to always resist bound armor effects. This prevents the game from crashing and other bugs.
    if e.target.object.objectType == tes3.objectType.creature and
        bound_effects.armor[e.source.effects[e.effectIndex + 1].id] then
        e.resistedPercent = 100
    end
end

local function ForceBoundEquipment(e)
    -- Force summoned creatures to use bound weapons and shields.
    -- Only skeletons, dremoras, and golden saints can use weapons and shields in vanilla. Also check for our
    -- replacement npc skeleton summon.
    -- Casting a bound weapon spell removes all weapons that aren't bound weapons.
    -- Casting a bound shield spell removes all shields that aren't bound shields.
    -- Casting a bound longbow spell also adds arrows.
    local object = e.target.object
    if summons[object.baseObject] then
        local effect = e.source.effects[e.effectIndex + 1]
        if bound_effects.weapons[effect.id] then
            for _, item in pairs(object.inventory) do
                if item.object.objectType == tes3.objectType.weapon and not bound_weapons[item.object] then
                    tes3.removeItem({ reference = e.target, item = item.object })
                end
            end
            if effect.id == tes3.effect.boundLongbow then
                tes3.addItem({ reference = e.target, item = arrow, count = effect.duration })
            end
        elseif effect.id == tes3.effect.boundShield then
            for _, item in pairs(object.inventory) do
                if item.object.objectType == tes3.objectType.armor and item.object.slot == tes3.armorSlot.shield and
                    item.object ~= bound_shield then
                    tes3.removeItem({ reference = e.target, item = item.object })
                end
            end
        end
    end
end

local function PlaySkeletonSound(target)
    -- Randomly play one of the vanilla skeleton creature sounds, but only if none of them are already playing.
    local is_sound_playing = false
    for _, sound in ipairs(sounds) do
        if tes3.getSoundPlaying({ sound = sound, reference = target }) then
            is_sound_playing = true
            break
        end
    end
    if not is_sound_playing then
        local sound = sounds[math.random(1, #sounds)]
        tes3.playSound({ sound = sound, reference = target})
    end
end

local function NewSummonActivation(e)
    -- Since our new skeleton summon is an NPC and not a creature, disable activation to avoid the dialog window.
    -- Randomly play a skeleton creature sound.
    if e.activator == tes3.player and e.target.object.baseObject == new_summon then
        if not e.target.mobile.isDead then
            PlaySkeletonSound(e.target)
        end
        return false
    end
end

local function PreventLooting(e)
    -- Prevent the player from looting summoned creatures that might have bound arrows.
    -- There's a small window where it's possible to loot a dead summoned creature before it disappears.
    if e.activator == tes3.player and summons[e.target.object.baseObject] and e.target.mobile.isDead then
        return false
    end
end

local function RemoveArrows(e)
    -- Remove bound arrows from corpses before the player can loot them. It's possible that they could be added to
    -- targets killed by a summon with a bound longbow, thanks to the the arrow recovery mechanic governed by
    -- fProjectileThrownStoreChance.
    if e.activator == tes3.player and (e.target.object.objectType == tes3.objectType.creature or
        e.target.object.objectType == tes3.objectType.npc) and e.target.mobile.isDead then
        for _, item in pairs(e.target.object.inventory) do
            if item.object.objectType == tes3.objectType.ammunition and item.object == arrow then
                tes3.removeItem({ reference = e.target, item = item.object, count = item.count})
            end
        end
    end
end

local function EnableBoundTouchTarget()
    -- Update bound item effects to allow for touch and target effect range.
    -- Armor, except shield (only NPCs and the player are valid targets for these effects)
    for id in pairs(bound_effects.armor) do
        local effect = tes3.getMagicEffect(id)
        effect.canCastTouch = true
        effect.canCastTarget = true
    end

    -- Weapons (Player, NPCs, and creatures are all valid targets)
    for id in pairs(bound_effects.weapons) do
        local effect = tes3.getMagicEffect(id)
        effect.canCastTouch = true
        effect.canCastTarget = true
    end

    -- Shield is a special case, as it's armor that can be used by creatures.
    local shield = tes3.getMagicEffect(tes3.effect.boundShield)
    shield.canCastTouch = true
    shield.canCastTarget = true
end

local function CacheObjects()
    -- Load objects we will want to compare later.
    sounds = {
        tes3.getSound('skeleton moan'),
        tes3.getSound('skeleton roar'),
        tes3.getSound('skeleton scream')
    }
    bound_shield = tes3.getObject('bound_shield')
    bound_weapons = {
        [tes3.getObject('bound_battle_axe')] = true,
        [tes3.getObject('bound_dagger')] = true,
        [tes3.getObject('bound_longbow')] = true,
        [tes3.getObject('bound_longsword')] = true,
        [tes3.getObject('bound_mace')] = true,
        [tes3.getObject('bound_spear')] = true
    }
    arrow = tes3.getObject('merz_bound_arrow')
    new_summon = tes3.getObject(new_summon_id)
    summons = {
        [tes3.getObject('dremora_summon')] = true,
        [tes3.getObject('golden saint_summon')] = true,
        [tes3.getObject('skeleton_summon')] = true,
        [new_summon] = true
    }
    bound_effects = {}
    bound_effects.armor = {
        [tes3.effect.boundCuirass] = true,
        [tes3.effect.boundHelm] = true,
        [tes3.effect.boundBoots] = true,
        [tes3.effect.boundGloves] = true
    }
    bound_effects.weapons = {
        [tes3.effect.boundDagger] = true,
        [tes3.effect.boundLongsword] = true,
        [tes3.effect.boundMace] = true,
        [tes3.effect.boundBattleAxe] = true,
        [tes3.effect.boundSpear] = true,
        [tes3.effect.boundLongbow] = true
    }
    if is_me_present then
        for effect in pairs(me.functions.getBoundArmorEffectList()) do
            bound_effects.armor[effect] = true
        end
        for effect, list in pairs(me.functions.getBoundWeaponEffectList()) do
            bound_effects.weapons[effect] = true
            for _, weapon in pairs(list) do
                -- Gracefully handle the case where ME is installed, but the esp is not activated.
                local object = tes3.getObject(weapon)
                if object then
                    bound_weapons[object] = true
                end
            end
        end
    end
end

local function InitializeMod()
    local esp = 'bestow_binding.esp'
    if tes3.isModActive(esp) then
        if not me then
            Log('Magicka Expanded not detected. Integration disabled.')
            is_me_present = false
        elseif not me.functions.getBoundArmorEffectList then
            Log('Magicka Expanded version < 2.04 detected. Integration disabled.')
            is_me_present = false
        else
            Log('Magicka Expanded version >= 2.04 detected. Integration enabled.')
            is_me_present = true
        end
        CacheObjects()
        EnableBoundTouchTarget()
        event.register('spellResist', ForceBoundEquipment)
        event.register('spellResist', ResistBoundArmor)
        event.register('activate', NewSummonActivation)
        event.register('activate', PreventLooting)
        event.register('activate', RemoveArrows)
        Log('Initialized Version ' .. version)
        is_mod_enabled = true
    else
        local msg = esp .. ' must be loaded. Mod disabled.'
        tes3.messageBox(mod .. '\n' .. msg)
        Log(msg)
        is_mod_enabled = false
    end
end

event.register('initialized', InitializeMod)

local function GetSummonId(gmst_id, magic_source_instance)
    if magic_source_instance.caster == tes3.player and is_mod_enabled then
        return new_summon_id
    else
        return tes3.findGMST(gmst_id).value
    end
end

-- Force the game to use our new skeleton summon, but only when the player casts the spell.
-- param_1 = 0x4
-- Get the magic source instance, then push it onto the stack.
mwse.memory.writeBytes({ address = 0x463ef0, bytes = { 0x8b, 0x44, 0x24, 0x04 } }) -- mov eax, dword ptr [esp + param_1]
mwse.memory.writeByte({ address = 0x463ef4, byte = 0x50 }) -- push eax
mwse.memory.writeNoOperation({ address = 0x463ef5, length = 0x1 })
-- Existing game code pushes gmst_id onto the stack at 0x463ef6.
mwse.memory.writeFunctionCall({
    address = 0x463efb,
    call = GetSummonId,
    signature = {
        arguments = { 'uint', 'tes3object' },
        returns = 'string'
    }
})