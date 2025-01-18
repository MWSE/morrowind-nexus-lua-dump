--- @param e loadedEventData
local function loadedCallback(e)
    if tes3.player.data.baseGameEdits ~= nil then
        return
    end

    --Give Fire Atronachs constant Fire Aura
    local ability1 = tes3.createObject({
        objectType = tes3.objectType.spell,
        isActiveCast = false,
        castType = tes3.spellType.ability }) --[[@as tes3spell]]
    ability1.name = "Atronach's Fire Aura"
    ability1.magickaCost = 0
            
    local effect = ability1.effects[1]
    effect.id = tes3.effect.fireAura
    effect.rangeType = tes3.effectRange.self
    effect.min = 5
    effect.max = 5
    effect.duration = 1
    effect.radius = 0
    effect.skill = -1
    effect.attribute = -1

    tes3.addSpell({actor = "atronach_flame", spell = ability1})
    tes3.addSpell({actor = "atronach_flame_ttmk", spell = ability1})
    tes3.addSpell({actor = "atronach_flame_summon", spell = ability1})
    tes3.addSpell({actor = "atronach_flame_az", spell = ability1})

    --Give Frost Atronachs constant Frost Aura
    local ability2 = tes3.createObject({
        objectType = tes3.objectType.spell,
        isActiveCast = false,
        castType = tes3.spellType.ability }) --[[@as tes3spell]]
    ability2.name = "Atronach's Frost Aura"
    ability2.magickaCost = 0
                    
    local effect = ability2.effects[1]
    effect.id = tes3.effect.frostAura
    effect.rangeType = tes3.effectRange.self
    effect.min = 6
    effect.max = 6
    effect.duration = 1
    effect.radius = 0
    effect.skill = -1
    effect.attribute = -1
    tes3.addSpell({actor = "atronach_frost", spell = ability2})
    tes3.addSpell({actor = "atronach_frost_summon", spell = ability2})
    tes3.addSpell({actor = "atronach_frost_gwai_uni", spell = ability2})

    -- Give Storm Atronachs Shock Aura
    local ability3 = tes3.createObject({
        objectType = tes3.objectType.spell,
        isActiveCast = false,
        castType = tes3.spellType.ability }) --[[@as tes3spell]]
    ability3.name = "Atronach's Shock Aura"
    ability3.magickaCost = 0
                        
    local effect = ability3.effects[1]
    effect.id = tes3.effect.frostAura
    effect.rangeType = tes3.effectRange.self
    effect.min = 8
    effect.max = 8
    effect.duration = 1
    effect.radius = 0
    effect.skill = -1
    effect.attribute = -1
    tes3.addSpell({actor = "atronach_storm", spell = ability3})
    tes3.addSpell({actor = "atronach_storm_summon", spell = ability3})
    tes3.addSpell({actor = "atronach_storm_az", spell = ability3})

    -- Give Dire Frost Atronachs Dire Frost Aura
    local ability4 = tes3.createObject({
        objectType = tes3.objectType.spell,
        isActiveCast = false,
        castType = tes3.spellType.ability }) --[[@as tes3spell]]
    ability4.name = "Atronach's Dire Frost Aura"
    ability4.magickaCost = 0
                    
    local effect = ability4.effects[1]
    effect.id = tes3.effect.frostAura
    effect.rangeType = tes3.effectRange.self
    effect.min = 8
    effect.max = 8
    effect.duration = 1
    effect.radius = 0
    effect.skill = -1
    effect.attribute = -1
    tes3.addSpell({actor = "atronach_frost_BM", spell = ability4})

    -- Give Skeletons Skeletal Resistances
    local ability5 = tes3.createObject({
        objectType = tes3.objectType.spell,
        isActiveCast = false,
        castType = tes3.spellType.ability }) --[[@as tes3spell]]
    ability5.name = "Skeletal Resistance"
    ability5.magickaCost = 0
                    
    local effect = ability5.effects[1]
    effect.id = tes3.effect.weaknessToBludgeoning
    effect.rangeType = tes3.effectRange.self
    effect.min = 40
    effect.max = 40
    effect.duration = 1
    effect.radius = 0
    effect.skill = -1
    effect.attribute = -1

    local effect = ability5.effects[2]
    effect.id = tes3.effect.resistCutting
    effect.rangeType = tes3.effectRange.self
    effect.min = 40
    effect.max = 40
    effect.duration = 1
    effect.radius = 0
    effect.skill = -1
    effect.attribute = -1

    local effect = ability5.effects[3]
    effect.id = tes3.effect.resistPiercing
    effect.rangeType = tes3.effectRange.self
    effect.min = 40
    effect.max = 40
    effect.duration = 1
    effect.radius = 0
    effect.skill = -1
    effect.attribute = -1

    tes3.addSpell({actor = "skeleton_Vemynal", spell = ability5})
    tes3.addSpell({actor = "skeleton_weak", spell = ability5})
    tes3.addSpell({actor = "skeleton", spell = ability5})
    tes3.addSpell({actor = "skeleton entrance", spell = ability5})
    tes3.addSpell({actor = "skeleton_summon", spell = ability5})
    tes3.addSpell({actor = "skeleton archer", spell = ability5})
    tes3.addSpell({actor = "skeleton champion", spell = ability5})
    tes3.addSpell({actor = "skeleton champ_sandas00", spell = ability5})
    tes3.addSpell({actor = "skeleton champ_sandas10", spell = ability5})
    tes3.addSpell({actor = "skeleton_aldredaynia", spell = ability5})
    tes3.addSpell({actor = "skeleton warrior", spell = ability5})
    tes3.addSpell({actor = "worm lord", spell = ability5})
    tes3.addSpell({actor = "bonelord", spell = ability5})
    tes3.addSpell({actor = "bonelord_summon", spell = ability5})
    tes3.addSpell({actor = "BM_wolf_skeleton", spell = ability5})
    tes3.addSpell({actor = "BM_wolf_bone_summon", spell = ability5})
    --tes3.addSpell({actor = "skeleton nord", spell = ability5})
    tes3.addSpell({actor = "skeleton_stahl_uni", spell = ability5})
    tes3.addSpell({actor = "skeleton nord_2", spell = ability5})
    --tes3.addSpell({actor = "bm_skeleton_pirate", spell = ability5})
    tes3.addSpell({actor = "bm_skeleton_pirate_capt", spell = ability5})
    tes3.addSpell({actor = "bm skeleton champion gr", spell = ability5})
    tes3.addSpell({actor = "bm_sk_champ_bloodskal01", spell = ability5})
    tes3.addSpell({actor = "bm_sk_champ_bloodskal02", spell = ability5})
    tes3.addSpell({actor = "lich", spell = ability5})
    tes3.addSpell({actor = "lich_profane_unique", spell = ability5})
    tes3.addSpell({actor = "lich_relvel", spell = ability5})
    tes3.addSpell({actor = "lich_barilzar", spell = ability5})

    -- Give Dwemer Constructs Metallic Resistances
    local ability6 = tes3.createObject({
        objectType = tes3.objectType.spell,
        isActiveCast = false,
        castType = tes3.spellType.ability }) --[[@as tes3spell]]
    ability6.name = "Construct Resistance"
    ability6.magickaCost = 0
                    
    local effect = ability6.effects[1]
    effect.id = tes3.effect.resistCutting
    effect.rangeType = tes3.effectRange.self
    effect.min = 40
    effect.max = 40
    effect.duration = 1
    effect.radius = 0
    effect.skill = -1
    effect.attribute = -1

    local effect = ability6.effects[2]
    effect.id = tes3.effect.weaknessToPiercing
    effect.rangeType = tes3.effectRange.self
    effect.min = 25
    effect.max = 25
    effect.duration = 1
    effect.radius = 0
    effect.skill = -1
    effect.attribute = -1

    tes3.addSpell({actor = "centurion_sphere", spell = ability6})
    tes3.addSpell({actor = "centurion_sphere_nchur", spell = ability6})
    tes3.addSpell({actor = "centurion_sphere_hts2", spell = ability6})
    tes3.addSpell({actor = "centurion_sphere_summon", spell = ability6})
    tes3.addSpell({actor = "centurion_shock_baladas", spell = ability6})
    tes3.addSpell({actor = "centurion_spider", spell = ability6})
    tes3.addSpell({actor = "centurion_spider_nchur", spell = ability6})
    tes3.addSpell({actor = "centurion_spider_tga1", spell = ability6})
    tes3.addSpell({actor = "centurion_spider_tga2", spell = ability6})
    tes3.addSpell({actor = "centurion_steam", spell = ability6})
    tes3.addSpell({actor = "centurion_steam_exhibit", spell = ability6})
    tes3.addSpell({actor = "centurion_steam_nchur", spell = ability6})
    tes3.addSpell({actor = "centurion_steam_hts", spell = ability6})
    tes3.addSpell({actor = "centurion_Mudan_unique", spell = ability6})
    tes3.addSpell({actor = "centurion_steam_advance", spell = ability6})
    tes3.addSpell({actor = "centurion_steam_C_L", spell = ability6})
    tes3.addSpell({actor = "centurion_projectile", spell = ability6})
    tes3.addSpell({actor = "centurion_projectile_C", spell = ability6})
    tes3.addSpell({actor = "centurion_sphere_bbot1", spell = ability6})
    tes3.addSpell({actor = "centurion_sphere_bbot5", spell = ability6})
    tes3.addSpell({actor = "centurion_sphere_bbot6", spell = ability6})
    tes3.addSpell({actor = "centurion_spider_bbot1", spell = ability6})
    tes3.addSpell({actor = "centurion_spider_bbot3", spell = ability6})
    tes3.addSpell({actor = "centurion_spider_bbot7", spell = ability6})
    tes3.addSpell({actor = "centurion_steam_bbot2", spell = ability6})
    tes3.addSpell({actor = "centurion_steam_bbot4", spell = ability6})
    tes3.addSpell({actor = "centurion_steam_bbot8", spell = ability6})

    -- Gives certain servants of Dagoth Ur Corprus Resistances
    local ability7 = tes3.createObject({
        objectType = tes3.objectType.spell,
        isActiveCast = false,
        castType = tes3.spellType.ability }) --[[@as tes3spell]]
    ability7.name = "Corprus Resistance"
    ability7.magickaCost = 0
                    
    local effect = ability7.effects[1]
    effect.id = tes3.effect.resistBludgeoning
    effect.rangeType = tes3.effectRange.self
    effect.min = 40
    effect.max = 40
    effect.duration = 1
    effect.radius = 0
    effect.skill = -1
    effect.attribute = -1

    local effect = ability7.effects[2]
    effect.id = tes3.effect.weaknessToCutting
    effect.rangeType = tes3.effectRange.self
    effect.min = 25
    effect.max = 25
    effect.duration = 1
    effect.radius = 0
    effect.skill = -1
    effect.attribute = -1

    tes3.addSpell({actor = "ascended_sleeper", spell = ability7})
    tes3.addSpell({actor = "dagoth fandril", spell = ability7})
    tes3.addSpell({actor = "dagoth molos", spell = ability7})
    tes3.addSpell({actor = "dagoth felmis", spell = ability7})
    tes3.addSpell({actor = "dagoth rather", spell = ability7})
    tes3.addSpell({actor = "dagoth garel", spell = ability7})
    tes3.addSpell({actor = "dagoth reler", spell = ability7})
    tes3.addSpell({actor = "dagoth goral", spell = ability7})
    tes3.addSpell({actor = "dagoth tanis", spell = ability7})
    tes3.addSpell({actor = "dagoth_hlevul", spell = ability7})
    tes3.addSpell({actor = "dagoth uvil", spell = ability7})
    tes3.addSpell({actor = "dagoth malan", spell = ability7})
    tes3.addSpell({actor = "dagoth vaner", spell = ability7})
    tes3.addSpell({actor = "dagoth ulen", spell = ability7})
    tes3.addSpell({actor = "dagoth irvyn", spell = ability7})
    tes3.addSpell({actor = "corprus_stalker", spell = ability7})
    tes3.addSpell({actor = "corprus_stalker_fgcs", spell = ability7})
    tes3.addSpell({actor = "corprus_stalker_fyr01", spell = ability7})
    tes3.addSpell({actor = "corprus_stalker_fyr02", spell = ability7})
    tes3.addSpell({actor = "corprus_stalker_fyr03", spell = ability7})
    tes3.addSpell({actor = "corprus_stalker_morvayn", spell = ability7})
    tes3.addSpell({actor = "corprus_stalker_danar", spell = ability7})
    tes3.addSpell({actor = "corprus_lame", spell = ability7})
    tes3.addSpell({actor = "corprus_lame_fyr01", spell = ability7})
    tes3.addSpell({actor = "corprus_lame_fyr02", spell = ability7})
    tes3.addSpell({actor = "corprus_lame_fyr03", spell = ability7})
    tes3.addSpell({actor = "corprus_lame_fyr04", spell = ability7})
    tes3.addSpell({actor = "corprus_lame_morvayn", spell = ability7})
    
    tes3.player.data.baseGameEdits = {}
    tes3.player.data.baseGameEdits = 1
end
event.register(tes3.event.loaded, loadedCallback)