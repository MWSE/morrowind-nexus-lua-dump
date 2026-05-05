local types = require('openmw.types')
local util = require('openmw.util')

return {
    [types.Clothing] = {
        title = 'Clothing',
        color = util.color.rgb(0.8, 0.6, 0.2),
        showWeight = true,
        showValue = true,
        uniqueDescriptions = {
			['common_amulet_01'] = {
				'Basic common amulet.',
				'Provides minor magical benefits.',
				'Type: Amulet'
			},
			['common_amulet_02'] = {
				'Another common amulet variant.',
				'Offers slight enchantment effects.',
				'Type: Amulet'
			},
			['common_amulet_03'] = {
				'Ordinary common amulet.',
				'Enhances basic magical abilities.',
				'Type: Amulet'
			},
			['common_amulet_04'] = {
				'Simple common amulet design.',
				'Grants minimal magical protection.',
				'Type: Amulet'
			},
			['common_amulet_05'] = {
				'Fifth variant of common amulet.',
				'Provides entry-level enchantments.',
				'Type: Amulet'
			},
			['expensive_amulet_01'] = {
				'High-grade amulet.',
				'Boasts advanced magical properties.',
				'Type: Amulet'
			},
			['expensive_amulet_02'] = {
				'Premium amulet variant.',
				'Enhances powerful magical abilities.',
				'Type: Amulet'
			},
			['expensive_amulet_03'] = {
				'Luxurious expensive amulet.',
				'Offers superior enchantment effects.',
				'Type: Amulet'
			},
			['extravagant_amulet_01'] = {
				'Opulent extravagant amulet.',
				'Imbued with rare magical energies.',
				'Type: Amulet'
			},
			['extravagant_amulet_02'] = {
				'Elegant extravagant design.',
				'Provides exceptional magical boons.',
				'Type: Amulet'
			},
			['exquisite_amulet_01'] = {
				'Fine exquisite amulet craftsmanship.',
				'Enhances refined magical abilities.',
				'Type: Amulet'
			},
			['amulet of mighty blows'] = {
				'Amulet enhancing physical power.',
				'Increases strength in combat.',
				'Type: Amulet'
			},
			['mandas_locket'] = {
				'Locket with Mandas symbolism.',
				'Offers personal magical protection.',
				'Type: Amulet'
			},
			['red despair amulet'] = {
				'Amulet imbued with dark energy.',
				'Inflicts despair on enemies.',
				'Type: Amulet'
			},
			['stumble charm'] = {
				'Charm causing foes to stumble.',
				'Disrupts enemy movement.',
				'Type: Amulet'
			},
			['gripes charm'] = {
				'Charm inducing discomfort.',
				'Weakens opponent’s resolve.',
				'Type: Amulet'
			},
			['fuddle charm'] = {
				'Confusion-inducing charm.',
				'Muddles enemy thinking.',
				'Type: Amulet'
			},
			['hex charm'] = {
				'Malevolent hex enchantment.',
				'Curses targets with ill fortune.',
				'Type: Amulet'
			},
			['evil eye charm'] = {
				'Charm with evil eye power.',
				'Inflicts misfortune on foes.',
				'Type: Amulet'
			},
			['clench charm'] = {
				'Charm restricting movement.',
				'Limits enemy agility.',
				'Type: Amulet'
			},
			['bonebiter charm'] = {
				'Charm causing bone pain.',
				'Weakens enemy physical form.',
				'Type: Amulet'
			},
			['woe charm'] = {
				'Sorrow-inducing magical charm.',
				'Lowers enemy morale.',
				'Type: Amulet'
			},
			["amulet of balyna's soothing bal"] = {
				'Healing amulet by Balyna.',
				'Provides health regeneration.',
				'Type: Amulet'
			},
			['amulet of stamina'] = {
				'Stamina-boosting amulet.',
				'Increases endurance in battle.',
				'Type: Amulet'
			},
			['amulet of light'] = {
				'Amulet radiating holy light.',
				'Protects against darkness.',
				'Type: Amulet'
			},
			['amulet of locking'] = {
				'Locking mechanism amulet.',
				'Seals doors or containers.',
				'Type: Amulet'
			},
			['amulet of opening'] = {
				'Opening enchanted amulet.',
				'Unlocks sealed objects.',
				'Type: Amulet'
			},
			['amulet of water walking'] = {
				'Water-walking magical amulet.',
				'Allows traversing water surfaces.',
				'Type: Amulet'
			},
			['amulet of slowfalling'] = {
				'Slowfalling enchantment amulet.',
				'Reduces fall damage.',
				'Type: Amulet'
			},
			['amulet of divine intervention'] = {
				'Divine protection amulet.',
				'Summons celestial aid in peril.',
				'Type: Amulet'
			},
			['amulet of almsivi intervention'] = {
				'Almsivi-blessed amulet.',
				'Teleports to safe location.',
				'Type: Amulet'
			},
			['light amulet'] = {
				'Simple light-emitting amulet.',
				'Illuminates dark areas.',
				'Type: Amulet'
			},
			['sleep amulet'] = {
				'Sleep-inducing magical amulet.',
				'Calms or sedates targets.',
				'Type: Amulet'
			},
			['balm amulet'] = {
				'Healing balm amulet.',
				'Soothes wounds and ailments.',
				'Type: Amulet'
			},
			['doze charm'] = {
				'Drowsiness-inducing charm.',
				'Causes fatigue in enemies.',
				'Type: Amulet'
			},
			['spirit charm'] = {
				'Spiritual energy charm.',
				'Enhances mystical awareness.',
				'Type: Amulet'
			},
			['soulpinch charm'] = {
				'Soul-disturbing charm.',
				'Harasses enemy spirits.',
				'Type: Amulet'
			},
			['bone charm'] = {
				'Bone-strengthening amulet.',
				'Enhances physical durability.',
				'Type: Amulet'
			},
			['ghost charm'] = {
				'Ghostly presence amulet.',
				'Summons spectral aid.',
				'Type: Amulet'
			},
			['silence charm'] = {
				'Silencing magical charm.',
				'Prevents vocal spells.',
				'Type: Amulet'
			},
			['amulet of rest'] = {
				'Restorative magic amulet.',
				'Accelerates recovery.',
				'Type: Amulet'
			},
			['amulet of health'] = {
				'Health-boosting magical amulet.',
				'Increases vitality.',
				'Type: Amulet'
			},
			['amulet of frost'] = {
				'Frost-infused magical amulet.',
				'Chills surroundings.',
				'Type: Amulet'
			},
			['thunderfall'] = {
				'Thunder-summoning amulet.',
				'Calls down lightning strikes.',
				'Type: Amulet'
			},
			['crimson despair amulet'] = {
				'Despair-inducing crimson amulet.',
				'Drains enemy willpower.',
				'Type: Amulet'
			},
			['Exquisite_Amulet_Arobar1'] = {
				'Exquisite amulet by Arobar.',
				'Offers refined magical benefits.',
				'Type: Amulet'
			},
			["st. sotha's judgement"] = {
				'Judicial amulet of St. Sotha.',
				'Delivers divine retribution.',
				'Type: Amulet'
			},
			['summon ancestor amulet'] = {
				'Ancestor-summoning amulet.',
				'Calls upon ancestral spirits.',
				'Type: Amulet'
			},
			['amulet of shades'] = {
				'Shade-controlling amulet.',
				'Manipulates shadow energies.',
				'Type: Amulet'
			},
			['graveward amulet'] = {
				'Graveward protection amulet.',
				'Wards off undead threats.',
				'Type: Amulet'
			},
			['blood despair amulet'] = {
				'Blood-infused despair amulet.',
				'Instills horror in foes.',
				'Type: Amulet'
			},
			["amulet of balyna's antidote"] = {
				'Antidotal amulet by Balyna.',
				'Neutralizes poisons.',
				'Type: Amulet'
			},
			['amulet of spell absorption'] = {
				'Spell-absorbing magical amulet.',
				'Soaks up hostile spells.',
				'Type: Amulet'
			},
			['amulet of far silence'] = {
				'Silence-extending amulet.',
				'Mutes sounds over distance.',
				'Type: Amulet'
			},
			['amulet of mark'] = {
				'Marking enchanted amulet.',
				'Tags locations or targets.',
				'Type: Amulet'
			},
			['amulet of recall'] = {
				'Recall-enabled magical amulet.',
				'Teleports to marked spots.',
				'Type: Amulet'
			},
			['amulet of silence'] = {
				'Silence-inducing amulet.',
				'Prevents spellcasting.',
				'Type: Amulet'
			},
			['amulet of shield'] = {
				'Protective shield amulet.',
				'Absorbs incoming damage.',
				'Type: Amulet'
			},
			['amulet_unity_uniq'] = {
				'Unique unity-binding amulet.',
				'Strengthens group synergy.',
				'Type: Amulet'
			},
			['amuletfleshmadewhole_uniq'] = {
				'Unique flesh-mending amulet.',
				'Accelerates wound healing.',
				'Type: Amulet'
			},
			['teeth'] = {
				'Amulet shaped like teeth.',
				'Grants ferocity in battle.',
				'Type: Amulet'
			},
			['madstone'] = {
				'Madstone-infused amulet.',
				'Alters mental states.',
				'Type: Amulet'
			},
			['thong'] = {
				'Thong-shaped magical amulet.',
				'Offers subtle protection.',
				'Type: Amulet'
			},
			['heart_of_fire'] = {
				'Fire-heart enchanted amulet.',
				'Ignites inner vigor.',
				'Type: Amulet'
			},
			['sanguineamuletglibspeech'] = {
				'Sanguine amulet for speech.',
				'Enhances persuasion skills.',
				'Type: Amulet'
			},
			['sanguineamuletenterprise'] = {
				'Enterprise-boosting amulet.',
				'Improves business acumen.',
				'Type: Amulet'
			},
			['sanguineamuletnimblearmor'] = {
				'Nimble armor sanguine amulet.',
				'Increases movement speed.',
				'Type: Amulet'
			},
			['amulet_usheeja'] = {
				'Usheeja-blessed amulet.',
				'Provides spiritual aid.',
				'Type: Amulet'
			},
			['exquisite_amulet_hlervu1'] = {
				'Exquisite Hlervu amulet.',
				'Offers refined magical boons.',
				'Type: Amulet'
			},
			['expensive_amulet_aeta'] = {
				'Expensive Aeta amulet.',
				'Imbued with potent magic.',
				'Type: Amulet'
			},
			['amulet of levitating'] = {
				'Levitating magic amulet.',
				'Allows brief airborne movement.',
				'Type: Amulet'
			},
			['artifact_amulet of heartheal'] = {
				'Heartheal artifact amulet.',
				'Rapidly restores health.',
				'Type: Amulet'
			},
			['artifact_amulet of heartrime'] = {
				'Heartrime artifact amulet.',
				'Slows time for the wearer.',
				'Type: Amulet'
			},
			['artifact_amulet of heartfire'] = {
				'Heartfire artifact amulet.',
				'Ignites with elemental power.',
				'Type: Amulet'
			},
			['artifact_amulet of heartthrum'] = {
				'Heartthrum artifact amulet.',
				'Enhances vital energy flow.',
				'Type: Amulet'
			},
			['sarandas_amulet'] = {
				'Sarandas-empowered amulet.',
				'Grants ancient wisdom.',
				'Type: Amulet'
			},
			['amulet of ashamanu (unique)'] = {
				'Unique Ashamanu amulet.',
				'Holds ancient curse power.',
				'Type: Amulet'
			},
			['expensive_amulet_methas'] = {
				'Methas expensive amulet.',
				'Imbued with rare enchantments.',
				'Type: Amulet'
			},
			['amulet of shadows'] = {
				'Shadow-weaving amulet.',
				'Hides the wearer in darkness.',
				'Type: Amulet'
			},
			['hlervu_locket_unique'] = {
				'Unique Hlervu locket.',
				'Protects with ancestral power.',
				'Type: Amulet'
			},
			['amulet of igniis'] = {
				'Igniis flame amulet.',
				'Ignites with fiery might.',
				'Type: Amulet'
			},
			['amulet of admonition'] = {
				'Admonition-bound amulet.',
				'Warns of impending danger.',
				'Type: Amulet'
			},
			['amulet of 6th house'] = {
				'6th House affiliated amulet.',
				'Grants House-specific boons.',
				'Type: Amulet'
			},
			['necromancers_amulet_uniq'] = {
				'Unique necromancer amulet.',
				'Controls undead minions.',
				'Type: Amulet'
			},
			['amulet_Agustas_unique'] = {
				'Unique Agustas amulet.',
				'Bears ancient sigils of power.',
				'Type: Amulet'
			},
			['amulet_Pop00'] = {
				'Pop00 branded amulet.',
				'Offers specialized enchantments.',
				'Type: Amulet'
			},
			['amulet of domination'] = {
				'Domination-focused amulet.',
				'Controls minds of foes.',
				'Type: Amulet'
			},
			['zenithar_whispers'] = {
				'Zenithar-whispering amulet.',
				'Guides in trade and wealth.',
				'Type: Amulet'
			},
			['amulet_aundae'] = {
				'Aundae-aligned amulet.',
				'Enhances mystical insight.',
				'Type: Amulet'
			},
			['amulet_berne'] = {
				'Berne-infused amulet.',
				'Grants elemental resistance.',
				'Type: Amulet'
			},
			['amulet_quarra'] = {
				'Quarra-empowered amulet.',
				'Summons elemental aid.',
				'Type: Amulet'
			},
			['Daedric_special01'] = {
				'Special Daedric amulet.',
				'Imbued with Daedric power.',
				'Type: Amulet'
			},
			['Daedric_special'] = {
				'Daedric-forged amulet.',
				'Bears dark Daedric magic.',
				'Type: Amulet'
			},
			['Maran Amulet'] = {
				'Maran-crafted amulet.',
				'Offers protective enchantments.',
				'Type: Amulet'
			},
			['Julielle_Aumines_Amulet'] = {
				'Julielle Aumines amulet.',
				'Enhances magical affinity.',
				'Type: Amulet'
			},
			['Linus_Iulus_Maran Amulet'] = {
				'Linus Iulus Maran amulet.',
				'Combines family magic.',
				'Type: Amulet'
			},
			['amulet_skink_unique'] = {
				'Unique skink amulet.',
				'Grants reptilian agility.',
				'Type: Amulet'
			},
			['expensive_amulet_delyna'] = {
				'Delyna expensive amulet.',
				'Imbued with elite enchantments.',
				'Type: Amulet'
			},
			['amulet_gem_feeding'] = {
				'Gem-feeding amulet.',
				'Absorbs gemstone power.',
				'Type: Amulet'
			},
			['amulet of verbosity'] = {
				'Verbosity-enhancing amulet.',
				'Improves speech skills.',
				'Type: Amulet'
			},
			['amulet_salandas'] = {
				'Salandas-blessed amulet.',
				'Provides elemental defense.',
				'Type: Amulet'
			},
			['amulet_gaenor'] = {
				'Gaenor-infused amulet.',
				'Enhances physical resilience.',
				'Type: Amulet'
			},
			['Helseth’s Collar'] = {
				'Royal collar of Helseth.',
				'Grants regal authority.',
				'Type: Amulet'
			},
			['amulet of infectious charm'] = {
				'Charm spreading enchantment.',
				'Attracts allies or confuses foes.',
				'Type: Amulet'
			},
			['bm_amulstr1'] = {
				'Strength-boosting BM amulet.',
				'Increases physical power.',
				'Type: Amulet'
			},
			['bm_amulspd1'] = {
				'Speed-enhancing BM amulet.',
				'Quickens movement and reflexes.',
				'Type: Amulet'
			},
			['templar belt'] = {
				'Templar-style belt.',
				'Provides waist protection.',
				'Type: Belt'
			},
			['imperial belt'] = {
				'Imperial design belt.',
				'A sturdy waist accessory.',
				'Type: Belt'
			},
			['indoril_belt'] = {
				'Belt with Indoril clan markings.',
				'Enhances waist support.',
				'Type: Belt'
			},
			['common_belt_01'] = {
				'Basic common belt.',
				'Simple waist accessory.',
				'Type: Belt'
			},
			['common_belt_02'] = {
				'Common belt, variant 02.',
				'Ordinary waistband.',
				'Type: Belt'
			},
			['common_belt_03'] = {
				'Common belt design, 03.',
				'Basic waist support.',
				'Type: Belt'
			},
			['common_belt_04'] = {
				'Fourth variant of common belt.',
				'Simple utility belt.',
				'Type: Belt'
			},
			['common_belt_05'] = {
				'Fifth common belt design.',
				'Everyday waist accessory.',
				'Type: Belt'
			},
			['expensive_belt_01'] = {
				'Expensive belt, first variant.',
				'Luxurious waistband.',
				'Type: Belt'
			},
			['expensive_belt_02'] = {
				'Second expensive belt design.',
				'Fine craftsmanship.',
				'Type: Belt'
			},
			['expensive_belt_03'] = {
				'Third expensive belt option.',
				'Elegant waist accessory.',
				'Type: Belt'
			},
			['extravagant_belt_01'] = {
				'Extravagant belt design, 01.',
				'Opulent waist ornament.',
				'Type: Belt'
			},
			['extravagant_belt_02'] = {
				'Second extravagant belt variant.',
				'Lavish waistband.',
				'Type: Belt'
			},
			['exquisite_belt_01'] = {
				'Exquisite belt design.',
				'Delicate and refined.',
				'Type: Belt'
			},
			['bone guard belt'] = {
				'Belt with bone guard elements.',
				'Provides light protection.',
				'Type: Belt'
			},
			['life belt'] = {
				'Life-enhancing belt.',
				'Boosts vitality.',
				'Type: Belt'
			},
			["watcher's belt"] = {
				'Belt for the watchful.',
				'Enhances awareness.',
				'Type: Belt'
			},
			["herder's belt"] = {
				'Practical herder’s belt.',
				'Utility belt for pastoral tasks.',
				'Type: Belt'
			},
			["hunter's belt"] = {
				'Hunter’s utility belt.',
				'Designed for tracking and hunting.',
				'Type: Belt'
			},
			["belt of orc's strength"] = {
				'Belt imbued with orcish power.',
				'Enhances physical strength.',
				'Type: Belt'
			},
			['belt of iron will'] = {
				'Belt of unbreakable will.',
				'Strengthens resolve.',
				'Type: Belt'
			},
			['belt of nimbleness'] = {
				'Belt enhancing agility.',
				'Improves movement speed.',
				'Type: Belt'
			},
			['belt of feet of notorgo'] = {
				'Mystic belt of Notorgo.',
				'Enhances footwork.',
				'Type: Belt'
			},
			['belt of fortitude'] = {
				'Fortitude-enhancing belt.',
				'Boosts endurance.',
				'Type: Belt'
			},
			['belt of charisma'] = {
				'Charismatic belt design.',
				'Enhances social skills.',
				'Type: Belt'
			},
			['belt of jack of trades'] = {
				'Belt for versatile skills.',
				'Aids in multiple professions.',
				'Type: Belt'
			},
			['belt of wisdom'] = {
				'Wisdom-imbued belt.',
				'Enhances mental acuity.',
				'Type: Belt'
			},
			['first barrier belt'] = {
				'Belt with first barrier enchantment.',
				'Provides elemental protection.',
				'Type: Belt'
			},
			["belt of balyna's soothing balm"] = {
				'Belt infused with Balyna’s balm.',
				'Heals minor wounds.',
				'Type: Belt'
			},
			["father's belt"] = {
				'Sentimental father’s belt.',
				'Family heirloom accessory.',
				'Type: Belt'
			},
			['hearth belt'] = {
				'Hearth-themed belt design.',
				'Symbol of home and warmth.',
				'Type: Belt'
			},
			['champion belt'] = {
				'Champion’s battle belt.',
				'Enhances combat prowess.',
				'Type: Belt'
			},
			['khan belt'] = {
				'Khan’s authoritative belt.',
				'Symbol of leadership.',
				'Type: Belt'
			},
			['blood belt'] = {
				'Blood-infused belt.',
				'Enhances vitality and strength.',
				'Type: Belt'
			},
			['second barrier belt'] = {
				'Belt with second barrier enchantment.',
				'Advanced elemental protection.',
				'Type: Belt'
			},
			['feather belt'] = {
				'Light feather-inspired belt.',
				'Enhances agility and speed.',
				'Type: Belt'
			},
			['belt of vigor'] = {
				'Vigor-enhancing belt.',
				'Boosts physical energy.',
				'Type: Belt'
			},
			["bugharz's belt"] = {
				'Belt belonging to Bugharz.',
				'Personalized utility belt.',
				'Type: Belt'
			},
			["founder's belt"] = {
				'Founder’s commemorative belt.',
				'Symbol of establishment.',
				'Type: Belt'
			},
			['third barrier belt'] = {
				'Belt with third barrier enchantment.',
				'Maximum elemental protection.',
				'Type: Belt'
			},
			['belt of free action'] = {
				'Belt of unhindered movement.',
				'Removes movement penalties.',
				'Type: Belt'
			},
			['extravagant_belt_hf'] = {
				'Extravagant belt, HF variant.',
				'Luxurious and unique design.',
				'Type: Belt'
			},
			['hortatorbelt'] = {
				'Hortator’s command belt.',
				'Symbol of leadership and duty.',
				'Type: Belt'
			},
			["malipu_ataman's_belt"] = {
				'Ataman Malipu’s personal belt.',
				'Tribal leader’s accessory.',
				'Type: Belt'
			},
			['seizing'] = {
				'Seizing power belt.',
				'Enhances grip and strength.',
				'Type: Belt'
			},
			['sanguinebeltfleetness'] = {
				'Sanguine belt of fleetness.',
				'Enhances movement speed.',
				'Type: Belt'
			},
			['sanguinebeltdenial'] = {
				'Sanguine denial belt.',
				'Resists magical effects.',
				'Type: Belt'
			},
			['sanguinebeltimpaling'] = {
				'Sanguine impaling belt.',
				'Enhances piercing attacks.',
				'Type: Belt'
			},
			['sanguinebeltstolidarmor'] = {
				'Sanguine stolid armor belt.',
				'Provides sturdy protection.',
				'Type: Belt'
			},
			['sanguinebeltsmiting'] = {
				'Sanguine smiting belt.',
				'Enhances melee damage.',
				'Type: Belt'
			},
			['sanguinebeltmartialcraft'] = {
				'Sanguine martial craft belt.',
				'Boosts combat skills.',
				'Type: Belt'
			},
			['sanguinebeltdeepbiting'] = {
				'Sanguine deep biting belt.',
				'Enhances critical hits.',
				'Type: Belt'
			},
			['sanguinebeltbalancedarmor'] = {
				'Sanguine balanced armor belt.',
				'Balanced protection and agility.',
				'Type: Belt'
			},
			['sanguinebelthewing'] = {
				'Sanguine wing belt.',
				'Enhances evasiveness.',
				'Type: Belt'
			},
			['sanguinebeltsureflight'] = {
				'Sanguine sure flight belt.',
				'Improves dodging and evasion.',
				'Type: Belt'
			},
			['belt of heartfire'] = {
				'Belt infused with heartfire energy.',
				'Enhances vitality and resilience.',
				'Type: Belt'
			},
			['artifact_belt_of_heartfire'] = {
				'Rare artifact belt of heartfire.',
				'Powerful life-enhancing enchantment.',
				'Type: Belt'
			},
			['scamp slinker belt'] = {
				'Sneaky scamp slinker belt.',
				'Enhances stealth capabilities.',
				'Type: Belt'
			},
			['sarandas_belt'] = {
				'Sarandas clan belt.',
				'Traditional tribal accessory.',
				'Type: Belt'
			},
			['belt of the armor of god'] = {
				'Divine belt of godly armor.',
				'Provides superior protection.',
				'Type: Belt'
			},
			['peakstar_belt_unique'] = {
				'Unique Peakstar belt design.',
				'Rare and distinctive accessory.',
				'Type: Belt'
			},
			['brawlers_belt'] = {
				'Brawler’s rugged belt.',
				'Enhances close-quarters combat.',
				'Type: Belt'
			},
			['Belt of Northern Knuck Knuck'] = {
				'Northern Knuck Knuck belt.',
				'Tribal belt with combat enchantments.',
				'Type: Belt'
			},
			['Stendarran Belt'] = {
				'Stendarran clan belt.',
				'Symbol of clan loyalty and strength.',
				'Type: Belt'
			},
			['Linus_Iulus_Stendarran_Belt'] = {
				'Stendarran belt belonging to Linus Iulus.',
				'Personalized clan accessory.',
				'Type: Belt'
			},
			['belt_goval'] = {
				'Goval tribe belt design.',
				'Traditional utility belt with tribal patterns.',
				'Type: Belt'
			},
			['common_glove_left_01'] = {
				'Basic left glove.',
				'Provides minimal hand protection.',
				'Type: Left Glove'
			},
			['expensive_glove_left_01'] = {
				'Elegant left glove.',
				'Made of premium materials.',
				'Type: Left Glove'
			},
			['extravagant_glove_left_01'] = {
				'Ornate left glove with intricate designs.',
				'Exudes luxury and status.',
				'Type: Left Glove'
			},
			['aryongloveleft'] = {
				'Traditional left glove.',
				'Features subtle embroidery.',
				'Type: Left Glove'
			},
			['sanguinelglovesafekeeping'] = {
				'Left glove with blood-red hue.',
				'Designed for safekeeping rituals.',
				'Type: Left Glove'
			},
			['common_glove_l_moragtong'] = {
				'Simple left glove from Moragtong.',
				'Practical and durable.',
				'Type: Left Glove'
			},
			['common_glove_l_balmolagmer'] = {
				'Basic left glove from Balmolagmer.',
				'Commonly used in daily wear.',
				'Type: Left Glove'
			},
			['extravagant_glove_left_maur'] = {
				'Luxurious left glove from Maur.',
				'Adorned with precious stones.',
				'Type: Left Glove'
			},
			['black_blindfold_glove'] = {
				'Black left glove with blindfold design.',
				'Limits vision but enhances other senses.',
				'Type: Left Glove'
			},
			["Zenithar's_Warning"] = {
				"Sacred left glove bearing Zenithar's mark.",
				'Imbued with protective magic.',
				'Type: Left Glove'
			},
			['expensive_glove_left_ilmeni'] = {
				'Fine left glove crafted in Ilmeni.',
				'Exquisitely detailed.',
				'Type: Left Glove'
			},
			['bitter_hand'] = {
				'Left glove with a dark, foreboding aura.',
				'Linked to ancient curses.',
				'Type: Left Glove'
			},
			['Left_Hand_of_Zenithar_EN'] = {
				"Sacred left glove — Zenithar's blessing.",
				'Enhances strength and fortitude.',
				'Type: Left Glove'
			},
			['Left_Hand_of_Zenithar'] = {
				'Divine left glove of Zenithar.',
				'Grants blessings in battle.',
				'Type: Left Glove'
			},
			['BM_Nordic01_gloveL'] = {
				'Nordic-style left glove.',
				'Reinforced for combat use.',
				'Type: Left Glove'
			},
			['BM_Nordic02_gloveL'] = {
				'Second variant of Nordic left glove.',
				'Slightly more ornate than BM_Nordic01.',
				'Type: Left Glove'
			},
			['BM_Wool01_gloveL'] = {
				'Woolen left glove for cold weather.',
				'Keeps hands warm in chilly climates.',
				'Type: Left Glove'
			},
			['BM_Wool02_gloveL'] = {
				'Second woolen left glove variant.',
				'Thicker wool for extreme cold.',
				'Type: Left Glove'
			},
			['bm_black_glove_l_s'] = {
				'Sleek black left glove.',
				'Perfect for stealth operations.',
				'Type: Left Glove'
			},
			['common_pants_01_u'] = {
				'Basic common pants, variant U.',
				'Provides leg coverage.',
				'Type: Pants'
			},
			['common_pants_01_a'] = {
				'Basic common pants, variant A.',
				'Provides leg coverage.',
				'Type: Pants'
			},
			['common_pants_01_z'] = {
				'Basic common pants, variant Z.',
				'Provides leg coverage.',
				'Type: Pants'
			},
			['common_pants_01_e'] = {
				'Basic common pants, variant E.',
				'Provides leg coverage.',
				'Type: Pants'
			},
			['common_pants_02'] = {
				'Standard common pants.',
				'Provides leg coverage.',
				'Type: Pants'
			},
			['common_pants_03'] = {
				'Ordinary common pants.',
				'Provides leg coverage.',
				'Type: Pants'
			},
			['common_pants_04'] = {
				'Simple common pants.',
				'Provides leg coverage.',
				'Type: Pants'
			},
			['common_pants_05'] = {
				'Basic common pants, fifth variant.',
				'Provides leg coverage.',
				'Type: Pants'
			},
			['expensive_pants_01'] = {
				'Luxurious pants with fine stitching.',
				'Provides leg coverage with style.',
				'Type: Pants'
			},
			['expensive_pants_01_u'] = {
				'Expensive pants, variant U, finely crafted.',
				'Provides leg coverage with elegance.',
				'Type: Pants'
			},
			['expensive_pants_01_a'] = {
				'Expensive pants, variant A, exquisite design.',
				'Provides leg coverage with grace.',
				'Type: Pants'
			},
			['expensive_pants_01_z'] = {
				'Expensive pants, variant Z, premium material.',
				'Provides leg coverage with luxury.',
				'Type: Pants'
			},
			['expensive_pants_01_e'] = {
				'Expensive pants, variant E, refined look.',
				'Provides leg coverage with sophistication.',
				'Type: Pants'
			},
			['expensive_pants_02'] = {
				'High-quality expensive pants.',
				'Provides leg coverage with refinement.',
				'Type: Pants'
			},
			['expensive_pants_03'] = {
				'Luxurious expensive pants, third variant.',
				'Provides leg coverage with opulence.',
				'Type: Pants'
			},
			['extravagant_pants_01'] = {
				'Extravagant pants with ornate details.',
				'Provides leg coverage with grandeur.',
				'Type: Pants'
			},
			['extravagant_pants_02'] = {
				'Opulent extravagant pants, second variant.',
				'Provides leg coverage with lavish design.',
				'Type: Pants'
			},
			['exquisite_pants_01'] = {
				'Exquisite pants with delicate embroidery.',
				'Provides leg coverage with elegance.',
				'Type: Pants'
			},
			['common_pants_03_b'] = {
				'Common pants, variant B of third model.',
				'Provides leg coverage, basic design.',
				'Type: Pants'
			},
			['common_pants_01'] = {
				'Basic common pants, primary variant.',
				'Provides leg coverage, standard fit.',
				'Type: Pants'
			},
			['common_pants_04_b'] = {
				'Common pants, variant B of fourth model.',
				'Provides leg coverage, utilitarian design.',
				'Type: Pants'
			},
			['common_pants_02_hentus'] = {
				'Common pants with Hentus pattern.',
				'Provides leg coverage with unique design.',
				'Type: Pants'
			},
			['common_pants_03_c'] = {
				'Common pants, variant C of third model.',
				'Provides leg coverage, practical style.',
				'Type: Pants'
			},
			['sarandas_pants_2'] = {
				'Sarandas-style pants, second variant.',
				'Provides leg coverage with tribal aesthetic.',
				'Type: Pants'
			},
			['peakstar_pants_unique'] = {
				'Unique Peakstar pants with special design.',
				'Provides leg coverage with distinctive style.',
				'Type: Pants'
			},
			['Caius_pants'] = {
				'Pants belonging to Caius, unique design.',
				'Provides leg coverage with personalized touch.',
				'Type: Pants'
			},
			['tailored_trousers'] = {
				'Tailored trousers with precise fit.',
				'Provides leg coverage with refined cut.',
				'Type: Pants'
			},
			['Expensive_pants_Mournhold'] = {
				'Expensive pants from Mournhold, fine craftsmanship.',
				'Provides leg coverage with regional elegance.',
				'Type: Pants'
			},
			['common_pants_06'] = {
				'Common pants, sixth model.',
				'Provides leg coverage, everyday use.',
				'Type: Pants'
			},
			['common_pants_07'] = {
				'Common pants, seventh model.',
				'Provides leg coverage, basic functionality.',
				'Type: Pants'
			},
			['BM_Nordic01_pants'] = {
				'Nordic-style pants, first variant by BM.',
				'Provides leg coverage with northern durability.',
				'Type: Pants'
			},
			['BM_Nordic02_pants'] = {
				'Nordic-style pants, second variant by BM.',
				'Provides leg coverage with rugged design.',
				'Type: Pants'
			},
			['BM_Wool01_pants'] = {
				'Woolen pants, first variant by BM.',
				'Provides leg coverage with warmth.',
				'Type: Pants'
			},
			['BM_Wool02_pants'] = {
				'Woolen pants, second variant by BM.',
				'Provides leg coverage with cozy feel.',
				'Type: Pants'
			},
			['common_glove_right_01'] = {
				'Basic right glove.',
				'Provides minimal hand protection.',
				'Type: Right Glove'
			},
			['expensive_glove_right_01'] = {
				'Elegant right glove.',
				'Offers superior hand protection.',
				'Type: Right Glove'
			},
			['extravagant_glove_right_01'] = {
				'Ornate right glove with intricate designs.',
				'Provides luxurious hand coverage.',
				'Type: Right Glove'
			},
			['aryongloveright'] = {
				'Simple right glove, well-worn.',
				'Basic hand protection for everyday use.',
				'Type: Right Glove'
			},
			['extravagant_rt_art_wild'] = {
				'Wild-patterned right glove, elaborately decorated.',
				'Offers stylish and protective handwear.',
				'Type: Right Glove'
			},
			['sanguinerglovehornyfist'] = {
				'Right glove with horned fist design.',
				'Provides aggressive-looking hand protection.',
				'Type: Right Glove'
			},
			['sanguinergloveswiftblade'] = {
				'Swiftblade-styled right glove.',
				'Designed for quick movements and protection.',
				'Type: Right Glove'
			},
			['common_glove_r_moragtong'] = {
				'Common right glove, Moragtong style.',
				'Basic hand coverage, practical design.',
				'Type: Right Glove'
			},
			['common_glove_r_balmolagmer'] = {
				'Common right glove, Balmolagmer variant.',
				'Simple yet functional hand protection.',
				'Type: Right Glove'
			},
			['extravagant_glove_right_maur'] = {
				'Maur-style extravagant right glove.',
				'Luxurious handwear with detailed embroidery.',
				'Type: Right Glove'
			},
			["Zenithar's_Wiles"] = {
				"Right glove imbued with Zenithar's cunning.",
				'Offers both protection and subtle magical benefits.',
				'Type: Right Glove'
			},
			['ember_hand'] = {
				'Right glove with ember-infused material.',
				'Provides warmth and minor fire resistance.',
				'Type: Right Glove'
			},
			['Right_Hand_of_Zenithar'] = {
				'Sacred right glove, blessed by Zenithar.',
				'Offers divine protection and strength.',
				'Type: Right Glove'
			},
			['ember hand'] = {
				'Right glove crafted from ember material.',
				'Offers heat resistance and durability.',
				'Type: Right Glove'
			},
			['BM_Nordic01_gloveR'] = {
				'Nordic-style right glove, design 01.',
				'Sturdy hand protection, inspired by Nordic warriors.',
				'Type: Right Glove'
			},
			['BM_Nordic02_gloveR'] = {
				'Nordic-style right glove, variant 02.',
				'Durable handwear with Nordic craftsmanship.',
				'Type: Right Glove'
			},
			['BM_Wool01_gloveR'] = {
				'Woolen right glove, model 01.',
				'Soft and warm hand protection.',
				'Type: Right Glove'
			},
			['BM_Wool02_gloveR'] = {
				'Woolen right glove, version 02.',
				'Comfortable handwear made of fine wool.',
				'Type: Right Glove'
			},
			['bm_black_glove_r_s'] = {
				'Black right glove with sleek design.',
				'Provides stealthy hand protection.',
				'Type: Right Glove'
			},
			['templar skirt obj'] = {
				'Skirt worn by templar order members.',
				'Provides modest lower body coverage.',
				'Type: Skirt'
			},
			['common_skirt_02'] = {
				'Basic skirt for everyday wear.',
				'Simple design, no frills.',
				'Type: Skirt'
			},
			['common_skirt_03'] = {
				'Common skirt with subtle pattern.',
				'Practical and unassuming.',
				'Type: Skirt'
			},
			['common_skirt_04'] = {
				'Ordinary skirt for daily use.',
				'Functional and plain.',
				'Type: Skirt'
			},
			['common_skirt_05'] = {
				'Simple skirt, widely available.',
				'No embellishments, pure utility.',
				'Type: Skirt'
			},
			['expensive_skirt_01'] = {
				'Elegant skirt with fine embroidery.',
				'Made of premium fabric.',
				'Type: Skirt'
			},
			['expensive_skirt_02'] = {
				'Luxurious skirt with intricate design.',
				'High-quality material, refined look.',
				'Type: Skirt'
			},
			['expensive_skirt_03'] = {
				'Costly skirt featuring delicate lace.',
				'Exquisite craftsmanship.',
				'Type: Skirt'
			},
			['extravagant_skirt_01'] = {
				'Opulent skirt with ornate details.',
				'Showcases wealth and status.',
				'Type: Skirt'
			},
			['extravagant_skirt_02'] = {
				'Grand skirt adorned with jewels.',
				'Designed for special occasions.',
				'Type: Skirt'
			},
			['exquisite_skirt_01'] = {
				'Fine skirt with artistic stitching.',
				'A masterpiece of tailoring.',
				'Type: Skirt'
			},
			['imperial skirt_clothing'] = {
				'Imperial-style skirt with regal cut.',
				'Symbolizes nobility and power.',
				'Type: Skirt'
			},
			['common_skirt_01'] = {
				'Basic skirt, commonly found.',
				'Unadorned and straightforward.',
				'Type: Skirt'
			},
			['common_skirt_04_c'] = {
				'Standard skirt with minimal design.',
				'Versatile and practical.',
				'Type: Skirt'
			},
			["therana's skirt"] = {
				'Skirt belonging to Therana.',
				'Personal item with unique style.',
				'Type: Skirt'
			},
			['Maras_Skirt'] = {
				'Skirt named after Maras.',
				'Distinctive design, culturally significant.',
				'Type: Skirt'
			},
			['common_skirt_06'] = {
				'Another simple skirt for common use.',
				'Unremarkable but serviceable.',
				'Type: Skirt'
			},
			['common_skirt_07'] = {
				'Plain skirt, nothing special.',
				'Perfect for mundane tasks.',
				'Type: Skirt'
			},
			['expensive_skirt_04'] = {
				'High-end skirt with elaborate pattern.',
				'Crafted for discerning tastes.',
				'Type: Skirt'
			},
			['expensive_skirt_Mournhold'] = {
				'Luxurious skirt from Mournhold.',
				"Reflects the city's elegance.",
				'Type: Skirt'
			},
			['common_shoes_01'] = {
				'Basic pair of common shoes.',
				'Provides standard foot protection.',
				'Type: Shoes'
			},
			['common_shoes_02'] = {
				'Another variant of common shoes.',
				'Simple design, durable material.',
				'Type: Shoes'
			},
			['common_shoes_03'] = {
				'Everyday shoes for casual wear.',
				'Basic foot coverage, no frills.',
				'Type: Shoes'
			},
			['common_shoes_04'] = {
				'Common shoes with minimal embellishment.',
				'Practical for daily use.',
				'Type: Shoes'
			},
			['common_shoes_05'] = {
				'Standard pair of common shoes.',
				'Reliable foot protection.',
				'Type: Shoes'
			},
			['expensive_shoes_01'] = {
				'Elegant shoes made of fine leather.',
				'Exudes luxury and status.',
				'Type: Shoes'
			},
			['expensive_shoes_02'] = {
				'Luxurious shoes with intricate stitching.',
				'A symbol of wealth and taste.',
				'Type: Shoes'
			},
			['expensive_shoes_03'] = {
				'High-end shoes with gold accents.',
				'Crafted for the affluent.',
				'Type: Shoes'
			},
			['extravagant_shoes_01'] = {
				'Over-the-top shoes with gemstone details.',
				'Designed to impress and dazzle.',
				'Type: Shoes'
			},
			['extravagant_shoes_02'] = {
				'Flashy shoes with ornate patterns.',
				'Perfect for grand occasions.',
				'Type: Shoes'
			},
			['exquisite_shoes_01'] = {
				'Delicate shoes with fine craftsmanship.',
				'A masterpiece of shoemaking art.',
				'Type: Shoes'
			},
			['shoes of st. rilms'] = {
				'Sacred shoes blessed by St. Rilms.',
				'Imbued with holy protection.',
				'Type: Shoes'
			},
			['sanguineshoesstalking'] = {
				'Mysterious shoes whispering ancient tales.',
				'Rumored to enhance speech skills.',
				'Type: Shoes'
			},
			['sanguineshoesleaping'] = {
				'Enchanted shoes that aid in leaping.',
				'Grant increased jumping ability.',
				'Type: Shoes'
			},
			['sarandas_shoes_2'] = {
				'Traditional shoes from Sarandas region.',
				'Handcrafted with local techniques.',
				'Type: Shoes'
			},
			['Shoes_of_Conviction'] = {
				'Shoes infused with unwavering resolve.',
				"Boosts the wearer's willpower.",
				'Type: Shoes'
			},
			['slippers_of_doom'] = {
				'Ominous slippers with dark enchantments.',
				'Carry a foreboding aura.',
				'Type: Shoes'
			},
			['common_shoes_02_surefeet'] = {
				'Common shoes with stability enchantment.',
				'Prevents tripping on rough terrain.',
				'Type: Shoes'
			},
			['Expensive_shoes_Mournhold'] = {
				'Fine shoes crafted in Mournhold.',
				"Reflect the city's refined style.",
				'Type: Shoes'
			},
			['common_shoes_06'] = {
				'Additional variant of common shoes.',
				'Versatile for any everyday task.',
				'Type: Shoes'
			},
			['common_shoes_07'] = {
				'Yet another pair of common shoes.',
				'Unassuming but reliable footwear.',
				'Type: Shoes'
			},
			['BM_Nordic01_shoes'] = {
				'Nordic-style shoes with fur lining.',
				'Designed for cold climates.',
				'Type: Shoes'
			},
			['BM_Nordic02_shoes'] = {
				'Second variant of Nordic shoes.',
				'Enhanced insulation against the cold.',
				'Type: Shoes'
			},
			['BM_Wool01_shoes'] = {
				'Woolen shoes for comfort and warmth.',
				'Soft interior, durable exterior.',
				'Type: Shoes'
			},
			['BM_Wool02_shoes'] = {
				'Second woolen shoe variant.',
				'Ideal for chilly weather.',
				'Type: Shoes'
			},
			['common_shirt_02'] = {
				'Basic common shirt.',
				'Simple design, everyday wear.',
				'Type: Shirt'
			},
			['common_shirt_03'] = {
				'Another variant of a common shirt.',
				'Practical and unassuming.',
				'Type: Shirt'
			},
			['common_shirt_04'] = {
				'Common shirt with subtle pattern.',
				'Perfect for daily use.',
				'Type: Shirt'
			},
			['common_shirt_05'] = {
				'Simple common shirt in neutral tone.',
				'Comfortable and durable.',
				'Type: Shirt'
			},
			['expensive_shirt_01'] = {
				'Elegant shirt made of fine fabric.',
				'Exudes luxury and status.',
				'Type: Shirt'
			},
			['expensive_shirt_02'] = {
				'Expensive shirt with intricate embroidery.',
				'A symbol of wealth.',
				'Type: Shirt'
			},
			['expensive_shirt_03'] = {
				'Luxurious shirt with delicate details.',
				'Designed for special occasions.',
				'Type: Shirt'
			},
			['extravagant_shirt_01'] = {
				'Extravagant shirt with bold design.',
				'Turns heads and makes a statement.',
				'Type: Shirt'
			},
			['extravagant_shirt_02'] = {
				'Over-the-top shirt with ornate patterns.',
				'For those who love attention.',
				'Type: Shirt'
			},
			['exquisite_shirt_01'] = {
				'Exquisite shirt crafted with care.',
				'Combines elegance and comfort.',
				'Type: Shirt'
			},
			['common_shirt_01_u'] = {
				'Common shirt with unique cut.',
				'Functional and stylish.',
				'Type: Shirt'
			},
			['common_shirt_01_z'] = {
				'Basic shirt with zigzag stitching.',
				'Simple yet practical.',
				'Type: Shirt'
			},
			['common_shirt_01_a'] = {
				'Affordable shirt in classic style.',
				'Ideal for everyday wear.',
				'Type: Shirt'
			},
			['common_shirt_01_e'] = {
				'Everyday shirt with elastic waistband.',
				'Comfort is a priority.',
				'Type: Shirt'
			},
			['common_shirt_02_r'] = {
				'Common shirt with red accents.',
				'Adds a pop of color to any outfit.',
				'Type: Shirt'
			},
			['common_shirt_02_h'] = {
				'Simple shirt with hidden pockets.',
				'Convenient for carrying small items.',
				'Type: Shirt'
			},
			['common_shirt_02_t'] = {
				'Thin common shirt for warm weather.',
				'Lightweight and breathable.',
				'Type: Shirt'
			},
			['common_shirt_03_b'] = {
				'Common shirt in dark blue shade.',
				'Versatile and understated.',
				'Type: Shirt'
			},
			['expensive_shirt_01_u'] = {
				'Upscale shirt with unique fabric.',
				'Feels luxurious against the skin.',
				'Type: Shirt'
			},
			['expensive_shirt_01_a'] = {
				'Expensive shirt with artistic design.',
				'A work of wearable art.',
				'Type: Shirt'
			},
			['expensive_shirt_01_z'] = {
				'Zesty expensive shirt with zebra print.',
				'Bold and fashionable.',
				'Type: Shirt'
			},
			['expensive_shirt_01_e'] = {
				'Elegant expensive shirt with embellishments.',
				'Perfect for formal events.',
				'Type: Shirt'
			},
			['extravagant_shirt_01_r'] = {
				'Red extravagant shirt with royal motifs.',
				'Commands respect and admiration.',
				'Type: Shirt'
			},
			['extravagant_shirt_01_h'] = {
				'Heavy extravagant shirt with heraldic symbols.',
				'Signifies high status.',
				'Type: Shirt'
			},
			['extravagant_shirt_01_t'] = {
				'Trendy extravagant shirt with tassels.',
				'Adds flair to any ensemble.',
				'Type: Shirt'
			},
			['common_shirt_01'] = {
				'Standard common shirt.',
				'No-frills, just comfort.',
				'Type: Shirt'
			},
			['common_shirt_04_a'] = {
				'Common shirt with additional pockets.',
				'Practical for adventurers.',
				'Type: Shirt'
			},
			['common_shirt_04_b'] = {
				'Basic common shirt in black.',
				'Classic and timeless.',
				'Type: Shirt'
			},
			['common_shirt_04_c'] = {
				'Common shirt with checkered pattern.',
				'Casual and relaxed look.',
				'Type: Shirt'
			},
			['expensive_shirt_hair'] = {
				'Expensive shirt with hair-like texture.',
				'Unique tactile experience.',
				'Type: Shirt'
			},
			['common_shirt_02_hh'] = {
				'Common shirt with hidden hood.',
				'Useful in windy weather.',
				'Type: Shirt'
			},
			['common_shirt_02_rr'] = {
				'Reinforced common shirt.',
				'Durable for rough conditions.',
				'Type: Shirt'
			},
			['common_shirt_02_tt'] = {
				'Thick common shirt for cold days.',
				'Provides warmth and comfort.',
				'Type: Shirt'
			},
			['exquisite_shirt_01_wedding'] = {
				'Exquisite shirt for wedding ceremonies.',
				'Fine craftsmanship and detail.',
				'Type: Shirt'
			},
			['common_shirt_03_c'] = {
				'Common shirt in casual cut.',
				'Relaxed fit for comfort.',
				'Type: Shirt'
			},
			['exquisite_shirt_01_rasha'] = {
				'Exquisite shirt inspired by Rasha style.',
				'Combines tradition and elegance.',
				'Type: Shirt'
			},
			['sarandas_shirt_2'] = {
				'Sarandas-style shirt with traditional motifs.',
				'Reflects cultural heritage.',
				'Type: Shirt'
			},
			['Zenithar_Frock'] = {
				'Frock in Zenithar style.',
				'Symbolizes devotion and piety.',
				'Type: Shirt'
			},
			['caius_shirt'] = {
				'Shirt named after Caius.',
				'Classic design with a touch of nobility.',
				'Type: Shirt'
			},
			['Restoration_Shirt'] = {
				'Shirt associated with Restoration era.',
				'Historical and refined.',
				'Type: Shirt'
			},
			['Maras_Blouse'] = {
				'Blouse in Maras style.',
				'Light and airy design.',
				'Type: Shirt'
			},
			['common_shirt_gondolier'] = {
				'Common shirt worn by gondoliers.',
				'Practical for water-based activities.',
				'Type: Shirt'
			},
			['Expensive_shirt_Mournhold'] = {
				'Expensive shirt from Mournhold region.',
				'High-quality materials and craftsmanship.',
				'Type: Shirt'
			},
			['common_shirt_06'] = {
				'Sixth variant of common shirt.',
				'Unassuming and reliable.',
				'Type: Shirt'
			},
			['common_shirt_07'] = {
				'Seventh common shirt design.',
				'Simple and functional.',
				'Type: Shirt'
			},
			['BM_Nordic01_shirt'] = {
				'Nordic-style shirt, first variant.',
				'Rugged and durable.',
				'Type: Shirt'
			},
			['BM_Nordic02_shirt'] = {
				'Second Nordic-style shirt.',
				'Enhanced insulation for cold climates.',
				'Type: Shirt'
			},
			['BM_Wool01_shirt'] = {
				'Wool shirt, first design.',
				'Warm and cozy.',
				'Type: Shirt'
			},
			['BM_Wool02_shirt'] = {
				'Second wool shirt variant.',
				'Soft wool with subtle pattern.',
				'Type: Shirt'
			},
			['common_robe_02'] = {
				'Basic common robe.',
				'Provides minimal protection.',
				'Type: Robe'
			},
			['common_robe_02_r'] = {
				'Common robe with red accents.',
				'Simple design, everyday wear.',
				'Type: Robe'
			},
			['common_robe_02_h'] = {
				'Common robe in grey-brown hue.',
				'Practical for daily use.',
				'Type: Robe'
			},
			['common_robe_02_t'] = {
				'Common robe with subtle pattern.',
				'Comfortable and unobtrusive.',
				'Type: Robe'
			},
			['common_robe_03'] = {
				'Another variant of common robe.',
				'Basic protection, no frills.',
				'Type: Robe'
			},
			['common_robe_03_a'] = {
				'Common robe with additional stitching.',
				'Slightly enhanced durability.',
				'Type: Robe'
			},
			['common_robe_03_b'] = {
				'Common robe in darker shade.',
				'Perfect for discreet wear.',
				'Type: Robe'
			},
			['common_robe_04'] = {
				'Simple common robe, basic model.',
				'Essential garment for travelers.',
				'Type: Robe'
			},
			['common_robe_05'] = {
				'Enhanced common robe design.',
				'Slightly better protection.',
				'Type: Robe'
			},
			['common_robe_05_a'] = {
				'Common robe with refined cut.',
				'Improved fit and comfort.',
				'Type: Robe'
			},
			['common_robe_05_b'] = {
				'Common robe with decorative edge.',
				'Adds a touch of style.',
				'Type: Robe'
			},
			['common_robe_05_c'] = {
				'Common robe in muted tones.',
				'Versatile and understated.',
				'Type: Robe'
			},
			['expensive_robe_01'] = {
				'Fine robe made of premium fabric.',
				'Exudes wealth and status.',
				'Type: Robe'
			},
			['expensive_robe_02'] = {
				'Luxurious robe with intricate weave.',
				'Designed for the affluent.',
				'Type: Robe'
			},
			['expensive_robe_02_a'] = {
				'Expensive robe with silver trim.',
				'Elegant and sophisticated.',
				'Type: Robe'
			},
			['expensive_robe_03'] = {
				'High-end robe with detailed embroidery.',
				'A symbol of high status.',
				'Type: Robe'
			},
			['extravagant_robe_01'] = {
				'Opulent robe with lavish decorations.',
				'Truly eye-catching garment.',
				'Type: Robe'
			},
			['extravagant_robe_01_a'] = {
				'Extravagant robe in rich purple.',
				'Royalty-inspired design.',
				'Type: Robe'
			},
			['extravagant_robe_01_b'] = {
				'Extravagant robe with gold accents.',
				'Exudes power and authority.',
				'Type: Robe'
			},
			['extravagant_robe_01_c'] = {
				'Extravagant robe with pearl details.',
				'Unmatched luxury and grace.',
				'Type: Robe'
			},
			['extravagant_robe_01_r'] = {
				'Extravagant robe in deep red.',
				'Bold and commanding presence.',
				'Type: Robe'
			},
			['extravagant_robe_01_h'] = {
				'Extravagant robe with heraldic motifs.',
				'Signifies noble lineage.',
				'Type: Robe'
			},
			['extravagant_robe_01_t'] = {
				'Extravagant robe in turquoise.',
				'Unique and striking design.',
				'Type: Robe'
			},
			['extravagant_robe_02'] = {
				'Second variant of extravagant robe.',
				'Even more luxurious than the first.',
				'Type: Robe'
			},
			['exquisite_robe_01'] = {
				'Exquisitely crafted robe.',
				'Masterpiece of tailoring art.',
				'Type: Robe'
			},
			['common_robe_01'] = {
				'Most basic common robe model.',
				'Essential for any traveler.',
				'Type: Robe'
			},
			['robe of st roris'] = {
				'Robe blessed by St. Roris.',
				'Imbued with holy energy.',
				'Type: Robe'
			},
			['Extravagant_Robe_01_Red'] = {
				'Red extravagant robe with gemstones.',
				'Symbol of royal bloodline.',
				'Type: Robe'
			},
			['flameguard robe'] = {
				'Robe protecting from fire damage.',
				'Essential for fire mages.',
				'Type: Robe'
			},
			['frostguard robe'] = {
				'Robe offering cold resistance.',
				'Perfect for ice magic users.',
				'Type: Robe'
			},
			['shockguard robe'] = {
				'Robe shielding from electrical shocks.',
				'Useful for shock magic practitioners.',
				'Type: Robe'
			},
			['magickguard robe'] = {
				'Robe enhancing magical resistance.',
				'Protects against spell damage.',
				'Type: Robe'
			},
			['poisonguard robe'] = {
				'Robe providing poison resistance.',
				'Safeguards against toxic effects.',
				'Type: Robe'
			},
			['robe of burdens'] = {
				'Robe carrying hidden weight.',
				'May slow down the wearer.',
				'Type: Robe'
			},
			['weeping robe'] = {
				'Mysterious robe with damp fabric.',
				'Associated with ancient curses.',
				'Type: Robe'
			},
			["veloth's robe"] = {
				"Robe inspired by Veloth's teachings.",
				'Carries spiritual significance.',
				'Type: Robe'
			},
			['robe of trials'] = {
				'Robe tested by time and battles.',
				'Bears marks of past adventures.',
				'Type: Robe'
			},
			['flamemirror robe'] = {
				'Robe reflecting fire spells back.',
				'Clever defense mechanism.',
				'Type: Robe'
			},
			['frostmirror robe'] = {
				'Robe mirroring cold spells.',
				'Turns enemy magic against them.',
				'Type: Robe'
			},
			['shockmirror robe'] = {
				'Robe reflecting electrical attacks.',
				'Protects with cunning design.',
				'Type: Robe'
			},
			['poisonmirror robe'] = {
				'Robe deflecting poison spells.',
				'Safeguards with toxic rebound.',
				'Type: Robe'
			},
			['flameeater robe'] = {
				'Robe absorbing fire damage.',
				'Turns heat into strength.',
				'Type: Robe'
			},
			['frosteater robe'] = {
				'Robe consuming cold energy.',
				'Transforms chill into power.',
				'Type: Robe'
			},
			['shockeater robe'] = {
				'Robe feeding on electrical energy.',
				'Converts shocks into vitality.',
				'Type: Robe'
			},
			['poisoneater robe'] = {
				'Robe neutralizing poison.',
				'Turns toxicity into resilience.',
				'Type: Robe'
			},
			['common_robe_02_hh'] = {
				'Common robe with heavy hem.',
				'Sturdy and practical design.',
				'Type: Robe'
			},
			['common_robe_02_rr'] = {
				'Common robe with reinforced ribs.',
				'Enhanced structural support.',
				'Type: Robe'
			},
			['common_robe_02_tt'] = {
				'Common robe with twin ties.',
				'Adjustable fit for comfort.',
				'Type: Robe'
			},
			["exquisite_robe_drake's pride"] = {
				'Exquisite robe adorned with dragon motifs.',
				'Symbolizes strength and nobility.',
				'Type: Robe'
			},
			['hortatorrobe'] = {
				'Robe worn by hortators in rituals.',
				'Imbued with ceremonial power.',
				'Type: Robe'
			},
			['robe_of_erur_dan'] = {
				'Ancient robe linked to Erur Dan lineage.',
				'Carries ancestral blessings.',
				'Type: Robe'
			},
			['hort_ledd_robe_unique'] = {
				'Unique robe crafted for Hort Ledd.',
				'Features personalized embroidery.',
				'Type: Robe'
			},
			["Adusamsi's_robe"] = {
				'Robe belonging to the sage Adusamsi.',
				'Infused with scholarly aura.',
				'Type: Robe'
			},
			['extravagant_robe_02_elanande'] = {
				'Second extravagant robe variant with Elanande pattern.',
				'Luxurious and intricately designed.',
				'Type: Robe'
			},
			['Helseth’s Robe'] = {
				'Regal robe once worn by King Helseth.',
				'Signifies royal authority.',
				'Type: Robe'
			},
			['robe_lich_unique'] = {
				'Unique robe imbued with lich magic.',
				'Exudes an eerie, undead energy.',
				'Type: Robe'
			},
			['robe_lich_unique_x'] = {
				'Enhanced version of lich robe.',
				'Possesses additional dark powers.',
				'Type: Robe'
			},
			['common_robe_EOT'] = {
				'Common robe designed for EOT faction.',
				'Simple yet functional attire.',
				'Type: Robe'
			},
			['mantle of woe'] = {
				'Mantle draped in sorrow and grief.',
				'Associated with mourning rituals.',
				'Type: Robe'
			},
			['WerewolfRobe'] = {
				'Robe tailored for werewolf form.',
				'Sturdy fabric resists transformations.',
				'Type: Robe'
			},
			['BM_Nordic01_Robe'] = {
				'Nordic-style robe with traditional patterns.',
				'Reflects northern heritage.',
				'Type: Robe'
			},
			['common_robe_unique'] = {
				'Unique variant of common robe.',
				'Slight design отличия make it special.',
				'Type: Robe'
			},
			['BM_Wool01_Robe'] = {
				'Woolen robe providing warmth.',
				'Ideal for cold climates.',
				'Type: Robe'
			},
			['BM_Nordic01_Robe_whitewalk'] = {
				'Nordic robe in whitewalk design.',
				'Light and agile for snowy terrain.',
				'Type: Robe'
			},
			['common_ring_01'] = {
				'A basic common ring.',
				'Provides no special effects.',
				'Type: Ring'
			},
			['common_ring_02'] = {
				'Another variant of a common ring.',
				'No enchantments or bonuses.',
				'Type: Ring'
			},
			['common_ring_03'] = {
				'Simple common ring with no special properties.',
				'Basic piece of jewelry.',
				'Type: Ring'
			},
			['common_ring_04'] = {
				'Ordinary common ring.',
				'Does not offer any bonuses.',
				'Type: Ring'
			},
			['common_ring_05'] = {
				'Yet another common ring variant.',
				'Plain and unenchanted.',
				'Type: Ring'
			},
			['expensive_ring_01'] = {
				'An expensive ring with subtle craftsmanship.',
				'May have hidden magical properties.',
				'Type: Ring'
			},
			['expensive_ring_02'] = {
				'Expensive ring with intricate design.',
				'Could provide minor bonuses.',
				'Type: Ring'
			},
			['expensive_ring_03'] = {
				'Fine expensive ring.',
				'Crafted with care and magic in mind.',
				'Type: Ring'
			},
			['extravagant_ring_01'] = {
				'Extravagant ring with luxurious design.',
				'Likely to have powerful enchantments.',
				'Type: Ring'
			},
			['extravagant_ring_02'] = {
				'Opulent extravagant ring.',
				'Exudes power and status.',
				'Type: Ring'
			},
			['exquisite_ring_02'] = {
				'Exquisite ring with delicate craftsmanship.',
				'May grant unique abilities.',
				'Type: Ring'
			},
			['othril_ring'] = {
				'Mysterious Othril ring.',
				'Possesses unknown magical properties.',
				'Type: Ring'
			},
			['first barrier ring'] = {
				'Ring providing initial barrier protection.',
				'Offers basic defensive enchantment.',
				'Type: Ring'
			},
			['life ring'] = {
				'Ring imbued with life energy.',
				'May restore health or offer vitality bonuses.',
				'Type: Ring'
			},
			['blind ring'] = {
				'Ring with blindness-related enchantment.',
				'Could affect visibility or perception.',
				'Type: Ring'
			},
			['hawkshaw ring'] = {
				'Hawkshaw ring with hunting-related properties.',
				'Might enhance stealth or agility.',
				'Type: Ring'
			},
			['chameleon ring'] = {
				'Chameleon ring for stealth.',
				'Increases invisibility or blending with environment.',
				'Type: Ring'
			},
			["ondusi's key"] = {
				"Ondusi's key ring — a special key item.",
				'May open specific locks or portals.',
				'Type: Ring'
			},
			['distraction ring'] = {
				'Ring causing distraction to enemies.',
				'Useful in combat for disorienting foes.',
				'Type: Ring'
			},
			["mother's ring"] = {
				"Sentimental mother's ring.",
				'Could have protective enchantments.',
				'Type: Ring'
			},
			["fenrick's doorjam ring"] = {
				"Fenrick's doorjam ring with locking properties.",
				'Might be used to secure or open doors.',
				'Type: Ring'
			},
			['ring of fleabite'] = {
				'Ring inflicting fleabite effect on enemies.',
				'Causes irritation or damage over time.',
				'Type: Ring'
			},
			['flamebolt ring'] = {
				'Ring launching flamebolts.',
				'Deals fire damage to targets.',
				'Type: Ring'
			},
			['sparkbolt ring'] = {
				'Sparkbolt ring with electric attacks.',
				'Emits electric shocks.',
				'Type: Ring'
			},
			['shardbolt ring'] = {
				'Shardbolt ring firing shards.',
				'Launches sharp projectiles.',
				'Type: Ring'
			},
			['viperbolt ring'] = {
				'Viperbolt ring with poisonous projectiles.',
				'Shoots venomous darts.',
				'Type: Ring'
			},
			['caliginy ring'] = {
				'Caliginy ring shrouding in darkness.',
				'Creates shadow or concealment effect.',
				'Type: Ring'
			},
			['wild sty ring'] = {
				'Wild sty ring with unpredictable effects.',
				'Causes random magical outcomes.',
				'Type: Ring'
			},
			['ring of shadow form'] = {
				'Ring transforming into shadow form.',
				'Allows stealthy movement and invisibility.',
				'Type: Ring'
			},
			['hoptoad ring'] = {
				'Hoptoad ring with amphibian-like abilities.',
				'Might enhance jumping or water breathing.',
				'Type: Ring'
			},
			['juicedaw ring'] = {
				'Juicedaw ring with bird-related powers.',
				'Could grant flight or enhanced vision.',
				'Type: Ring'
			},
			['crying ring'] = {
				'Crying ring emitting sorrowful energy.',
				'Affects mood or inflicts debuffs.',
				'Type: Ring'
			},
			['sacrifice ring'] = {
				'Sacrifice ring with dark ritualistic power.',
				'May consume health for powerful effects.',
				'Type: Ring'
			},
			['witch charm'] = {
				'Witch charm ring with mystical allure.',
				'Enhances charisma or casting abilities.',
				'Type: Ring'
			},
			['heartbite ring'] = {
				'Heartbite ring inflicting emotional pain.',
				'Affects enemies morale or health.',
				'Type: Ring'
			},
			['cruel flamebolt ring'] = {
				'Cruel flamebolt ring with enhanced fire damage.',
				'Deals severe fire-based harm.',
				'Type: Ring'
			},
			['cruel shardbolt ring'] = {
				'Cruel shardbolt ring firing sharp, deadly projectiles.',
				'Inflicts piercing damage.',
				'Type: Ring'
			},
			['cruel sparkbolt ring'] = {
				'Cruel sparkbolt ring with intense electric shocks.',
				'Delivers powerful electric bursts.',
				'Type: Ring'
			},
			['cruel viperbolt ring'] = {
				'Cruel viperbolt ring launching lethal venom.',
				'Poisonous attacks with high damage.',
				'Type: Ring'
			},
			['ring of hornhand'] = {
				'Ring enhancing strength and durability.',
				'Boosts physical prowess.',
				'Type: Ring'
			},
			['ring of ironhand'] = {
				'Ironhand ring strengthening grip and defense.',
				'Increases melee damage and armor.',
				'Type: Ring'
			},
			['feather ring'] = {
				'Feather ring granting lightness and agility.',
				'Improves movement speed and evasion.',
				'Type: Ring'
			},
			['light ring'] = {
				'Light ring illuminating the surroundings.',
				'Provides light in dark areas.',
				'Type: Ring'
			},
			["ancestor's ring"] = {
				"Ancestor's ring connecting to ancestral power.",
				'Grants wisdom or protective blessings.',
				'Type: Ring'
			},
			['firestone'] = {
				'Firestone ring with elemental fire affinity.',
				'Enhances fire-based spells or resistance.',
				'Type: Ring'
			},
			['lifestone'] = {
				'Lifestone ring bonded to life energy.',
				'Restores health or grants vitality.',
				'Type: Ring'
			},
			['heartstone'] = {
				'Heartstone ring linked to emotional power.',
				'Affects willpower or morale.',
				'Type: Ring'
			},
			['second barrier ring'] = {
				'Second barrier ring offering enhanced protection.',
				'Provides stronger defensive enchantment.',
				'Type: Ring'
			},
			['ring of aversion'] = {
				'Ring of aversion repelling enemies.',
				'Creates repulsive force field.',
				'Type: Ring'
			},
			['eye-maze ring'] = {
				'Eye-maze ring confusing vision.',
				'Causes disorientation or blindness.',
				'Type: Ring'
			},
			['shadowmask ring'] = {
				'Shadowmask ring concealing presence.',
				'Enhances stealth and invisibility.',
				'Type: Ring'
			},
			['shadowweave ring'] = {
				'Shadowweave ring woven with dark magic.',
				'Enhances concealment and shadow manipulation.',
				'Type: Ring'
			},
			['Expensive_Ring_01_HRDT'] = {
				'Expensive ring with high-grade enchantments.',
				'Offers significant magical bonuses.',
				'Type: Ring'
			},
			['dire flamebolt ring'] = {
				'Dire flamebolt ring with devastating firepower.',
				'Inflicts massive fire damage on enemies.',
				'Type: Ring'
			},
			['dire shardbolt ring'] = {
				'Dire shardbolt ring launching lethal shards.',
				'Deals critical piercing damage.',
				'Type: Ring'
			},
			['dire sparkbolt ring'] = {
				'Dire sparkbolt ring unleashing fierce electric energy.',
				'Delivers powerful electric shocks.',
				'Type: Ring'
			},
			['dire viperbolt ring'] = {
				'Dire viperbolt ring spewing deadly venom.',
				'Poison attacks with extreme potency.',
				'Type: Ring'
			},
			['ring of knuckle luck'] = {
				'Ring of knuckle luck bringing fortune in combat.',
				'Increases critical hit chance or dodge rate.',
				'Type: Ring'
			},
			['ring of firefist'] = {
				'Ring of firefist igniting fists with flames.',
				'Enhances melee attacks with fire damage.',
				'Type: Ring'
			},
			['ring of icegrip'] = {
				'Ring of icegrip freezing enemies on touch.',
				'Applies chill or freeze effects to targets.',
				'Type: Ring'
			},
			['ring of stormhand'] = {
				'Ring of stormhand channeling elemental power.',
				'Summons lightning or storm effects in combat.',
				'Type: Ring'
			},
			['ring of the black hand'] = {
				'Ring of the black hand imbued with dark power.',
				'Grants shadow-based abilities or damage.',
				'Type: Ring'
			},
			['ring of the five fingers of pai'] = {
				'Ring of the five fingers of Pai with ancient power.',
				'Provides unique combat or magical bonuses.',
				'Type: Ring'
			},
			["st. felm's fire"] = {
				"St. Felm's fire ring with holy flame power.",
				'Deals holy fire damage to undead.',
				'Type: Ring'
			},
			['shame ring'] = {
				'Shame ring inflicting debuffs on enemies.',
				'Lowers enemy morale or stats.',
				'Type: Ring'
			},
			['ring of exhaustion'] = {
				'Ring of exhaustion draining energy from foes.',
				'Reduces stamina or health over time.',
				'Type: Ring'
			},
			['ring of fireballs'] = {
				'Ring of fireballs launching explosive fire orbs.',
				'Creates AoE fire damage.',
				'Type: Ring'
			},
			['spiritstrike ring'] = {
				'Spiritstrike ring channeling ethereal energy.',
				'Deals ghostly damage to enemies.',
				'Type: Ring'
			},
			['ring of ice bolts'] = {
				'Ring of ice bolts firing frozen projectiles.',
				'Inflicts cold damage and slows enemies.',
				'Type: Ring'
			},
			['ring of poisonblooms'] = {
				'Ring of poisonblooms releasing toxic spores.',
				'Applies poison damage over time.',
				'Type: Ring'
			},
			['ring of shockballs'] = {
				'Ring of shockballs unleashing electric orbs.',
				'Deals AoE electric damage.',
				'Type: Ring'
			},
			['ring of wounds'] = {
				'Ring of wounds inflicting bleeding effects.',
				'Causes health drain on hit.',
				'Type: Ring'
			},
			['third barrier ring'] = {
				'Third barrier ring providing advanced protection.',
				'Enhances defense with multiple layers.',
				'Type: Ring'
			},
			['ring of shocking touch'] = {
				'Ring of shocking touch electrifying touch attacks.',
				'Delivers electric damage on melee hits.',
				'Type: Ring'
			},
			["ring of vampire's kiss"] = {
				"Ring of vampire's kiss draining life on hit.",
				'Steals health from enemies.',
				'Type: Ring'
			},
			["ring of wizard's fire"] = {
				"Ring of wizard's fire summoning arcane flames.",
				'Enhances fire spells or deals magic fire damage.',
				'Type: Ring'
			},
			['ring of fireball'] = {
				'Ring of fireball casting explosive fireballs.',
				'Launches fire projectiles at enemies.',
				'Type: Ring'
			},
			['ring of ice storm'] = {
				'Ring of ice storm conjuring freezing winds.',
				'Creates AoE ice damage and chill effects.',
				'Type: Ring'
			},
			['ring of lightning bolt'] = {
				'Ring of lightning bolt unleashing electric strikes.',
				'Deals direct lightning damage.',
				'Type: Ring'
			},
			['ring of fire storm'] = {
				'Ring of fire storm summoning raging fire whirlwind.',
				'Creates widespread fire damage.',
				'Type: Ring'
			},
			['ring of lightning storm'] = {
				'Ring of lightning storm channeling electric fury.',
				'Generates AoE lightning damage.',
				'Type: Ring'
			},
			['ring of sphere of negation'] = {
				'Ring of sphere of negation creating protective barrier.',
				'Nullifies magic or physical attacks.',
				'Type: Ring'
			},
			['ring of toxic cloud'] = {
				'Ring of toxic cloud releasing poisonous fog.',
				'Applies poison damage in area.',
				'Type: Ring'
			},
			["ring of medusa's gaze"] = {
				"Ring of Medusa's gaze petrifying enemies.",
				'Turns foes to stone on gaze.',
				'Type: Ring'
			},
			['ring of wildfire'] = {
				'Ring of wildfire igniting surroundings.',
				'Spreads fire damage to nearby enemies.',
				'Type: Ring'
			},
			["warden's ring"] = {
				"Warden's ring enhancing guardianship abilities.",
				'Boosts defense and leadership skills.',
				'Type: Ring'
			},
			['ring of transfiguring wisdom'] = {
				'Ring of transfiguring wisdom granting insight.',
				'Enhances intelligence and spellcasting.',
				'Type: Ring'
			},
			['ring of transcendent wisdom'] = {
				'Ring of transcendent wisdom elevating mental power.',
				'Increases magic resistance and intellect.',
				'Type: Ring'
			},
			['ring_blackjinx_uniq'] = {
				'Unique blackjinx ring with cursed power.',
				'Inflicts misfortune on enemies or self.',
				'Type: Ring'
			},
			['ring_dahrkmezalf_uniq'] = {
				'Unique Dahrkmezalf ring with dark enchantments.',
				'Grants shadow or necromantic abilities.',
				'Type: Ring'
			},
			['exquisite_ring_01'] = {
				'Exquisite ring with refined craftsmanship.',
				'Offers subtle yet potent magical effects.',
				'Type: Ring'
			},
			['ring_keley'] = {
				"Kelley's ring with personalized enchantments.",
				'Provides unique bonuses based on wearer.',
				'Type: Ring'
			},
			['ring_equity_uniq'] = {
				'Unique equity ring balancing forces.',
				'Stabilizes stats or elements around wearer.',
				'Type: Ring'
			},
			['hortatorring'] = {
				'Hortator ring enhancing leadership and speech.',
				'Improves charisma and persuasion.',
				'Type: Ring'
			},
			['moon_and_star'] = {
				'Moon and Star ring with celestial power.',
				'Grants lunar or stellar magic bonuses.',
				'Type: Ring'
			},
			['sanguineringsublimew'] = {
				'Sublime sanguine ring with blood magic.',
				'Enhances vampire or blood-based abilities.',
				'Type: Ring'
			},
			['sanguineringgoldenw'] = {
				'Golden sanguine ring with noble blood enchantments.',
				'Provides status and health bonuses.',
				'Type: Ring'
			},
			['sanguineringsilverw'] = {
				'Silver sanguine ring with purified blood magic.',
				'Enhances healing or anti-undead powers.',
				'Type: Ring'
			},
			['sanguineringunseenw'] = {
				'Unseen sanguine ring with hidden blood magic.',
				'Grants stealth and dark life-draining powers.',
				'Type: Ring'
			},
			['sanguineringgreenw'] = {
				'Green sanguine ring with vitality enchantments.',
				'Enhances health regeneration and poison resistance.',
				'Type: Ring'
			},
			['sanguineringfluidevasion'] = {
				'Sanguine ring of fluid evasion with agile magic.',
				'Improves dodge chance and movement speed.',
				'Type: Ring'
			},
			['sanguineringtranscendw'] = {
				'Transcendent sanguine ring with elevated blood power.',
				'Boosts magical and physical potential.',
				'Type: Ring'
			},
			['sanguineringtransfigurw'] = {
				'Transfigurative sanguine ring altering form and essence.',
				'Allows minor shapeshifting or illusion effects.',
				'Type: Ring'
			},
			['sanguineringredw'] = {
				'Red sanguine ring with aggressive blood magic.',
				'Enhances damage output and berserk abilities.',
				'Type: Ring'
			},
			['blood ring'] = {
				'Blood ring channeling vital essence.',
				'Restores health or drains life from foes.',
				'Type: Ring'
			},
			['soul ring'] = {
				'Soul ring binding ethereal energy.',
				'Absorbs or manipulates souls for power.',
				'Type: Ring'
			},
			['heart ring'] = {
				'Heart ring resonating with emotional power.',
				'Enhances willpower or morale bonuses.',
				'Type: Ring'
			},
			['artifact_blood_ring'] = {
				'Artifact blood ring with ancient life magic.',
				'Provides superior health regeneration and dark powers.',
				'Type: Ring'
			},
			['artifact_soul_ring'] = {
				'Artifact soul ring harnessing spectral energy.',
				'Grants control over spirits and shadow magic.',
				'Type: Ring'
			},
			['artifact_heart_ring'] = {
				'Artifact heart ring imbued with pure emotion power.',
				'Boosts charisma, willpower, and mental resistance.',
				'Type: Ring'
			},
			['exquisite_ring_brallion'] = {
				'Exquisite Brallion ring with elegant design.',
				'Offers refined magical bonuses and status.',
				'Type: Ring'
			},
			['expensive_ring_aeta'] = {
				'Expensive Aeta ring with luxurious craftsmanship.',
				'Provides significant magical enhancements.',
				'Type: Ring'
			},
			['common_ring_tsiya'] = {
				'Common Tsiya ring with simple design.',
				'Basic jewelry with no major enchantments.',
				'Type: Ring'
			},
			['ring of azura'] = {
				'Ring of Azura blessed by the goddess of dusk.',
				'Enhances magic resistance and night vision.',
				'Type: Ring'
			},
			['ring of tears'] = {
				'Ring of tears channeling sorrowful energy.',
				'Inflicts debuffs or heals based on emotion.',
				'Type: Ring'
			},
			['murdrum ring'] = {
				'Murdrum ring with murderous intent.',
				'Increases critical hit chance and damage.',
				'Type: Ring'
			},
			['ring_denstagmer_unique'] = {
				'Unique Denstagmer ring with personalized power.',
				"Grants special abilities tied to wearer's fate.",
				'Type: Ring'
			},
			['ring_khajiit_unique'] = {
				'Unique Khajiit ring with feline agility enchantments.',
				'Enhances speed, stealth, and night vision.',
				'Type: Ring'
			},
			['ring_mentor_unique'] = {
				'Unique mentor ring with wisdom and teaching power.',
				'Boosts intelligence and spell absorption.',
				'Type: Ring'
			},
			['ring_phynaster_unique'] = {
				'Unique Phynaster ring with ancient scholar magic.',
				'Enhances memory, learning, and spellcasting.',
				'Type: Ring'
			},
			['ring_surrounding_unique'] = {
				'Unique surrounding ring with environmental control.',
				'Allows manipulation of terrain and weather.',
				'Type: Ring'
			},
			['ring_vampiric_unique'] = {
				'Unique vampiric ring with blood-sucking power.',
				'Steals health and grants dark vision.',
				'Type: Ring'
			},
			['ring_warlock_unique'] = {
				'Unique warlock ring with dark arcane magic.',
				'Enhances necromancy and shadow spells.',
				'Type: Ring'
			},
			['ring_wind_unique'] = {
				'Unique wind ring channeling aerial power.',
				'Grants flight, speed, and air elemental damage.',
				'Type: Ring'
			},
			['sarandas_ring_1'] = {
				'Sarandas ring #1 with elemental balance.',
				'Provides resistance to all elements.',
				'Type: Ring'
			},
			['sarandas_ring_2'] = {
				'Sarandas ring #2 with focused elemental power.',
				'Enhances a specific element (fire, ice, etc.).',
				'Type: Ring'
			},
			['fighter_ring'] = {
				'Fighter ring boosting physical prowess.',
				'Increases strength, endurance, and melee damage.',
				'Type: Ring'
			},
			['mage_ring'] = {
				'Mage ring enhancing arcane abilities.',
				'Boosts mana, spell power, and magic resistance.',
				'Type: Ring'
			},
			['thief_ring'] = {
				'Thief ring improving stealth and dexterity.',
				'Enhances lockpicking, pickpocketing, and evasion.',
				'Type: Ring'
			},
			['exquisite_ring_processus'] = {
				'Exquisite Processus ring with intricate magic.',
				'Offers complex enchantments for multiple roles.',
				'Type: Ring'
			},
			["Sheogorath's Signet Ring"] = {
				"Sheogorath's signet ring with madness magic.",
				'Grants chaotic powers and unpredictable effects.',
				'Type: Ring'
			},
			['expensive_ring_01_BILL'] = {
				'Expensive BILL ring with premium enchantments.',
				'Provides top-tier magical and physical bonuses.',
				'Type: Ring'
			},
			["Adusamsi's_Ring"] = {
				"Adusamsi's ring with ancestral power.",
				'Enhances connection to heritage and spirit guides.',
				'Type: Ring'
			},
			['ring of nullification'] = {
				'Ring of nullification negating magical effects.',
				'Cancels spells, enchantments, and curses.',
				'Type: Ring'
			},
			['Nuccius_ring'] = {
				'Nuccius ring with enigmatic power.',
				'Provides subtle but versatile magical bonuses.',
				'Type: Ring'
			},
			['Ring of Night-Eye'] = {
				'Ring of Night-Eye enhancing low-light vision.',
				'Allows clear sight in darkness and dim areas.',
				'Type: Ring'
			},
			['common_ring_01_fg_nchur01'] = {
				'Common FG Nchur01 ring with basic design.',
				'Simple jewelry with minimal enchantments.',
				'Type: Ring'
			},
			['common_ring_01_fg_nchur02'] = {
				'Common FG Nchur02 ring with standard craftsmanship.',
				'Ordinary ring with no significant effects.',
				'Type: Ring'
			},
			['common_ring_01_fg_nchur03'] = {
				'Common FG Nchur03 ring with unremarkable design.',
				'Basic piece of jewelry.',
				'Type: Ring'
			},
			['common_ring_01_fg_nchur04'] = {
				'Common FG Nchur04 ring with plain appearance.',
				'No special magical properties.',
				'Type: Ring'
			},
			['common_ring_01_fg_corp01'] = {
				'Common FG Corp01 ring with corporate branding.',
				'Simple ring, likely a token or symbol.',
				'Type: Ring'
			},
			['Caius_ring'] = {
				'Caius ring with noble heritage magic.',
				'Enhances status, leadership, and combat skills.',
				'Type: Ring'
			},
			['common_ring_01_arena'] = {
				'Common arena ring for combatants.',
				'Provides minor physical and magical resistance.',
				'Type: Ring'
			},
			['common_ring_01_mge'] = {
				'Common MGE ring with standard enchantments.',
				'Offers basic bonuses for general use.',
				'Type: Ring'
			},
			['extravagant_ring_aund_uni'] = {
				'Extravagant Aund unique ring with opulent design.',
				'Grants luxurious bonuses and status symbols.',
				'Type: Ring'
			},
			['common_ring_01_tt_mountkand'] = {
				'Common TT Mountkand ring with simple craftsmanship.',
				'Basic ring, suitable for everyday wear.',
				'Type: Ring'
			},
			['cl_ringofregeneration'] = {
				'CL ring of regeneration with healing magic.',
				'Restores health over time or on hit.',
				'Type: Ring'
			},
			['Mark_Ring'] = {
				'Mark ring imprinting magical signature.',
				'Allows identification or teleportation links.',
				'Type: Ring'
			},
			['Recall_Ring'] = {
				'Recall ring enabling instant teleportation.',
				'Returns wearer to a preset location.',
				'Type: Ring'
			},
			['ring_marara_unique'] = {
				'Unique Marara ring with personal enchantments.',
				"Tailored bonuses based on wearer's attributes.",
				'Type: Ring'
			},
			['ring_fathasa_unique'] = {
				'Unique Fathasa ring with ancestral power.',
				'Enhances strength and resilience through heritage.',
				'Type: Ring'
			},
			['common_ring_danar'] = {
				'Common Danar ring with unassuming design.',
				'No significant magical properties, just a token.',
				'Type: Ring'
			},
			['Septim Ring'] = {
				'Septim ring bearing imperial insignia.',
				'Grants minor bonuses and symbolizes authority.',
				'Type: Ring'
			},
			["Akatosh's Ring"] = {
				"Akatosh's ring blessed by the dragon god.",
				'Enhances willpower, resistance to magic, and divine protection.',
				'Type: Ring'
			},
			['Detect_Enchantment_ring'] = {
				'Detect enchantment ring revealing hidden magic.',
				'Allows detection of spells and enchantments on objects.',
				'Type: Ring'
			},
			['common_ring_01_haunt_Ken'] = {
				'Common Haunt Ken ring with subtle design.',
				'Basic jewelry with no major enchantments.',
				'Type: Ring'
			},
			['common_ring_01_mgbwg'] = {
				'Common MGBWG ring with standard craftsmanship.',
				'Ordinary ring for general use, minimal effects.',
				'Type: Ring'
			},
			['foe-quern'] = {
				'Foe-quern ring grinding down enemy defenses.',
				'Reduces armor and resistance of targets.',
				'Type: Ring'
			},
			['foe-grinder'] = {
				'Foe-grinder ring crushing foes with might.',
				'Increases damage against weakened enemies.',
				'Type: Ring'
			},
			['Akatosh Ring'] = {
				'Akatosh ring with divine dragon power.',
				'Grants stamina, magic resistance, and celestial aura.',
				'Type: Ring'
			},
			['ring of telekinesis_UNIQUE'] = {
				'Unique ring of telekinesis with mind-over-matter power.',
				'Allows levitation and manipulation of objects.',
				'Type: Ring'
			},
			['ring_shashev_unique'] = {
				'Unique Shashev ring with personalized magic.',
				'Tailored enchantments for specific tasks.',
				'Type: Ring'
			},
			['ring_phynaster_unique_x'] = {
				'Unique Phynaster X ring with advanced scholar magic.',
				'Enhances memory, spellcasting, and learning speed.',
				'Type: Ring'
			},
			['ring_warlock_unique_x'] = {
				'Unique warlock X ring with dark arcane might.',
				'Boosts necromancy, shadow spells, and corruption power.',
				'Type: Ring'
			},
			['ring_vampiric_unique_x'] = {
				'Unique vampiric X ring with enhanced blood magic.',
				'Steals health, grants dark vision, and increases damage at night.',
				'Type: Ring'
			},
			['mazed_band'] = {
				'Mazed band with confusing enchantments.',
				'Disorients enemies and protects wearer from mental attacks.',
				'Type: Ring'
			},
			["Helseth's Ring"] = {
				"Helseth's ring with royal authority.",
				'Enhances leadership, charisma, and political influence.',
				'Type: Ring'
			},
			["Variner's Ring"] = {
				"Variner's ring with ancient alchemical power.",
				'Grants resistance to poisons and enhances healing.',
				'Type: Ring'
			},
			['mazed_band_end'] = {
				'Mazed band end with final confusion enchantment.',
				'Creates powerful disorientation field around wearer.',
				'Type: Ring'
			},
			['hroldar_ring'] = {
				"Hroldar ring with warrior's spirit.",
				'Boosts melee damage, stamina, and battle rage.',
				'Type: Ring'
			},
			['expensive_ring_erna'] = {
				'Expensive Erna ring with refined enchantments.',
				'Provides balanced magical and physical bonuses.',
				'Type: Ring'
			},
			['ulfgar_ring'] = {
				'Ulfgar ring with Nordic warrior power.',
				'Enhances strength, endurance, and frost resistance.',
				'Type: Ring'
			},
			['glenmoril_ring_BM'] = {
				'Glenmoril BM ring with dark druidic magic.',
				'Grants nature control, poison resistance, and shapeshifting.',
				'Type: Ring'
			},
			['ritual_ring'] = {
				'Ritual ring focusing magical energy.',
				'Enhances spellcasting during rituals and ceremonies.',
				'Type: Ring'
			},
			['common_ring_05_BM_UNI'] = {
				'Common BM unique ring with basic design.',
				'Simple jewelry with minor, unique enchantments.',
				'Type: Ring'
			},
			['BM_ring_Aesliip'] = {
				'BM Aesliip ring with elemental balance.',
				'Provides resistance to fire, ice, and lightning.',
				'Type: Ring'
			},
			['BM_ring_hircine'] = {
				'BM Hircine ring with beastly power.',
				'Enhances agility, strength, and animal instincts.',
				'Type: Ring'
			},
			['bm_ring_marksman'] = {
				'BM marksman ring with precision enchantments.',
				'Improves archery skills, accuracy, and critical hits.',
				'Type: Ring'
			},
			['bm_ring_view'] = {
				'BM view ring with enhanced perception.',
				'Boosts awareness, night vision, and detection range.',
				'Type: Ring'
			}
        }
    }
}