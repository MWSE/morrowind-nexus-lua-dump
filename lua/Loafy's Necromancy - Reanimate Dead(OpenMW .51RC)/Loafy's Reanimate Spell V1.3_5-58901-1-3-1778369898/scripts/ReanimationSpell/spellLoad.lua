local content = require('openmw.content')

content.statics.records.reanimate_cast_vfx = {
    model = "meshes/ReanimationSpell/z_magiccast.nif" 
}

content.statics.records.reanimate_active_vfx = {
    model = "meshes/ReanimationSpell/z_activesummon.nif" 
}

content.statics.records.reanimate_active2_vfx = {
    model = "meshes/ReanimationSpell/z_activesummon2.nif" 
}

content.magicEffects.records.reanimatedead = {
    name     = 'Reanimate Dead',
    harmful  =  false,
    hasDuration = true,
    onTouch = false,
    allowsSpellmaking = true,
    allowsEnchanting = true,
    onTarget = false,
    onSelf = true,
    baseCost = 2.8 ,
    isAutocalc = true,
    hasMagnitude = true,
    school       = "conjuration",
    icon         = "ReanimationSpell/tx_s_zomb.dds",
    --color = util.color.rgb(0, 0.6, 1.0),
    particle = "ReanimationSpell/vfx_z_sum_cast.dds",
    castStatic = "reanimate_cast_vfx",
    description =  "This effect reanimates the dead flesh of the mortal creatures and people of nirn." .. 
    " It will raise from where their corpses were and attack anything that attacks the caster until the effects ends or the reanimated dead is killed.".. 
    "At death, or when the effect ends, the reanimated dead's essence fades, leaving behind ashes where remains would be.".. 
    "Necromancy is a crime in morrowind and if you get caught using this spell by gaurds or factions less tolerant, you will be in serious trouble." ..
    "(Warning: Using this effect in a custom spell with several other effects will cause the entire spell to end when the zombie expires.)"

}

    content.spells.records.raisezombie = { 
    name = 'Raise Zombie', 
    type = content.spells.TYPE.Spell, 
    cost = 250,
    isAutocalc = true,
    starterSpellFlag = true,
    effects = { 
        { 
            id = 'reanimatedead', 
            range = content.RANGE.Self,
            duration = 30, 
            magnitudeMin = 3,
            magnitudeMax = 6
        } 
    }   
}

 content.spells.records.reanimatecorpse = { 
    name = 'Reanimate Corpse', 
    type = content.spells.TYPE.Spell, 
    cost = 375,
    isAutocalc = true,
    effects = { 
        { 
            id = 'reanimatedead', 
            range = content.RANGE.Self,
            duration = 30, 
            magnitudeMin = 9,
            magnitudeMax = 13,
        } 
    } 
}

content.spells.records.revenant = { 
    name = 'Revenant', 
    type = content.spells.TYPE.Spell, 
    cost = 445,
    isAutocalc = true,
    effects = { 
        { 
            id = 'reanimatedead', 
            range = content.RANGE.Self,
            duration = 30, 
            magnitudeMin = 16,
            magnitudeMax = 21,
        } 
    } 
}

content.spells.records.dreadzombie = { 
    name = 'Dread Zombie', 
    type = content.spells.TYPE.Spell, 
    cost = 635,
    isAutocalc = true,
    effects = { 
        { 
            id = 'reanimatedead', 
            range = content.RANGE.Self,
            duration = 30, 
            magnitudeMin = 26,
            magnitudeMax = 30,
        } 
    } 
}

content.spells.records.deadthrall = { 
    name = 'Dead Thrall', 
    type = content.spells.TYPE.Spell, 
    cost = 800,
    isAutocalc = true,
    effects = { 
        { 
            id = 'reanimatedead', 
            range = content.RANGE.Self,
            duration = 30, 
            magnitudeMin = 34,
            magnitudeMax = 40,
        } 
    } 
}