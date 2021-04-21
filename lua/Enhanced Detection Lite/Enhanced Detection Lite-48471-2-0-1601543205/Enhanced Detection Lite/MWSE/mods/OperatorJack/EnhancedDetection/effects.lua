local effectVfx = {
    animal = {
        castVFX = "VFX_MysticismCast",
        hitVFX = "VFX_MysticismHit",
    },
    key = {
        castVFX = "VFX_MysticismCast",
        hitVFX = "VFX_MysticismHit",
    },
    enchantment = {
        castVFX = "VFX_MysticismCast",
        hitVFX = "VFX_MysticismHit",
    },
}

local particleTexture = "vfx_myst_flare01.tga"

local staticIds = {
    animalCast = "VFX_OJ_ED_AnimalCast",
    animalHit = "VFX_OJ_ED_AnimalHit",
    keyCast = "VFX_OJ_ED_KeyCast",
    keyHit = "VFX_OJ_ED_KeyHit",
    enchantmentCast = "VFX_OJ_ED_EnchantmentCast",
    enchantmentHit = "VFX_OJ_ED_EnchantmentHit",
}
local statics = {
    [staticIds.animalCast] = "EditorMarker.nif",
    [staticIds.animalHit] = "OJ\\ED\\hit\\ED_H_Animal.nif",
    [staticIds.keyCast] = "EditorMarker.nif",
    [staticIds.keyHit] = "OJ\\ED\\hit\\ED_H_Key.nif",
    [staticIds.enchantmentCast] = "EditorMarker.nif",
    [staticIds.enchantmentHit] = "OJ\\ED\\hit\\ED_H_Enchant.nif",
}

local function addMagicEffects()
    if tes3.getFileExists("meshes\\OJ\\ED\\hit\\ED_H_Animal.nif") == true then
        for id, mesh in pairs(statics) do
            if (tes3.getObject(id) == nil) then
                if (tes3.getFileExists("meshes\\" .. mesh) == true) then
                    tes3.createObject({
                        objectType = tes3.objectType.static,
                        id = id,
                        mesh = mesh
                    })
                else
                    print("[Enhanced Detection: ERROR] Static " .. id .. " missing mesh at path " .. mesh)
                    return
                end
            end
        end

        particleTexture = "\\OJ\\ED\\md_rfd_kurp\\Blank.dds"

        effectVfx = {
            animal = {
                castVFX = staticIds.animalCast,
                hitVFX = staticIds.animalHit,
            },
            key = {
                castVFX = staticIds.keyCast,
                hitVFX = staticIds.keyHit,
            },
            enchantment = {
                castVFX = staticIds.enchantmentCast,
                hitVFX = staticIds.enchantmentHit,
            },
        }

        for effectType , pair in pairs(effectVfx) do
            for vfxType, staticId in pairs(pair) do
                if (tes3.getObject(staticId) == nil) then
                    print("[Enhanced Detection: ERROR] Static " .. staticId .. " failed to be created for effect type " .. effectType)
                    return
                end
            end
        end

        print("[Enhanced Detection: INFO] Optional VFX Initialized.")
    end

    local animalEffect = tes3.getMagicEffect(tes3.effect.detectAnimal)
    animalEffect.castVisualEffect = tes3.getObject(effectVfx.animal.castVFX)
    animalEffect.hitVisualEffect = tes3.getObject(effectVfx.animal.hitVFX)
    animalEffect.particleTexture = particleTexture
    animalEffect.icon = "RFD\\ED_RFD_icon_animal.dds"

    local keyEffect = tes3.getMagicEffect(tes3.effect.detectKey)
    keyEffect.castVisualEffect = tes3.getObject(effectVfx.key.castVFX)
    keyEffect.hitVisualEffect = tes3.getObject(effectVfx.key.hitVFX)
    keyEffect.particleTexture = particleTexture
    keyEffect.icon = "RFD\\ED_RFD_icon_key.dds"

    local enchantmentEffect = tes3.getMagicEffect(tes3.effect.detectEnchantment)
    enchantmentEffect.castVisualEffect = tes3.getObject(effectVfx.enchantment.castVFX)
    enchantmentEffect.hitVisualEffect = tes3.getObject(effectVfx.enchantment.hitVFX)
    enchantmentEffect.particleTexture = particleTexture
    enchantmentEffect.icon = "RFD\\ED_RFD_icon_enchant.dds"
end

event.register("magicEffectsResolved", addMagicEffects)