local types = require('openmw.types')
local util = require('openmw.util')

return {
    [types.Weapon] = {
        title = 'Weapon',
        color = util.color.rgb(0.8, 0.4, 0.4),
        showDamage = true,
        showCondition = true,
        showValue = true,
        uniqueDescriptions = {
			['VFX_DefaultBolt'] = {
				'Default Bolt',
				'Standard projectile effect.',
				'Basic visual effect.',
				'Type: Arrow'
			},

			['steel mace'] = {
				'Steel Mace',
				'Sturdy steel mace.',
				'Reliable blunt weapon.',
				'Type: One-handed blunt weapon'
			},

			['steel dagger'] = {
				'Steel Dagger',
				'Standard steel dagger.',
				'Light and quick.',
				'Type: Short blade'
			},

			['spiked club'] = {
				'Spiked Club',
				'Rough spiked club.',
				'Deadly close combat weapon.',
				'Type: One-handed blunt weapon'
			},

			['steel broadsword'] = {
				'Steel Broadsword',
				'Classic steel broadsword.',
				'Versatile weapon.',
				'Type: Long one-handed blade'
			},

			['steel shortsword'] = {
				'Steel Shortsword',
				'Compact steel shortsword.',
				'Agile and fast.',
				'Type: Short blade'
			},

			['imperial shortsword'] = {
				'Imperial Shortsword',
				'Imperial-made shortsword.',
				'Well-balanced.',
				'Type: Short blade'
			},

			['steel spear'] = {
				'Steel Spear',
				'Standard steel spear.',
				'Reach weapon.',
				'Type: Spear'
			},

			['steel tanto'] = {
				'Steel Tanto',
				'Akaviri-style dagger.',
				'Precision weapon.',
				'Type: Short blade'
			},

			['imperial broadsword'] = {
				'Imperial Broadsword',
				'Imperial-forged broadsword.',
				'Powerful weapon.',
				'Type: Long one-handed blade'
			},

			['iron longsword'] = {
				'Iron Longsword',
				'Solid iron longsword.',
				'Durable weapon.',
				'Type: Long one-handed blade'
			},

			['iron shortsword'] = {
				'Iron Shortsword',
				'Basic iron shortsword.',
				'Common weapon.',
				'Type: Short blade'
			},

			['nordic claymore'] = {
				'Nordic Claymore',
				'Heavy Nordic claymore.',
				'Two-handed weapon.',
				'Type: Two-handed sword'
			},

			['steel dai-katana'] = {
				'Steel Dai-Katana',
				'Large Akaviri sword.',
				'Long reach.',
				'Type: Two-handed sword'
			},

			['iron claymore'] = {
				'Iron Claymore',
				'Iron-forged claymore.',
				'Powerful weapon.',
				'Type: Two-handed sword'
			},

			['silver longsword'] = {
				'Silver Longsword',
				'Silver longsword.',
				'Effective against supernatural foes.',
				'Type: Long one-handed blade'
			},

			['ebony shortsword'] = {
				'Ebony Shortsword',
				'Ebony shortsword.',
				'Nearly indestructible.',
				'Type: Short blade'
			},

			['ebony longsword'] = {
				'Ebony Longsword',
				'Ebony longsword.',
				'Nearly indestructible.',
				'Type: Long one-handed blade'
			},

			['silver shortsword'] = {
				'Silver Shortsword',
				'Silver shortsword.',
				'Effective against supernatural foes.',
				'Type: Short blade'
			},

			['daedric longsword'] = {
				'Daedric Longsword',
				'Cursed daedric longsword.',
				'Whispers in the wind.',
				'Type: Long one-handed blade'
			},
			['nordic battle axe'] = {
				'Nordic Battle Axe',
				'Sturdy Nordic battle axe.',
				'Powerful two-handed weapon.',
				'Type: Two-handed axe'
			},

			['steel axe'] = {
				'Steel Axe',
				'Standard steel axe.',
				'Reliable one-handed weapon.',
				'Type: One-handed axe'
			},

			['iron battle axe'] = {
				'Iron Battle Axe',
				'Durable iron battle axe.',
				'Solid two-handed weapon.',
				'Type: Two-handed axe'
			},

			['steel claymore'] = {
				'Steel Claymore',
				'Heavy steel claymore.',
				'Two-handed greatsword.',
				'Type: Two-handed sword'
			},

			['steel katana'] = {
				'Steel Katana',
				'Traditional Akaviri katana.',
				'Sharp one-handed blade.',
				'Type: Long one-handed blade'
			},

			['steel saber'] = {
				'Steel Saber',
				'Agile steel saber.',
				'Quick and precise.',
				'Type: Long one-handed blade'
			},

			['steel wakizashi'] = {
				'Steel Wakizashi',
				'Short Akaviri companion blade.',
				'Perfect for close combat.',
				'Type: Short blade'
			},

			['long bow'] = {
				'Long Bow',
				'Standard long bow.',
				'Long-range weapon.',
				'Type: Bow'
			},

			['iron arrow'] = {
				'Iron Arrow',
				'Basic iron arrow.',
				'Standard projectile.',
				'Type: Arrow'
			},

			['steel staff'] = {
				'Steel Staff',
				'Sturdy steel staff.',
				'Durable weapon.',
				'Type: Staff'
			},

			['steel war axe'] = {
				'Steel War Axe',
				'Battle-ready war axe.',
				'One-handed weapon.',
				'Type: One-handed axe'
			},

			['steel longsword'] = {
				'Steel Longsword',
				'Classic steel longsword.',
				'Versatile weapon.',
				'Type: Long one-handed blade'
			},

			['steel club'] = {
				'Steel Club',
				'Heavy steel club.',
				'Blunt one-handed weapon.',
				'Type: One-handed blunt weapon'
			},

			['steel battle axe'] = {
				'Steel Battle Axe',
				'Powerful battle axe.',
				'Two-handed weapon.',
				'Type: Two-handed axe'
			},

			['steel warhammer'] = {
				'Steel Warhammer',
				'Mighty warhammer.',
				'Two-handed blunt weapon.',
				'Type: Two-handed blunt weapon'
			},

			['steel halberd'] = {
				'Steel Halberd',
				'Long steel polearm.',
				'Reach weapon.',
				'Type: Spear'
			},

			['steel crossbow'] = {
				'Steel Crossbow',
				'Precision crossbow.',
				'Ranged weapon.',
				'Type: Crossbow'
			},

			['steel throwing star'] = {
				'Steel Throwing Star',
				'Sharpened throwing star.',
				'Thrown weapon.',
				'Type: Thrown'
			},

			['steel throwing knife'] = {
				'Steel Throwing Knife',
				'Thrown combat knife.',
				'Sharp projectile.',
				'Type: Thrown'
			},

			['steel dart'] = {
				'Steel Dart',
				'Light throwing dart.',
				'Quick projectile.',
				'Type: Thrown'
			},

			['chitin dagger'] = {
				'Chitin Dagger',
				'Lightweight chitin dagger.',
				'Natural material.',
				'Type: Short blade'
			},

			['chitin shortsword'] = {
				'Chitin Shortsword',
				'Chitin-crafted shortsword.',
				'Light and agile.',
				'Type: Short blade'
			},

			['chitin club'] = {
				'Chitin Club',
				'Natural chitin club.',
				'Blunt weapon.',
				'Type: One-handed blunt weapon'
			},

			['chitin war axe'] = {
				'Chitin War Axe',
				'Chitin-made war axe.',
				'One-handed axe.',
				'Type: One-handed axe'
			},

			['chitin spear'] = {
				'Chitin Spear',
				'Long chitin spear.',
				'Reach weapon.',
				'Type: Spear'
			},

			['chitin short bow'] = {
				'Chitin Short Bow',
				'Compact chitin bow.',
				'Ranged weapon.',
				'Type: Bow'
			},

			['chitin throwing star'] = {
				'Chitin Throwing Star',
				'Sharpened chitin star.',
				'Thrown weapon.',
				'Type: Thrown'
			},

			['iron dagger'] = {
				'Iron Dagger',
				'Basic iron dagger.',
				'Common weapon.',
				'Type: Short blade'
			},

			['iron tanto'] = {
				'Iron Tanto',
				'Akaviri-style iron dagger.',
				'Precision blade.',
				'Type: Short blade'
			},

			['iron wakizashi'] = {
				'Iron Wakizashi',
				'Short iron companion blade.',
				'Traditional design.',
				'Type: Short blade'
			},

			['iron broadsword'] = {
				'Iron Broadsword',
				'Sturdy iron broadsword.',
				'Versatile weapon.',
				'Type: Long one-handed blade'
			},

			['iron saber'] = {
				'Iron Saber',
				'Iron-forged saber.',
				'Agile weapon.',
				'Type: Long one-handed blade'
			},

			['iron club'] = {
				'Iron Club',
				'Heavy iron club.',
				'Blunt weapon.',
				'Type: One-handed blunt weapon'
			},

			['iron mace'] = {
				'Iron Mace',
				'Standard iron mace.',
				'Blunt damage.',
				'Type: One-handed blunt weapon'
			},

			['iron warhammer'] = {
				'Iron Warhammer',
				'Heavy iron warhammer.',
				'Powerful two-handed weapon.',
				'Type: Two-handed blunt weapon'
			},

			['iron war axe'] = {
				'Iron War Axe',
				'Sturdy iron war axe.',
				'One-handed axe.',
				'Type: One-handed axe'
			},

			['iron spear'] = {
				'Iron Spear',
				'Standard iron spear.',
				'Reach weapon.',
				'Type: Spear'
			},

			['iron halberd'] = {
				'Iron Halberd',
				'Long iron polearm.',
				'Two-handed weapon.',
				'Type: Spear'
			},

			['daedric battle axe'] = {
				'Daedric Battle Axe',
				'Cursed daedric battle axe.',
				'Powerful two-handed weapon.',
				'Type: Two-handed axe'
			},

			['daedric claymore'] = {
				'Daedric Claymore',
				'Cursed daedric claymore.',
				'Two-handed greatsword.',
				'Type: Two-handed sword'
			},

			['daedric club'] = {
				'Daedric Club',
				'Cursed daedric club.',
				'Blunt one-handed weapon.',
				'Type: One-handed blunt weapon'
			},

			['daedric dagger'] = {
				'Daedric Dagger',
				'Cursed daedric dagger.',
				'Sharp one-handed blade.',
				'Type: Short blade'
			},

			['daedric dai-katana'] = {
				'Daedric Dai-Katana',
				'Cursed daedric greatsword.',
				'Two-handed weapon.',
				'Type: Two-handed sword'
			},

			['daedric dart'] = {
				'Daedric Dart',
				'Cursed daedric dart.',
				'Thrown projectile.',
				'Type: Thrown'
			},

			['daedric katana'] = {
				'Daedric Katana',
				'Cursed daedric katana.',
				'Sharp one-handed blade.',
				'Type: Long one-handed blade'
			},

			['daedric long bow'] = {
				'Daedric Long Bow',
				'Cursed daedric long bow.',
				'Powerful ranged weapon.',
				'Type: Bow'
			},

			['daedric mace'] = {
				'Daedric Mace',
				'Cursed daedric mace.',
				'Blunt one-handed weapon.',
				'Type: One-handed blunt weapon'
			},

			['daedric shortsword'] = {
				'Daedric Shortsword',
				'Cursed daedric shortsword.',
				'One-handed blade.',
				'Type: Short blade'
			},

			['daedric spear'] = {
				'Daedric Spear',
				'Cursed daedric spear.',
				'Reach weapon.',
				'Type: Spear'
			},

			['daedric staff'] = {
				'Daedric Staff',
				'Cursed daedric staff.',
				'Two-handed weapon.',
				'Type: Staff'
			},

			['daedric tanto'] = {
				'Daedric Tanto',
				'Cursed daedric tanto.',
				'Short blade.',
				'Type: Short blade'
			},

			['daedric wakizashi'] = {
				'Daedric Wakizashi',
				'Cursed daedric wakizashi.',
				'Short companion blade.',
				'Type: Short blade'
			},

			['daedric war axe'] = {
				'Daedric War Axe',
				'Cursed daedric war axe.',
				'One-handed weapon.',
				'Type: One-handed axe'
			},

			['daedric warhammer'] = {
				'Daedric Warhammer',
				'Cursed daedric warhammer.',
				'Powerful two-handed weapon.',
				'Type: Two-handed blunt weapon'
			},

			['dreugh club'] = {
				'Dreugh Club',
				'Bestial dreugh club.',
				'Crude but effective.',
				'Type: One-handed blunt weapon'
			},

			['dreugh staff'] = {
				'Dreugh Staff',
				'Dreugh-crafted staff.',
				'Unusual design.',
				'Type: Staff'
			},

			['dwarven battle axe'] = {
				'Dwarven Battle Axe',
				'Ancient dwarven axe.',
				'Mechanical enhancements.',
				'Type: Two-handed axe'
			},

			['dwarven claymore'] = {
				'Dwarven Claymore',
				'Dwarven-forged greatsword.',
				'Precision engineering.',
				'Type: Two-handed sword'
			},

			['dwarven crossbow'] = {
				'Dwarven Crossbow',
				'Advanced dwarven crossbow.',
				'Highly accurate.',
				'Type: Crossbow'
			},

			['dwarven halberd'] = {
				'Dwarven Halberd',
				'Dwarven polearm.',
				'Mechanical components.',
				'Type: Spear'
			},

			['dwarven mace'] = {
				'Dwarven Mace',
				'Dwarven-crafted mace.',
				'Unique design.',
				'Type: One-handed blunt weapon'
			},

			['dwarven shortsword'] = {
				'Dwarven Shortsword',
				'Compact dwarven blade.',
				'Exceptional craftsmanship.',
				'Type: Short blade'
			},

			['dwarven spear'] = {
				'Dwarven Spear',
				'Dwarven-forged spear.',
				'Precision balance.',
				'Type: Spear'
			},

			['dwarven war axe'] = {
				'Dwarven War Axe',
				'Dwarven one-handed axe.',
				'Mechanical features.',
				'Type: One-handed axe'
			},

			['dwarven warhammer'] = {
				'Dwarven Warhammer',
				'Dwarven warhammer.',
				'Advanced design.',
				'Type: Two-handed blunt weapon'
			},

			['ebony broadsword'] = {
				'Ebony Broadsword',
				'Ebony-forged broadsword.',
				'Nearly indestructible.',
				'Type: Long one-handed blade'
			},

			['ebony dart'] = {
				'Ebony Dart',
				'Ebony throwing dart.',
				'Sharp and deadly.',
				'Type: Thrown'
			},

			['ebony mace'] = {
				'Ebony Mace',
				'Ebony mace.',
				'Powerful weapon.',
				'Type: One-handed blunt weapon'
			},

			['ebony spear'] = {
				'Ebony Spear',
				'Ebony spear.',
				'Reach weapon.',
				'Type: Spear'
			},

			['ebony staff'] = {
				'Ebony Staff',
				'Ebony staff.',
				'Mystic properties.',
				'Type: Staff'
			},

			['ebony throwing star'] = {
				'Ebony Throwing Star',
				'Ebony throwing star.',
				'Precision weapon.',
				'Type: Thrown'
			},

			['ebony war axe'] = {
				'Ebony War Axe',
				'One-handed ebony axe.',
				'Powerful and durable.',
				'Type: One-handed axe'
			},

			['glass claymore'] = {
				'Glass Claymore',
				'Crystalline two-handed sword.',
				'Sharp and elegant.',
				'Type: Two-handed sword'
			},

			['glass dagger'] = {
				'Glass Dagger',
				'Delicate glass dagger.',
				'Precise strikes.',
				'Type: Short blade'
			},

			['glass halberd'] = {
				'Glass Halberd',
				'Crystalline polearm.',
				'Reach weapon.',
				'Type: Spear'
			},

			['glass longsword'] = {
				'Glass Longsword',
				'Elegant glass blade.',
				'Sharp and deadly.',
				'Type: Long one-handed blade'
			},

			['glass staff'] = {
				'Glass Staff',
				'Crystalline staff.',
				'Mystic properties.',
				'Type: Staff'
			},

			['glass throwing knife'] = {
				'Glass Throwing Knife',
				'Thrown glass blade.',
				'Sharp projectile.',
				'Type: Thrown'
			},

			['glass throwing star'] = {
				'Glass Throwing Star',
				'Star-shaped glass weapon.',
				'Precision throw.',
				'Type: Thrown'
			},

			['glass war axe'] = {
				'Glass War Axe',
				'Crystalline war axe.',
				'One-handed weapon.',
				'Type: One-handed axe'
			},

			['iron throwing knife'] = {
				'Iron Throwing Knife',
				'Basic iron throwing knife.',
				'Common projectile.',
				'Type: Thrown'
			},

			['short bow'] = {
				'Short Bow',
				'Compact ranged weapon.',
				'Quick draw.',
				'Type: Bow'
			},

			['silver claymore'] = {
				'Silver Claymore',
				'Two-handed silver sword.',
				'Effective against supernatural foes.',
				'Type: Two-handed sword'
			},

			['silver dagger'] = {
				'Silver Dagger',
				'Silver-forged dagger.',
				'Anti-supernatural weapon.',
				'Type: Short blade'
			},

			['silver dart'] = {
				'Silver Dart',
				'Silver throwing dart.',
				'Anti-supernatural projectile.',
				'Type: Thrown'
			},

			['silver spear'] = {
				'Silver Spear',
				'Silver polearm.',
				'Reach weapon.',
				'Type: Spear'
			},

			['silver staff'] = {
				'Silver Staff',
				'Silver mystic staff.',
				'Anti-supernatural properties.',
				'Type: Staff'
			},

			['silver throwing star'] = {
				'Silver Throwing Star',
				'Silver star-shaped weapon.',
				'Anti-supernatural throw.',
				'Type: Thrown'
			},

			['silver war axe'] = {
				'Silver War Axe',
				'Silver one-handed axe.',
				'Anti-supernatural edge.',
				'Type: One-handed axe'
			},

			['wooden staff'] = {
				'Wooden Staff',
				'Basic wooden staff.',
				'Used by novice mages.',
				'Type: Staff'
			},

			['nordic broadsword'] = {
				'Nordic Broadsword',
				'Sturdy nordic blade.',
				'Versatile weapon.',
				'Type: Long one-handed blade'
			},

			['Iron Long Spear'] = {
				'Iron Long Spear',
				'Extended iron spear.',
				'Reach weapon.',
				'Type: Spear'
			},

			["lugrub's axe"] = {
				"lugrub's axe",
				'Ancient crafted axe.',
				'Powerful weapon.',
				'Type: One-handed axe'
			},

			['magic_bolt'] = {
				'Magic Bolt',
				'Basic magic projectile.',
				'Standard effect.',
				'Type: Arrow'
			},

			['steel blade of heaven'] = {
				'Steel Blade of Heaven',
				'Sacred steel blade.',
				'Blessed weapon.',
				'Type: Short blade'
			},

			["ebony wizard's staff"] = {
				"ebony wizard's staff",
				'Dark ebony staff.',
				'Mystic properties.',
				'Type: Staff'
			},

			['steel jinkblade of the aegis'] = {
				'Steel Jinkblade of the Aegis',
				'Protective steel blade.',
				'Defensive properties.',
				'Type: Short blade'
			},

			['fiend tanto'] = {
				'Fiend Tanto',
				'Cursed short blade.',
				'Malevolent weapon.',
				'Type: Short blade'
			},

			['bonemold arrow'] = {
				'Bonemold Arrow',
				'Arrow made of bone.',
				'Primitive projectile.',
				'Type: Arrow'
			},

			['dire viperarrow'] = {
				'Dire Viperarrow',
				'Poison-tipped arrow.',
				'Venomous projectile.',
				'Type: Arrow'
			},

			['6th bell hammer'] = {
				'6th Bell Hammer',
				'Heavy war hammer.',
				'Powerful weapon.',
				'Type: Two-handed blunt weapon'
			},

			['dwarven war axe_redas'] = {
				'Dwarven War Axe Redas',
				'Dwarven-forged axe.',
				'Mechanical features.',
				'Type: One-handed axe'
			},

			['bonemold long bow'] = {
				'Bonemold Long Bow',
				'Bow made of bone.',
				'Primitive ranged weapon.',
				'Type: Bow'
			},

			['clutterbane'] = {
				'Clutterbane',
				'Cruel weapon.',
				'Deadly blade.',
				'Type: One-handed blunt weapon'
			},

			['water spear'] = {
				'Water Spear',
				'Elemental spear.',
				'Water magic.',
				'Type: Spear'
			},

			['spear_of_light'] = {
				'Spear of Light',
				'Radiant spear.',
				'Holy weapon.',
				'Type: Spear'
			},

			['fireblade'] = {
				'Fireblade',
				'Flame-infused blade.',
				'Fire damage.',
				'Type: Short blade'
			},

			['icebreaker'] = {
				'Icebreaker',
				'Frost-infused weapon.',
				'Cold damage.',
				'Type: One-handed blunt weapon'
			},

			['stormblade'] = {
				'Stormblade',
				'Lightning-infused blade.',
				'Shock damage.',
				'Type: Long one-handed blade'
			},

			['spiderbite'] = {
				'Spiderbite',
				'Poisonous blade.',
				'Venomous attacks.',
				'Type: Long one-handed blade'
			},

			['flamestar'] = {
				'Flamestar',
				'Fire-infused star.',
				'Burning projectile.',
				'Type: Thrown'
			},

			['shardstar'] = {
				'Shardstar',
				'Sharp throwing star.',
				'Piercing damage.',
				'Type: Thrown'
			},

			['viperstar'] = {
				'Viperstar',
				'Poisonous star.',
				'Venomous attacks.',
				'Type: Thrown'
			},

			['demon tanto'] = {
				'Demon Tanto',
				'Cursed short blade.',
				'Malevolent weapon.',
				'Type: Short blade'
			},

			['corkbulb arrow'] = {
				'Corkbulb Arrow',
				'Special corkbulb arrow.',
				'Unique projectile.',
				'Type: Arrow'
			},

			['chitin arrow'] = {
				'Chitin Arrow',
				'Natural chitin arrow.',
				'Light projectile.',
				'Type: Arrow'
			},

			['arrow of wasting flame'] = {
				'Arrow of Wasting Flame',
				'Flame-infused arrow.',
				'Fire damage.',
				'Type: Arrow'
			},

			['silver arrow'] = {
				'Silver Arrow',
				'Silver-tipped arrow.',
				'Anti-supernatural.',
				'Type: Arrow'
			},

			['glass arrow'] = {
				'Glass Arrow',
				'Crystalline arrow.',
				'Sharp projectile.',
				'Type: Arrow'
			},

			['ebony arrow'] = {
				'Ebony Arrow',
				'Ebony-tipped arrow.',
				'Powerful projectile.',
				'Type: Arrow'
			},

			['daedric arrow'] = {
				'Daedric Arrow',
				'Cursed daedric arrow.',
				'Dark magic.',
				'Type: Arrow'
			},

			['corkbulb bolt'] = {
				'Corkbulb Bolt',
				'Special corkbulb bolt.',
				'Unique ammunition.',
				'Type: Bolt'
			},

			['iron bolt'] = {
				'Iron Bolt',
				'Basic iron bolt.',
				'Standard ammunition.',
				'Type: Bolt'
			},

			['steel bolt'] = {
				'Steel Bolt',
				'Steel crossbow bolt.',
				'Sharp projectile.',
				'Type: Bolt'
			},

			['silver bolt'] = {
				'Silver Bolt',
				'Silver crossbow bolt.',
				'Anti-supernatural.',
				'Type: Bolt'
			},

			['bonemold bolt'] = {
				'Bonemold Bolt',
				'Bone-made bolt.',
				'Primitive ammunition.',
				'Type: Bolt'
			},

			['orcish bolt'] = {
				'Orcish Bolt',
				'Orcish crossbow bolt.',
				'Heavy ammunition.',
				'Type: Bolt'
			},

			['flame_bolt'] = {
				'Flame Bolt',
				'Flame-infused bolt.',
				'Fire damage.',
				'Type: Bolt'
			},

			['shard_bolt'] = {
				'Shard Bolt',
				'Sharp bolt.',
				'Piercing damage.',
				'Type: Bolt'
			},

			['spark_bolt'] = {
				'Spark Bolt',
				'Lightning bolt.',
				'Shock damage.',
				'Type: Bolt'
			},

			['viper_bolt'] = {
				'Viper Bolt',
				'Poisonous bolt.',
				'Venomous effect.',
				'Type: Bolt'
			},

			['flame arrow'] = {
				'Flame Arrow',
				'Flame-tipped arrow.',
				'Fire damage.',
				'Type: Arrow'
			},

			['shard arrow'] = {
				'Shard Arrow',
				'Sharp arrow.',
				'Piercing damage.',
				'Type: Arrow'
			},

			['spark arrow'] = {
				'Spark Arrow',
				'Spark-tipped arrow.',
				'Shock damage.',
				'Type: Arrow'
			},

			['viper arrow'] = {
				'Viper Arrow',
				'Poisonous arrow.',
				'Venomous effect.',
				'Type: Arrow'
			},

			['steel arrow'] = {
				'Steel Arrow',
				'Standard steel arrow.',
				'Basic projectile.',
				'Type: Arrow'
			},

			['arrow of wasting shard'] = {
				'Arrow of Wasting Shard',
				'Shard-infused arrow.',
				'Piercing effect.',
				'Type: Arrow'
			},

			['arrow of wasting spark'] = {
				'Arrow of Wasting Spark',
				'Spark-infused arrow.',
				'Shock effect.',
				'Type: Arrow'
			},

			['arrow of wasting viper'] = {
				'Arrow of Wasting Viper',
				'Venom-infused arrow.',
				'Poisonous effect.',
				'Type: Arrow'
			},

			['grey shaft of holding'] = {
				'Grey Shaft of Holding',
				'Mysterious grey arrow.',
				'Special properties.',
				'Type: Arrow'
			},

			['grey shaft of nonsense'] = {
				'Grey Shaft of Nonsense',
				'Enigmatic grey arrow.',
				'Unknown effects.',
				'Type: Arrow'
			},

			['grey shaft of unraveling'] = {
				'Grey Shaft of Unraveling',
				'Strange grey arrow.',
				'Unusual properties.',
				'Type: Arrow'
			},

			['demon katana'] = {
				'Demon Katana',
				'Cursed demonic blade.',
				'Malevolent power.',
				'Type: Long one-handed blade'
			},

			['steel longbow'] = {
				'Steel Longbow',
				'Sturdy steel bow.',
				'Accurate shots.',
				'Type: Bow'
			},

			['demon longbow'] = {
				'Demon Longbow',
				'Cursed demonic bow.',
				'Dark power.',
				'Type: Bow'
			},

			['peacemaker'] = {
				'Peacemaker',
				'Peaceful weapon.',
				'Balanced design.',
				'Type: Staff'
			},

			['cruel flameblade'] = {
				'Cruel Flameblade',
				'Flame-infused blade.',
				'Burning damage.',
				'Type: Short blade'
			},

			['cruel shardblade'] = {
				'Cruel Shardblade',
				'Sharp cruel blade.',
				'Piercing damage.',
				'Type: Short blade'
			},

			['cruel sparkblade'] = {
				'Cruel Sparkblade',
				'Spark-infused blade.',
				'Shock damage.',
				'Type: Short blade'
			},

			['cruel viperblade'] = {
				'Cruel Viperblade',
				'Poisonous blade.',
				'Venomous effect.',
				'Type: Short blade'
			},

			['cruel flamesword'] = {
				'Cruel Flamesword',
				'Flame-infused sword.',
				'Burning damage.',
				'Type: Short blade'
			},

			['cruel shardsword'] = {
				'Cruel Shardsword',
				'Sharp cruel sword.',
				'Piercing damage.',
				'Type: Short blade'
			},

			['cruel sparksword'] = {
				'Cruel Sparksword',
				'Spark-infused sword.',
				'Shock damage.',
				'Type: Short blade'
			},

			['cruel vipersword'] = {
				'Cruel Vipersword',
				'Poisonous sword.',
				'Venomous effect.',
				'Type: Short blade'
			},

			['steel jinkblade'] = {
				'Steel Jinkblade',
				'Agile steel blade.',
				'Quick strikes.',
				'Type: Short blade'
			},

			['steel jinksword'] = {
				'Steel Jinksword',
				'Swift steel sword.',
				'Fast attacks.',
				'Type: Short blade'
			},

			['steel firesword'] = {
				'Steel Firesword',
				'Flame-infused steel sword.',
				'Burning damage.',
				'Type: Long one-handed blade'
			},

			['steel frostsword'] = {
				'Steel Frostsword',
				'Frost-infused steel sword.',
				'Cold damage.',
				'Type: Long one-handed blade'
			},

			['steel stormsword'] = {
				'Steel Stormsword',
				'Lightning-infused steel sword.',
				'Shock damage.',
				'Type: Long one-handed blade'
			},

			['steel poisonsword'] = {
				'Steel Poisonsword',
				'Poison-infused steel sword.',
				'Venomous effect.',
				'Type: Long one-handed blade'
			},

			['iron flameblade'] = {
				'Iron Flameblade',
				'Iron blade with flame.',
				'Burning damage.',
				'Type: Short blade'
			},

			['iron shardblade'] = {
				'Iron Shardblade',
				'Iron blade with shards.',
				'Piercing damage.',
				'Type: Short blade'
			},

			['iron sparkblade'] = {
				'Iron Sparkblade',
				'Spark-infused iron blade.',
				'Shock damage.',
				'Type: Short blade'
			},

			['iron viperblade'] = {
				'Iron Viperblade',
				'Poisonous iron blade.',
				'Venomous effect.',
				'Type: Short blade'
			},

			['iron flamecleaver'] = {
				'Iron Flamecleaver',
				'Flame-infused cleaver.',
				'Burning damage.',
				'Type: Spear'
			},

			['iron shardcleaver'] = {
				'Iron Shardcleaver',
				'Sharp iron cleaver.',
				'Piercing damage.',
				'Type: Spear'
			},

			['iron sparkcleaver'] = {
				'Iron Sparkcleaver',
				'Spark-infused cleaver.',
				'Shock damage.',
				'Type: Spear'
			},

			['iron vipercleaver'] = {
				'Iron Vipercleaver',
				'Poisonous cleaver.',
				'Venomous effect.',
				'Type: Spear'
			},

			['iron flamesword'] = {
				'Iron Flamesword',
				'Flame-infused iron sword.',
				'Burning damage.',
				'Type: Long one-handed blade'
			},

			['iron sparksword'] = {
				'Iron Sparksword',
				'Spark-infused iron sword.',
				'Shock damage.',
				'Type: Long one-handed blade'
			},

			['iron shardsword'] = {
				'Iron Shardsword',
				'Sharp iron sword.',
				'Piercing damage.',
				'Type: Long one-handed blade'
			},

			['iron vipersword'] = {
				'Iron Vipersword',
				'Poisonous iron sword.',
				'Venomous effect.',
				'Type: Long one-handed blade'
			},

			['iron flamemace'] = {
				'Iron Flamemace',
				'Flame-infused mace.',
				'Burning damage.',
				'Type: One-handed blunt weapon'
			},

			['iron shardmace'] = {
				'Iron Shardmace',
				'Sharp iron mace.',
				'Piercing damage.',
				'Type: One-handed blunt weapon'
			},

			['iron sparkmace'] = {
				'Iron Sparkmace',
				'Spark-infused mace.',
				'Shock damage.',
				'Type: One-handed blunt weapon'
			},

			['iron sparkaxe'] = {
				'Iron Sparkaxe',
				'Spark-infused axe.',
				'Shock damage.',
				'Type: One-handed axe'
			},

			['iron viperaxe'] = {
				'Iron Viperaxe',
				'Poisonous axe.',
				'Venomous effect.',
				'Type: One-handed axe'
			},

			['iron flameslayer'] = {
				'Iron Flameslayer',
				'Flame-infused greatsword.',
				'Burning damage.',
				'Type: Two-handed sword'
			},

			['iron shardslayer'] = {
				'Iron Shardslayer',
				'Sharp greatsword.',
				'Piercing damage.',
				'Type: Two-handed sword'
			},

			['iron sparkslayer'] = {
				'Iron Sparkslayer',
				'Spark-infused greatsword.',
				'Shock damage.',
				'Type: Two-handed sword'
			},

			['iron viperslayer'] = {
				'Iron Viperslayer',
				'Poisonous greatsword.',
				'Venomous effect.',
				'Type: Two-handed sword'
			},
			['iron flameskewer'] = {
				'Iron Flameskewer',
				'Flame-infused skewer.',
				'Burning damage.',
				'Type: Spear'
			},

			['iron shardskewer'] = {
				'Iron Shardskewer',
				'Sharp iron skewer.',
				'Piercing damage.',
				'Type: Spear'
			},

			['iron sparkskewer'] = {
				'Iron Sparkskewer',
				'Spark-infused skewer.',
				'Shock damage.',
				'Type: Spear'
			},

			['iron viperskewer'] = {
				'Iron Viperskewer',
				'Poisonous skewer.',
				'Venomous effect.',
				'Type: Spear'
			},

			['iron flamemauler'] = {
				'Iron Flamemauler',
				'Flame-infused maul.',
				'Burning damage.',
				'Type: Two-handed blunt weapon'
			},

			['iron sparkmauler'] = {
				'Iron Sparkmauler',
				'Spark-infused maul.',
				'Shock damage.',
				'Type: Two-handed blunt weapon'
			},

			['iron shardmauler'] = {
				'Iron Shardmauler',
				'Sharp iron maul.',
				'Piercing damage.',
				'Type: Two-handed blunt weapon'
			},

			['iron vipermauler'] = {
				'Iron Vipermauler',
				'Poisonous maul.',
				'Venomous effect.',
				'Type: Two-handed blunt weapon'
			},

			['wooden staff of peace'] = {
				'Wooden Staff of Peace',
				'Blessed wooden staff.',
				'Healing properties.',
				'Type: Staff'
			},

			['wooden staff of war'] = {
				'Wooden Staff of War',
				"Warriors wooden staff.",
				'Enhances strength.',
				'Type: Staff'
			},

			['wooden staff of shaming'] = {
				'Wooden Staff of Shaming',
				'Mystical wooden staff.',
				'Debuffs enemies.',
				'Type: Staff'
			},

			['wooden staff of chastening'] = {
				'Wooden Staff of Chastening',
				'Punishing wooden staff.',
				'Deals extra damage.',
				'Type: Staff'
			},

			['wooden staff of divine'] = {
				'Wooden Staff of Divine',
				'Holy wooden staff.',
				'Radiant damage.',
				'Type: Staff'
			},
			['firebite sword'] = {
				'Firebite Sword',
				'Flame-infused short sword.',
				'Deals fire damage.',
				'Type: Short blade'
			},

			['firebite star'] = {
				'Firebite Star',
				'Flaming throwing star.',
				'Fire damage.',
				'Type: Thrown'
			},

			['firebite war axe'] = {
				'Firebite War Axe',
				'Flame-infused war axe.',
				'Deals fire damage.',
				'Type: One-handed axe'
			},

			['firebite dagger'] = {
				'Firebite Dagger',
				'Flame-tipped dagger.',
				'Deals fire damage.',
				'Type: Short blade'
			},

			['firebite club'] = {
				'Firebite Club',
				'Flaming club.',
				'Blunt damage.',
				'Type: One-handed blunt weapon'
			},

			['shockbite mace'] = {
				'Shockbite Mace',
				'Lightning-infused mace.',
				'Deals shock damage.',
				'Type: One-handed blunt weapon'
			},

			['shockbite halberd'] = {
				'Shockbite Halberd',
				'Lightning-infused halberd.',
				'Deals shock damage.',
				'Type: Spear'
			},

			['shockbite battle axe'] = {
				'Shockbite Battle Axe',
				'Lightning-infused battle axe.',
				'Deals shock damage.',
				'Type: Two-handed axe'
			},

			['shockbite war axe'] = {
				'Shockbite War Axe',
				'Lightning-infused war axe.',
				'Deals shock damage.',
				'Type: One-handed axe'
			},

			['shockbite warhammer'] = {
				'Shockbite Warhammer',
				'Lightning-infused warhammer.',
				'Deals shock damage.',
				'Type: Two-handed blunt weapon'
			},

			['last wish'] = {
				'Last Wish',
				'Legendary weapon.',
				'Special abilities.',
				'Type: Short blade'
			},

			['icicle'] = {
				'Icicle',
				'Frost-infused blade.',
				'Deals cold damage.',
				'Type: Long one-handed blade'
			},

			['foeburner'] = {
				'Foeburner',
				'Flame-infused greatsword.',
				'Deals fire damage.',
				'Type: Two-handed sword'
			},

			['snowy crown'] = {
				'Snowy Crown',
				'Frost-infused mace.',
				'Deals cold damage.',
				'Type: One-handed blunt weapon'
			},

			['last rites'] = {
				'Last Rites',
				'Cursed battle axe.',
				'Special abilities.',
				'Type: Two-handed axe'
			},
			['cruel flame bolt'] = {
				'Cruel Flame Bolt',
				'Flame-infused bolt.',
				'Deals fire damage.',
				'Type: Bolt'
			},

			['cruel shard bolt'] = {
				'Cruel Shard Bolt',
				'Sharp cruel bolt.',
				'Piercing damage.',
				'Type: Bolt'
			},

			['cruel spark bolt'] = {
				'Cruel Spark Bolt',
				'Spark-infused bolt.',
				'Shock damage.',
				'Type: Bolt'
			},

			['cruel viper bolt'] = {
				'Cruel Viper Bolt',
				'Poisonous bolt.',
				'Venomous effect.',
				'Type: Bolt'
			},

			['cruel flamearrow'] = {
				'Cruel Flame Arrow',
				'Flame-tipped arrow.',
				'Burning damage.',
				'Type: Arrow'
			},

			['cruel shardarrow'] = {
				'Cruel Shard Arrow',
				'Sharp cruel arrow.',
				'Piercing damage.',
				'Type: Arrow'
			},

			['cruel sparkarrow'] = {
				'Cruel Spark Arrow',
				'Spark-tipped arrow.',
				'Shock damage.',
				'Type: Arrow'
			},

			['cruel viperarrow'] = {
				'Cruel Viper Arrow',
				'Poisonous arrow.',
				'Venomous effect.',
				'Type: Arrow'
			},

			['cruel flamestar'] = {
				'Cruel Flame Star',
				'Flame-infused star.',
				'Burning damage.',
				'Type: Thrown'
			},

			['cruel sparkstar'] = {
				'Cruel Spark Star',
				'Spark-infused star.',
				'Shock damage.',
				'Type: Thrown'
			},

			['cruel shardstar'] = {
				'Cruel Shard Star',
				'Sharp cruel star.',
				'Piercing damage.',
				'Type: Thrown'
			},

			['cruel viperstar'] = {
				'Cruel Viper Star',
				'Poisonous star.',
				'Venomous effect.',
				'Type: Thrown'
			},

			['dire flameblade'] = {
				'Dire Flameblade',
				'Flame-infused blade.',
				'Burning damage.',
				'Type: Short blade'
			},

			['dire shardblade'] = {
				'Dire Shardblade',
				'Sharp dire blade.',
				'Piercing damage.',
				'Type: Short blade'
			},

			['dire sparkblade'] = {
				'Dire Sparkblade',
				'Spark-infused blade.',
				'Shock damage.',
				'Type: Short blade'
			},

			['dire viperblade'] = {
				'Dire Viperblade',
				'Deadly poisonous blade.',
				'Venomous attacks.',
				'Type: Short blade'
			},

			['dire flamesword'] = {
				'Dire Flamesword',
				'Fiery longsword.',
				'Deals fire damage.',
				'Type: Short blade'
			},

			['dire shardsword'] = {
				'Dire Shardsword',
				'Sharp piercing sword.',
				'Deals piercing damage.',
				'Type: Short blade'
			},

			['dire sparksword'] = {
				'Dire Sparksword',
				'Electric sword.',
				'Deals shock damage.',
				'Type: Short blade'
			},

			['dire vipersword'] = {
				'Dire Vipersword',
				'Poisonous longsword.',
				'Venomous effects.',
				'Type: Short blade'
			},

			['orcish warhammer'] = {
				'Orcish Warhammer',
				'Heavy orcish hammer.',
				'Blunt damage.',
				'Type: Two-handed blunt weapon'
			},

			['orcish battle axe'] = {
				'Orcish Battle Axe',
				'Sturdy orcish axe.',
				'Two-handed weapon.',
				'Type: Two-handed axe'
			},

			['steel flameblade'] = {
				'Steel Flameblade',
				'Flame-infused steel blade.',
				'Burning damage.',
				'Type: Short blade'
			},

			['steel shardblade'] = {
				'Steel Shardblade',
				'Sharp steel blade.',
				'Piercing damage.',
				'Type: Short blade'
			},

			['steel sparkblade'] = {
				'Steel Sparkblade',
				'Electric steel blade.',
				'Shock damage.',
				'Type: Short blade'
			},

			['steel viperblade'] = {
				'Steel Viperblade',
				'Poisonous steel blade.',
				'Venomous effects.',
				'Type: Short blade'
			},

			['steel flamesword'] = {
				'Steel Flamesword',
				'Flame-infused longsword.',
				'Burning damage.',
				'Type: Long one-handed blade'
			},

			['steel shardsword'] = {
				'Steel Shardsword',
				'Sharp steel longsword.',
				'Piercing damage.',
				'Type: Long one-handed blade'
			},

			['steel sparksword'] = {
				'Steel Sparksword',
				'Electric longsword.',
				'Shock damage.',
				'Type: Long one-handed blade'
			},

			['steel vipersword'] = {
				'Steel Vipersword',
				'Poisonous longsword.',
				'Venomous effects.',
				'Type: Long one-handed blade'
			},
			['steel flamemace'] = {
				'Steel Flamemace',
				'Flame-infused steel mace.',
				'Burning damage.',
				'Type: One-handed blunt weapon'
			},

			['steel shardmace'] = {
				'Steel Shardmace',
				'Sharp steel mace.',
				'Piercing damage.',
				'Type: One-handed blunt weapon'
			},

			['steel sparkmace'] = {
				'Steel Sparkmace',
				'Spark-infused steel mace.',
				'Shock damage.',
				'Type: One-handed blunt weapon'
			},

			['steel vipermace'] = {
				'Steel Vipermace',
				'Poisonous steel mace.',
				'Venomous effect.',
				'Type: One-handed blunt weapon'
			},

			['steel flameaxe'] = {
				'Steel Flameaxe',
				'Flame-infused steel axe.',
				'Burning damage.',
				'Type: One-handed axe'
			},

			['steel sparkaxe'] = {
				'Steel Sparkaxe',
				'Spark-infused steel axe.',
				'Shock damage.',
				'Type: One-handed axe'
			},

			['steel shardaxe'] = {
				'Steel Shardaxe',
				'Sharp steel axe.',
				'Piercing damage.',
				'Type: One-handed axe'
			},

			['steel viperaxe'] = {
				'Steel Viperaxe',
				'Poisonous steel axe.',
				'Venomous effect.',
				'Type: One-handed axe'
			},

			['steel flameslayer'] = {
				'Steel Flameslayer',
				'Flame-infused greatsword.',
				'Burning damage.',
				'Type: Two-handed sword'
			},

			['steel shardslayer'] = {
				'Steel Shardslayer',
				'Sharp greatsword.',
				'Piercing damage.',
				'Type: Two-handed sword'
			},

			['steel sparkslayer'] = {
				'Steel Sparkslayer',
				'Spark-infused greatsword.',
				'Shock damage.',
				'Type: Two-handed sword'
			},

			['steel viperslayer'] = {
				'Steel Viperslayer',
				'Poisonous greatsword.',
				'Venomous effect.',
				'Type: Two-handed sword'
			},

			['steel flamescythe'] = {
				'Steel Flamescythe',
				'Flame-infused scythe.',
				'Burning damage.',
				'Type: Two-handed sword'
			},

			['steel shardscythe'] = {
				'Steel Shardscythe',
				'Sharp steel scythe.',
				'Piercing damage.',
				'Type: Two-handed sword'
			},

			['steel sparkscythe'] = {
				'Steel Sparkscythe',
				'Spark-infused scythe.',
				'Shock damage.',
				'Type: Two-handed sword'
			},

			['steel viperscythe'] = {
				'Steel Viperscythe',
				'Poisonous scythe.',
				'Venomous effect.',
				'Type: Two-handed sword'
			},
			['steel flamecleaver'] = {
				'Steel Flamecleaver',
				'Flame-infused cleaver.',
				'Burning damage.',
				'Type: Spear'
			},

			['steel shardcleaver'] = {
				'Steel Shardcleaver',
				'Sharp steel cleaver.',
				'Piercing damage.',
				'Type: Spear'
			},

			['steel sparkcleaver'] = {
				'Steel Sparkcleaver',
				'Spark-infused cleaver.',
				'Shock damage.',
				'Type: Spear'
			},

			['steel vipercleaver'] = {
				'Steel Vipercleaver',
				'Poisonous cleaver.',
				'Venomous effect.',
				'Type: Spear'
			},

			['steel flameskewer'] = {
				'Steel Flameskewer',
				'Flame-infused skewer.',
				'Burning damage.',
				'Type: Spear'
			},

			['steel shardskewer'] = {
				'Steel Shardskewer',
				'Sharp steel skewer.',
				'Piercing damage.',
				'Type: Spear'
			},

			['steel sparkskewer'] = {
				'Steel Sparkskewer',
				'Spark-infused skewer.',
				'Shock damage.',
				'Type: Spear'
			},

			['steel viperskewer'] = {
				'Steel Viperskewer',
				'Poisonous skewer.',
				'Venomous effect.',
				'Type: Spear'
			},

			['steel flamemauler'] = {
				'Steel Flamemauler',
				'Flame-infused maul.',
				'Burning damage.',
				'Type: Two-handed blunt weapon'
			},

			['steel shardmauler'] = {
				'Steel Shardmauler',
				'Sharp steel maul.',
				'Piercing damage.',
				'Type: Two-handed blunt weapon'
			},

			['steel sparkmauler'] = {
				'Steel Sparkmauler',
				'Spark-infused maul.',
				'Shock damage.',
				'Type: Two-handed blunt weapon'
			},

			['steel vipermauler'] = {
				'Steel Vipermauler',
				'Poisonous maul.',
				'Venomous effect.',
				'Type: Two-handed blunt weapon'
			},

			['flying viper'] = {
				'Flying Viper',
				'Thrown poisonous weapon.',
				'Venomous effect.',
				'Type: Thrown'
			},

			['steel staff of peace'] = {
				'Steel Staff of Peace',
				'Blessed steel staff.',
				'Healing properties.',
				'Type: Staff'
			},

			['steel staff of war'] = {
				'Steel Staff of War',
				"Warriors steel staff.",
				'Enhances strength.',
				'Type: Staff'
			},

			['steel staff of shaming'] = {
				'Steel Staff of Shaming',
				'Mystical steel staff.',
				'Debuffs enemies.',
				'Type: Staff'
			},

			['steel staff of chastening'] = {
				'Steel Staff of Chastening',
				'Punishing steel staff.',
				'Deals extra damage.',
				'Type: Staff'
			},

			['steel staff of divine judgement'] = {
				'Steel Staff of Divine Judgement',
				'Holy steel staff.',
				'Radiant damage.',
				'Type: Staff'
			},
			['steel staff of the ancestors'] = {
				'Steel Staff of the Ancestors',
				'Ancient steel staff.',
				'Honors forefathers.',
				'Type: Staff'
			},

			['battle axe of wounds'] = {
				'Battle Axe of Wounds',
				'Cursed battle axe.',
				'Deals extra damage.',
				'Type: Two-handed axe'
			},

			['war axe of wounds'] = {
				'War Axe of Wounds',
				'Cursed war axe.',
				'Deals extra damage.',
				'Type: One-handed axe'
			},

			['warhammer of wounds'] = {
				'Warhammer of Wounds',
				'Cursed warhammer.',
				'Deals extra damage.',
				'Type: Two-handed blunt weapon'
			},

			['silver staff of reckoning'] = {
				'Silver Staff of Reckoning',
				'Silver mystic staff.',
				'Judgment magic.',
				'Type: Staff'
			},

			['dire flame bolt'] = {
				'Dire Flame Bolt',
				'Powerful flame bolt.',
				'Deals fire damage.',
				'Type: Bolt'
			},

			['dire shard bolt'] = {
				'Dire Shard Bolt',
				'Sharp dire bolt.',
				'Piercing damage.',
				'Type: Bolt'
			},

			['dire spark bolt'] = {
				'Dire Spark Bolt',
				'Electric bolt.',
				'Deals shock damage.',
				'Type: Bolt'
			},

			['dire viper bolt'] = {
				'Dire Viper Bolt',
				'Poisonous bolt.',
				'Venomous effect.',
				'Type: Bolt'
			},

			['wild flameblade'] = {
				'Wild Flameblade',
				'Flame-infused wild blade.',
				'Burning damage.',
				'Type: Short blade'
			},

			['wild shardblade'] = {
				'Wild Shardblade',
				'Sharp wild blade.',
				'Piercing damage.',
				'Type: Short blade'
			},

			['wild sparkblade'] = {
				'Wild Sparkblade',
				'Spark-infused wild blade.',
				'Shock damage.',
				'Type: Short blade'
			},

			['wild viperblade'] = {
				'Wild Viperblade',
				'Poisonous wild blade.',
				'Venomous effect.',
				'Type: Short blade'
			},
			['wild flamesword'] = {
				'Wild Flamesword',
				'Flame-infused wild sword.',
				'Burning damage.',
				'Type: Short blade'
			},

			['wild shardsword'] = {
				'Wild Shardsword',
				'Sharp wild sword.',
				'Piercing damage.',
				'Type: Short blade'
			},

			['wild sparksword'] = {
				'Wild Sparksword',
				'Spark-infused wild sword.',
				'Shock damage.',
				'Type: Short blade'
			},

			['wild vipersword'] = {
				'Wild Vipersword',
				'Poisonous wild sword.',
				'Venomous effect.',
				'Type: Short blade'
			},

			['glass jinkblade'] = {
				'Glass Jinkblade',
				'Agile glass blade.',
				'Quick strikes.',
				'Type: Short blade'
			},

			['dwemer jinksword'] = {
				'Dwemer Jinksword',
				'Ancient dwemer sword.',
				'Mechanical features.',
				'Type: Short blade'
			},

			['glass firesword'] = {
				'Glass Firesword',
				'Flame-infused glass sword.',
				'Burning damage.',
				'Type: Long one-handed blade'
			},

			['glass frostsword'] = {
				'Glass Frostsword',
				'Frost-infused glass sword.',
				'Cold damage.',
				'Type: Long one-handed blade'
			},

			['glass stormsword'] = {
				'Glass Stormsword',
				'Lightning-infused glass sword.',
				'Shock damage.',
				'Type: Long one-handed blade'
			},

			['glass poisonsword'] = {
				'Glass Poisonsword',
				'Poison-infused glass sword.',
				'Venomous effect.',
				'Type: Long one-handed blade'
			},

			['silver flameblade'] = {
				'Silver Flameblade',
				'Flame-infused silver blade.',
				'Burning damage.',
				'Type: Short blade'
			},

			['silver shardblade'] = {
				'Silver Shardblade',
				'Sharp silver blade.',
				'Piercing damage.',
				'Type: Short blade'
			},

			['silver sparkblade'] = {
				'Silver Sparkblade',
				'Spark-infused silver blade.',
				'Shock damage.',
				'Type: Short blade'
			},

			['silver viperblade'] = {
				'Silver Viperblade',
				'Poisonous silver blade.',
				'Venomous effect.',
				'Type: Short blade'
			},
			['silver flamesword'] = {
				'Silver Flamesword',
				'Flame-infused silver sword.',
				'Burning damage.',
				'Type: Long one-handed blade'
			},

			['silver shardsword'] = {
				'Silver Shardsword',
				'Sharp silver sword.',
				'Piercing damage.',
				'Type: Long one-handed blade'
			},

			['silver sparksword'] = {
				'Silver Sparksword',
				'Spark-infused silver sword.',
				'Shock damage.',
				'Type: Long one-handed blade'
			},

			['silver vipersword'] = {
				'Silver Vipersword',
				'Poisonous silver sword.',
				'Venomous effect.',
				'Type: Long one-handed blade'
			},

			['silver flameaxe'] = {
				'Silver Flameaxe',
				'Flame-infused silver axe.',
				'Burning damage.',
				'Type: One-handed axe'
			},

			['silver sparkaxe'] = {
				'Silver Sparkaxe',
				'Spark-infused silver axe.',
				'Shock damage.',
				'Type: One-handed axe'
			},

			['silver shardaxe'] = {
				'Silver Shardaxe',
				'Sharp silver axe.',
				'Piercing damage.',
				'Type: One-handed axe'
			},

			['silver viperaxe'] = {
				'Silver Viperaxe',
				'Poisonous silver axe.',
				'Venomous effect.',
				'Type: One-handed axe'
			},

			['silver flameslayer'] = {
				'Silver Flameslayer',
				'Flame-infused silver greatsword.',
				'Burning damage.',
				'Type: Two-handed sword'
			},

			['silver shardslayer'] = {
				'Silver Shardslayer',
				'Sharp silver greatsword.',
				'Piercing damage.',
				'Type: Two-handed sword'
			},

			['silver sparkslayer'] = {
				'Silver Sparkslayer',
				'Spark-infused silver greatsword.',
				'Shock damage.',
				'Type: Two-handed sword'
			},

			['silver viperslayer'] = {
				'Silver Viperslayer',
				'Poisonous silver greatsword.',
				'Venomous effect.',
				'Type: Two-handed sword'
			},

			['silver flameskewer'] = {
				'Silver Flameskewer',
				'Flame-infused silver skewer.',
				'Burning damage.',
				'Type: Spear'
			},

			['silver shardskewer'] = {
				'Silver Shardskewer',
				'Sharp silver skewer.',
				'Piercing damage.',
				'Type: Spear'
			},

			['silver sparkskewer'] = {
				'Silver Sparkskewer',
				'Spark-infused silver skewer.',
				'Shock damage.',
				'Type: Spear'
			},

			['silver viperskewer'] = {
				'Silver Viperskewer',
				'Poisonous silver skewer.',
				'Venomous effect.',
				'Type: Spear'
			},
			['silver staff of peace'] = {
				'Silver Staff of Peace',
				'Blessed silver staff.',
				'Healing properties.',
				'Type: Staff'
			},

			['steel warhammer of smiting'] = {
				'Steel Warhammer of Smiting',
				'Powerful warhammer.',
				'Deals smiting damage.',
				'Type: Two-handed blunt weapon'
			},

			['steel broadsword of hewing'] = {
				'Steel Broadsword of Hewing',
				'Hewing broadsword.',
				'Special cutting ability.',
				'Type: Long one-handed blade'
			},

			['steel claymore of hewing'] = {
				'Steel Claymore of Hewing',
				'Hewing claymore.',
				'Enhanced cutting power.',
				'Type: Two-handed sword'
			},

			['steel war axe of deep biting'] = {
				'Steel War Axe of Deep Biting',
				'Deep biting war axe.',
				'Penetrating strikes.',
				'Type: One-handed axe'
			},

			['steel spear of impaling thrust'] = {
				'Steel Spear of Impaling Thrust',
				'Impaling spear.',
				'Thrusting damage.',
				'Type: Spear'
			},

			['steel dagger of swiftblade'] = {
				'Steel Dagger of Swiftblade',
				'Agile steel dagger.',
				'Quick attacks.',
				'Type: Short blade'
			},

			['shortbow of sanguine sureflight'] = {
				'Shortbow of Sanguine Sureflight',
				'Accurate shortbow.',
				'Blood magic.',
				'Type: Bow'
			},

			['throwing knife of sureflight'] = {
				'Throwing Knife of Sureflight',
				'Precision throwing knife.',
				'Accurate throws.',
				'Type: Thrown'
			},

			['gavel of the ordinator'] = {
				'Gavel of the Ordinator',
				"Ordinators gavel.",
				'Special abilities.',
				'Type: One-handed blunt weapon'
			},

			['light staff'] = {
				'Light Staff',
				'Radiant staff.',
				'Light magic.',
				'Type: Staff'
			},

			['merisan club'] = {
				'Merisan Club',
				'Ancient club.',
				'Special properties.',
				'Type: One-handed blunt weapon'
			},

			['spirit-eater'] = {
				'Spirit-Eater',
				'Soul-consuming blade.',
				'Drain life.',
				'Type: Long one-handed blade'
			},

			['daunting mace'] = {
				'Daunting Mace',
				'Fear-inducing mace.',
				'Fear effect.',
				'Type: One-handed blunt weapon'
			},

			['sword of white woe'] = {
				'Sword of White Woe',
				'Cursed white sword.',
				'Special effects.',
				'Type: Long one-handed blade'
			},
			['staff of the forefathers'] = {
				'Staff of the Forefathers',
				'Ancient family staff.',
				'Honors ancestors.',
				'Type: Staff'
			},

			["boethiahs walking stick"] = {
				"Boethiahs Walking Stick",
				'Daedric walking staff.',
				'Dark magic.',
				'Type: Staff'
			},

			["mephala's teacher"] = {
				"Mephala's Teacher",
				'Daedric mace.',
				"Assassin's weapon.",
				'Type: One-handed blunt weapon'
			},

			['bound_longsword'] = {
				'Bound Longsword',
				'Conjured longsword.',
				'Summoned weapon.',
				'Type: Long one-handed blade'
			},

			['bound_mace'] = {
				'Bound Mace',
				'Conjured mace.',
				'Summoned weapon.',
				'Type: One-handed blunt weapon'
			},

			['bound_battle_axe'] = {
				'Bound Battle Axe',
				'Conjured battle axe.',
				'Summoned weapon.',
				'Type: Two-handed axe'
			},

			['bound_spear'] = {
				'Bound Spear',
				'Conjured spear.',
				'Summoned weapon.',
				'Type: Spear'
			},

			['bound_longbow'] = {
				'Bound Longbow',
				'Conjured longbow.',
				'Summoned weapon.',
				'Type: Bow'
			},

			['fiend katana'] = {
				'Fiend Katana',
				'Cursed katana.',
				'Dark magic.',
				'Type: Long one-handed blade'
			},

			['fiend battle axe'] = {
				'Fiend Battle Axe',
				'Cursed battle axe.',
				'Dark magic.',
				'Type: Two-handed axe'
			},

			['fiend spear'] = {
				'Fiend Spear',
				'Cursed spear.',
				'Dark magic.',
				'Type: Spear'
			},

			['fiend longbow'] = {
				'Fiend Longbow',
				'Cursed longbow.',
				'Dark magic.',
				'Type: Bow'
			},

			['silver staff of war'] = {
				'Silver Staff of War',
				'Silver war staff.',
				'Blessed weapon.',
				'Type: Staff'
			},

			['divine judgement silver staff'] = {
				'Divine Judgement Silver Staff',
				'Holy silver staff.',
				'Radiant damage.',
				'Type: Staff'
			},

			['silver staff of chastening'] = {
				'Silver Staff of Chastening',
				'Silver chastening staff.',
				'Punishing effects.',
				'Type: Staff'
			},

			['silver staff of shaming'] = {
				'Silver Staff of Shaming',
				'Silver shaming staff.',
				'Debuff effects.',
				'Type: Staff'
			},

			['devil tanto'] = {
				'Devil Tanto',
				'Cursed short blade.',
				'Dark magic.',
				'Type: Short blade'
			},

			['devil katana'] = {
				'Devil Katana',
				'Cursed katana.',
				'Dark magic.',
				'Type: Long one-handed blade'
			},

			['devil spear'] = {
				'Devil Spear',
				'Cursed spear.',
				'Dark magic.',
				'Type: Spear'
			},

			['devil longbow'] = {
				'Devil Longbow',
				'Cursed longbow.',
				'Dark magic.',
				'Type: Bow'
			},
			["saint's black sword"] = {
				"Saint's Black Sword",
				'Holy black blade.',
				'Blessed weapon.',
				'Type: Short blade'
			},

			['daedric wakizashi_hhst'] = {
				'Daedric Wakizashi HHST',
				'Cursed short blade.',
				'Dark enchantments.',
				'Type: Short blade'
			},

			['demon mace'] = {
				'Demon Mace',
				'Cursed demonic mace.',
				'Dark power.',
				'Type: One-handed blunt weapon'
			},

			['chargen dagger'] = {
				'Chargen Dagger',
				'Basic training dagger.',
				'Standard weapon.',
				'Type: Short blade'
			},

			['ebony staff caper'] = {
				'Ebony Staff of Caper',
				'Ebony mystic staff.',
				'Special abilities.',
				'Type: Staff'
			},

			['war_axe_airan_ammu'] = {
				'War Axe of Airan Ammu',
				'Ancient war axe.',
				'Historical weapon.',
				'Type: One-handed axe'
			},

			['sunder'] = {
				'Sunder',
				'Powerful warhammer.',
				'Crushing blows.',
				'Type: One-handed blunt weapon'
			},

			['keening'] = {
				'Keening',
				'Sharp blade.',
				'Piercing attacks.',
				'Type: Short blade'
			},

			['cruel frostarrow'] = {
				'Cruel Frost Arrow',
				'Frost-infused arrow.',
				'Cold damage.',
				'Type: Arrow'
			},

			['dire frostarrow'] = {
				'Dire Frost Arrow',
				'Powerful frost arrow.',
				'Cold damage.',
				'Type: Arrow'
			},

			['steelstaffancestors_ttsa'] = {
				'Steel Staff of Ancestors TTSA',
				'Steel ancestral staff.',
				'Honors forefathers.',
				'Type: Staff'
			},

			['cleaverstfelms'] = {
				'Cleaver of Stfelms',
				'Heavy cleaver.',
				'Powerful strikes.',
				'Type: One-handed axe'
			},

			['crosierstllothis'] = {
				'Crosier of Stllothis',
				'Holy crosier.',
				'Blessed weapon.',
				'Type: Staff'
			},

			['ebony_bow_auriel'] = {
				'Ebony Bow of Auriel',
				'Radiant ebony bow.',
				'Holy damage.',
				'Type: Bow'
			},

			['dwarven_hammer_volendrung'] = {
				'Dwarven Hammer Volendrung',
				'Ancient dwarven hammer.',
				'Powerful weapon.',
				'Type: Two-handed blunt weapon'
			},

			['devil_tanto_tgamg'] = {
				'Devil Tanto TGAMG',
				'Cursed short blade.',
				'Dark magic.',
				'Type: Short blade'
			},

			['ebony_dagger_mehrunes'] = {
				'Ebony Dagger of Mehrunes',
				'Daedric dagger.',
				'Cursed blade.',
				'Type: Short blade'
			},

			['bound_dagger'] = {
				'Bound Dagger',
				'Conjured dagger.',
				'Summoned weapon.',
				'Type: Short blade'
			},

			['ebony_staff_tges'] = {
				'Ebony Staff TGes',
				'Ebony mystic staff.',
				'Dark magic.',
				'Type: Staff'
			},

			['daedric dagger_mtas'] = {
				'Daedric Dagger MT',
				'Cursed daedric dagger.',
				'Dark enchantments.',
				'Type: Short blade'
			},

			['iron_arrow_uniq_judgement'] = {
				'Iron Arrow of Judgement',
				'Special judgement arrow.',
				'Unique properties.',
				'Type: Arrow'
			},

			['daedric_club_tgdc'] = {
				'Daedric Club TGDC',
				'Cursed daedric club.',
				'Dark power.',
				'Type: One-handed blunt weapon'
			},
			["miners pick"] = {
				"Miners Pick",
				'Heavy mining tool.',
				'Powerful strikes.',
				'Type: Two-handed axe'
			},

			['glass_dagger_enamor'] = {
				'Glass Dagger of Enamor',
				'Enchanted glass dagger.',
				'Special properties.',
				'Type: Short blade'
			},

			['sparkstar'] = {
				'Sparkstar',
				'Spark-infused throwing star.',
				'Shock damage.',
				'Type: Thrown'
			},

			['daedric_scourge_unique'] = {
				'Daedric Scourge Unique',
				'Cursed daedric weapon.',
				'Dark magic.',
				'Type: One-handed blunt weapon'
			},

			['claymore_chrysamere_unique'] = {
				'Claymore of Chrysamere Unique',
				'Legendary claymore.',
				'Special abilities.',
				'Type: Two-handed sword'
			},

			['staff_magnus_unique'] = {
				'Staff of Magnus Unique',
				'Powerful mystic staff.',
				'Magic enhancement.',
				'Type: Staff'
			},

			['spear_mercy_unique'] = {
				'Spear of Mercy Unique',
				'Blessed spear.',
				'Holy properties.',
				'Type: Spear'
			},

			['longbow_shadows_unique'] = {
				'Longbow of Shadows Unique',
				'Shadow-infused bow.',
				'Stealth magic.',
				'Type: Bow'
			},

			['claymore_iceblade_unique'] = {
				'Claymore of Iceblade Unique',
				'Frost-infused claymore.',
				'Cold damage.',
				'Type: Two-handed sword'
			},

			['staff_hasedoki_unique'] = {
				'Staff of Hasedoki Unique',
				'Ancient mystic staff.',
				'Special abilities.',
				'Type: Staff'
			},

			['warhammer_crusher_unique'] = {
				'Warhammer of Crusher Unique',
				'Powerful warhammer.',
				'Crushing blows.',
				'Type: One-handed blunt weapon'
			},

			['katana_goldbrand_unique'] = {
				'Katana of Goldbrand Unique',
				'Golden katana.',
				'Special properties.',
				'Type: Long one-handed blade'
			},

			['dagger_fang_unique'] = {
				'Dagger of Fang Unique',
				'Unique fang dagger.',
				'Special abilities.',
				'Type: Short blade'
			},

			['longsword_umbra_unique'] = {
				'Longsword of Umbra Unique',
				'Shadow-infused longsword.',
				'Shadow magic.',
				'Type: Two-handed sword'
			},

			['axe_queen_of_bats_unique'] = {
				'Axe of Queen of Bats Unique',
				'Bat-themed axe.',
				'Special abilities.',
				'Type: Two-handed axe'
			},

			['shock_bolt'] = {
				'Shock Bolt',
				'Spark-infused bolt.',
				'Shock damage.',
				'Type: Bolt'
			},

			['shield_bolt'] = {
				'Shield Bolt',
				'Protective bolt.',
				'Defensive enchantment.',
				'Type: Bolt'
			},

			['dagoth dagger'] = {
				'Dagoth Dagger',
				'Ancient dagger.',
				'Special properties.',
				'Type: Short blade'
			},

			["mehrunes'_razor_unique"] = {
				"Mehrunes' Razor Unique",
				'Daedric razor.',
				'Cursed blade.',
				'Type: Short blade'
			},

			['azura_star_unique'] = {
				"Azura's Star Unique",
				'Star artifact.',
				'Special abilities.',
				'Type: Thrown'
			},

			['mace of molag bal_unique'] = {
				'Mace of Molag Bal Unique',
				'Dark mace.',
				'Dark magic.',
				'Type: One-handed blunt weapon'
			},

			['erur_dan_spear_unique'] = {
				"Erur Dan's Spear Unique",
				'Ancient spear of Erur Dan.',
				'Special enchantments.',
				'Type: Spear'
			},

			['ane_teria_mace_unique'] = {
				'Ane Teria Mace Unique',
				'Powerful mystic mace.',
				'Special abilities.',
				'Type: One-handed blunt weapon'
			},

			['conoon_chodala_axe_unique'] = {
				'Conoon Chodala Axe Unique',
				'Ancient axe.',
				'Special properties.',
				'Type: One-handed axe'
			},

			['Rusty_Dagger_UNIQUE'] = {
				'Rusty Dagger Unique',
				'Unique rusty dagger.',
				'Special effects.',
				'Type: Short blade'
			},

			['false_sunder'] = {
				'False Sunder',
				'Counterfeit warhammer.',
				'Imitation weapon.',
				'Type: Two-handed blunt weapon'
			},

			['fork_horripilation_unique'] = {
				'Fork of Horripilation Unique',
				'Special fork weapon.',
				'Unique abilities.',
				'Type: Short blade'
			},

			['widowmaker_unique'] = {
				'Widowmaker Unique',
				'Deadly battle axe.',
				'Special enchantments.',
				'Type: Two-handed axe'
			},

			['bonebiter_bow_unique'] = {
				'Bonebiter Bow Unique',
				'Bone-infused bow.',
				'Special properties.',
				'Type: Bow'
			},

			['herder_crook'] = {
				"Herders Crook",
				"Shepherd's tool.",
				'Utility weapon.',
				'Type: Staff'
			},

			['iron fork'] = {
				'Iron Fork',
				'Basic iron fork.',
				'Multipurpose tool.',
				'Type: Short blade'
			},

			['cloudcleaver_unique'] = {
				'Cloudcleaver Unique',
				'Legendary battle axe.',
				'Special abilities.',
				'Type: Two-handed axe'
			},

			['sunder_fake'] = {
				'Sunder Fake',
				'Fake warhammer.',
				'Counterfeit weapon.',
				'Type: One-handed blunt weapon'
			},

			['we_hellfirestaff'] = {
				'Hellfire Staff',
				'Fiery mystic staff.',
				'Fire magic.',
				'Type: Staff'
			},

			['we_stormforge'] = {
				'Stormforge',
				'Thunder-infused halberd.',
				'Lightning damage.',
				'Type: Spear'
			},

			['staff_of_llevule'] = {
				'Staff of Llevule',
				'Mystic staff.',
				'Special abilities.',
				'Type: Staff'
			},

			['Dagger of Judgement'] = {
				'Dagger of Judgement',
				'Judging dagger.',
				'Special effects.',
				'Type: Short blade'
			},

			['we_illkurok'] = {
				'Illkurok',
				'Ancient weapon.',
				'Special properties.',
				'Type: Two-handed sword'
			},

			['Silver Dagger_Hanin Cursed'] = {
				'Silver Dagger of Hanin Cursed',
				'Cursed silver dagger.',
				'Poison effect.',
				'Type: Short blade'
			},

			['ebony_staff_trebonius'] = {
				'Ebony Staff of Trebonius',
				'Ebony mystic staff.',
				'Dark magic.',
				'Type: Staff'
			},

			['Fury'] = {
				'Fury',
				'Powerful claymore.',
				'Special enchantments.',
				'Type: Two-handed sword'
			},

			['Greed'] = {
				'Greed',
				'Greedy spear.',
				'Special abilities.',
				'Type: Spear'
			},
			['VFX_DestructBolt'] = {
				'Destructive Bolt',
				'Powerful destruction magic bolt.',
				'Deals elemental damage.',
				'Type: Arrow'
			},

			['VFX_PoisonBolt'] = {
				'Poison Bolt',
				'Toxic magic bolt.',
				'Poison effect.',
				'Type: Arrow'
			},

			['VFX_RestoreBolt'] = {
				'Restoration Bolt',
				'Healing magic bolt.',
				'Restores health.',
				'Type: Arrow'
			},

			['banhammer_unique'] = {
				'Banhammer Unique',
				'Powerful unique warhammer.',
				'Special abilities.',
				'Type: Two-handed blunt weapon'
			},

			['VFX_AlterationBolt'] = {
				'Alteration Bolt',
				'Alteration magic bolt.',
				'Enhances attributes.',
				'Type: Arrow'
			},

			['VFX_ConjureBolt'] = {
				'Conjuration Bolt',
				'Summoning magic bolt.',
				'Calls creatures.',
				'Type: Arrow'
			},

			['VFX_FrostBolt'] = {
				'Frost Bolt',
				'Frost magic bolt.',
				'Cold damage.',
				'Type: Arrow'
			},

			['VFX_MysticismBolt'] = {
				'Mysticism Bolt',
				'Mystic magic bolt.',
				'Special effects.',
				'Type: Arrow'
			},

			['VFX_IllusionBolt'] = {
				'Illusion Bolt',
				'Illusion magic bolt.',
				'Deception magic.',
				'Type: Arrow'
			},

			['VFX_Multiple2'] = {
				'Multiple Effect 2',
				'Complex magic effect.',
				'Combines abilities.',
				'Type: Arrow'
			},

			['VFX_Multiple3'] = {
				'Multiple Effect 3',
				'Complex magic effect.',
				'Combines abilities.',
				'Type: Arrow'
			},

			['VFX_Multiple4'] = {
				'Multiple Effect 4',
				'Complex magic effect.',
				'Combines abilities.',
				'Type: Arrow'
			},

			['VFX_Multiple5'] = {
				'Multiple Effect 5',
				'Complex magic effect.',
				'Combines abilities.',
				'Type: Arrow'
			},

			['VFX_Multiple6'] = {
				'Multiple Effect 6',
				'Complex magic effect.',
				'Combines abilities.',
				'Type: Arrow'
			},

			['VFX_Multiple7'] = {
				'Multiple Effect 7',
				'Complex magic effect.',
				'Combines abilities.',
				'Type: Arrow'
			},

			['VFX_Multiple8'] = {
				'Multiple Effect 8',
				'Complex magic effect.',
				'Combines abilities.',
				'Type: Arrow'
			},

			['racerbeak'] = {
				'Racerbeak',
				'Unique short blade.',
				'Special properties.',
				'Type: Short blade'
			},

			['Wind of Ahaz'] = {
				'Wind of Ahaz',
				'Powerful battle axe.',
				'Wind magic.',
				'Type: One-handed axe'
			},

			["Karpal's Friend"] = {
				"Karpal's Friend",
				'Loyal companion axe.',
				'Special abilities.',
				'Type: One-handed axe'
			},

			['we_shimsil'] = {
				'Shimsil',
				'Ancient short blade.',
				'Mystical powers.',
				'Type: Short blade'
			},

			['iron spider dagger'] = {
				'Iron Spider Dagger',
				'Spider-themed dagger.',
				'Special effects.',
				'Type: Short blade'
			},

			['steel spider blade'] = {
				'Steel Spider Blade',
				'Steel spider-themed blade.',
				'Special effects.',
				'Type: Short blade'
			},

			['imperial netch blade'] = {
				'Imperial Netch Blade',
				'Unique imperial blade.',
				'Special properties.',
				'Type: Short blade'
			},

			['glass netch dagger'] = {
				'Glass Netch Dagger',
				'Glass netch-themed dagger.',
				'Special effects.',
				'Type: Short blade'
			},

			['claymore_Agustas'] = {
				'Claymore of Agustas',
				'Powerful family claymore.',
				'Drains agility on hit.',
				'Type: Two-handed sword'
			},

			['ebony spear_hrce_unique'] = {
				'Ebony Spear HRCE Unique',
				'Unique ebony spear.',
				'Special properties.',
				'Type: Spear'
			},

			['lightofday_unique'] = {
				'Light of Day Unique',
				'Holy one-handed weapon.',
				'Radiant damage.',
				'Type: One-handed blunt weapon'
			},

			['glass stormblade'] = {
				'Glass Stormblade',
				'Glass storm-infused blade.',
				'Shock damage.',
				'Type: Short blade'
			},

			['daedric_crescent_unique'] = {
				'Daedric Crescent Unique',
				'Crescent-shaped daedric weapon.',
				'Special abilities.',
				'Type: Two-handed sword'
			},

			['silver_staff_dawn_uniq'] = {
				'Silver Staff of Dawn Unique',
				'Silver dawn staff.',
				'Holy magic.',
				'Type: Staff'
			},

			["Airan_Ahhe's_Spirit_Spear_uniq"] = {
				"Airan Ahhe's Spirit Spear Unique",
				'Spiritual spear.',
				'Special abilities.',
				'Type: Spear'
			},

			['katana_bluebrand_unique'] = {
				'Katana of Bluebrand Unique',
				'Blue-hued katana.',
				'Special properties.',
				'Type: Long one-handed blade'
			},

			['glass dagger_Dae_cursed'] = {
				'Glass Dagger Dae Cursed',
				'Cursed glass dagger.',
				'Dark magic.',
				'Type: Short blade'
			},

			['glass claymore_magebane'] = {
				'Glass Magebane Claymore',
				'Mage-hunting claymore.',
				'Magic resistance.',
				'Type: Two-handed sword'
			},

			['daedric warhammer_ttgd'] = {
				'Daedric Warhammer TTGD',
				'Cursed daedric warhammer.',
				'Dark power.',
				'Type: Two-handed blunt weapon'
			},

			['dart_uniq_judgement'] = {
				'Dart of Unique Judgement',
				'Special judgement dart.',
				'Unique properties.',
				'Type: Thrown'
			},

			['Stormkiss'] = {
				'Stormkiss',
				'Thunder-infused axe.',
				'Shock damage.',
				'Type: Two-handed axe'
			},

			['dwarven axe_soultrap'] = {
				'Dwarven Axe Soultrap',
				'Soul-trapping axe.',
				'Soul magic.',
				'Type: Two-handed axe'
			},

			['silver staff of hunger'] = {
				'Silver Staff of Hunger',
				'Hunger-inducing staff.',
				'Special effects.',
				'Type: Staff'
			},

			['daedric dagger_soultrap'] = {
				'Daedric Dagger Soultrap',
				'Soul-trapping dagger.',
				'Soul magic.',
				'Type: Short blade'
			},

			['dwarven halberd_soultrap'] = {
				'Dwarven Halberd Soultrap',
				'Soul-trapping halberd.',
				'Soul magic.',
				'Type: Spear'
			},

			['fiend spear_Dae_cursed'] = {
				'Fiend Spear Dae Cursed',
				'Cursed fiend spear.',
				'Dark magic.',
				'Type: Spear'
			},

			['ebony broadsword_Dae_cursed'] = {
				'Ebony Broadsword Dae Cursed',
				'Cursed ebony broadsword.',
				'Dark magic.',
				'Type: Long one-handed blade'
			},

			['iron shardaxe'] = {
				'Iron Shard Axe',
				'Iron axe.',
				'Piercing damage.',
				'Type: Two-handed axe'
			},

			['dwe_jinksword_curse_Unique'] = {
				'Dwe Jinksword Curse Unique',
				'Cursed Dwarven sword of evasion.',
				'Paralysis effect on hit.',
				'Type: Short blade'
			},

			['iron dagger_telasero_unique'] = {
				'Iron Dagger Telasero Unique',
				'Unique iron dagger.',
				'Special properties.',
				'Type: Short blade'
			},

			['Gravedigger'] = {
				'Gravedigger',
				'Powerful two-handed sword.',
				'Special abilities.',
				'Type: Two-handed sword'
			},

			['silver dagger_droth_unique'] = {
				'Silver Dagger Droth Unique',
				'Unique silver dagger.',
				'Special enchantments.',
				'Type: Short blade'
			},

			['spear_mercy_unique_x'] = {
				'Spear of Mercy Unique X',
				'Blessed spear variant.',
				'Holy properties.',
				'Type: Spear'
			},

			['longsword_umbra_unique_x'] = {
				'Longsword of Umbra Unique X',
				'Shadow-infused longsword variant.',
				'Shadow magic.',
				'Type: Two-handed sword'
			},

			['dagger_fang_unique_x'] = {
				'Dagger of Fang Unique X',
				'Unique fang dagger variant.',
				'Special abilities.',
				'Type: Short blade'
			},

			['ebony_bow_auriel_X'] = {
				'Ebony Bow of Auriel X',
				'Radiant ebony bow variant.',
				'Holy damage.',
				'Type: Bow'
			},

			['daedric warhammer_ttgd_x'] = {
				'Daedric Warhammer TTGD X',
				'Cursed daedric warhammer variant.',
				'Dark power.',
				'Type: Two-handed blunt weapon'
			},

			['mace of molag bal_unique_x'] = {
				'Mace of Molag Bal Unique X',
				'Dark mace variant.',
				'Dark magic.',
				'Type: One-handed blunt weapon'
			},

			['longbow_shadows_unique_x'] = {
				'Longbow of Shadows Unique X',
				'Shadow-infused bow variant.',
				'Stealth magic.',
				'Type: Bow'
			},

			['katana_goldbrand_unique_x'] = {
				'Katana of Goldbrand Unique X',
				'Golden katana variant.',
				'Special properties.',
				'Type: Long one-handed blade'
			},

			['claymore_iceblade_unique_x'] = {
				'Claymore of Iceblade Unique X',
				'Frost-infused claymore variant.',
				'Cold damage.',
				'Type: Two-handed sword'
			},

			['claymore_chrysamere_unique_x'] = {
				'Claymore of Chrysamere Unique X',
				'Legendary claymore variant.',
				'Special abilities.',
				'Type: Two-handed sword'
			},

			['warhammer_crusher_unique_x'] = {
				'Warhammer of Crusher Unique X',
				'Powerful warhammer variant.',
				'Crushing blows.',
				'Type: One-handed blunt weapon'
			},

			['staff_magnus_unique_x'] = {
				'Staff of Magnus Unique X',
				'Powerful mystic staff variant.',
				'Magic enhancement.',
				'Type: Staff'
			},

			['staff_hasedoki_unique_x'] = {
				'Staff of Hasedoki Unique X',
				'Ancient mystic staff variant.',
				'Special abilities.',
				'Type: Staff'
			},

			['ebony war axe_elanande'] = {
				'Ebony War Axe Elanande',
				'Ebony war axe.',
				'Special properties.',
				'Type: One-handed axe'
			},

			['ebony shortsword_soscean'] = {
				'Ebony Shortsword Soscean',
				'Ebony shortsword.',
				'Special enchantments.',
				'Type: Short blade'
			},

			['silver spear_uvenim'] = {
				'Silver Spear Uvenim',
				'Silver spear.',
				'Special abilities.',
				'Type: Spear'
			},

			['goblin_club'] = {
				'Goblin Club',
				'Roughly crafted club.',
				'Primitive weapon.',
				'Type: One-handed blunt weapon'
			},

			['Mace of Slurring'] = {
				'Mace of Slurring',
				'Mace with strange enchantment.',
				'Special effects.',
				'Type: One-handed blunt weapon'
			},

			['Bipolar Blade'] = {
				'Bipolar Blade',
				'Dual-natured blade.',
				'Unique properties.',
				'Type: Two-handed sword'
			},

			['Ebony Scimitar'] = {
				'Ebony Scimitar',
				'Curved ebony blade.',
				'Agile weapon.',
				'Type: Long one-handed blade'
			},

			['spite_dart'] = {
				'Spite Dart',
				'Poisoned throwing dart.',
				'Venomous effect.',
				'Type: Thrown'
			},

			["King's Oath"] = {
				"King's Oath",
				'Royal longsword.',
				'Legendary weapon.',
				'Type: Two-handed sword'
			},

			['Ebony Scimitar_her'] = {
				'Ebony Scimitar HER',
				'Enhanced ebony scimitar.',
				'Improved stats.',
				'Type: Long one-handed blade'
			},

			['her dart'] = {
				'Her Dart',
				'Special throwing dart.',
				'Unique abilities.',
				'Type: Thrown'
			},

			["King's Oath_pc"] = {
				"King's Oath",
				'Player character version.',
				'Customizable weapon.',
				'Type: Two-handed sword'
			},

			['dwarven mace_salandas'] = {
				'Dwarven Mace Salandas',
				'Ancient dwarven mace.',
				'Special enchantments.',
				'Type: One-handed blunt weapon'
			},

			['Bipolar Blade_x'] = {
				'Bipolar Blade',
				'Enhanced dual-natured blade.',
				'Improved effects.',
				'Type: Two-handed sword'
			},

			['Mace of Slurring_x'] = {
				'Mace of Slurring',
				'Enhanced slurring mace.',
				'Amplified effects.',
				'Type: One-handed blunt weapon'
			},

			['spring dart'] = {
				'Spring Dart',
				'Lightweight throwing dart.',
				'Quick strikes.',
				'Type: Thrown'
			},

			['bleeder dart'] = {
				'Bleeder Dart',
				'Blood-draining dart.',
				'Life drain effect.',
				'Type: Thrown'
			},

			['carmine dart'] = {
				'Carmine Dart',
				'Crimson-tipped dart.',
				'Special properties.',
				'Type: Thrown'
			},

			['black dart'] = {
				'Black Dart',
				'Darkened throwing dart.',
				'Shadow magic.',
				'Type: Thrown'
			},

			['fine black dart'] = {
				'Fine Black Dart',
				'Refined dark dart.',
				'Enhanced effects.',
				'Type: Thrown'
			},

			['fine carmine dart'] = {
				'Fine Carmine Dart',
				'Refined crimson dart.',
				'Improved stats.',
				'Type: Thrown'
			},

			['fine bleeder dart'] = {
				'Fine Bleeder Dart',
				'Refined blood dart.',
				'Amplified drain.',
				'Type: Thrown'
			},

			['fine spring dart'] = {
				'Fine Spring Dart',
				'Refined quick dart.',
				'Swift attacks.',
				'Type: Thrown'
			},

			['goblin_sword'] = {
				'Goblin Sword',
				'Roughly forged blade.',
				'Primitive weapon.',
				'Type: Short blade'
			},

			['centurion_projectile_dart'] = {
				'Centurion Projectile Dart',
				'Military dart.',
				'Standard issue.',
				'Type: Thrown'
			},

			['adamantium_shortsword'] = {
				'Adamantium Shortsword',
				'Powerful adamantium blade.',
				'Exceptional durability.',
				'Type: Short blade'
			},

			['adamantium_claymore'] = {
				'Adamantium Claymore',
				'Massive adamantium greatsword.',
				'Heavy damage output.',
				'Type: Two-handed sword'
			},

			['adamantium_axe'] = {
				'Adamantium Axe',
				'Sturdy adamantium axe.',
				'Superior cutting power.',
				'Type: Two-handed axe'
			},

			['adamantium_spear'] = {
				'Adamantium Spear',
				'Long adamantium spear.',
				'Reaching strikes.',
				'Type: Spear'
			},

			['adamantium_mace'] = {
				'Adamantium Mace',
				'Heavy adamantium mace.',
				'Crushing blows.',
				'Type: One-handed blunt weapon'
			},

			['nerevarblade_01'] = {
				'Nerevar Blade',
				'Ancient blade of legend.',
				'Special properties.',
				'Type: Long one-handed blade'
			},

			['bladepiece_01'] = {
				'Bladepiece',
				'Unique blade fragment.',
				'Special abilities.',
				'Type: Long one-handed blade'
			},

			['Sword of Almalexia'] = {
				'Sword of Almalexia',
				'Divine blade.',
				'Blessed weapon.',
				'Type: Long one-handed blade'
			},

			['ebony dart_db_unique'] = {
				'Ebony Dart DB Unique',
				'Ebony throwing dart.',
				'Special enchantments.',
				'Type: Thrown'
			},

			['ebony arrow_sadri'] = {
				'Ebony Arrow Sadri',
				'Ebony arrow.',
				'Enhanced damage.',
				'Type: Arrow'
			},

			['stendar_hammer_unique'] = {
				'Stendar Hammer Unique',
				'Hammer of Stendarr.',
				'Blessed weapon.',
				'Type: Two-handed blunt weapon'
			},

			['stendar_hammer_unique_x'] = {
				'Stendar Hammer Unique',
				'Enhanced hammer of Stendarr.',
				'Improved blessings.',
				'Type: Two-handed blunt weapon'
			},

			['centurion_projectile_dart_shock'] = {
				'Centurion Projectile Dart Shock',
				'Shock-infused military dart.',
				'Electric damage.',
				'Type: Thrown'
			},

			['nerevarblade_01_flame'] = {
				'Nerevar Blade Flame',
				'Flame-infused ancient blade.',
				'Burning damage.',
				'Type: Long one-handed blade'
			},

			['daedric dagger_bar'] = {
				'Daedric Dagger BAR',
				'Cursed daedric dagger.',
				'Dark enchantments.',
				'Type: Short blade'
			},

			['adamantium_shortsword_db'] = {
				'Adamantium Shortsword DB',
				'Special adamantium blade.',
				'Unique properties.',
				'Type: Short blade'
			},

			['silver dagger_othril_unique'] = {
				'Silver Dagger Othril Unique',
				'Unique silver dagger.',
				'Special abilities.',
				'Type: Short blade'
			},

			['silver dagger_iryon_unique'] = {
				'Silver Dagger Iryon Unique',
				'Unique silver dagger.',
				'Special enchantments.',
				'Type: Short blade'
			},

			['silver dagger_rathalas_unique'] = {
				'Silver Dagger Rathalas Unique',
				'Unique silver dagger.',
				'Special properties.',
				'Type: Short blade'
			},

			['ebony spear_blessed_unique'] = {
				'Ebony Spear Blessed Unique',
				'Blessed ebony spear.',
				'Holy properties.',
				'Type: Spear'
			},

			['glass dagger_symmachus_unique'] = {
				'Glass Dagger Symmachus Unique',
				'Unique glass dagger.',
				'Special abilities.',
				'Type: Short blade'
			},

			['glass_dagger_symmachus_unique_x'] = {
				'Glass Dagger Symmachus Unique X',
				'Enhanced glass dagger of Symmachus.',
				'Improved enchantments.',
				'Type: Short blade'
			},

			['silver_dagger_droth_unique_a'] = {
				'Silver Dagger Droth Unique A',
				'Ancient silver dagger.',
				'Special abilities.',
				'Type: Short blade'
			},

			['BM_huntsman_axe'] = {
				'BM Huntsman Axe',
				'Huntsman-crafted battle axe.',
				"Hunters edge.",
				'Type: One-handed axe'
			},

			['BM_huntsman_longsword'] = {
				'BM Huntsman Longsword',
				"Huntsman's longsword.",
				'Precision strikes.',
				'Type: Long one-handed blade'
			},

			['BM_Huntsman_Spear'] = {
				'BM Huntsman Spear',
				"Huntsman's spear.",
				'Reaching weapon.',
				'Type: Spear'
			},

			['BM_ice_longsword'] = {
				'BM Ice Longsword',
				'Frost-infused longsword.',
				'Cold damage.',
				'Type: Long one-handed blade'
			},

			['BM_ice_mace'] = {
				'BM Ice Mace',
				'Frost-touched mace.',
				'Cold enchantment.',
				'Type: One-handed blunt weapon'
			},

			['BM_ice_dagger'] = {
				'BM Ice Dagger',
				'Frost-touched dagger.',
				'Cold damage.',
				'Type: Short blade'
			},

			['BM_nordic_silver_axe'] = {
				'BM Nordic Silver Axe',
				'Nordic silver axe.',
				'Special properties.',
				'Type: One-handed axe'
			},

			['BM_nordic_silver_claymore'] = {
				'BM Nordic Silver Claymore',
				'Nordic silver greatsword.',
				'Powerful strikes.',
				'Type: Two-handed sword'
			},

			['BM_nordic_silver_battleaxe'] = {
				'BM Nordic Silver Battleaxe',
				'Nordic silver battle axe.',
				'Heavy damage.',
				'Type: Two-handed axe'
			},

			['BM_nordic_silver_dagger'] = {
				'BM Nordic Silver Dagger',
				'Nordic silver dagger.',
				'Agile weapon.',
				'Type: Short blade'
			},

			['BM_nordic_silver_longsword'] = {
				'BM Nordic Silver Longsword',
				'Nordic silver longsword.',
				'Balanced weapon.',
				'Type: Long one-handed blade'
			},

			['BM_nordic_silver_mace'] = {
				'BM Nordic Silver Mace',
				'Nordic silver mace.',
				'Crushing power.',
				'Type: One-handed blunt weapon'
			},

			['BM_nordic_silver_shortsword'] = {
				'BM Nordic Silver Shortsword',
				'Nordic silver shortsword.',
				'Quick strikes.',
				'Type: Short blade'
			},

			['warhammer_rammekald_unique'] = {
				'Warhammer of Rammekald Unique',
				'Powerful warhammer.',
				'Special abilities.',
				'Type: Two-handed blunt weapon'
			},

			['solvistapp'] = {
				'Solvistapp',
				'Ancient blade.',
				'Mystic properties.',
				'Type: Long one-handed blade'
			},

			['steel_spear_snow_prince'] = {
				'Steel Spear of the Snow Prince',
				'Frost-touched spear.',
				'Cold damage.',
				'Type: Spear'
			},

			['steel_saber_elberoth'] = {
				'Steel Saber of Elberoth',
				'Agile saber.',
				'Quick attacks.',
				'Type: Long one-handed blade'
			},

			['BM_huntsman_crossbow'] = {
				'BM Huntsman Crossbow',
				"Huntsman's crossbow.",
				'Precision shots.',
				'Type: Crossbow'
			},

			['BM_ice_war_axe'] = {
				'BM Ice War Axe',
				'Frost-infused war axe.',
				'Cold damage.',
				'Type: One-handed axe'
			},

			['BM_huntsman_war_axe'] = {
				'BM Huntsman War Axe',
				"Huntsman's war axe.",
				'Precision strikes.',
				'Type: One-handed axe'
			},

			['BM_Huntsmanbolt'] = {
				'BM Huntsman Bolt',
				'Special hunting bolt.',
				'Enhanced range.',
				'Type: Bolt'
			},

			['imperial_shortsword_severio'] = {
				'Imperial Shortsword Severio',
				'Imperial-forged blade.',
				'Balanced weapon.',
				'Type: Short blade'
			},

			['nordic_claymore_stormfang'] = {
				'Nordic Claymore Stormfang',
				'Storm-touched claymore.',
				'Lightning damage.',
				'Type: Two-handed sword'
			},

			['BM_arrow_riekling_uni'] = {
				'BM Riekling Unique Arrow',
				'Special riekling arrow.',
				'Unique properties.',
				'Type: Arrow'
			},

			['BM_silver_dagger_wolfender'] = {
				'BM Silver Dagger Wolfender',
				'Silver wolf-themed dagger.',
				'Special abilities.',
				'Type: Short blade'
			},

			['silver_arrow_thirsk_1'] = {
				'Silver Arrow Thirsk 1',
				'Silver hunting arrow.',
				'Enhanced damage.',
				'Type: Arrow'
			},

			['silver_arrow_thirsk_2'] = {
				'Silver Arrow Thirsk 2',
				'Silver hunting arrow.',
				'Enhanced damage.',
				'Type: Arrow'
			},

			['silver_arrow_thirsk_3'] = {
				'Silver Arrow Thirsk 3',
				'Silver hunting arrow.',
				'Enhanced damage.',
				'Type: Arrow'
			},

			['silver_arrow_thirsk_4'] = {
				'Silver Arrow Thirsk 4',
				'Silver hunting arrow.',
				'Enhanced damage.',
				'Type: Arrow'
			},

			['silver_arrow_thirsk_5'] = {
				'Silver Arrow Thirsk 5',
				'Silver hunting arrow.',
				'Enhanced damage.',
				'Type: Arrow'
			},

			['silver_arrow_thirsk_6'] = {
				'Silver Arrow Thirsk 6',
				'Silver hunting arrow.',
				'Enhanced damage.',
				'Type: Arrow'
			},

			['silver_arrow_thirsk_7'] = {
				'Silver Arrow Thirsk 7',
				'Silver hunting arrow.',
				'Enhanced damage.',
				'Type: Arrow'
			},

			['silver_arrow_thirsk_8'] = {
				'Silver Arrow Thirsk 8',
				'Silver hunting arrow.',
				'Enhanced damage.',
				'Type: Arrow'
			},

			['silver_arrow_thirsk_9'] = {
				'Silver Arrow Thirsk 9',
				'Silver hunting arrow.',
				'Enhanced damage.',
				'Type: Arrow'
			},

			['silver_arrow_thirsk_0'] = {
				'Silver Arrow Thirsk 0',
				'Silver hunting arrow.',
				'Enhanced damage.',
				'Type: Arrow'
			},

			['BM_hunter_battleaxe_unique'] = {
				'BM Hunter Battleaxe Unique',
				'Unique hunting battle axe.',
				'Special abilities.',
				'Type: Two-handed axe'
			},

			['BM_nordic_silver_lgswd_bloodska'] = {
				'BM Nordic Silver Longsword Bloodska',
				'Blood-themed silver longsword.',
				'Special properties.',
				'Type: Long one-handed blade'
			},

			['BM_Nordic_Pick'] = {
				'BM Nordic Pick',
				'Nordic mining tool.',
				'Powerful strikes.',
				'Type: One-handed axe'
			},

			['BM_ice_minion_lance'] = {
				'BM Ice Minion Lance',
				'Frost-touched lance.',
				'Cold damage.',
				'Type: Short blade'
			},

			['BM_dagger_wolfgiver'] = {
				'BM Dagger Wolfgiver',
				'Wolf-themed silver dagger.',
				'Special abilities.',
				'Type: Short blade'
			},

			['bm_saber_seasplitter'] = {
				'BM Saber Seasplitter',
				'Powerful cutting saber.',
				'Special enchantments.',
				'Type: Long one-handed blade'
			},

			['BM nordic_longsword_tracker'] = {
				'BM Nordic Longsword Tracker',
				"Trackers longsword.",
				'Precision strikes.',
				'Type: Long one-handed blade'
			},

			['BM riekling lance'] = {
				'BM Riekling Lance',
				'Riekling-sized lance.',
				'Special properties.',
				'Type: Short blade'
			},

			['BM riekling sword'] = {
				'BM Riekling Sword',
				'Small hunting sword.',
				'Unique abilities.',
				'Type: Long one-handed blade'
			},

			['steel arrow_Carnius'] = {
				'Steel Arrow Carnius',
				'Special steel arrow.',
				'Enhanced stats.',
				'Type: Arrow'
			},

			['steel longbow_carnius'] = {
				'Steel Longbow Carnius',
				'Custom steel longbow.',
				'Special properties.',
				'Type: Bow'
			},

			['silver axe of paralysis'] = {
				'Silver Axe of Paralysis',
				'Paralyzing silver axe.',
				'Special effect.',
				'Type: One-handed axe'
			},

			['silver sword of paralysis'] = {
				'Silver Sword of Paralysis',
				'Paralyzing silver sword.',
				'Special effect.',
				'Type: Long one-handed blade'
			},

			['silver staff of paralysis'] = {
				'Silver Staff of Paralysis',
				'Paralyzing silver staff.',
				'Special effect.',
				'Type: Staff'
			},

			['BM nordic silver claymore_ber'] = {
				'BM Nordic Silver Claymore Ber',
				'Ber-themed silver claymore.',
				'Special abilities.',
				'Type: Two-handed sword'
			},

			['BM nordic silver longsword_ber'] = {
				'BM Nordic Silver Longsword Ber',
				'Ber-themed silver longsword.',
				'Special abilities.',
				'Type: Long one-handed blade'
			},

			['BM nordic silver axe_ber'] = {
				'BM Nordic Silver Axe Ber',
				'Ber-themed silver axe.',
				'Special abilities.',
				'Type: One-handed axe'
			},

			['BM nordic silver battleaxe_ber'] = {
				'BM Nordic Silver Battleaxe Ber',
				'Ber-themed silver battleaxe.',
				'Special abilities.',
				'Type: Two-handed axe'
			},

			['BM nord leg'] = {
				'BM Nordic Leg',
				'Special nordic weapon.',
				'Unique properties.',
				'Type: One-handed blunt weapon'
			},

			['bm_ebony_staff_necro'] = {
				'BM Ebony Staff Necro',
				'Necromantic ebony staff.',
				'Dark magic.',
				'Type: Staff'
			},

			['BM Winterwound Dagger'] = {
				'BM Winterwound Dagger',
				'Frost-infused dagger.',
				'Cold damage.',
				'Type: Short blade'
			},

			['BM_axe_Heartfang_Unique'] = {
				'BM Axe Heartfang Unique',
				'Unique heart-themed axe.',
				'Special abilities.',
				'Type: Two-handed axe'
			},

			['BM_Mace_Aevar_UNI'] = {
				'BM Mace Aevar UNI',
				'Special mace.',
				'Unique enchantments.',
				'Type: One-handed blunt weapon'
			},

			['BM ice longsword_FG_Unique'] = {
				'BM Ice Longsword FG Unique',
				'Frost-infused longsword.',
				'Cold damage.',
				'Type: Long one-handed blade'
			},

			['bm reaver battle axe'] = {
				'BM Reaver Battle Axe',
				'Reaver-themed battle axe.',
				'Special abilities.',
				'Type: Two-handed axe'
			},


			['BM nordic silver axe_spurius'] = {
				'BM Nordic Silver Axe Spurius',
				'Spurius-forged silver axe.',
				'Special enchantments.',
				'Type: One-handed axe'
			},

			['BM nordic silver longsword_cft'] = {
				'BM Nordic Silver Longsword CFT',
				'Custom forged silver longsword.',
				'Enhanced properties.',
				'Type: Long one-handed blade'
			},

			['Lucky_Break'] = {
				'Lucky Break',
				'Fortune-infused warhammer.',
				'Critical strike bonus.',
				'Type: Staff'
			},

			['BM frostgore'] = {
				'BM Frostgore',
				'Frost-touched short blade.',
				'Cold damage.',
				'Type: Short blade'
			},

			['bm_ebonyarrow_s'] = {
				'BM Ebony Arrow S',
				'Standard ebony arrow.',
				'Enhanced stats.',
				'Type: Arrow'
			},

			['bm_ebonylongsword_s'] = {
				'BM Ebony Longsword S',
				'Standard ebony longsword.',
				'Balanced weapon.',
				'Type: Long one-handed blade'
			},

			['BM riekling sword_rusted'] = {
				'BM Riekling Sword Rusty',
				'Rusty riekling sword.',
				'Durable weapon.',
				'Type: Long one-handed blade'
			},

			['BM_hunterspear_unique'] = {
				"BM Hunters Spear Unique",
				'Unique hunting spear.',
				'Special abilities.',
				'Type: Spear'
			}
		}
	}
}