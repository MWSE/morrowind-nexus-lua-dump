local anim = require('openmw.animation')
local core = require('openmw.core')
local types = require('openmw.types')
local omwself = require('openmw.self')
local I = require('openmw.interfaces')
local storage = require('openmw.storage')
local settings = storage.globalSection('SettingsThirdPersonAltAttacksVFX')
local camera = nil

local mp = "scripts/MaxYari/ReAnimation_v2/"
local gutils = require(mp .. "scripts/gutils")

local spellvfx = false

if omwself.type == types.Player then
    camera = require('openmw.camera')
end

local function cloneAnimOptions(opts)
    local newOpts = gutils.shallowTableCopy(opts)
    if type(opts.priority) ~= "number" then
        newOpts.priority = gutils.shallowTableCopy(opts.priority)
    end
    return newOpts
end

I.ReAnimation.addAnimationOverride(
    -- thanks, Max!
    {
        parent = {"idle1h"},
        groupname = "idle1hs",
        armatureType = I.ReAnimation.ARMATURE_TYPE.ThirdPerson,
        condition = function()
            return gutils.isAShield(types.Actor.equipment(omwself, types.Actor.EQUIPMENT_SLOT.CarriedLeft)) and not types.NPC.races.records[types.NPC.record(omwself).race].isBeast
        end,
        stopCondition = function(self)
            return not self:condition()
        end,
        options = function(self, pOptions)
            local opts = cloneAnimOptions(pOptions)
            opts.blendMask = anim.BLEND_MASK.All
            gutils.expandPriority(pOptions)
            pOptions.priority[anim.BONE_GROUP.LeftArm] = -1
            return opts
        end,
        startOnAnimEvent = true
    }
)

I.ReAnimation.addAltAttackAnimations({
        parentAttackGroupname = "weapononehand",
        altAttackGroupname = "weapononehand1",
        armatureType = I.ReAnimation.ARMATURE_TYPE.ThirdPerson
})

I.ReAnimation.addAltAttackAnimations({
        parentAttackGroupname = "weapontwohand",
        altAttackGroupname = "weapontwohand1",
        armatureType = I.ReAnimation.ARMATURE_TYPE.ThirdPerson
})

I.ReAnimation.addAltAttackAnimations({
        parentAttackGroupname = "weapontwowide",
        altAttackGroupname = "weapontwowide1",
        armatureType = I.ReAnimation.ARMATURE_TYPE.ThirdPerson
})

I.ReAnimation.addAltAttackAnimations({
        parentAttackGroupname = "throwweapon",
        altAttackGroupname = "throwweapon1",
        armatureType = I.ReAnimation.ARMATURE_TYPE.ThirdPerson
})

-- some spell vfx --
local function get_spell_or_enchanted_item()
    local spell_or_item = types.Actor.getSelectedSpell(omwself);
    if not spell_or_item then
        local item = types.Actor.getSelectedEnchantedItem(omwself)
        if item and item.type then
            local rec = item.type.record(item)
            if rec and rec.enchant then
                spell_or_item = core.magic.enchantments.records[rec.enchant]
            end
        end
    end
    return spell_or_item
end

local lastSpell = get_spell_or_enchanted_item()

local function add_spell_vfx_one(left)
    local spell = get_spell_or_enchanted_item()
    lastSpell = spell
    local texture = "vfx_starglow.tga"
    if spell then
        texture = spell.effects[1].effect.particle or texture
    end

    if texture:find("blank") then
        texture = "vfx_starglow.tga"
    end

    local bone = "bip01 r hand"
    local vfx_id = "spellvfxright"

    if left then
        bone = "bip01 l hand"
        vfx_id = "spellvfxleft"
    end

    anim.addVfx(
        omwself,
        "meshes/tpaa/spellvfx.nif",
        {
            particleTextureOverride=texture,
            boneName=bone,
            loop=true,
            vfxId=vfx_id
        }
    )
end

local function add_spell_vfx()
    if settings:get("disable-vfx-for-1st-person") and camera and camera.getMode() == camera.MODE.FirstPerson then
        return
    end
    add_spell_vfx_one(true)
    add_spell_vfx_one(false)
    spellvfx = true
end

local function remove_spell_vfx()
    if spellvfx then
        anim.removeVfx(omwself, "spellvfxright")
        anim.removeVfx(omwself, "spellvfxleft")
        spellvfx = false
    end
end


I.AnimationController.addTextKeyHandler(
    'spellcast',
    function(_, key)
        if not anim.hasAnimation(omwself) then
            return
        end

        if key == "self vfxstop" then
            anim.removeVfx(omwself, "spellvfxright")
        end

        if key == "equip start" then
            add_spell_vfx()
        end

        if key == "unequip stop" then
            remove_spell_vfx()
        end
    end
)

I.AnimationController.addTextKeyHandler(
    'idlespell',
    function(_, key)
        if key == "start" then
            add_spell_vfx()
        end
    end
)

-- disable or blend some other animations

I.AnimationController.addPlayBlendedAnimationHandler(function(groupname, options)
        if camera and camera.getMode() == camera.MODE.FirstPerson then
            return
        end

        local beast = types.NPC.races.records[types.NPC.record(omwself).race].isBeast
        -- why does idlestorm have another blend mask to begin with?
        -- because beasts look funny without!
        if groupname == "idlestorm" and not beast then
            options.blendMask = anim.BLEND_MASK.RightArm
        end

        if groupname:find("spellcast") and options.startKey and options.startKey:find("unequip") and beast then
            options.blendMask = anim.BLEND_MASK.UpperBody
        end

        -- if types.Actor.getStance(omwself) == types.Actor.STANCE.Weapon then
        --     if groupname:find("turn") then -- todo turn off turn animation only when a bow is readied
        --         options.blendMask = 0
        --     end
        -- end


        if types.Actor.getStance(omwself) == types.Actor.STANCE.Spell then
            if beast and not groupname:find("turn") then
                options.blendMask = anim.BLEND_MASK.UpperBody
                -- play the idle animation for the feet with low prio so we get sane beast animations
                anim.playBlended(omwself, "idle", {loop=-1, priority=4, blendMask=anim.BLEND_MASK.LowerBody})
            end

            if groupname:find("run") then
                options.blendMask = anim.BLEND_MASK.All - anim.BLEND_MASK.RightArm
            end
            if groupname:find("walk") then
                options.blendMask = anim.BLEND_MASK.All - anim.BLEND_MASK.RightArm - anim.BLEND_MASK.LeftArm
            end
        end
end)

return {
    engineHandlers = {
        onUpdate = function  (_)
            if types.Actor.getStance(omwself) ~= types.Actor.STANCE.Spell or types.Actor.isDead(omwself) then
                remove_spell_vfx()
            else
                local currentSpell = get_spell_or_enchanted_item()
                if currentSpell and lastSpell then
                    if currentSpell.type ~= lastSpell.type or currentSpell.id ~= lastSpell.id then
                        remove_spell_vfx()
                        add_spell_vfx()
                    end
                end
            end
        end
    }
}
