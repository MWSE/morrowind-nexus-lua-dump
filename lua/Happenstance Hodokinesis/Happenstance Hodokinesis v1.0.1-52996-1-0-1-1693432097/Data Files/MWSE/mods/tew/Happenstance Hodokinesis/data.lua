local data = {}

data.vfx = {
	default = "VFX_DefaultHit",
	alteration = "VFX_AlterationHit",
	destruction = "VFX_DestructHit",
	illusion = "VFX_IllusionHit",
	mysticism = "VFX_MysticismHit",
	conjuration = "VFX_ConjureCast",
	restoration = "VFX_RestorationHit",
	poison = "VFX_PoisonHit"
}

data.bountyNPCs = {
	"rissinia",
	"arantamo",
	"phane rielle",
	"tongue_toad"
}

data.blights = {
	"ash woe blight",
	"black-heart blight",
	"chanthrax blight"
}

data.diseases = {
	"ataxia",
	"brown rot",
	"chills",
	"collywobbles",
	"dampworm",
	"droops",
	"greenspore",
	"helljoint",
	"rattles",
	"rockjoint",
	"rust chancre",
	"swamp fever",
	"witbane",
	"yellow tick"
}

data.blacklistedCells = {
	["Mournhold"] = true,
	["Mournhold, Temple"] = true,
	["Mournhold, Royal Palace"] = true,
	["Pelagiad, Ignatius Flaccus' House"] = true,
	["ToddTest"] = true,
	["character stuff wonderland"] = true,
	["mark's vampire test cell"] = true,
	["Clutter Warehouse - Everything Must Go!"] = true,
	["redoran interior"] = true,
	["ken's test hole"] = true,
	["draugr test"] = true,
	["mark's script testing cell"] = true,
	["Solstheim, Castle Karstaag"] = true,
	["Solstheim, Castle Karstaag, Banquet Hall"] = true,
	["Solstheim, Castle Karstaag, Caverns of Karstaag"] = true,
	["Solstheim, Castle Karstaag, Throne Room"] = true,
	["Solstheim, Castle Karstaag, Karstaag's Chambers"] = true,
	["Solstheim, Castle Karstaag, Tower"] = true,
	["Solstheim, Caves of Fjalding"] = true,
	["Solstheim, Aesliip's Lair"] = true,
	["Solstheim, Aesliip's Lair, Caverns"] = true,
	["Solstheim, Tombs of Skaalara"] = true,
	["Old Mournhold: Abandoned Crypt"] = true,
	["Bamz-Amschend, Hall of Wails"] = true,
	["Bamz-Amschend, Hall of Winds"] = true,
	["Bamz-Amschend, Hearthfire Hall"] = true,
	["Bamz-Amschend, King's Walk"] = true,
	["Bamz-Amschend, Passage of the Walker"] = true,
	["Bamz-Amschend, Passage of Whispers"] = true,
	["Bamz-Amschend, Radac's Forge"] = true,
	["Bamz-Amschend, Skybreak Gallery"] = true,
	["Norenen-dur"] = true,
	["Norenen-dur, Basilica of Divine Whispers"] = true,
	["Norenen-dur, Citadel of Myn Dhrur"] = true,
	["Norenen-dur, The Grand Stair"] = true,
	["Norenen-dur, The Teeth that Gnash"] = true,
	["Norenen-dur, The Wailingdelve"] = true,
	["Sotha Sil, Central Gearworks"] = true,
	["Sotha Sil, Chamber of Sohleh"] = true,
	["Sotha Sil, Dome of Kasia"] = true,
	["Sotha Sil, Dome of Serlyn"] = true,
	["Sotha Sil, Dome of Sotha Sil"] = true,
	["Sotha Sil, Dome of the Imperfect"] = true,
	["Sotha Sil, Dome of Udok"] = true,
	["Sotha Sil, Hall of Delirium"] = true,
	["Sotha Sil, Hall of Mileitho"] = true,
	["Sotha Sil, Hall of Sallaemu"] = true,
	["Sotha Sil, Hall of Theuda"] = true,
	["Sotha Sil, Inner Flooded Halls"] = true,
	["Sotha Sil, Outer Flooded Halls"] = true,
	["Holamayan Monastery"] = true,
	["Urshilaku, Astral Burial"] = true,
	["Urshilaku, Karma Burial"] = true,
	["Urshilaku, Laterus Burial"] = true,
	["Urshilaku, Fragile Burial"] = true,
	["Urshilaku, Kefka Burial"] = true,
	["Urshilaku, Kakuna Burial"] = true,
	["Urshilaku, Juno Burial"] = true,
	["Ilunibi, Blackened Heart"] = true,
	["Ilunibi, Carcass of the Saint"] = true,
	["Ilunibi, Marowak's Spine"] = true,
	["Ilunibi, Soul's Rattle"] = true,
	["Ilunibi, Tainted Marrow"] = true,
	["Vivec, Palace of Vivec"] = true,
	["Akulakhan's Chamber"] = true,
	["Dagoth Ur, Facility Cavern"] = true,
	["Dagoth Ur, Inner Facility"] = true,
	["Dagoth Ur, Inner Tower"] = true,
	["Dagoth Ur, Lower Facility"] = true,
	["Dagoth Ur, Outer Facility"] = true,
	["Mamaea, Shrine of Pitted Dreams"] = true,
	["Mamaea, Sanctum of Black Hope"] = true,
	["Mamaea, Sanctum of Awakening"] = true,
	["Vemynal, Outer Fortress"] = true,
	["Vemynal, Hall of Torque"] = true,
	["Odrosal, Dwemer Training Academy"] = true,
	["Odrosal, Tower"] = true,
	["Tureynulal, Kagrenac's Library"] = true,
	["Tureynulal, Eye of Thom Wye"] = true,
	["Tureynulal, Eye of Duggan"] = true,
	["Tureynulal, Bladder of Clovis"] = true,
	["Endusal, Kagrenac's Study"] = true,
	["Kogoruhn, Bleeding Heart"] = true,
	["Kogoruhn, Charma's Breath"] = true,
	["Kogoruhn, Dome of Pollock's Eve"] = true,
	["Kogoruhn, Dome of Urso"] = true,
	["Kogoruhn, Hall of Maki"] = true,
	["Kogoruhn, Hall of Phisto"] = true,
	["Kogoruhn, Hall of the Watchful Touch"] = true,
	["Kogoruhn, Nabith Waterway"] = true,
	["Kogoruhn, Temple of Fey"] = true,
	["Kogoruhn, Vault of Aerode"] = true
}

data.weaponSkills = {
	[tes3.skill.axe] = true,
	[tes3.skill.spear] = true,
	[tes3.skill.bluntWeapon] = true,
	[tes3.skill.longBlade] = true,
	[tes3.skill.marksman] = true,
	[tes3.skill.shortBlade] = true
}


data.armorSkills = {
	[tes3.skill.lightArmor] = true,
	[tes3.skill.mediumArmor] = true,
	[tes3.skill.heavyArmor] = true
}


return data