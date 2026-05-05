local types = require('openmw.types')
local util = require('openmw.util')

return {
    [types.NPC] = {
        title = 'NPC',
        color = util.color.rgb(0.2, 0.8, 0.8),
        showRace = true,
        showClass = true,
        uniqueDescriptions = {
			['erranil'] = {
				'Erranil',
				'Ancient High Elf scholar serving as Guild Guide in the Mages Guild.',
				'Faction: Mages Guild',
				'Location: Mages Guild Headquarters',
				'Role: Provides guidance to new mages and access to advanced spells.',
				'Notes: Highly knowledgeable in arcane arts, calm and reserved demeanor'
			},

			['anarenen'] = {
				'Anarenen',
				'Skilled High Elf alchemist working in the Mages Guild.',
				'Faction: Mages Guild',
				'Location: Alchemy Lab',
				'Role: Creates potions and elixirs, teaches alchemy techniques.',
				'Notes: Expert in potion-making, often experimenting with new formulas'
			},

			['orrent geontene'] = {
				'Orrent Geontene',
				'Breton Nightblade specialist serving in the Mages Guild.',
				'Faction: Mages Guild',
				'Location: Nightblade Training Area',
				'Role: Teaches stealth and shadow magic techniques.',
				'Notes: Master of dark arts and concealment'
			},

			['tanar llervi'] = {
				'Tanar Llervi',
				'Dark Elf enchanter with exceptional skill in magical imbuing.',
				'Faction: Mages Guild',
				'Location: Enchanting Workshop',
				'Role: Specializes in enchanting weapons and armor.',
				'Notes: Calculating and precise in work'
			},

			['ergnir'] = {
				'Ergnir',
				'Nord blacksmith with a passion for crafting fine weapons.',
				'Faction: Fighters Guild',
				'Location: Smithy',
				'Role: Crafts and repairs weapons and armor.',
				'Notes: Rugged but honest, known for quality craftsmanship'
			},

			['tralan'] = {
				'Tralan',
				'Redguard master-at-arms training fighters.',
				'Faction: Fighters Guild',
				'Location: Training Grounds',
				'Role: Instructs in combat techniques and weapon mastery.',
				'Notes: Strict but fair trainer'
			},

			['baradras'] = {
				'Baradras',
				'Wood Elf scout with exceptional wilderness skills.',
				'Faction: Fighters Guild',
				'Location: Scout Outpost',
				'Role: Teaches tracking and survival skills.',
				'Notes: Expert in stealth and nature awareness'
			},

			['lirielle stoine'] = {
				'Lirielle Stoine',
				'Breton thief providing services to the Thieves Guild.',
				'Faction: Thieves Guild',
				'Location: Thieves Guild Headquarters',
				'Role: Specializes in pickpocketing and lockpicking.',
				'Notes: Charismatic and skilled in social deception'
			},

			['aengoth'] = {
				'Aengoth',
				'Wood Elf scout working for the Thieves Guild.',
				'Faction: Thieves Guild',
				'Location: Guild Outpost',
				'Role: Provides reconnaissance and stealth services.',
				'Notes: Expert in silent movement and observation'
			},

			['allding'] = {
				'Allding',
				'Nord pawnbroker handling stolen goods.',
				'Faction: Thieves Guild',
				'Location: Pawn Shop',
				'Role: Buys and sells stolen items.',
				'Notes: Straightforward dealings, no questions asked'
			},

			['ather belden'] = {
				'Ather Belden',
				'Dark Elf pawnbroker with extensive connections.',
				'Faction: Thieves Guild',
				'Location: Pawn Shop',
				'Role: Deals in valuable stolen merchandise.',
				'Notes: Shrewd negotiator, knows true value of items'
			},

			['dalos golathyn'] = {
				'Dalos Golathyn',
				'Dark Elf thief specializing in high-value heists.',
				'Faction: Thieves Guild',
				'Location: Thieves Guild Headquarters',
				'Role: Executes complex theft operations.',
				'Notes: Skilled in lockpicking and stealth'
			},

			['fomesa tharys'] = {
				'Fomesa Tharys',
				'Dark Elf smith specializing in creating specialized weapons for thieves.',
				'Faction: Thieves Guild',
				'Location: Guild Smithy',
				'Role: Crafts custom weapons and tools for thievery.',
				'Notes: Expert in creating hidden blades and poisoned weapons'
			},

			['gildan'] = {
				'Gildan',
				'Wood Elf Nightblade serving in the Blades.',
				'Faction: Blades',
				'Location: Blades Headquarters',
				'Role: Specializes in stealth and assassination missions.',
				'Notes: Loyal and skilled in shadow arts'
			},

			['estoril'] = {
				'Estoril',
				'High Elf battlemage serving in the Thieves Guild.',
				'Faction: Thieves Guild',
				'Location: Mage Quarter',
				'Role: Combines magic and combat skills for guild missions.',
				'Notes: Powerful spellcaster with martial training'
			},

			['molvirian palenix'] = {
				'Molvirian Palenix',
				'Imperial Legionary guard dedicated to upholding law.',
				'Faction: Imperial Legion',
				'Location: Legion Barracks',
				'Role: Patrols and maintains security.',
				'Notes: Strict adherent to Imperial law'
			},

			['ughash gro-batul'] = {
				'Ughash gro-Batul',
				'Orc Legionary guard known for strength and loyalty.',
				'Faction: Imperial Legion',
				'Location: Legion Outpost',
				'Role: Protects Imperial interests and citizens.',
				'Notes: Formidable warrior with unwavering resolve'
			},

			['yashnarz gro-ufthamph'] = {
				'Yashnarz gro-Uftamph',
				'Orc Legionary guard specializing in combat.',
				'Faction: Imperial Legion',
				'Location: Legion Fort',
				'Role: Engages in frontline combat duties.',
				'Notes: Expert axe-wielder with great endurance'
			},

			['optio bologra'] = {
				'Optio Bologra',
				'Orc drillmaster training Legion recruits.',
				'Faction: Imperial Legion',
				'Location: Training Grounds',
				'Role: Instructs soldiers in combat techniques.',
				'Notes: Harsh but effective trainer'
			},

			['dumbuk gro-bolak'] = {
				'Dumbuk gro-Bolak',
				'Orc knight serving in the Imperial Legion.',
				'Faction: Imperial Legion',
				'Location: Legion Headquarters',
				'Role: Leads cavalry charges and defends positions.',
				'Notes: Experienced in mounted combat'
			},

			['oritius maro'] = {
				'Oritius Maro',
				'Imperial warrior serving the Talos Cult.',
				'Faction: Talos Cult',
				'Location: Talos Shrine',
				'Role: Fights in the name of Talos.',
				'Notes: Devout follower of Talos'
			},

			['arius rulician'] = {
				'Arius Rulician',
				'Imperial warrior dedicated to Talos.',
				'Faction: Talos Cult',
				'Location: Talos Temple',
				'Role: Protects the faith and its followers.',
				'Notes: Pious and skilled in combat'
			},

			['varian angius'] = {
				'Varian Angius',
				'Imperial battlemage serving in the Legion.',
				'Faction: Imperial Legion',
				'Location: Mage Corps',
				'Role: Combines magic and martial skills in battle.',
				'Notes: Proficient in both spellcraft and swordplay'
			},

			['strillian macro'] = {
				'Strillian Macro',
				'Imperial spellsword serving in the Legion.',
				'Faction: Imperial Legion',
				'Location: Elite Forces',
				'Role: Specializes in combining magic and melee combat.',
				'Notes: Highly trained in dual disciplines'
			},

			['allian carbo'] = {
				'Allian Carbo',
				'Imperial warrior serving in the Legion.',
				'Faction: Imperial Legion',
				'Location: Legion Barracks',
				'Role: Engages in frontline combat.',
				'Notes: Stalwart and reliable soldier'
			},

			['vertilvius cines'] = {
				'Vertilvius Cines',
				'Imperial warrior known for tactical prowess.',
				'Faction: Imperial Legion',
				'Location: Legion Outpost',
				'Role: Leads infantry formations in battle.',
				'Notes: Experienced battlefield commander'
			},

			['vantustius pundus'] = {
				'Vantustius Pundus',
				'Imperial soldier specializing in siege warfare.',
				'Faction: Imperial Legion',
				'Location: Legion Fort',
				'Role: Expert in siege tactics and fortifications.',
				'Notes: Skilled in siege engine operation'
			},

			['chaplain ogrul'] = {
				'Chaplain Ogrul',
				'Orc healer serving in the Imperial Cult.',
				'Faction: Imperial Cult',
				'Location: Cult Temple',
				'Role: Provides healing and spiritual guidance.',
				'Notes: Devoted to healing arts'
			},

			['sharkub gro-khashnar'] = {
				'Sharkub gro-Khashnar',
				'Orc drillmaster training Legion recruits.',
				'Faction: Imperial Legion',
				'Location: Training Grounds',
				'Role: Instructs soldiers in combat techniques.',
				'Notes: Harsh but effective trainer'
			},

			['mug gro-dulob'] = {
				'Mug gro-Dulob',
				'Orc blacksmith serving the Legion.',
				'Faction: Imperial Legion',
				'Location: Legion Smithy',
				'Role: Crafts and repairs weapons and armor.',
				'Notes: Expert in orcish forging techniques'
			},

			['ulumpha gra-sharob'] = {
				'Ulumpha gra-Sharob',
				'Orc healer serving in the Legion.',
				'Faction: Imperial Legion',
				'Location: Field Hospital',
				'Role: Treats wounded soldiers.',
				'Notes: Skilled in battlefield medicine'
			},

			['bagamul gro-dumul'] = {
				'Bagamul gro-Dumul',
				'Orc guard patrolling Imperial territories.',
				'Faction: Imperial Legion',
				'Location: Border Outpost',
				'Role: Maintains security and order.',
				'Notes: Stalwart defender of the Empire'
			},

			['uloth gra-ushar'] = {
				'Uloth gra-Ushar',
				'Orc legionary stationed at key locations.',
				'Faction: Imperial Legion',
				'Location: Strategic Posts',
				'Role: Enforces Imperial law.',
				'Notes: Loyal to Imperial command'
			},

			['dul gro-dush'] = {
				'Dul gro-Dush',
				'Orc warrior serving in the Legion.',
				'Faction: Imperial Legion',
				'Location: Legion Barracks',
				'Role: Frontline combat specialist.',
				'Notes: Fearless in battle'
			},

			['largakh gro-bulfim'] = {
				'Largakh gro-Bulfim',
				'Orc legionary guarding important sites.',
				'Faction: Imperial Legion',
				'Location: Key Fortifications',
				'Role: Defends strategic positions.',
				'Notes: Known for endurance in combat'
			},

			['bogdub gra-gurakh'] = {
				'Bogdub gra-Gurakh',
				'Orc guard stationed at outposts.',
				'Faction: Imperial Legion',
				'Location: Remote Posts',
				'Role: Maintains Imperial presence.',
				'Notes: Reliable sentry'
			},

			['yambul gro-bogrol'] = {
				'Yambul gro-Bogrol',
				'Orc legionary enforcing Imperial law.',
				'Faction: Imperial Legion',
				'Location: Patrol Routes',
				'Role: Conducts security operations.',
				'Notes: Strict enforcer of regulations'
			},

			['fenas madach'] = {
				'Fenas Madach',
				'Breton thief with extensive guild connections.',
				'Faction: Thieves Guild',
				'Location: Thieves Guild Headquarters',
				'Role: Performs various guild missions.',
				'Notes: Skilled in burglary and information gathering'
			},

			['ertius fulbenus'] = {
				'Ertius Fulbenus',
				'Imperial Legionary warrior.',
				'Faction: Imperial Legion',
				'Location: Legion Barracks',
				'Role: Serves in infantry units.',
				'Notes: Experienced in formation combat'
			},

			['clilias pullia'] = {
				'Clilias Pullia',
				'Imperial Legionary guard.',
				'Faction: Imperial Legion',
				'Location: City Guard Posts',
				'Role: Maintains public order.',
				'Notes: Dedicated to Imperial service'
			},

			['snakha gro-marob'] = {
				'Snakha gro-Marob',
				'Orc Legionary warrior.',
				'Faction: Imperial Legion',
				'Location: Frontier Forts',
				'Role: Engages in border defense.',
				'Notes: Known for physical strength'
			},

			['asha-ammu kutebani'] = {
				'Asha-Ammu Kutebani',
				'Dark Elf scout serving in the Legion.',
				'Faction: Imperial Legion',
				'Location: Scout Camps',
				'Role: Provides reconnaissance.',
				'Notes: Expert in wilderness survival'
			},

			['general darius'] = {
				'General Darius',
				'High-ranking Imperial officer.',
				'Faction: Imperial Legion',
				'Location: Command Headquarters',
				'Role: Oversees military operations.',
				'Notes: Experienced military strategist'
			},

			['nash gro-khazor'] = {
				'Nash gro-Khazor',
				'Orc Legionary guard.',
				'Faction: Imperial Legion',
				'Location: Strategic Posts',
				'Role: Enforces Imperial authority.',
				'Notes: Loyal to command structure'
			},

			['athal nerano'] = {
				'Athal Nerano',
				'Dark Elf rogue serving House Hlaalu.',
				'Faction: Hlaalu',
				'Location: Hlaalu Estates',
				'Role: Performs covert operations.',
				'Notes: Trusted agent of the house'
			},

			['talms dralor'] = {
				'Talms Dralor',
				'Dark Elf pilgrim devoted to faith.',
				'Faction: Hlaalu',
				'Location: Religious Sites',
				'Role: Serves in religious capacity.',
				'Notes: Devout follower of tradition'
			},

			['ragash gra-shuzgub'] = {
				'Ragash gra-Shuzgub',
				'Orc Legionary warrior.',
				'Faction: Imperial Legion',
				'Location: Combat Units',
				'Role: Engages in frontline combat.',
				'Notes: Formidable in melee'
			},

			['mehra drora'] = {
				'Mehra Drora',
				'Dark Elf priest serving in the Temple.',
				'Faction: Temple',
				'Location: Temple Precincts',
				'Role: Conducts religious services.',
				'Notes: Devoted to temple duties'
			},

			['esib-nummu assunudadnud'] = {
				'Esib-Nummu Assunudadnud',
				'Dark Elf pilgrim seeking enlightenment.',
				'Faction: Temple',
				'Location: Pilgrimage Sites',
				'Role: Participates in religious rituals.',
				'Notes: Dedicated follower of tradition'
			},

			['zanmulk sammalamus'] = {
				'Zanmulk Sammalamus',
				'Dark Elf healer in service to the Temple.',
				'Faction: Temple',
				'Location: Temple Infirmary',
				'Role: Provides medical assistance.',
				'Notes: Skilled in healing arts'
			},

			['hentus yansurnummu'] = {
				'Hentus Yansurnummu',
				'Dark Elf miner working for the Temple.',
				'Faction: Temple',
				'Location: Temple Mines',
				'Role: Extracts valuable resources.',
				'Notes: Experienced in mining'
			},

			['vatollia apo'] = {
				'Vatollia Apo',
				'Dark Elf guard serving the Legion.',
				'Faction: Imperial Legion',
				'Location: Legion Posts',
				'Role: Maintains security.',
				'Notes: Stalwart defender'
			},

			['lugrub gro-ogdum'] = {
				'Lugrub gro-Ogdum',
				'Orc warrior in Imperial service.',
				'Faction: Imperial Legion',
				'Location: Combat Units',
				'Role: Engages in combat operations.',
				'Notes: Formidable in battle'
			},

			['kummi-namus almu'] = {
				'Kummi-Namus Almu',
				'Dark Elf miner employed by the Temple.',
				'Faction: Temple',
				'Location: Mining Operations',
				'Role: Manages mining activities.',
				'Notes: Expert in resource extraction'
			},

			['mausur ababael'] = {
				'Mausur Ababael',
				'Dark Elf miner working for the Temple.',
				'Faction: Temple',
				'Location: Temple Mines',
				'Role: Assists in mining operations.',
				'Notes: Knowledgeable in geology'
			},

			['shanud ududnabia'] = {
				'Shanud Ududnabia',
				'Dark Elf miner serving the Temple.',
				'Faction: Temple',
				'Location: Mining Sites',
				'Role: Supports mining efforts.',
				'Notes: Experienced underground worker'
			},

			['zebdusipal mantiti'] = {
				'Zebdusipal Mantiti',
				'Dark Elf miner in Temple service.',
				'Faction: Temple',
				'Location: Mining Camps',
				'Role: Participates in mining tasks.',
				'Notes: Familiar with mining techniques'
			},

			['darvam hlaren'] = {
				'Darvam Hlaren',
				'Dark Elf trader associated with the Thieves Guild.',
				'Faction: Thieves Guild',
				'Location: Guild Markets',
				'Role: Facilitates illicit trade.',
				'Notes: Connected to underground commerce'
			},

			['volene llervu'] = {
				'Volene Llervu',
				'Dark Elf knight serving House Redoran.',
				'Faction: Redoran',
				'Location: Redoran Holds',
				'Role: Protects House interests.',
				'Notes: Loyal to Redoran traditions'
			},

			['hassour zainsubani'] = {
				'Hassour Zainsubani',
				'Dark Elf thief working for the Guild.',
				'Faction: Thieves Guild',
				'Location: Thieves Guild Hideouts',
				'Role: Executes theft missions.',
				'Notes: Skilled in burglary'
			},

			['mansilamat vabdas'] = {
				'Mansilamat Vabdas',
				'Dark Elf miner serving House Redoran.',
				'Faction: Redoran',
				'Location: Redoran Mining Camps',
				'Role: Manages mining operations.',
				'Notes: Expert in ore extraction'
			},

			['imperial guard captain'] = {
				'Imperial Guard Captain',
				'High-ranking officer in the Imperial Legion.',
				'Faction: Imperial Legion',
				'Location: Guard Headquarters',
				'Role: Commands guard units.',
				'Notes: Experienced military leader'
			},

			['shadbak gra-burbug'] = {
				'Shadbak gra-Burbug',
				'Orc blacksmith serving the Legion.',
				'Faction: Imperial Legion',
				'Location: Legion Smithy',
				'Role: Crafts weapons and armor.',
				'Notes: Master blacksmith'
			},

			['angoril'] = {
				'Angoril',
				'High Elf master-at-arms in the Legion.',
				'Faction: Imperial Legion',
				'Location: Training Grounds',
				'Role: Teaches combat techniques.',
				'Notes: Skilled martial instructor'
			},

			['ygfa'] = {
				'Ygfa',
				'Nord healer serving the Imperial Cult.',
				'Faction: Imperial Cult',
				'Location: Cult Temples',
				'Role: Provides medical aid.',
				'Notes: Devoted to healing'
			},

			['miner arobar'] = {
				'Miner Arobar',
				'Redoran crusader.',
				'Faction: Redoran',
				'Location: Under Scar',
				'Role: Perfect combat skills.',
				'Notes: Dual-trained specialist'
			},

			['llavane hlas'] = {
				'Llavane Hlas',
				'Dark Elf archer serving House Redoran.',
				'Faction: Redoran',
				'Location: Redoran Holds',
				'Role: Provides ranged support.',
				'Notes: Expert marksman'
			},

			['bolyn elval'] = {
				'Bolyn Elval',
				'Dark Elf archer in Redoran service.',
				'Faction: Redoran',
				'Location: Redoran Outposts',
				'Role: Guards borders.',
				'Notes: Skilled in long-range combat'
			},

			['ethes evos'] = {
				'Ethes Evos',
				'Dark Elf commoner serving House Redoran.',
				'Faction: Redoran',
				'Location: Redoran Holdings',
				'Role: Performs various duties.',
				'Notes: Loyal to House traditions'
			},

			['vindyne belvani'] = {
				'Vindyne Belvani',
				'Dark Elf commoner in Redoran service.',
				'Faction: Redoran',
				'Location: Redoran Settlements',
				'Role: Supports House operations.',
				'Notes: Dutiful servant'
			},

			['gandosa arobar'] = {
				'Gandosa Arobar',
				'Dark Elf noble of House Redoran.',
				'Faction: Redoran',
				'Location: Noble Estates',
				'Role: Advises House leadership.',
				'Notes: Influential noble'
			},

			['dinara othrelas'] = {
				'Dinara Othrelas',
				'Dark Elf commoner serving Redoran interests.',
				'Faction: Redoran',
				'Location: Redoran Territories',
				'Role: Assists in House matters.',
				'Notes: Devoted to House goals'
			},

			['eindel'] = {
				'Eindel',
				'Wood Elf archer in Redoran service.',
				'Faction: Redoran',
				'Location: Redoran Defenses',
				'Role: Provides archer support.',
				'Notes: Skilled marksman'
			},

			['llanel brenos'] = {
				'Llanel Brenos',
				'Dark Elf archer serving House Redoran.',
				'Faction: Redoran',
				'Location: Redoran Posts',
				'Role: Guards borders.',
				'Notes: Experienced in archery'
			},

			['tens nolar'] = {
				'Tens Nolar',
				'Dark Elf warrior serving House Redoran.',
				'Faction: Redoran',
				'Location: Redoran Strongholds',
				'Role: Engages in combat operations.',
				'Notes: Skilled in melee combat'
			},

			['ureval dralayn'] = {
				'Ureval Dralayn',
				'Dark Elf warrior in Redoran service.',
				'Faction: Redoran',
				'Location: Redoran Military Posts',
				'Role: Defends House territories.',
				'Notes: Experienced combatant'
			},

			['garisa llethri'] = {
				'Garisa Lletri',
				'Dark Elf warrior serving House Redoran.',
				'Faction: Redoran',
				'Location: Redoran Holds',
				'Role: Enforces House authority.',
				'Notes: Loyal to Redoran traditions'
			},

			['fathasa llethri'] = {
				'Fathasa Lletri',
				'Dark Elf noble serving House Redoran.',
				'Faction: Redoran',
				'Location: Noble Estates',
				'Role: Advises House leadership.',
				'Notes: Influential noblewoman'
			},

			['garvs ramarys'] = {
				'Garvs Ramarys',
				'Dark Elf commoner in Redoran service.',
				'Faction: Redoran',
				'Location: Redoran Settlements',
				'Role: Supports House operations.',
				'Notes: Devoted servant'
			},

			['favilea sathendas'] = {
				'Favilea Sathendas',
				'Dark Elf commoner serving Redoran interests.',
				'Faction: Redoran',
				'Location: Redoran Territories',
				'Role: Assists in House matters.',
				'Notes: Dutiful worker'
			},

			['hlaren ramoran'] = {
				'Hlaren Ramoran',
				'Dark Elf knight in Redoran service.',
				'Faction: Redoran',
				'Location: Redoran Military Camps',
				'Role: Leads cavalry units.',
				'Notes: Experienced commander'
			},

			['domesea sarethi'] = {
				'Domesea Sarethi',
				'Dark Elf noble of House Redoran.',
				'Faction: Redoran',
				'Location: Noble Residences',
				'Role: Oversees House affairs.',
				'Notes: Highly respected noble'
			},

			['athyn sarethi'] = {
				'Athin Sarethi',
				'Dark Elf agent serving House Redoran.',
				'Faction: Redoran',
				'Location: Secretive Locations',
				'Role: Conducts covert operations.',
				'Notes: Trusted operative'
			},

			['dilvene venim'] = {
				'Dilvene Venim',
				'Dark Elf noble in Redoran service.',
				'Faction: Redoran',
				'Location: Noble Estates',
				'Role: Advises House leadership.',
				'Notes: Wise counselor'
			},

			['bolvyn venim'] = {
				'Bolvyn Venim',
				'Dark Elf crusader serving House Redoran.',
				'Faction: Redoran',
				'Location: Redoran Military Posts',
				'Role: Leads crusading forces.',
				'Notes: Devout warrior'
			},

			['varvur sarethi'] = {
				'Varvur Sarethi',
				'Dark Elf noble overseeing Redoran affairs.',
				'Faction: Redoran',
				'Location: Noble Palaces',
				'Role: Manages House resources.',
				'Notes: Influential figure'
			},

			['tuveso beleth'] = {
				'Tuveso Beleth',
				'Dark Elf master-at-arms in Redoran service.',
				'Faction: Redoran',
				'Location: Training Grounds',
				'Role: Teaches combat skills.',
				'Notes: Experienced instructor'
			},

			['vonden mano'] = {
				'Vonden Mano',
				'Dark Elf warrior serving House Redoran.',
				'Faction: Redoran',
				'Location: Redoran Strongholds',
				'Role: Guards important locations.',
				'Notes: Stalwart defender'
			},

			['goras andrelo'] = {
				'Goras Andrelo',
				'Dark Elf scout in Redoran service.',
				'Faction: Redoran',
				'Location: Redoran Border Posts',
				'Role: Provides reconnaissance.',
				'Notes: Expert tracker'
			},

			['neminda'] = {
				'Neminda',
				'Redguard drillmaster serving House Redoran.',
				'Faction: Redoran',
				'Location: Training Camps',
				'Role: Instructs soldiers in combat.',
				'Notes: Strict but effective trainer'
			},

			['malpenix blonia'] = {
				'Malpenix Blonia',
				'Imperial trader serving House Redoran.',
				'Faction: Redoran',
				'Location: Trading Posts',
				'Role: Facilitates trade operations.',
				'Notes: Knowledgeable in commerce'
			},

			['guls llervu'] = {
				'Guls Llervu',
				'Dark Elf priest serving House Redoran.',
				'Faction: Redoran',
				'Location: Redoran Temples',
				'Role: Conducts religious ceremonies.',
				'Notes: Devoted to faith'
			},

			['mivanu retheran'] = {
				'Mivanu Retheran',
				'Dark Elf savant in Redoran service.',
				'Faction: Redoran',
				'Location: Redoran Libraries',
				'Role: Studies ancient knowledge.',
				'Notes: Scholarly pursuits'
			},

			['boldrisa andrano'] = {
				'Boldrisa Andrano',
				'Dark Elf agent serving House Redoran.',
				'Faction: Redoran',
				'Location: Secretive Locations',
				'Role: Conducts espionage missions.',
				'Notes: Trusted operative'
			},

			['galsa gindu'] = {
				'Galsa Gindu',
				'Dark Elf noble of House Redoran.',
				'Faction: Redoran',
				'Location: Noble Estates',
				'Role: Advises House leadership.',
				'Notes: Influential noble'
			},

			['mivanu andrelo'] = {
				'Mivanu Andrelo',
				'Dark Elf savant in Redoran service.',
				'Faction: Redoran',
				'Location: Redoran Academies',
				'Role: Conducts research.',
				'Notes: Expert in arcane knowledge'
			},

			['brara morvayn'] = {
				'Brara Morvayn',
				'Dark Elf noble overseeing Redoran affairs.',
				'Faction: Redoran',
				'Location: Noble Palaces',
				'Role: Manages House resources.',
				'Notes: Respected matriarch'
			},

			['nilos talds'] = {
				'Nilos Talds',
				'Dark Elf warrior serving House Redoran.',
				'Faction: Redoran',
				'Location: Redoran Military Posts',
				'Role: Engages in combat operations.',
				'Notes: Experienced soldier'
			},

			['mondros balur'] = {
				'Mondros Balur',
				'Dark Elf master-at-arms in Redoran service.',
				'Faction: Redoran',
				'Location: Training Grounds',
				'Role: Teaches combat techniques.',
				'Notes: Skilled instructor'
			},

			['balyn omavel'] = {
				'Balyn Omavel',
				'Dark Elf assassin serving Morag Tong.',
				'Faction: Morag Tong',
				'Location: Secretive Locations',
				'Role: Executes contracts.',
				'Notes: Deadly assassin'
			},

			['hickim'] = {
				'Hickim',
				'Redguard assassin in Morag Tong service.',
				'Faction: Morag Tong',
				'Location: Hidden Assassination Posts',
				'Role: Conducts assassinations.',
				'Notes: Silent killer'
			},

			['gluronk gra-shula'] = {
				'Gluronk gra-Shula',
				'Orc assassin serving Morag Tong.',
				'Faction: Morag Tong',
				'Location: Hidden Assassination Posts',
				'Role: Executes contracts for the guild.',
				'Notes: Ruthless and efficient killer'
			},

			['ladia flarugrius'] = {
				'Ladia Flarugrius',
				'Imperial savant serving the Thieves Guild.',
				'Faction: Thieves Guild',
				'Location: Guild Headquarters',
				'Role: Provides information and research.',
				'Notes: Knowledgeable in various fields'
			},

			['ahnassi'] = {
				'Ahnassi',
				'Khajiit monk serving the Thieves Guild.',
				'Faction: Thieves Guild',
				'Location: Guild Monastery',
				'Role: Teaches martial arts and meditation.',
				'Notes: Master of combat and discipline'
			},

			['nileno dorvayn'] = {
				'Nileno Dorvayn',
				'Dark Elf thief serving House Hlaalu.',
				'Faction: Hlaalu',
				'Location: Hlaalu Holdings',
				'Role: Performs covert operations.',
				'Notes: Skilled in burglary'
			},

			['danar dalomo'] = {
				'Danar Dalomo',
				'Dark Elf scout in Hlaalu service.',
				'Faction: Hlaalu',
				'Location: Hlaalu Outposts',
				'Role: Provides reconnaissance.',
				'Notes: Expert tracker'
			},

			['aurnie vanne'] = {
				'Aurnie Vanne',
				'Breton monk serving House Hlaalu.',
				'Faction: Hlaalu',
				'Location: Hlaalu Temples',
				'Role: Teaches martial arts.',
				'Notes: Disciplined and focused'
			},

			['falvel arenim'] = {
				'Falvel Arenim',
				'Dark Elf savant in Hlaalu service.',
				'Faction: Hlaalu',
				'Location: Hlaalu Libraries',
				'Role: Conducts research.',
				'Notes: Scholarly pursuits'
			},

			['mervs uvayn'] = {
				'Mervs Uvayn',
				'Dark Elf agent serving House Hlaalu.',
				'Faction: Hlaalu',
				'Location: Hlaalu Estates',
				'Role: Conducts espionage missions.',
				'Notes: Trusted operative'
			},

			['bolnor andrani'] = {
				'Bolnor Andrani',
				'Dark Elf assassin serving House Hlaalu.',
				'Faction: Hlaalu',
				'Location: Secretive Locations',
				'Role: Executes covert operations.',
				'Notes: Deadly and discreet'
			},

			['imare'] = {
				'Imare',
				'High Elf nightblade serving House Hlaalu.',
				'Faction: Hlaalu',
				'Location: Hlaalu Strongholds',
				'Role: Performs stealth missions.',
				'Notes: Expert in shadow arts'
			},

			['briras tyravel'] = {
				'Briras Tyravel',
				'Dark Elf warrior in Hlaalu service.',
				'Faction: Hlaalu',
				'Location: Hlaalu Military Posts',
				'Role: Engages in combat operations.',
				'Notes: Skilled in melee combat'
			},

			['ondres nerano'] = {
				'Ondres Nerano',
				'Dark Elf merchant serving House Hlaalu.',
				'Faction: Hlaalu',
				'Location: Hlaalu Trading Posts',
				'Role: Facilitates trade.',
				'Notes: Knowledgeable in commerce'
			},

			['shannat pansamsi'] = {
				'Shannat Pansamsi',
				'Dark Elf monk serving Morag Tong.',
				'Faction: Morag Tong',
				'Location: Hidden Monastery',
				'Role: Teaches martial arts.',
				'Notes: Disciplined and focused'
			},

			['nachael'] = {
				'Nachael',
				'Redguard agent serving Morag Tong.',
				'Faction: Morag Tong',
				'Location: Secretive Locations',
				'Role: Conducts espionage missions.',
				'Notes: Trusted operative'
			},

			['gilyan sedas'] = {
				'Gilyan Sedas',
				'Dark Elf nightblade serving Morag Tong.',
				'Faction: Morag Tong',
				'Location: Hidden Assassination Posts',
				'Role: Executes contracts.',
				'Notes: Expert in stealth and combat'
			},

			['ethasi rilvayn'] = {
				'Ethasi Rilvayn',
				'Dark Elf nightblade serving Morag Tong.',
				'Faction: Morag Tong',
				'Location: Secretive Locations',
				'Role: Performs covert operations.',
				'Notes: Master of shadows'
			},

			['traven marvos'] = {
				'Traven Marvos',
				'Dark Elf rogue serving House Hlaalu.',
				'Faction: Hlaalu',
				'Location: Hlaalu Holdings',
				'Role: Performs various missions.',
				'Notes: Skilled in subterfuge'
			},

			['meril hlaano'] = {
				'Meril Hlaano',
				'Dark Elf noble serving House Hlaalu.',
				'Faction: Hlaalu',
				'Location: Noble Estates',
				'Role: Advises House leadership.',
				'Notes: Influential noble'
			},

			['eydis fire-eye'] = {
				'Eydis Fire-Eye',
				'Nord master-at-arms serving Fighters Guild.',
				'Faction: Fighters Guild',
				'Location: Training Grounds',
				'Role: Teaches combat techniques.',
				'Notes: Fierce and experienced instructor'
			},

			['wayn'] = {
				'Wayn',
				'Redguard blacksmith serving Fighters Guild.',
				'Faction: Fighters Guild',
				'Location: Guild Smithy',
				'Role: Crafts and repairs weapons.',
				'Notes: Skilled in metalworking'
			},

			['fasile charascel'] = {
				'Fasile Haraskel',
				'Breton scout serving Fighters Guild.',
				'Faction: Fighters Guild',
				'Location: Outpost Camps',
				'Role: Provides reconnaissance.',
				'Notes: Expert tracker'
			},

			['flaenia amiulusus'] = {
				'Flaenia Amiulusus',
				'Imperial drillmaster serving Fighters Guild.',
				'Faction: Fighters Guild',
				'Location: Training Facilities',
				'Role: Instructs recruits.',
				'Notes: Strict but effective trainer'
			},

			['hasphat antabolis'] = {
				'Hasphat Antabolis',
				'Imperial drillmaster serving Fighters Guild.',
				'Faction: Fighters Guild',
				'Location: Training Grounds',
				'Role: Oversees combat training.',
				'Notes: Experienced military instructor'
			},

			['masalinie merian'] = {
				'Masalinie Merian',
				'Breton guild guide serving Mages Guild.',
				'Faction: Mages Guild',
				'Location: Guild Headquarters',
				'Role: Guides new mages.',
				'Notes: Knowledgeable in arcane arts'
			},

			['marayn dren'] = {
				'Marayn Dren',
				'Dark Elf mage serving Mages Guild.',
				'Faction: Mages Guild',
				'Location: Mage Quarters',
				'Role: Practices and teaches magic.',
				'Notes: Skilled in spellcraft'
			},

			['sharn gra-muzgob'] = {
				'Sharn gra-Muzgob',
				'Orc healer serving Mages Guild.',
				'Faction: Mages Guild',
				'Location: Healing Chambers',
				'Role: Provides medical assistance.',
				'Notes: Proficient in healing magic'
			},

			['ajira'] = {
				'Ajira',
				'Khajiit alchemist serving Mages Guild.',
				'Faction: Mages Guild',
				'Location: Alchemy Lab',
				'Role: Creates potions and elixirs.',
				'Notes: Expert in potion-making'
			},

			['estirdalin'] = {
				'Estirdalin',
				'High Elf mage serving Mages Guild.',
				'Faction: Mages Guild',
				'Location: Mage Quarters',
				'Role: Practices and teaches magic.',
				'Notes: Skilled in arcane arts'
			},

			['ranis athrys'] = {
				'Ranis Athrys',
				'Dark Elf nightblade serving Mages Guild.',
				'Faction: Mages Guild',
				'Location: Nightblade Training',
				'Role: Specializes in stealth magic.',
				'Notes: Master of shadow arts'
			},

			['galbedir'] = {
				'Galbedir',
				'Wood Elf enchanter serving Mages Guild.',
				'Faction: Mages Guild',
				'Location: Enchanting Workshop',
				'Role: Imbues items with magic.',
				'Notes: Expert in enchanting'
			},

			['banor seran'] = {
				'Banor Seran',
				'Wood Elf publican serving Camonna Tong.',
				'Faction: Camonna Tong',
				'Location: Tong Establishments',
				'Role: Manages front operations.',
				'Notes: Trusted associate'
			},

			['vadusa sathryon'] = {
				'Vadusa Sathryon',
				'Dark Elf scout serving Camonna Tong.',
				'Faction: Camonna Tong',
				'Location: Tong Outposts',
				'Role: Provides reconnaissance.',
				'Notes: Expert tracker'
			},

			['marasa aren'] = {
				'Marasa Aren',
				'Dark Elf pawnbroker serving Camonna Tong.',
				'Faction: Camonna Tong',
				'Location: Tong Headquarters',
				'Role: Handles illicit goods.',
				'Notes: Knowledgeable in valuables'
			},

			['madrale thirith'] = {
				'Madrale Thirith',
				'Dark Elf thief serving Camonna Tong.',
				'Faction: Camonna Tong',
				'Location: Tong Operations',
				'Role: Performs theft missions.',
				'Notes: Skilled burglar'
			},

			['sovor trandel'] = {
				'Sovor Trandel',
				'Dark Elf savant serving Camonna Tong.',
				'Faction: Camonna Tong',
				'Location: Tong Archives',
				'Role: Conducts research.',
				'Notes: Expert in information'
			},

			['tedryn brenur'] = {
				'Tedryn Brenur',
				'Dark Elf master-at-arms serving Camonna Tong.',
				'Faction: Camonna Tong',
				'Location: Training Facilities',
				'Role: Teaches combat skills.',
				'Notes: Experienced instructor'
			},

			['dranas dradas'] = {
				'Dranas Dradas',
				'Dark Elf drillmaster serving Camonna Tong.',
				'Faction: Camonna Tong',
				'Location: Training Grounds',
				'Role: Oversees training.',
				'Notes: Strict trainer'
			},

			['bacola closcius'] = {
				'Bacola Closcius',
				'Imperial publican serving Thieves Guild.',
				'Faction: Thieves Guild',
				'Location: Guild Establishments',
				'Role: Manages front operations.',
				'Notes: Trusted associate'
			},

			['chirranirr'] = {
				'Chirranirr',
				'Khajiit thief serving Thieves Guild.',
				'Faction: Thieves Guild',
				'Location: Guild Headquarters',
				'Role: Performs theft missions.',
				'Notes: Skilled burglar'
			},

			['arathor'] = {
				'Arathor',
				'Wood Elf scout serving Thieves Guild.',
				'Faction: Thieves Guild',
				'Location: Guild Outposts',
				'Role: Provides reconnaissance.',
				'Notes: Expert tracker'
			},

			['sottilde'] = {
				'Sottilde',
				'Nord pawnbroker serving Thieves Guild.',
				'Faction: Thieves Guild',
				'Location: Guild Pawn Shops',
				'Role: Handles stolen goods.',
				'Notes: Knowledgeable in valuables'
			},

			['habasi'] = {
				'Habasi',
				'Khajiit thief serving Thieves Guild.',
				'Faction: Thieves Guild',
				'Location: Guild Headquarters',
				'Role: Performs theft missions.',
				'Notes: Charismatic and skilled'
			},

			['phane rielle'] = {
				'Phane Riell',
				'Breton savant serving Thieves Guild.',
				'Faction: Thieves Guild',
				'Location: Guild Archives',
				'Role: Conducts research.',
				'Notes: Expert in information'
			},

			['caius cosades'] = {
				'Caius Cosades',
				'Imperial monk serving Blades.',
				'Faction: Blades',
				'Location: Blades Headquarters',
				'Role: Teaches martial arts.',
				'Notes: Disciplined and focused'
			},

			['rithleen'] = {
				'Rithleen',
				'Redguard warrior serving Blades.',
				'Faction: Blades',
				'Location: Blades Strongholds',
				'Role: Engages in combat operations.',
				'Notes: Skilled in melee combat'
			},

			['hecerinde'] = {
				'Hecerinde',
				'High Elf agent serving Thieves Guild.',
				'Faction: Thieves Guild',
				'Location: Secretive Locations',
				'Role: Conducts espionage missions.',
				'Notes: Trusted operative'
			},

			['tyermaillin'] = {
				'Tyermaillin',
				'High Elf healer serving Blades.',
				'Faction: Blades',
				'Location: Blades Infirmary',
				'Role: Provides medical aid.',
				'Notes: Skilled in healing'
			},

			['theldyn virith'] = {
				'Theldyn Virith',
				'Dark Elf scout serving Redoran.',
				'Faction: Redoran',
				'Location: Redoran Outposts',
				'Role: Provides reconnaissance.',
				'Notes: Expert tracker'
			},

			['dalyne arvel'] = {
				'Dalyne Arvel',
				'Dark Elf mage serving Telvanni.',
				'Faction: Telvanni',
				'Location: Telvanni Towers',
				'Role: Practices and teaches magic.',
				'Notes: Skilled in arcane arts'
			},

			['nelso salenim'] = {
				'Nelso Salenim',
				'Dark Elf mage serving Telvanni.',
				'Faction: Telvanni',
				'Location: Mage Quarters',
				'Role: Specializes in spellcraft.',
				'Notes: Expert in magic'
			},

			['galar rothan'] = {
				'Galar Rotan',
				'Dark Elf enchanter serving Telvanni.',
				'Faction: Telvanni',
				'Location: Enchanting Workshop',
				'Role: Imbues items with magic.',
				'Notes: Master enchanter'
			},

			['niras farys'] = {
				'Niras Farys',
				'Dark Elf priest serving Temple.',
				'Faction: Temple',
				'Location: Temple Precincts',
				'Role: Conducts religious services.',
				'Notes: Devoted to faith'
			},

			['urtiso faryon'] = {
				'Urtiso Faryon',
				'Dark Elf sorcerer serving Telvanni.',
				'Faction: Telvanni',
				'Location: Sorcerer Towers',
				'Role: Practices dark magic.',
				'Notes: Expert in arcane arts'
			},

			['delvam andarys'] = {
				'Delvam Andarys',
				'Dark Elf sorcerer serving Telvanni.',
				'Faction: Telvanni',
				'Location: Mage Quarters',
				'Role: Specializes in destructive magic.',
				'Notes: Powerful sorcerer'
			},

			['llaalam madalas'] = {
				'Llaalam Madalas',
				'Dark Elf nightblade serving Telvanni.',
				'Faction: Telvanni',
				'Location: Telvanni Shadow Operations',
				'Role: Specializes in covert missions.',
				'Notes: Expert in stealth and assassination'
			},

			['thervul serethi'] = {
				'Thervul Serethi',
				'Dark Elf healer serving Telvanni.',
				'Faction: Telvanni',
				'Location: Telvanni Healer Services',
				'Role: Provides medical assistance.',
				'Notes: Skilled in healing arts'
			},

			['anis seloth'] = {
				'Anis Seloth',
				'Dark Elf alchemist serving Telvanni.',
				'Faction: Telvanni',
				'Location: Telvanni Alchemy Lab',
				'Role: Creates potions and elixirs.',
				'Notes: Expert in alchemy'
			},

			['pierlette rostorard'] = {
				'Pierlette Rostorard',
				'Breton apothecary serving Telvanni.',
				'Faction: Telvanni',
				'Location: Telvanni Apothecary',
				'Role: Prepares medicines.',
				'Notes: Knowledgeable in herbs'
			},

			['hannat zainsubani'] = {
				'Hannat Zainsubani',
				'Dark Elf thief serving Thieves Guild.',
				'Faction: Thieves Guild',
				'Location: Thieves Guild Operations',
				'Role: Performs theft missions.',
				'Notes: Skilled burglar'
			},

			['dreamer priest'] = {
				'Dreamer Priest',
				'Dark Elf priest serving Sixth House.',
				'Faction: Sixth House',
				'Location: Dreamer Sanctums',
				'Role: Conducts dream rituals.',
				'Notes: Expert in dream magic'
			},

			['llarar bereloth'] = {
				'Llarar Bereloth',
				'Dark Elf sorcerer serving Telvanni.',
				'Faction: Telvanni',
				'Location: Telvanni Towers',
				'Role: Practices arcane magic.',
				'Notes: Powerful spellcaster'
			},

			['brithroth'] = {
				'Brithroth',
				'Wood Elf acrobat serving Telvanni.',
				'Faction: Telvanni',
				'Location: Telvanni Training Grounds',
				'Role: Performs acrobatic feats.',
				'Notes: Agile and skilled'
			},

			['nael'] = {
				'Nael',
				'Wood Elf archer serving Telvanni.',
				'Faction: Telvanni',
				'Location: Telvanni Archery Range',
				'Role: Provides ranged support.',
				'Notes: Expert marksman'
			},

			['cuunel'] = {
				'Cuunel',
				'Wood Elf monk serving Telvanni.',
				'Faction: Telvanni',
				'Location: Telvanni Monastery',
				'Role: Teaches martial arts.',
				'Notes: Disciplined practitioner'
			},

			['malielle broles'] = {
				'Malielle Broles',
				'Breton spellsword serving Telvanni.',
				'Faction: Telvanni',
				'Location: Telvanni Battlegrounds',
				'Role: Combines magic and swordsmanship.',
				'Notes: Dual-trained warrior'
			},

			['dondreth'] = {
				'Dondreth',
				'Wood Elf monk serving Telvanni.',
				'Faction: Telvanni',
				'Location: Telvanni Monastery',
				'Role: Teaches combat techniques.',
				'Notes: Experienced instructor'
			},

			['arannir'] = {
				'Arannir',
				'Wood Elf acrobat serving Telvanni.',
				'Faction: Telvanni',
				'Location: Telvanni Training Grounds',
				'Role: Performs acrobatic feats.',
				'Notes: Agile and skilled'
			},

			['reron rinith'] = {
				'Reron Rinith',
				'Dark Elf sorcerer serving Telvanni.',
				'Faction: Telvanni',
				'Location: Telvanni Towers',
				'Role: Practices arcane magic.',
				'Notes: Powerful spellcaster'
			},

			['lielle vette'] = {
				'Lielle Vette',
				'Breton spellsword serving Telvanni.',
				'Faction: Telvanni',
				'Location: Telvanni Battlegrounds',
				'Role: Combines magic and swordsmanship.',
				'Notes: Dual-trained warrior'
			},

			['farare othril'] = {
				'Farare Othril',
				'Dark Elf thief serving Hlaalu.',
				'Faction: Hlaalu',
				'Location: Hlaalu Thieves Guild',
				'Role: Performs theft missions.',
				'Notes: Skilled burglar'
			},

			['remasa othril'] = {
				'Remasa Othril',
				'Dark Elf thief serving Hlaalu.',
				'Faction: Hlaalu',
				'Location: Hlaalu Thieves Guild',
				'Role: Performs theft missions.',
				'Notes: Skilled burglar'
			},

			['talmsa falas'] = {
				'Talmsa Falas',
				'Dark Elf thief serving Hlaalu.',
				'Faction: Hlaalu',
				'Location: Hlaalu Thieves Guild',
				'Role: Performs theft missions.',
				'Notes: Skilled burglar'
			},

			['valyne vedaren'] = {
				'Valyne Vedaren',
				'Dark Elf thief serving Hlaalu.',
				'Faction: Hlaalu',
				'Location: Hlaalu Thieves Guild',
				'Role: Performs theft missions.',
				'Notes: Skilled burglar'
			},

			['haleneri salor'] = {
				'Haleneri Salor',
				'Dark Elf thief serving Hlaalu.',
				'Faction: Hlaalu',
				'Location: Hlaalu Thieves Guild',
				'Role: Performs theft missions.',
				'Notes: Skilled burglar'
			},

			['vedelea othril'] = {
				'Vedelea Othril',
				'Dark Elf thief serving Hlaalu.',
				'Faction: Hlaalu',
				'Location: Hlaalu Thieves Guild',
				'Role: Performs theft missions.',
				'Notes: Skilled burglar'
			},

			['milyn faram'] = {
				'Milyn Faram',
				'Dark Elf sorcerer serving Telvanni.',
				'Faction: Telvanni',
				'Location: Telvanni Towers',
				'Role: Practices arcane magic.',
				'Notes: Powerful spellcaster'
			},

			['tirer belvayn'] = {
				'Tirer Belvayn',
				'Dark Elf sorcerer serving Telvanni.',
				'Faction: Telvanni',
				'Location: Telvanni Towers',
				'Role: Practices arcane magic.',
				'Notes: Powerful spellcaster'
			},

			['treras dres'] = {
				'Treras Dres',
				'Dark Elf sorcerer serving Telvanni.',
				'Faction: Telvanni',
				'Location: Telvanni Towers',
				'Role: Practices arcane magic.',
				'Notes: Powerful spellcaster'
			},

			['noleon sele'] = {
				'Noleon Sele',
				'Breton spellsword serving Telvanni.',
				'Faction: Telvanni',
				'Location: Telvanni Battlegrounds',
				'Role: Combines magic and swordsmanship.',
				'Notes: Dual-trained warrior'
			},

			['faric panoit'] = {
				'Faric Panoit',
				'Breton healer serving Telvanni.',
				'Faction: Telvanni',
				'Location: Telvanni Healing Chambers',
				'Role: Provides medical assistance.',
				'Notes: Skilled in healing arts'
			},

			['aglaril'] = {
				'Aglaril',
				'Wood Elf archer serving Telvanni.',
				'Faction: Telvanni',
				'Location: Telvanni Archery Range',
				'Role: Provides ranged support.',
				'Notes: Expert marksman'
			},

			['edwinna elbert'] = {
				'Edwinna Elbert',
				'Breton mage serving Mages Guild.',
				'Faction: Mages Guild',
				'Location: Mages Guild Halls',
				'Role: Practices and teaches magic.',
				'Notes: Skilled in arcane arts'
			},

			['malven romori'] = {
				'Malven Romori',
				'Dark Elf mage serving Mages Guild.',
				'Faction: Mages Guild',
				'Location: Mages Guild Facilities',
				'Role: Conducts magical research.',
				'Notes: Expert in spellcraft'
			},

			['trebonius artorius'] = {
				'Trebonius Artorius',
				'Imperial battlemage serving Mages Guild.',
				'Faction: Mages Guild',
				'Location: Mages Guild Training Grounds',
				'Role: Combines combat and magic.',
				'Notes: Powerful combat mage'
			},

			['sirilonwe'] = {
				'Sirilonwe',
				'High Elf nightblade serving Mages Guild.',
				'Faction: Mages Guild',
				'Location: Nightblade Training Areas',
				'Role: Specializes in stealth magic.',
				'Notes: Master of shadow arts'
			},

			['senilias cadiusus'] = {
				'Senilias Cadiusus',
				'Imperial mage serving Mages Guild.',
				'Faction: Mages Guild',
				'Location: Mages Guild Towers',
				'Role: Practices various schools of magic.',
				'Notes: Versatile spellcaster'
			},

			['tenyeminwe'] = {
				'Tenyeminwe',
				'High Elf battlemage serving Mages Guild.',
				'Faction: Mages Guild',
				'Location: Battlemage Training Grounds',
				'Role: Combines combat and magic.',
				'Notes: Formidable warrior-mage'
			},

			['sinnammu mirpal'] = {
				'Sinnammu Mirpal',
				'Dark Elf wise woman serving Ashlanders.',
				'Faction: Ashlanders',
				'Location: Ashlander Camps',
				'Role: Provides spiritual guidance.',
				'Notes: Expert in tribal magic'
			},

			['raxle berne'] = {
				'Raxle Berne',
				'Imperial enforcer serving Clan Berne.',
				'Faction: Clan Berne',
				'Location: Clan Strongholds',
				'Role: Maintains order.',
				'Notes: Trusted enforcer'
			},

			['dhaunayne aundae'] = {
				'Dhaunayne Aundae',
				'High Elf nightblade serving Clan Aundae.',
				'Faction: Clan Aundae',
				'Location: Clan Territories',
				'Role: Performs covert operations.',
				'Notes: Skilled in stealth'
			},

			['itermerel'] = {
				'Itermerel',
				'High Elf mage serving Mages Guild.',
				'Faction: Mages Guild',
				'Location: Mages Guild Libraries',
				'Role: Conducts magical research.',
				'Notes: Scholarly pursuits'
			},

			['listien bierles'] = {
				'Listien Bierles',
				'Breton sorcerer serving Mages Guild.',
				'Faction: Mages Guild',
				'Location: Sorcerer Quarters',
				'Role: Specializes in destructive magic.',
				'Notes: Expert in arcane arts'
			},

			['nibani maesa'] = {
				'Nibani Maesa',
				'Dark Elf wise woman serving Ashlanders.',
				'Faction: Ashlanders',
				'Location: Ashlander Camps',
				'Role: Provides spiritual guidance.',
				'Notes: Tribal leader'
			},

			['manirai'] = {
				'Manirai',
				'Dark Elf wise woman serving Ashlanders.',
				'Faction: Ashlanders',
				'Location: Ashlander Camps',
				'Role: Practices tribal magic.',
				'Notes: Respected elder'
			},

			['sonummu zabamat'] = {
				'Sonummu Zabamat',
				'Dark Elf wise woman serving Ashlanders.',
				'Faction: Ashlanders',
				'Location: Ashlander Camps',
				'Role: Heals and advises.',
				'Notes: Tribal healer'
			},

			['kaushad'] = {
				'Kaushad',
				'Dark Elf champion serving Ashlanders.',
				'Faction: Ashlanders',
				'Location: Ashlander Camps',
				'Role: Leads in combat.',
				'Notes: Powerful warrior'
			},

			['merard geves'] = {
				'Merard Geves',
				'Breton bard serving Telvanni.',
				'Faction: Telvanni',
				'Location: Telvanni Halls',
				'Role: Entertains and informs.',
				'Notes: Skilled storyteller'
			},

			['relie jeannie'] = {
				'Relie Jeannie',
				'Breton healer serving Telvanni.',
				'Faction: Telvanni',
				'Location: Telvanni Healing Chambers',
				'Role: Provides medical aid.',
				'Notes: Compassionate healer'
			},

			['rianciene aurilie'] = {
				'Rianciene Aurilie',
				'Breton spellsword serving Telvanni.',
				'Faction: Telvanni',
				'Location: Telvanni Battlegrounds',
				'Role: Combines magic and combat.',
				'Notes: Dual-class warrior'
			},

			['bravosi henim'] = {
				'Bravosi Henim',
				'Dark Elf sorcerer serving Telvanni.',
				'Faction: Telvanni',
				'Location: Telvanni Towers',
				'Role: Practices arcane magic.',
				'Notes: Powerful spellcaster'
			},

			['brerama selas'] = {
				'Brerama Selas',
				'Dark Elf warrior serving Redoran.',
				'Faction: Redoran',
				'Location: Redoran Strongholds',
				'Role: Defends territories.',
				'Notes: Loyal soldier'
			},

			['anise romoran'] = {
				'Anise Romoran',
				'Dark Elf warrior serving Redoran.',
				'Faction: Redoran',
				'Location: Redoran Fortresses',
				'Role: Engages in combat.',
				'Notes: Experienced fighter'
			},

			['temis romavel'] = {
				'Temis Romavel',
				'Dark Elf warrior serving Redoran.',
				'Faction: Redoran',
				'Location: Redoran Outposts',
				'Role: Protects borders.',
				'Notes: Stalwart defender'
			},

			['jeberilie moniel'] = {
				'Jeberilie Moniel',
				'Breton spellsword serving Telvanni.',
				'Faction: Telvanni',
				'Location: Telvanni Battlegrounds',
				'Role: Combines magic and combat.',
				'Notes: Dual-class warrior'
			},

			['derelle ysciele'] = {
				'Derelle Ysciele',
				'Breton healer serving Telvanni.',
				'Faction: Telvanni',
				'Location: Telvanni Healing Chambers',
				'Role: Treats injuries.',
				'Notes: Skilled medic'
			},

			['debentien sylbenitte'] = {
				'Debentien Sylbenitte',
				'Breton bard serving Telvanni.',
				'Faction: Telvanni',
				'Location: Telvanni Halls',
				'Role: Entertains and informs.',
				'Notes: Talented musician'
			},

			['daris adram'] = {
				'Daris Adram',
				'Dark Elf sorcerer serving Telvanni.',
				'Faction: Telvanni',
				'Location: Telvanni Towers',
				'Role: Practices arcane magic.',
				'Notes: Scholarly mage'
			},

			['ulyne henim'] = {
				'Ulyne Henim',
				'Dark Elf witchhunter serving Fighters Guild.',
				'Faction: Fighters Guild',
				'Location: Guild Headquarters',
				'Role: Hunts supernatural threats.',
				'Notes: Expert in monster hunting'
			},

			['erradan'] = {
				'Erradan',
				'Wood Elf acrobat serving Telvanni.',
				'Faction: Telvanni',
				'Location: Telvanni Training Grounds',
				'Role: Performs acrobatic feats.',
				'Notes: Agile and skilled'
			},

			['distel'] = {
				'Distel',
				'Wood Elf archer serving Telvanni.',
				'Faction: Telvanni',
				'Location: Telvanni Archery Range',
				'Role: Provides ranged support.',
				'Notes: Expert marksman'
			},

			['medyn gilnith'] = {
				'Medyn Gilnith',
				'Dark Elf sorcerer serving Telvanni.',
				'Faction: Telvanni',
				'Location: Telvanni Towers',
				'Role: Practices arcane magic.',
				'Notes: Powerful spellcaster'
			},

			['iingail'] = {
				'Iingail',
				'Wood Elf monk serving Telvanni.',
				'Faction: Telvanni',
				'Location: Telvanni Monastery',
				'Role: Teaches martial arts.',
				'Notes: Disciplined practitioner'
			},

			['arbene gernis'] = {
				'Arbene Gernis',
				'Breton healer serving Telvanni.',
				'Faction: Telvanni',
				'Location: Telvanni Healing Chambers',
				'Role: Provides medical assistance.',
				'Notes: Skilled in healing arts'
			},

			['belene yvienne'] = {
				'Belene Yvienne',
				'Breton spellsword serving Telvanni.',
				'Faction: Telvanni',
				'Location: Telvanni Battlegrounds',
				'Role: Combines magic and swordsmanship.',
				'Notes: Dual-trained warrior'
			},

			['nevrila areloth'] = {
				'Nevrila Areloth',
				'Dark Elf thief serving Camonna Tong.',
				'Faction: Camonna Tong',
				'Location: Camonna Tong Operations',
				'Role: Performs theft missions.',
				'Notes: Skilled burglar'
			},

			['meder nulen'] = {
				'Meder Nulen',
				'Dark Elf pawnbroker serving Camonna Tong.',
				'Faction: Camonna Tong',
				'Location: Camonna Tong Establishments',
				'Role: Handles illicit goods.',
				'Notes: Knowledgeable in valuables'
			},

			['minasi bavani'] = {
				'Minasi Bavani',
				'Dark Elf thief serving Camonna Tong.',
				'Faction: Camonna Tong',
				'Location: Camonna Tong Operations',
				'Role: Performs theft missions.',
				'Notes: Skilled burglar'
			},

			['llevas fels'] = {
				'Llevas Fels',
				'Dark Elf savant serving Camonna Tong.',
				'Faction: Camonna Tong',
				'Location: Camonna Tong Archives',
				'Role: Conducts research.',
				'Notes: Expert in information'
			},

			['dunsalipal dun-ahhe'] = {
				'Dunsalipal Dun-Ahhe',
				'Dark Elf assassin serving Morag Tong.',
				'Faction: Morag Tong',
				'Location: Morag Tong Contracts',
				'Role: Executes contracts.',
				'Notes: Expert in assassination'
			},

			['alven salas'] = {
				'Alven Salas',
				'Dark Elf monk serving Morag Tong.',
				'Faction: Morag Tong',
				'Location: Morag Tong Training',
				'Role: Teaches combat techniques.',
				'Notes: Disciplined practitioner'
			},

			['vaveli dralas'] = {
				'Vaveli Dralas',
				'Dark Elf agent serving Morag Tong.',
				'Faction: Morag Tong',
				'Location: Morag Tong Headquarters',
				'Role: Conducts espionage missions.',
				'Notes: Trusted operative'
			},

			['namanian facian'] = {
				'Namanius Facian',
				'Imperial nightblade serving Morag Tong.',
				'Faction: Morag Tong',
				'Location: Morag Tong Operations',
				'Role: Performs covert missions.',
				'Notes: Expert in stealth'
			},

			['muriel sette'] = {
				'Muriel Sette',
				'Breton thief serving Thieves Guild.',
				'Faction: Thieves Guild',
				'Location: Thieves Guild Headquarters',
				'Role: Performs theft missions.',
				'Notes: Skilled burglar'
			},

			['celegorn'] = {
				'Celeborn',
				'Wood Elf thief serving Thieves Guild.',
				'Faction: Thieves Guild',
				'Location: Thieves Guild Operations',
				'Role: Specializes in forest thievery.',
				'Notes: Agile and stealthy'
			},

			['big helende'] = {
				'Big Helende',
				'High Elf thief serving Thieves Guild.',
				'Faction: Thieves Guild',
				'Location: Thieves Guild Headquarters',
				'Role: Performs high-profile heists.',
				'Notes: Charismatic and skilled'
			},

			['rissinia'] = {
				'Rissinia',
				'Redguard savant serving Thieves Guild.',
				'Faction: Thieves Guild',
				'Location: Guild Archives',
				'Role: Conducts research.',
				'Notes: Expert in information'
			},

			['fandus puruseius'] = {
				'Fandus Puruseius',
				'Imperial scout serving Thieves Guild.',
				'Faction: Thieves Guild',
				'Location: Guild Outposts',
				'Role: Gathers intelligence.',
				'Notes: Skilled tracker'
			},

			['iniel'] = {
				'Iniel',
				'High Elf guild guide serving Mages Guild.',
				'Faction: Mages Guild',
				'Location: Mages Guild Halls',
				'Role: Guides new members.',
				'Notes: Knowledgeable mentor'
			},

			['hrundi'] = {
				'Hrundi',
				'Nord smith serving Fighters Guild.',
				'Faction: Fighters Guild',
				'Location: Guild Forge',
				'Role: Crafts weapons and armor.',
				'Notes: Master blacksmith'
			},

			['sondryn irathi'] = {
				'Sondryn Irathi',
				'Dark Elf scout serving Fighters Guild.',
				'Faction: Fighters Guild',
				'Location: Guild Outposts',
				'Role: Gathers intelligence.',
				'Notes: Expert tracker'
			},

			['procyon nigilius'] = {
				'Procyon Nigilius',
				'Imperial mage serving Mages Guild.',
				'Faction: Mages Guild',
				'Location: Mages Guild Towers',
				'Role: Practices various schools of magic.',
				'Notes: Versatile spellcaster'
			},

			['tusamircil'] = {
				'Tusamircil',
				'High Elf alchemist serving Mages Guild.',
				'Faction: Mages Guild',
				'Location: Alchemy Lab',
				'Role: Creates potions and elixirs.',
				'Notes: Expert in concoctions'
			},

			['uleni heleran'] = {
				'Uleni Heleran',
				'Dark Elf mage serving Mages Guild.',
				'Faction: Mages Guild',
				'Location: Mage Quarters',
				'Role: Specializes in spellcraft.',
				'Notes: Skilled in arcane arts'
			},

			['arielle phiencel'] = {
				'Arielle Phiencel',
				'Breton nightblade serving Mages Guild.',
				'Faction: Mages Guild',
				'Location: Nightblade Training',
				'Role: Combines stealth and magic.',
				'Notes: Master of shadows'
			},

			['dabienne mornardl'] = {
				'Dabienne Mornardl',
				'Breton enchanter serving Mages Guild.',
				'Faction: Mages Guild',
				'Location: Enchanting Workshop',
				'Role: Imbues items with magic.',
				'Notes: Expert enchanter'
			},

			['aunius autrus'] = {
				'Aunius Autrus',
				'Imperial priest serving Imperial Cult.',
				'Faction: Imperial Cult',
				'Location: Imperial Cult Temples',
				'Role: Conducts religious services.',
				'Notes: Devoted to Imperial traditions'
			},

			['scelian plebo'] = {
				'Scelian Plebo',
				'Imperial healer serving Imperial Cult.',
				'Faction: Imperial Cult',
				'Location: Healing Chambers',
				'Role: Provides medical aid.',
				'Notes: Skilled in temple healing'
			},

			['hasell'] = {
				'Hasell',
				'Redguard drillmaster serving Fighters Guild.',
				'Faction: Fighters Guild',
				'Location: Training Grounds',
				'Role: Trains recruits.',
				'Notes: Strict instructor'
			},

			['segunivus mantedius'] = {
				'Segunivus Mantedius',
				'Imperial savant serving Imperial Cult.',
				'Faction: Imperial Cult',
				'Location: Cult Archives',
				'Role: Conducts research.',
				'Notes: Expert in Imperial history'
			},

			['olquar'] = {
				'Olquar',
				'High Elf enchanter serving Imperial Cult.',
				'Faction: Imperial Cult',
				'Location: Enchanting Chambers',
				'Role: Imbues items with magic.',
				'Notes: Skilled enchanter'
			},

			['cocistian quaspus'] = {
				'Cocistian Quaspus',
				'Imperial apothecary serving Imperial Cult.',
				'Faction: Imperial Cult',
				'Location: Apothecary',
				'Role: Prepares potions and remedies.',
				'Notes: Expert in herbs'
			},

			['syloria siruliulus'] = {
				'Syloria Siruliulus',
				'Imperial trader serving Imperial Cult.',
				'Faction: Imperial Cult',
				'Location: Cult Markets',
				'Role: Manages trade operations.',
				'Notes: Knowledgeable merchant'
			},

			['imsin the dreamer'] = {
				'Imsin the Dreamer',
				'Nord master-at-arms serving Imperial Legion.',
				'Faction: Imperial Legion',
				'Location: Legion Training Grounds',
				'Role: Oversees combat training.',
				'Notes: Experienced military instructor'
			},

			['attelivupis catius'] = {
				'Attelivupis Catius',
				'Imperial drillmaster serving Imperial Legion.',
				'Faction: Imperial Legion',
				'Location: Legion Barracks',
				'Role: Conducts military drills.',
				'Notes: Strict disciplinarian'
			},

			['arnand liric'] = {
				'Arnand Liric',
				'Breton healer serving Imperial Legion.',
				'Faction: Imperial Legion',
				'Location: Legion Medical',
				'Role: Treats injuries.',
				'Notes: Compassionate medic'
			},

			['yambagorn gor-shulor'] = {
				'Yambagorn Gor-Shulor',
				'Orc smith serving Imperial Legion.',
				'Faction: Imperial Legion',
				'Location: Legion Forge',
				'Role: Crafts weapons and armor.',
				'Notes: Powerful blacksmith'
			},

			['hingor'] = {
				'Hingor',
				'Wood Elf scout serving Imperial Legion.',
				'Faction: Imperial Legion',
				'Location: Legion Outposts',
				'Role: Gathers intelligence.',
				'Notes: Expert tracker'
			},

			['dulian'] = {
				'Dulian',
				'Redguard priest serving Imperial Legion.',
				'Faction: Imperial Legion',
				'Location: Legion Chapels',
				'Role: Conducts religious services.',
				'Notes: Devoted cleric'
			},

			['aldaril'] = {
				'Aldaril',
				'High Elf battlemage serving Imperial Legion.',
				'Faction: Imperial Legion',
				'Location: Legion Mage Corps',
				'Role: Combines magic and combat.',
				'Notes: Powerful spellcaster'
			},

			['elvasea thalas'] = {
				'Elvasea Thalas',
				'Dark Elf scout serving Redoran.',
				'Faction: Redoran',
				'Location: Redoran Outposts',
				'Role: Gathers intelligence.',
				'Notes: Expert tracker'
			},

			['radd hard-heart'] = {
				'Radd Hard-Heart',
				'Nord master-at-arms serving Imperial Legion.',
				'Faction: Imperial Legion',
				'Location: Legion Training Grounds',
				'Role: Oversees combat training.',
				'Notes: Strict instructor'
			},

			['amarie charien'] = {
				'Amarie Charien',
				'Breton healer serving Imperial Legion.',
				'Faction: Imperial Legion',
				'Location: Legion Medical',
				'Role: Treats injuries.',
				'Notes: Skilled medic'
			},

			['erla'] = {
				'Erla',
				'Redguard smith serving Imperial Legion.',
				'Faction: Imperial Legion',
				'Location: Legion Forge',
				'Role: Crafts weapons and armor.',
				'Notes: Experienced blacksmith'
			},

			['urfing'] = {
				'Urфинг',
				'Nord trader serving Imperial Legion.',
				'Faction: Imperial Legion',
				'Location: Legion Markets',
				'Role: Manages supplies.',
				'Notes: Knowledgeable merchant'
			},

			['somutis vunnis'] = {
				'Somutis Vunnis',
				'Imperial priest serving Imperial Cult.',
				'Faction: Imperial Cult',
				'Location: Imperial Temples',
				'Role: Conducts religious services.',
				'Notes: Devoted cleric'
			},

			['solea nuccusius'] = {
				'Solea Nuccusius',
				'Imperial battlemage serving Imperial Legion.',
				'Faction: Imperial Legion',
				'Location: Legion Mage Corps',
				'Role: Combines magic and combat.',
				'Notes: Powerful spellcaster'
			},

			['crulius pontanian'] = {
				'Crulius Pontanian',
				'Imperial enchanter serving Imperial Cult.',
				'Faction: Imperial Cult',
				'Location: Enchanting Chambers',
				'Role: Imbues items with magic.',
				'Notes: Expert enchanter'
			},

			['peragon'] = {
				'Peragon',
				'Wood Elf apothecary serving Imperial Cult.',
				'Faction: Imperial Cult',
				'Location: Apothecary',
				'Role: Prepares potions and remedies.',
				'Notes: Skilled herbalist'
			},

			['naspis apinia'] = {
				'Naspis Apinia',
				'Imperial trader serving Imperial Cult.',
				'Faction: Imperial Cult',
				'Location: Cult Markets',
				'Role: Manages trade operations.',
				'Notes: Experienced merchant'
			},

			['addhiranirr'] = {
				'Addhiranirr',
				'Khajiit thief serving Thieves Guild.',
				'Faction: Thieves Guild',
				'Location: Thieves Guild Headquarters',
				'Role: Performs theft missions.',
				'Notes: Agile and cunning'
			},

			['duvianus platorius'] = {
				'Duvianus Platorius',
				'Imperial agent serving Census and Excise.',
				'Faction: Census and Excise',
				'Location: Imperial Offices',
				'Role: Conducts investigations.',
				'Notes: Trusted operative'
			},

			['mehra milo'] = {
				'Mehra Milo',
				'Dark Elf priest serving Temple.',
				'Faction: Temple',
				'Location: Temple Sanctums',
				'Role: Conducts religious services.',
				'Notes: Devoted cleric'
			},

			['huleeya'] = {
				'Huleeya',
				'Argonian assassin serving Morag Tong.',
				'Faction: Morag Tong',
				'Location: Morag Tong Contracts',
				'Role: Executes contracts.',
				'Notes: Expert in stealth'
			},

			['urven davor'] = {
				'Urven Davor',
				'Dark Elf enforcer serving Hlaalu.',
				'Faction: Hlaalu',
				'Location: Hlaalu Strongholds',
				'Role: Maintains order and security.',
				'Notes: Loyal enforcer'
			},

			['ethys savil'] = {
				'Ethys Savil',
				'Dark Elf nightblade serving Hlaalu.',
				'Faction: Hlaalu',
				'Location: Hlaalu Operations',
				'Role: Performs covert missions.',
				'Notes: Expert in stealth'
			},

			['favel gobor'] = {
				'Favel Gobor',
				'Dark Elf rogue serving Hlaalu.',
				'Faction: Hlaalu',
				'Location: Hlaalu Territory',
				'Role: Conducts espionage.',
				'Notes: Skilled infiltrator'
			},

			['trivon llaren'] = {
				'Trivon Llaren',
				'Dark Elf warrior serving Redoran.',
				'Faction: Redoran',
				'Location: Redoran Holds',
				'Role: Defends territory.',
				'Notes: Stalwart defender'
			},

			['raldenu ieneth'] = {
				'Raldenu Ieneth',
				'Dark Elf bard serving Redoran.',
				'Faction: Redoran',
				'Location: Redoran Courts',
				'Role: Entertains and informs.',
				'Notes: Talented performer'
			},

			['ferynu indrano'] = {
				'Ferynu Indrano',
				'Dark Elf barbarian serving Redoran.',
				'Faction: Redoran',
				'Location: Redoran Battlegrounds',
				'Role: Engages in melee combat.',
				'Notes: Brutal warrior'
			},

			['nathyn ilnith'] = {
				'Nathyn Ilnith',
				'Dark Elf crusader serving Redoran.',
				'Faction: Redoran',
				'Location: Redoran Strongholds',
				'Role: Leads crusades.',
				'Notes: Devoted crusader'
			},

			['ruthrisu andoril'] = {
				'Ruthrisu Andoril',
				'Dark Elf crusader serving Redoran.',
				'Faction: Redoran',
				'Location: Redoran Outposts',
				'Role: Protects interests.',
				'Notes: Fearless warrior'
			},

			['relamu ulom'] = {
				'Relamu Ulom',
				'Dark Elf witchhunter serving Redoran.',
				'Faction: Redoran',
				'Location: Redoran Territory',
				'Role: Hunts supernatural threats.',
				'Notes: Expert hunter'
			},

			['vuldronu girith'] = {
				'Vuldronu Girith',
				'Dark Elf knight serving Redoran.',
				'Faction: Redoran',
				'Location: Redoran Castles',
				'Role: Leads cavalry.',
				'Notes: Noble knight'
			},

			['balynu teran'] = {
				'Balynu Teran',
				'Dark Elf healer serving Redoran.',
				'Faction: Redoran',
				'Location: Redoran Healing Halls',
				'Role: Provides medical aid.',
				'Notes: Skilled healer'
			},

			['milvonu terandas'] = {
				'Milvonu Terandas',
				'Dark Elf warrior serving Redoran.',
				'Faction: Redoran',
				'Location: Redoran Battlegrounds',
				'Role: Engages in combat.',
				'Notes: Experienced fighter'
			},

			['golven hleran'] = {
				'Golven Hleran',
				'Dark Elf witchhunter serving Redoran.',
				'Faction: Redoran',
				'Location: Redoran Territory',
				'Role: Hunts supernatural threats.',
				'Notes: Expert tracker'
			},

			['dorynu verendas'] = {
				'Dorynu Verendas',
				'Dark Elf bard serving Redoran.',
				'Faction: Redoran',
				'Location: Redoran Courts',
				'Role: Entertains nobles.',
				'Notes: Accomplished musician'
			},

			['nethyn valno'] = {
				'Nethyn Valno',
				'Dark Elf knight serving Redoran.',
				'Faction: Redoran',
				'Location: Redoran Castles',
				'Role: Leads cavalry charges.',
				'Notes: Experienced commander'
			},

			['tavilu moren'] = {
				'Tavilu Moren',
				'Dark Elf barbarian serving Redoran.',
				'Faction: Redoran',
				'Location: Redoran Battlegrounds',
				'Role: Engages in melee combat.',
				'Notes: Fearsome warrior'
			},

			['driloru uvaram'] = {
				'Driloru Uvaram',
				'Dark Elf healer serving Redoran.',
				'Faction: Redoran',
				'Location: Redoran Healing Halls',
				'Role: Treats injuries.',
				'Notes: Compassionate healer'
			},

			['sodres nerethi'] = {
				'Sodres Nerethi',
				'Dark Elf knight serving Redoran.',
				'Faction: Redoran',
				'Location: Redoran Strongholds',
				'Role: Defends territory.',
				'Notes: Loyal defender'
			},

			['norus marvel'] = {
				'Norus Marvel',
				'Dark Elf crusader serving Redoran.',
				'Faction: Redoran',
				'Location: Redoran Outposts',
				'Role: Leads crusades.',
				'Notes: Devoted follower'
			},

			['virvyn athren'] = {
				'Virvyn Athren',
				'Dark Elf bard serving Redoran.',
				'Faction: Redoran',
				'Location: Redoran Courts',
				'Role: Entertains nobles.',
				'Notes: Skilled performer'
			},

			['dathus selvilo'] = {
				'Dathus Selvilo',
				'Dark Elf knight serving Redoran.',
				'Faction: Redoran',
				'Location: Redoran Castles',
				'Role: Commands troops.',
				'Notes: Experienced leader'
			},

			['tanel faren'] = {
				'Tanel Faren',
				'Dark Elf healer serving Redoran.',
				'Faction: Redoran',
				'Location: Redoran Healing Halls',
				'Role: Provides medical aid.',
				'Notes: Knowledgeable healer'
			},

			['tevyn athin'] = {
				'Tevyn Athin',
				'Dark Elf barbarian serving Redoran.',
				'Faction: Redoran',
				'Location: Redoran Battlegrounds',
				'Role: Engages in combat.',
				'Notes: Powerful warrior'
			},

			['both gro-durug'] = {
				'Both Gro-Durug',
				'Orc pawnbroker serving Thieves Guild.',
				'Faction: Thieves Guild',
				'Location: Thieves Guild Headquarters',
				'Role: Handles valuables.',
				'Notes: Trusted broker'
			},

			['hanarai assutlanipal'] = {
				'Hanarai Assutlanipal',
				'Dark Elf agent serving Sixth House.',
				'Faction: Sixth House',
				'Location: Sixth House Operations',
				'Role: Conducts espionage.',
				'Notes: Skilled operative'
			},

			['faves andas'] = {
				'Faves Andas',
				'Dark Elf sorcerer serving Telvanni.',
				'Faction: Telvanni',
				'Location: Telvanni Towers',
				'Role: Practices magic.',
				'Notes: Powerful spellcaster'
			},

			['gragus lleran'] = {
				'Gragus Lleran',
				'Dark Elf assassin serving Morag Tong.',
				'Faction: Morag Tong',
				'Location: Morag Tong Contracts',
				'Role: Executes contracts.',
				'Notes: Expert killer'
			},

			['arsyn salas'] = {
				'Arsyn Salas',
				'Dark Elf assassin serving Morag Tong.',
				'Faction: Morag Tong',
				'Location: Morag Tong Operations',
				'Role: Performs assassinations.',
				'Notes: Deadly assassin'
			},

			['birer indaram'] = {
				'Birer Indaram',
				'Dark Elf buoyant armiger serving Temple.',
				'Faction: Temple',
				'Location: Temple Sanctums',
				'Role: Protects sacred grounds.',
				'Notes: Elite temple guard'
			},

			['llerar mandas'] = {
				'Llerar Mandas',
				'Dark Elf crusader serving Redoran.',
				'Faction: Redoran',
				'Location: Redoran Strongholds',
				'Role: Leads crusades.',
				'Notes: Devoted warrior'
			},

			['arns saren'] = {
				'Arns Saren',
				'Dark Elf noble serving Redoran.',
				'Faction: Redoran',
				'Location: Redoran Courts',
				'Role: Advises leadership.',
				'Notes: Influential noble'
			},

			['toris saren'] = {
				'Toris Saren',
				'Dark Elf noble serving Redoran.',
				'Faction: Redoran',
				'Location: Redoran Palaces',
				'Role: Oversees affairs.',
				'Notes: High-ranking noble'
			},

			['tralas rendas'] = {
				'Tralas Rendas',
				'Dark Elf priest serving Temple.',
				'Faction: Temple',
				'Location: Temple Sanctuaries',
				'Role: Conducts services.',
				'Notes: Devout priest'
			},

			['reynel uvirith'] = {
				'Reynel Uvirith',
				'Dark Elf mage serving Telvanni.',
				'Faction: Telvanni',
				'Location: Telvanni Towers',
				'Role: Practices magic.',
				'Notes: Skilled arcane scholar'
			},

			['brethas deras'] = {
				'Brethas Deras',
				'Dark Elf spellsword serving Hlaalu.',
				'Faction: Hlaalu',
				'Location: Hlaalu Battlegrounds',
				'Role: Combines magic and combat.',
				'Notes: Dual-class warrior'
			},

			['lloros sarano'] = {
				'Lloros Sarano',
				'Dark Elf priest serving Redoran.',
				'Faction: Redoran',
				'Location: Redoran Temples',
				'Role: Conducts religious services.',
				'Notes: Devoted cleric'
			},

			['faral retheran'] = {
				'Faral Retheran',
				'Dark Elf agent serving Redoran.',
				'Faction: Redoran',
				'Location: Redoran Intelligence',
				'Role: Conducts espionage.',
				'Notes: Trusted operative'
			},

			['elone'] = {
				'Elone',
				'Redguard scout serving Blades.',
				'Faction: Blades',
				'Location: Blades Headquarters',
				'Role: Gathers intelligence.',
				'Notes: Expert tracker'
			},

			['raflod the braggart'] = {
				'Rraflod the Braggart',
				'Nord scout serving Thieves Guild.',
				'Faction: Thieves Guild',
				'Location: Thieves Guild Outposts',
				'Role: Scouts missions.',
				'Notes: Boastful but skilled'
			},

			['adraria vandacia'] = {
				'Adraria Vandacia',
				'Imperial agent serving Census and Excise.',
				'Faction: Census and Excise',
				'Location: Imperial Offices',
				'Role: Conducts investigations.',
				'Notes: Dedicated agent'
			},

			['hrisskar flat-foot'] = {
				'Hrisskar Flat-Foot',
				'Nord rogue serving Imperial Legion.',
				'Faction: Imperial Legion',
				'Location: Legion Outposts',
				'Role: Performs covert missions.',
				'Notes: Cunning rogue'
			},

			['ondi'] = {
				'Ondi',
				'Nord knight serving Imperial Legion.',
				'Faction: Imperial Legion',
				'Location: Legion Barracks',
				'Role: Leads cavalry.',
				'Notes: Experienced commander'
			},

			['almse arenim'] = {
				'Almse Arenim',
				'Dark Elf agent serving Hlaalu.',
				'Faction: Hlaalu',
				'Location: Hlaalu Intelligence',
				'Role: Conducts espionage missions.',
				'Notes: Trusted informant'
			},

			['drarus berano'] = {
				'Darus Berano',
				'Dark Elf assassin serving Hlaalu.',
				'Faction: Hlaalu',
				'Location: Hlaalu Operations',
				'Role: Executes targets.',
				'Notes: Skilled killer'
			},

			['dridas salvani'] = {
				'Dridas Salvani',
				'Dark Elf scout serving Hlaalu.',
				'Faction: Hlaalu',
				'Location: Hlaalu Outposts',
				'Role: Gathers intelligence.',
				'Notes: Expert tracker'
			},

			['andilo thelas'] = {
				'Andilo Thelas',
				'Dark Elf savant serving Hlaalu.',
				'Faction: Hlaalu',
				'Location: Hlaalu Archives',
				'Role: Conducts research.',
				'Notes: Knowledgeable scholar'
			},

			['selvura andrano'] = {
				'Selvura Andrano',
				'Dark Elf pawnbroker serving Camonna Tong.',
				'Faction: Camonna Tong',
				'Location: Camonna Tong Establishments',
				'Role: Handles valuables.',
				'Notes: Shrewd broker'
			},

			['anas ulven'] = {
				'Anas Ulven',
				'Dark Elf thief serving Camonna Tong.',
				'Faction: Camonna Tong',
				'Location: Camonna Tong Operations',
				'Role: Performs theft missions.',
				'Notes: Skilled burglar'
			},

			['sodrara andalas'] = {
				'Sodrara Andalas',
				'Dark Elf savant serving Camonna Tong.',
				'Faction: Camonna Tong',
				'Location: Camonna Tong Archives',
				'Role: Analyzes information.',
				'Notes: Expert researcher'
			},

			['daren adryn'] = {
				'Daren Adryn',
				'Dark Elf drillmaster serving Camonna Tong.',
				'Faction: Camonna Tong',
				'Location: Camonna Tong Training',
				'Role: Trains recruits.',
				'Notes: Strict instructor'
			},

			['wadarkhu'] = {
				'Wadarkhu',
				'Khajiit smuggler serving Thieves Guild.',
				'Faction: Thieves Guild',
				'Location: Thieves Guild Networks',
				'Role: Facilitates smuggling.',
				'Notes: Experienced smuggler'
			},

			['balan'] = {
				'Balan',
				'Redguard scout serving Thieves Guild.',
				'Faction: Thieves Guild',
				'Location: Thieves Guild Outposts',
				'Role: Scouts missions.',
				'Notes: Reliable scout'
			},

			['hinald'] = {
				'Hinald',
				'Redguard pawnbroker serving Thieves Guild.',
				'Faction: Thieves Guild',
				'Location: Thieves Guild Headquarters',
				'Role: Handles valuables.',
				'Notes: Trusted broker'
			},

			['persius mercius'] = {
				'Persius Mercius',
				'Imperial drillmaster serving Fighters Guild.',
				'Faction: Fighters Guild',
				'Location: Guild Training Grounds',
				'Role: Oversees training.',
				'Notes: Experienced instructor'
			},

			['lorbumol gro-aglakh'] = {
				'Lorbumol Gro-Aglakh',
				'Orc smith serving Fighters Guild.',
				'Faction: Fighters Guild',
				'Location: Guild Forge',
				'Role: Crafts weapons and armor.',
				'Notes: Master blacksmith'
			},

			['sjoring hard-heart'] = {
				'Sjoring Hard-Heart',
				'Nord drillmaster serving Fighters Guild.',
				'Faction: Fighters Guild',
				'Location: Guild Barracks',
				'Role: Conducts drills.',
				'Notes: Strict trainer'
			},

			['arantamo'] = {
				'Arantamo',
				'Dark Elf savant serving Thieves Guild.',
				'Faction: Thieves Guild',
				'Location: Guild Archives',
				'Role: Conducts research and analysis.',
				'Notes: Known as "Dурная Нога"'
			},

			['stacey'] = {
				'Stacey (Gentleman Jim Stacey)',
				'Redguard thief serving Thieves Guild.',
				'Faction: Thieves Guild',
				'Location: Thieves Guild Headquarters',
				'Role: Performs theft missions.',
				'Notes: Charismatic thief'
			},

			['avon oran'] = {
				'Sergio Avon Oran',
				'Dark Elf thief serving Hlaalu.',
				'Faction: Hlaalu',
				'Location: Hlaalu Thieves Guild',
				'Role: Conducts covert operations.',
				'Notes: Experienced infiltrator'
			},

			['engaer'] = {
				'Engaer',
				'Wood Elf assassin serving Telvanni.',
				'Faction: Telvanni',
				'Location: Telvanni Operations',
				'Role: Executes targets.',
				'Notes: Skilled killer'
			},

			['Manos Othreleth'] = {
				'Manos Othreleth',
				'Dark Elf warrior serving Hlaalu.',
				'Faction: Hlaalu',
				'Location: Hlaalu Strongholds',
				'Role: Defends territory.',
				'Notes: Loyal soldier'
			},

			['Vedam Dren'] = {
				'Vedam Dren',
				'Dark Elf knight serving Hlaalu.',
				'Faction: Hlaalu',
				'Location: Hlaalu Castles',
				'Role: Leads cavalry.',
				'Notes: Noble knight and duke'
			},

			['Suvryn Doves'] = {
				'Suvryn Doves',
				'Dark Elf scout serving Thieves Guild.',
				'Faction: Thieves Guild',
				'Location: Thieves Guild Outposts',
				'Role: Gathers intelligence.',
				'Notes: Expert tracker'
			},

			['Rufinus Alleius'] = {
				'Rufinus Alleius',
				'Imperial acrobat serving Imperial Legion.',
				'Faction: Imperial Legion',
				'Location: Legion Training Grounds',
				'Role: Performs acrobatic feats.',
				'Notes: Agile performer'
			},

			['Llemisa Marys'] = {
				'Llemisa Marys',
				'Dark Elf thief serving Camonna Tong.',
				'Faction: Camonna Tong',
				'Location: Camonna Tong Operations',
				'Role: Performs theft missions.',
				'Notes: Skilled burglar'
			},

			['Dalam Gavyn'] = {
				'Dalam Gavyn',
				'Dark Elf smith serving Camonna Tong.',
				'Faction: Camonna Tong',
				'Location: Camonna Tong Forge',
				'Role: Crafts weapons and armor.',
				'Notes: Experienced blacksmith'
			},

			['Pallia Ceno'] = {
				'Pallia Ceno',
				'Imperial agent serving Imperial Cult.',
				'Faction: Imperial Cult',
				'Location: Imperial Cult Offices',
				'Role: Conducts investigations.',
				'Notes: Trusted operative'
			},

			['frizkav brutya'] = {
				'Frizkav Brutya',
				'Breton thief serving Thieves Guild.',
				'Faction: Thieves Guild',
				'Location: Thieves Guild Headquarters',
				'Role: Performs theft missions.',
				'Notes: Cunning thief'
			},

			['ilden mirel'] = {
				'Ilden Mirel',
				'Redguard warrior serving Fighters Guild.',
				'Faction: Fighters Guild',
				'Location: Guild Battlegrounds',
				'Role: Engages in combat.',
				'Notes: Experienced fighter'
			},

			['vobend dulfass'] = {
				'Vobend Dulfass',
				'Dark Elf thief serving Thieves Guild.',
				'Faction: Thieves Guild',
				'Location: Thieves Guild Outposts',
				'Role: Performs theft missions.',
				'Notes: Skilled burglar'
			},

			['daglin selarar'] = {
				'Daglin Selarar',
				'Nord barbarian serving Fighters Guild.',
				'Faction: Fighters Guild',
				'Location: Guild Battlegrounds',
				'Role: Engages in melee combat.',
				'Notes: Powerful warrior'
			},

			['Galas Drenim'] = {
				'Galas Drenim',
				'Dark Elf sorcerer serving Telvanni.',
				'Faction: Telvanni',
				'Location: Telvanni Towers',
				'Role: Practices arcane magic.',
				'Notes: Skilled spellcaster'
			},

			['Relen Hlaalu'] = {
				'Relen Hlaalu',
				'Dark Elf nightblade serving Hlaalu.',
				'Faction: Hlaalu',
				'Location: Hlaalu Operations',
				'Role: Performs covert missions.',
				'Notes: Expert in stealth'
			},

			['Llivas Othravel'] = {
				'Llivas Othravel',
				'Dark Elf witchhunter serving Temple.',
				'Faction: Temple',
				'Location: Temple Grounds',
				'Role: Hunts supernatural threats.',
				'Notes: Devoted witchhunter'
			},

			['Ruccia Conician'] = {
				'Ruccia Conician',
				'Imperial agent serving Imperial Cult.',
				'Faction: Imperial Cult',
				'Location: Imperial Cult Offices',
				'Role: Conducts investigations.',
				'Notes: Trusted operative'
			},

			['Lassinia Mussillius'] = {
				'Lassinia Mussillius',
				'Imperial agent serving Imperial Cult.',
				'Faction: Imperial Cult',
				'Location: Imperial Cult Headquarters',
				'Role: Handles intelligence.',
				'Notes: Skilled investigator'
			},

			['Llaalam Dredil'] = {
				'Llaalam Dredil',
				'Dark Elf savant serving Imperial Legion.',
				'Faction: Imperial Legion',
				'Location: Legion Archives',
				'Role: Conducts research.',
				'Notes: Knowledgeable scholar'
			},

			['Varus Vatinius'] = {
				'Varus Vatinius',
				'Imperial warrior serving Imperial Legion.',
				'Faction: Imperial Legion',
				'Location: Legion Barracks',
				'Role: Engages in combat.',
				'Notes: Experienced soldier'
			},

			['Matus Mido'] = {
				'Matus Mido',
				'Imperial spellsword serving Imperial Legion.',
				'Faction: Imperial Legion',
				'Location: Legion Battlegrounds',
				'Role: Combines magic and combat.',
				'Notes: Dual-class warrior'
			},

			['Augurius Sialius'] = {
				'Augurius Sialius',
				'Imperial guard serving Imperial Legion.',
				'Faction: Imperial Legion',
				'Location: Legion Posts',
				'Role: Maintains security.',
				'Notes: Strict guardsman'
			},

			['Tuvene Arethan'] = {
				'Tuvene Arethan',
				'Dark Elf savant serving Imperial Legion.',
				'Faction: Imperial Legion',
				'Location: Legion Intelligence',
				'Role: Analyzes data.',
				'Notes: Expert researcher'
			},

			['Alodie Jes'] = {
				'Alodie Jes',
				'Breton warrior serving Imperial Legion.',
				'Faction: Imperial Legion',
				'Location: Legion Battlegrounds',
				'Role: Engages in combat.',
				'Notes: Skilled fighter'
			},

			['Norring'] = {
				'Norring',
				'Nord warrior serving Imperial Legion.',
				'Faction: Imperial Legion',
				'Location: Legion Outposts',
				'Role: Defends territory.',
				'Notes: Loyal soldier'
			},

			['Cavortius Albuttian'] = {
				'Cavortius Albuttian',
				'Imperial warrior serving Imperial Legion.',
				'Faction: Imperial Legion',
				'Location: Legion Barracks',
				'Role: Leads troops.',
				'Notes: Experienced commander'
			},

			['Frald the White'] = {
				'Frald the White',
				'Nord warrior serving Imperial Legion.',
				'Faction: Imperial Legion',
				'Location: Legion Battlegrounds',
				'Role: Engages in combat.',
				'Notes: Renowned for his prowess in battle'
			},

			['viccia claevius'] = {
				'Viccia Claevius',
				'Imperial Legion Priest',
				'Faction: Imperial Legion',
				'Location: Imperial Temples',
				'Role: Conducts religious services.',
				'Notes: Imperial priest'
			},

			['glallian maraennius'] = {
				'Glallian Maraennius',
				'Imperial Legion Priest',
				'Faction: Imperial Legion',
				'Location: Imperial Temples',
				'Role: Conducts religious services.',
				'Notes: Imperial priest'
			},

			['ekkhi'] = {
				'Ekkhi',
				'Imperial Legion Battlemage',
				'Faction: Imperial Legion',
				'Location: Imperial Battlegrounds',
				'Role: Combines magic and combat.',
				'Notes: Nord battlemage'
			},

			['sader'] = {
				'Sader',
				'Imperial Legion Warrior',
				'Faction: Imperial Legion',
				'Location: Imperial Barracks',
				'Role: Engages in combat.',
				'Notes: Redguard warrior'
			},

			['jelin'] = {
				'Jelin',
				'Imperial Legion Warrior',
				'Faction: Imperial Legion',
				'Location: Imperial Barracks',
				'Role: Engages in combat.',
				'Notes: Redguard warrior'
			},

			['birard adrognese'] = {
				'Birard Adrognese',
				'Imperial Legion Warrior',
				'Faction: Imperial Legion',
				'Location: Imperial Barracks',
				'Role: Engages in combat.',
				'Notes: Breton warrior'
			},

			['frostien ephine'] = {
				'Frostien Ephine',
				'Imperial Legion Warrior',
				'Faction: Imperial Legion',
				'Location: Imperial Barracks',
				'Role: Engages in combat.',
				'Notes: Breton warrior'
			},

			['lalatia varian'] = {
				'Lalatia Varian',
				'Imperial Cult Priest Service',
				'Faction: Imperial Cult',
				'Location: Imperial Temples',
				'Role: Conducts religious services.',
				'Notes: Imperial priest'
			},

			['synnolian tunifus'] = {
				'Synnolian Tunifus',
				'Imperial Cult Healer Service',
				'Faction: Imperial Cult',
				'Location: Healing Chambers',
				'Role: Provides medical aid.',
				'Notes: Imperial healer'
			},

			['sarmosia vant'] = {
				'Sarmosia Vant',
				'Imperial Cult Monk Service',
				'Faction: Imperial Cult',
				'Location: Imperial Monastery',
				'Role: Practices meditation.',
				'Notes: Imperial monk'
			},

			['sauleius cullian'] = {
				'Sauleius Cullian',
				'Imperial Cult Enchanter Service',
				'Faction: Imperial Cult',
				'Location: Enchanting Chambers',
				'Role: Imbues items with magic.',
				'Notes: Imperial enchanter'
			},

			['frik'] = {
				'Frik',
				'Imperial Cult Apothecary Service',
				'Faction: Imperial Cult',
				'Location: Apothecary',
				'Role: Prepares potions.',
				'Notes: Nord apothecary'
			},

			['kaye'] = {
				'Kaye',
				'Imperial Cult Trader Service',
				'Faction: Imperial Cult',
				'Location: Imperial Markets',
				'Role: Manages trade.',
				'Notes: Redguard trader'
			},

			['iulus truptor'] = {
				'Iulus Truptor',
				'Imperial Cult Savant Service',
				'Faction: Imperial Cult',
				'Location: Imperial Archives',
				'Role: Conducts research.',
				'Notes: Imperial scholar'
			},

			['sirollus saccus'] = {
				'Sirollus Saccus',
				'Imperial Legion Smith',
				'Faction: Imperial Legion',
				'Location: Imperial Forge',
				'Role: Crafts weapons and armor.',
				'Notes: Imperial blacksmith'
			},

			['fanildil'] = {
				'Fanildil',
				'Imperial Legion Healer Service',
				'Faction: Imperial Legion',
				'Location: Imperial Healing Halls',
				'Role: Provides medical aid.',
				'Notes: High Elf healer'
			},

			['aumsi'] = {
				'Aumsi',
				'Imperial Legion Master-at-Arms',
				'Faction: Imperial Legion',
				'Location: Imperial Training Grounds',
				'Role: Oversees combat training.',
				'Notes: Nord instructor'
			},

			['nedhelorn'] = {
				'Nedhelorn',
				'Imperial Legion Drillmaster Service',
				'Faction: Imperial Legion',
				'Location: Imperial Barracks',
				'Role: Conducts drills.',
				'Notes: Wood Elf drillmaster'
			},

			['landorume'] = {
				'Landorume',
				'Imperial Legion Trader Service',
				'Faction: Imperial Legion',
				'Location: Imperial Markets',
				'Role: Manages supplies.',
				'Notes: High Elf trader'
			},

			['nebia amphia'] = {
				'Nebia Amphia',
				'Imperial Legion Priest Service',
				'Faction: Imperial Legion',
				'Location: Imperial Temples',
				'Role: Conducts religious services.',
				'Notes: Imperial priest'
			},

			['ervona barys'] = {
				'Ervona Barys',
				'Imperial Legion Battlemage Service',
				'Faction: Imperial Legion',
				'Location: Imperial Battlegrounds',
				'Role: Combines magic and combat.',
				'Notes: Dark Elf battlemage'
			},

			['haening'] = {
				'Haening',
				'Fighters Guild Rogue',
				'Faction: Fighters Guild',
				'Location: Fighters Guild Headquarters',
				'Role: Performs covert missions.',
				'Notes: Nord rogue'
			},

			['fiiriel'] = {
				'Fiiriel',
				'Fighters Guild Barbarian',
				'Faction: Fighters Guild',
				'Location: Fighters Guild Battlegrounds',
				'Role: Engages in melee combat.',
				'Notes: High Elf barbarian'
			},

			['olfin gro-logrob'] = {
				'Olfin gro-Logrob',
				'Fighters Guild Warrior',
				'Faction: Fighters Guild',
				'Location: Fighters Guild Outposts',
				'Role: Engages in combat.',
				'Notes: Orc warrior'
			},

			['ian'] = {
				'Ian',
				'Fighters Guild Archer',
				'Faction: Fighters Guild',
				'Location: Fighters Guild Ranges',
				'Role: Provides ranged support.',
				'Notes: Redguard archer'
			},

			['siltalaure'] = {
				'Siltalaure',
				'Fighters Guild Rogue',
				'Faction: Fighters Guild',
				'Location: Fighters Guild Headquarters',
				'Role: Performs covert missions.',
				'Notes: High Elf rogue'
			},

			['thoromlallor'] = {
				'Thoromlallor',
				'Fighters Guild Barbarian',
				'Faction: Fighters Guild',
				'Location: Fighters Guild Battlegrounds',
				'Role: Engages in melee combat.',
				'Notes: Wood Elf barbarian'
			},

			['fainertil'] = {
				'Fainertil',
				'Fighters Guild Warrior',
				'Faction: Fighters Guild',
				'Location: Fighters Guild Outposts',
				'Role: Engages in combat.',
				'Notes: High Elf warrior'
			},

			['gaeldol'] = {
				'Gaeldol',
				'Fighters Guild Archer',
				'Faction: Fighters Guild',
				'Location: Fighters Guild Ranges',
				'Role: Provides ranged support.',
				'Notes: Wood Elf archer'
			},

			['saprius entius'] = {
				'Saprius Entius',
				'Imperial Legion Crusader',
				'Faction: Imperial Legion',
				'Location: Imperial Battlegrounds',
				'Role: Leads crusades.',
				'Notes: Imperial crusader'
			},
			['vinnus laecinnius'] = {
				'Vinnus Laecinnius',
				'Imperial Legion Pilgrim',
				'Faction: Imperial Legion',
				'Location: Six Fish Inn, Ebonheart',
				'Role: Serves as a teacher of skills.',
				'Notes: Teaches Merchandising (up to level 52),',
				'Persuasion (up to level 52) and Marksmanship (up to level 42)'
			},

			['ukawei'] = {
				'Ukawei',
				'Twin Lamps Healer',
				'Faction: Twin Lamps',
				'Location: Twin Lamps Headquarters',
				'Role: Provides medical aid.',
				'Notes: Argonian healer'
			},

			['onasha'] = {
				'Onasha',
				'Twin Lamps Agent',
				'Faction: Twin Lamps',
				'Location: Twin Lamps Operations',
				'Role: Conducts espionage.',
				'Notes: Argonian agent'
			},

			['heidmir'] = {
				'Heidmir',
				'Imperial Legion Noble',
				'Faction: Imperial Legion',
				'Location: Imperial Legion Headquarters',
				'Role: Advises leadership.',
				'Notes: Nord noble'
			},

			['ingokning'] = {
				'Ingokning',
				'Imperial Legion Assassin',
				'Faction: Imperial Legion',
				'Location: Imperial Legion Outposts',
				'Role: Performs assassinations.',
				'Notes: Nord assassin'
			},

			['bedraflod'] = {
				'Bedraflod',
				'Imperial Legion Savant',
				'Faction: Imperial Legion',
				'Location: Imperial Legion Archives',
				'Role: Conducts research.',
				'Notes: Nord scholar'
			},

			['eiruki hearth-healer'] = {
				'Eiruki Hearth-Healer',
				'Imperial Legion Barbarian',
				'Faction: Imperial Legion',
				'Location: Imperial Legion Battlegrounds',
				'Role: Engages in melee combat.',
				'Notes: Nord barbarian'
			},

			['briring'] = {
				'Briring',
				'Imperial Legion Barbarian',
				'Faction: Imperial Legion',
				'Location: Imperial Legion Battlegrounds',
				'Role: Engages in melee combat.',
				'Notes: Nord barbarian'
			},

			['grand inquisitor'] = {
				'Grand Inquisitor',
				'Temple Spellsword',
				'Faction: Temple',
				'Location: Temple Sanctuaries',
				'Role: Combines magic and combat.',
				'Notes: Dark Elf spellsword'
			},

			['brelo athelvis'] = {
				'Brelo Athelvis',
				'Temple Warrior',
				'Faction: Temple',
				'Location: Temple Grounds',
				'Role: Engages in combat.',
				'Notes: Dark Elf warrior'
			},

			['tamira vian'] = {
				'Tamira Vian',
				'Temple Warrior',
				'Faction: Temple',
				'Location: Temple Battlegrounds',
				'Role: Engages in combat.',
				'Notes: Dark Elf warrior'
			},

			['miara viake'] = {
				'Miara Viake',
				'Temple Warrior',
				'Faction: Temple',
				'Location: Temple Battlegrounds',
				'Role: Engages in combat.',
				'Notes: Dark Elf warrior'
			},

			['ilet tistar'] = {
				'Ilet Tistar',
				'Temple Warrior',
				'Faction: Temple',
				'Location: Temple Battlegrounds',
				'Role: Engages in combat.',
				'Notes: Dark Elf warrior'
			},

			['trevyn fedos'] = {
				'Trevyn Fedos',
				'Temple Warrior',
				'Faction: Temple',
				'Location: Temple Battlegrounds',
				'Role: Engages in combat.',
				'Notes: Dark Elf warrior'
			},

			['andalin hardil'] = {
				'Andalin Hardil',
				'Temple Warrior',
				'Faction: Temple',
				'Location: Temple Battlegrounds',
				'Role: Engages in combat.',
				'Notes: Dark Elf warrior'
			},

			['shimsun'] = {
				'Shimsun',
				'Ashlanders Hunter',
				'Faction: Ashlanders',
				'Location: Ashlander Camps',
				'Role: Tracks and hunts game.',
				'Notes: Dark Elf hunter'
			},

			['shara'] = {
				'Shara',
				'Ashlanders Hunter',
				'Faction: Ashlanders',
				'Location: Ashlander Camps',
				'Role: Tracks and hunts game.',
				'Notes: Dark Elf hunter'
			},

			['ninirrasour'] = {
				'Ninirrasour',
				'Ashlanders Herder',
				'Faction: Ashlanders',
				'Location: Ashlander Camps',
				'Role: Tends to livestock.',
				'Notes: Dark Elf herder'
			},

			['sakiran'] = {
				'Sakiran',
				'Ashlanders Hunter',
				'Faction: Ashlanders',
				'Location: Ashlander Camps',
				'Role: Tracks and hunts game.',
				'Notes: Dark Elf hunter'
			},

			['yen'] = {
				'Yen',
				'Ashlanders Herder',
				'Faction: Ashlanders',
				'Location: Ashlander Camps',
				'Role: Tends to livestock.',
				'Notes: Dark Elf herder'
			},

			['ahasour'] = {
				'Ahasour',
				'Ashlanders Herder',
				'Faction: Ashlanders',
				'Location: Ashlander Camps',
				'Role: Tends to livestock.',
				'Notes: Dark Elf herder'
			},

			['maeli'] = {
				'Maeli',
				'Ashlanders Champion',
				'Faction: Ashlanders',
				'Location: Ashlander Camps',
				'Role: Leads in combat.',
				'Notes: Dark Elf champion'
			},

			['zabamund'] = {
				'Zabamund',
				'Ashlanders Champion',
				'Faction: Ashlanders',
				'Location: Ashlander Camps',
				'Role: Leads in combat.',
				'Notes: Dark Elf champion'
			},

			['zanummu'] = {
				'Zanummu',
				'Ashlanders Scout',
				'Faction: Ashlanders',
				'Location: Ashlander Camps',
				'Role: Gathers intelligence.',
				'Notes: Dark Elf scout'
			},

			['kurapli'] = {
				'Kurapli',
				'Ashlanders Trader',
				'Faction: Ashlanders',
				'Location: Ashlander Camps',
				'Role: Manages trade.',
				'Notes: Dark Elf trader'
			},

			['shallath-piremus'] = {
				'Shallath-Piremus',
				'Ashlanders Hunter',
				'Faction: Ashlanders',
				'Location: Ashlander Camps',
				'Role: Tracks and hunts game.',
				'Notes: Dark Elf hunter'
			},

			['tussurradad'] = {
				'Tussurradad',
				'Ashlanders Hunter',
				'Faction: Ashlanders',
				'Location: Ashlander Camps',
				'Role: Tracks and hunts game.',
				'Notes: Dark Elf hunter'
			},

			['shabinbael'] = {
				'Shabinbael',
				'Ashlanders Hunter',
				'Faction: Ashlanders',
				'Location: Ashlander Camps',
				'Role: Tracks and hunts game.',
				'Notes: Dark Elf hunter'
			},

			['hainab'] = {
				'Hainab',
				'Ashlanders Herder',
				'Faction: Ashlanders',
				'Location: Ashlander Camps',
				'Role: Tends to livestock.',
				'Notes: Dark Elf herder'
			},

			['assemmus'] = {
				'Assemmus',
				'Ashlanders Scout',
				'Faction: Ashlanders',
				'Location: Ashlander Camps',
				'Role: Gathers intelligence.',
				'Notes: Dark Elf scout'
			},

			['zabamund'] = {
				'Zabamund',
				'Ashlanders Champion',
				'Faction: Ashlanders',
				'Location: Ashlander Camps',
				'Role: Leads in combat.',
				'Notes: Dark Elf champion'
			},

			['zallit'] = {
				'Zallit',
				'Ashlanders Hunter',
				'Faction: Ashlanders',
				'Location: Ashlander Camps',
				'Role: Tracks and hunts game.',
				'Notes: Dark Elf hunter'
			},

			['sen'] = {
				'Sen',
				'Ashlanders Herder',
				'Faction: Ashlanders',
				'Location: Ashlander Camps',
				'Role: Tends to livestock.',
				'Notes: Dark Elf herder'
			},

			['kammu'] = {
				'Kammu',
				'Ashlanders Scout',
				'Faction: Ashlanders',
				'Location: Ashlander Camps',
				'Role: Gathers intelligence.',
				'Notes: Dark Elf scout'
			},

			['sakulerib'] = {
				'Sakulerib',
				'Ashlanders Herder',
				'Faction: Ashlanders',
				'Location: Ashlander Camps',
				'Role: Tends to livestock.',
				'Notes: Dark Elf herder'
			},

			['ababael timsar-dadisun'] = {
				'Ababael Timsar-Dadisun',
				'Ashlanders Trader',
				'Faction: Ashlanders',
				'Location: Ashlander Camps',
				'Role: Manages trade.',
				'Notes: Dark Elf trader'
			},

			['zaba'] = {
				'Zaba',
				'Ashlanders Hunter',
				'Faction: Ashlanders',
				'Location: Ashlander Camps',
				'Role: Tracks and hunts game.',
				'Notes: Dark Elf hunter'
			},

			['tussi'] = {
				'Tussi',
				'Ashlanders Healer',
				'Faction: Ashlanders',
				'Location: Ashlander Camps',
				'Role: Provides medical aid.',
				'Notes: Dark Elf healer'
			},

			['ashur-dan'] = {
				'Ashur-Dan',
				'Ashlanders Trader',
				'Faction: Ashlanders',
				'Location: Ashlander Camps',
				'Role: Manages trade.',
				'Notes: Dark Elf trader'
			},

			['patababi'] = {
				'Patababi',
				'Ashlanders Scout',
				'Faction: Ashlanders',
				'Location: Ashlander Camps',
				'Role: Gathers intelligence.',
				'Notes: Dark Elf scout'
			},

			['ralen hlaalo'] = {
				'Ralen Hlaalo',
				'Hlaalu Merchant',
				'Faction: Hlaalu',
				'Location: Hlaalu Markets',
				'Role: Manages trade.',
				'Notes: Dark Elf merchant'
			},

			['andilu drothan'] = {
				'Andilu Drothan',
				'Hlaalu Alchemist',
				'Faction: Hlaalu',
				'Location: Hlaalu Laboratories',
				'Role: Creates potions.',
				'Notes: Dark Elf alchemist'
			},

			['zallay subaddamael'] = {
				'Zallay Subaddamael',
				'Ashlanders Scout',
				'Faction: Ashlanders',
				'Location: Ashlander Camps',
				'Role: Gathers intelligence.',
				'Notes: Dark Elf scout'
			},

			['raesa pullia'] = {
				'Raesa Pullia',
				'Imperial Legion Knight',
				'Faction: Imperial Legion',
				'Location: Imperial Barracks',
				'Role: Leads cavalry.',
				'Notes: Imperial knight'
			},

			['sul-matuul'] = {
				'Sul-Matuul',
				'Ashlanders Champion',
				'Faction: Ashlanders',
				'Location: Ashlander Camps',
				'Role: Leads in combat.',
				'Notes: Dark Elf champion'
			},

			['ashibaal'] = {
				'Ashibaal',
				'Ashlanders Champion',
				'Faction: Ashlanders',
				'Location: Ashlander Camps',
				'Role: Leads in combat.',
				'Notes: Dark Elf champion'
			},

			['minassour'] = {
				'Minassour',
				'Ashlanders Champion',
				'Faction: Ashlanders',
				'Location: Ashlander Camps',
				'Role: Leads in combat.',
				'Notes: Dark Elf champion'
			},

			['crassius curio'] = {
				'Crassius Curio',
				'Hlaalu Noble',
				'Faction: Hlaalu',
				'Location: Hlaalu Palace',
				'Role: Advises leadership.',
				'Notes: Imperial noble'
			},

			['edryno arethi'] = {
				'Edryno Areti',
				'Hlaalu Scout',
				'Faction: Hlaalu',
				'Location: Hlaalu Outposts',
				'Role: Gathers intelligence.',
				'Notes: Dark Elf scout'
			},

			['odral helvi'] = {
				'Odral Helvi',
				'Hlaalu Monk',
				'Faction: Hlaalu',
				'Location: Hlaalu Temples',
				'Role: Practices meditation.',
				'Notes: Dark Elf monk'
			},

			['ilmeni dren'] = {
				'Ilmeni Dren',
				'Hlaalu Noble',
				'Faction: Hlaalu',
				'Location: Hlaalu Courts',
				'Role: Advises leadership.',
				'Notes: Dark Elf noble'
			},

			['baren alen'] = {
				'Baren Alen',
				'Hlaalu Noble',
				'Faction: Hlaalu',
				'Location: Hlaalu Courts',
				'Role: Advises leadership.',
				'Notes: Dark Elf noble'
			},

			['tarvyn faren'] = {
				'Tarvyn Faren',
				'Hlaalu Trader',
				'Faction: Hlaalu',
				'Location: Hlaalu Markets',
				'Role: Manages trade.',
				'Notes: Dark Elf trader'
			},

			['yngling half-troll'] = {
				'Yngling Half-Troll',
				'Hlaalu Noble',
				'Faction: Hlaalu',
				'Location: Hlaalu Courts',
				'Role: Advises leadership.',
				'Notes: Nord noble'
			},

			['drarel andus'] = {
				'Drarel Andus',
				'Thieves Guild Thief',
				'Faction: Thieves Guild',
				'Location: Thieves Guild Headquarters',
				'Role: Performs theft missions.',
				'Notes: Dark Elf thief'
			},

			['ralen tilvur'] = {
				'Ralen Tilvur',
				'Hlaalu Smith',
				'Faction: Hlaalu',
				'Location: Hlaalu Forge',
				'Role: Crafts weapons and armor.',
				'Notes: Dark Elf blacksmith'
			},

			['tenisi lladri'] = {
				'Tenisi Lladri',
				'Hlaalu Commoner',
				'Faction: Hlaalu',
				'Location: Hlaalu Settlements',
				'Role: Performs daily tasks.',
				'Notes: Dark Elf commoner'
			},

			['nevena ules'] = {
				'Nevena Ules',
				'Hlaalu Noble',
				'Faction: Hlaalu',
				'Location: Hlaalu Courts',
				'Role: Advises leadership.',
				'Notes: Dark Elf noble'
			},

			['elmussa damori'] = {
				'Elmussa Damori',
				'Thieves Guild Rogue',
				'Faction: Thieves Guild',
				'Location: Thieves Guild Headquarters',
				'Role: Performs covert missions.',
				'Notes: Dark Elf rogue'
			},

			['rovone arvel'] = {
				'Rovone Arvel',
				'Hlaalu Noble',
				'Faction: Hlaalu',
				'Location: Hlaalu Courts',
				'Role: Advises leadership.',
				'Notes: Dark Elf noble'
			},
			['dram bero'] = {
				'Dram Bero',
				'Hlaalu Noble',
				'Faction: Hlaalu',
				'Location: Hlaalu Courts',
				'Role: Advises leadership.',
				'Notes: Dark Elf noble'
			},

			['banden indarys'] = {
				'Banden Indarys',
				'Redoran Warrior',
				'Faction: Redoran',
				'Location: Redoran Strongholds',
				'Role: Engages in combat.',
				'Notes: Dark Elf warrior'
			},

			['tholer saryoni'] = {
				'Tholer Saryoni',
				'Temple Priest',
				'Faction: Temple',
				'Location: Temple Sanctuaries',
				'Role: Conducts religious services.',
				'Notes: Dark Elf priest'
			},

			['uupse fyr'] = {
				'Uupse Fyr',
				'Telvanni Spellsword',
				'Faction: Telvanni',
				'Location: Telvanni Towers',
				'Role: Combines magic and combat.',
				'Notes: Dark Elf spellsword'
			},

			['ernand thierry'] = {
				'Ernand Thierry',
				'Mages Guild Alchemist',
				'Faction: Mages Guild',
				'Location: Mages Guild Laboratories',
				'Role: Creates potions.',
				'Notes: Breton alchemist'
			},

			['medila indaren'] = {
				'Medila Indaren',
				'Mages Guild Mage',
				'Faction: Mages Guild',
				'Location: Mages Guild Towers',
				'Role: Practices magic.',
				'Notes: Dark Elf mage'
			},

			['eraamion'] = {
				'Eraamion',
				'Mages Guild Nightblade',
				'Faction: Mages Guild',
				'Location: Mages Guild Shadows',
				'Role: Performs covert missions.',
				'Notes: High Elf nightblade'
			},

			['folms mirel'] = {
				'Folms Mirel',
				'Mages Guild Enchanter',
				'Faction: Mages Guild',
				'Location: Mages Guild Enchanter Chambers',
				'Role: Imbues items with magic.',
				'Notes: Dark Elf enchanter'
			},

			['iratian albarnian'] = {
				'Iratian Albarnian',
				'Imperial Legion Master-at-Arms',
				'Faction: Imperial Legion',
				'Location: Imperial Training Grounds',
				'Role: Oversees combat training.',
				'Notes: Imperial instructor'
			},

			['cunius pelelius'] = {
				'Cunius Pelelius',
				'Hlaalu Agent',
				'Faction: Hlaalu',
				'Location: Hlaalu Intelligence',
				'Role: Conducts espionage.',
				'Notes: Imperial agent'
			},

			['foves arenim'] = {
				'Foves Arenim',
				'Hlaalu Assassin',
				'Faction: Hlaalu',
				'Location: Hlaalu Operations',
				'Role: Performs assassinations.',
				'Notes: Dark Elf assassin'
			},

			['llaros uvayn'] = {
				'Llaros Uvayn',
				'Hlaalu Nightblade',
				'Faction: Hlaalu',
				'Location: Hlaalu Shadows',
				'Role: Performs covert missions.',
				'Notes: Dark Elf nightblade'
			},

			['adusamsi assurnarairan'] = {
				'Adusamsi Assurnarayran',
				'Imperial Cult Priest',
				'Faction: Imperial Cult',
				'Location: Imperial Temples',
				'Role: Conducts religious services.',
				'Notes: Dark Elf priest'
			},

			['urjorad'] = {
				'Urjorad',
				'Imperial Cult Healer',
				'Faction: Imperial Cult',
				'Location: Imperial Healing Halls',
				'Role: Provides medical aid.',
				'Notes: Khajiit healer'
			},

			['surane leoriane'] = {
				'Surane Leoriane',
				'Blades Mage',
				'Faction: Blades',
				'Location: Blades Headquarters',
				'Role: Practices magic and serves the Empire.',
				'Notes: Breton mage'
			},

			['llirala sendas'] = {
				'Llirala Sendas',
				'Temple Monk',
				'Faction: Temple',
				'Location: Temple Monastery',
				'Role: Practices meditation and service.',
				'Notes: Dark Elf monk'
			},

			['edd theman'] = {
				'Edd "Быстрый Эдди" Теман',
				'Telvanni Sorcerer',
				'Faction: Telvanni',
				'Location: Telvanni Towers',
				'Role: Practices arcane magic.',
				'Notes: Dark Elf sorcerer'
			},

			['baladas demnevanni'] = {
				'Baladas Demnevanni',
				'Telvanni Sorcerer',
				'Faction: Telvanni',
				'Location: Telvanni Towers',
				'Role: Practices arcane magic.',
				'Notes: Dark Elf sorcerer'
			},

			['aryon'] = {
				'Aryon',
				'Telvanni Sorcerer',
				'Faction: Telvanni',
				'Location: Telvanni Towers',
				'Role: Practices arcane magic.',
				'Notes: Dark Elf sorcerer'
			},

			['galos mathendis'] = {
				'Galos Mathendis',
				'Telvanni Enchanter',
				'Faction: Telvanni',
				'Location: Telvanni Enchanter Chambers',
				'Role: Imbues items with magic.',
				'Notes: Dark Elf enchanter'
			},

			['arara uvulas'] = {
				'Arara Uvulas',
				'Telvanni Sorcerer',
				'Faction: Telvanni',
				'Location: Telvanni Towers',
				'Role: Practices arcane magic.',
				'Notes: Dark Elf sorcerer'
			},

			['raven omayn'] = {
				'Raven Omayn',
				'Telvanni Sorcerer',
				'Faction: Telvanni',
				'Location: Telvanni Towers',
				'Role: Practices arcane magic.',
				'Notes: Dark Elf sorcerer'
			},

			['felisa ulessen'] = {
				'Felisa Ulessen',
				'Telvanni Mage',
				'Faction: Telvanni',
				'Location: Telvanni Towers',
				'Role: Practices magic.',
				'Notes: Dark Elf mage'
			},

			['mallam ryon'] = {
				'Mallam Rion',
				'Telvanni Mage',
				'Faction: Telvanni',
				'Location: Telvanni Towers',
				'Role: Practices magic.',
				'Notes: Dark Elf mage'
			},

			['neloth'] = {
				'Neloth',
				'Telvanni Mage',
				'Faction: Telvanni',
				'Location: Telvanni Towers',
				'Role: Practices magic.',
				'Notes: Dark Elf mage'
			},

			['dratha'] = {
				'Dratha',
				'Telvanni Sorcerer',
				'Faction: Telvanni',
				'Location: Telvanni Towers',
				'Role: Practices arcane magic.',
				'Notes: Dark Elf sorcerer'
			},

			['therana'] = {
				'Therana',
				'Telvanni Mage',
				'Faction: Telvanni',
				'Location: Telvanni Towers',
				'Role: Practices magic.',
				'Notes: Dark Elf mage'
			},

			['gothren'] = {
				'Gothren',
				'Telvanni Sorcerer',
				'Faction: Telvanni',
				'Location: Telvanni Towers',
				'Role: Practices arcane magic.',
				'Notes: Dark Elf sorcerer'
			},

			['andil'] = {
				'Andil',
				'Telvanni Apothecary',
				'Faction: Telvanni',
				'Location: Telvanni Apothecary',
				'Role: Prepares potions.',
				'Notes: High Elf apothecary'
			},

			['tenaru romoren'] = {
				'Tenaru Romoren',
				'Redoran Scout',
				'Faction: Redoran',
				'Location: Redoran Outposts',
				'Role: Gathers intelligence.',
				'Notes: Dark Elf scout'
			},

			['saruse hloran'] = {
				'Saruse Hloran',
				'Redoran Warrior',
				'Faction: Redoran',
				'Location: Redoran Strongholds',
				'Role: Engages in combat.',
				'Notes: Dark Elf warrior'
			},

			['daroso setri'] = {
				'Daroso Setri',
				'Redoran Knight',
				'Faction: Redoran',
				'Location: Redoran Castles',
				'Role: Leads cavalry.',
				'Notes: Dark Elf knight'
			},

			['relms gilvilo'] = {
				'Relms Gilvilo',
				'Redoran Priest',
				'Faction: Redoran',
				'Location: Redoran Temples',
				'Role: Conducts religious services.',
				'Notes: Dark Elf priest'
			},

			['guril reteran'] = {
				'Guril Reteran',
				'Redoran Assassin',
				'Faction: Redoran',
				'Location: Redoran Operations',
				'Role: Performs assassinations.',
				'Notes: Dark Elf assassin'
			},

			['talis drudrel'] = {
				'Talis Drudrel',
				'Redoran Barbarian',
				'Faction: Redoran',
				'Location: Redoran Battlegrounds',
				'Role: Engages in melee combat.',
				'Notes: Dark Elf barbarian'
			},

			['elms llervu'] = {
				'Elms Llervu',
				'Redoran Savant',
				'Faction: Redoran',
				'Location: Redoran Archives',
				'Role: Conducts research.',
				'Notes: Dark Elf scholar'
			},

			['balen andrano'] = {
				'Balen Andrano',
				'Redoran Trader',
				'Faction: Redoran',
				'Location: Redoran Markets',
				'Role: Manages trade.',
				'Notes: Dark Elf trader'
			},

			['savard'] = {
				'Savard',
				'Redoran Smith',
				'Faction: Redoran',
				'Location: Redoran Forge',
				'Role: Crafts weapons and armor.',
				'Notes: Nord blacksmith'
			},

			['minglos'] = {
				'Minglos',
				'Redoran Scout',
				'Faction: Redoran',
				'Location: Redoran Outposts',
				'Role: Gathers intelligence.',
				'Notes: Wood Elf scout'
			},

			['ulyno uvirith'] = {
				'Ulyno Uvirith',
				'Redoran Master-at-Arms',
				'Faction: Redoran',
				'Location: Redoran Training Grounds',
				'Role: Oversees combat training.',
				'Notes: Dark Elf instructor'
			},

			['brildraso nethan'] = {
				'Brildraso Nethan',
				'Redoran Drillmaster',
				'Faction: Redoran',
				'Location: Redoran Barracks',
				'Role: Conducts drills.',
				'Notes: Dark Elf drillmaster'
			},

			['balen sedrethi'] = {
				'Balen Sedrethi',
				'Hlaalu Enforcer',
				'Faction: Hlaalu',
				'Location: Hlaalu Enforcement',
				'Role: Maintains order.',
				'Notes: Dark Elf enforcer'
			},

			['hlenil neladren'] = {
				'Hlenil Neladren',
				'Hlaalu Spellsword',
				'Faction: Hlaalu',
				'Location: Hlaalu Battlegrounds',
				'Role: Combines magic and combat.',
				'Notes: Dark Elf spellsword'
			},

			['forvse nerethi'] = {
				'Forvse Nerethi',
				'Hlaalu Agent',
				'Faction: Hlaalu',
				'Location: Hlaalu Intelligence',
				'Role: Conducts espionage.',
				'Notes: Dark Elf agent'
			},

			['bronosa nedalor'] = {
				'Bronosa Nedalor',
				'Hlaalu Nightblade',
				'Faction: Hlaalu',
				'Location: Hlaalu Shadows',
				'Role: Performs covert missions.',
				'Notes: Dark Elf nightblade'
			},

			['lliram alvor'] = {
				'Lliram Alvor',
				'Camonna Tong Scout',
				'Faction: Camonna Tong',
				'Location: Camonna Tong Outposts',
				'Role: Gathers intelligence.',
				'Notes: Dark Elf scout'
			},

			['rarvela teran'] = {
				'Rarvela Teran',
				'Camonna Tong Pawnbroker',
				'Faction: Camonna Tong',
				'Location: Camonna Tong Headquarters',
				'Role: Manages loans.',
				'Notes: Dark Elf pawnbroker'
			},

			['belos falos'] = {
				'Belos Falos',
				'Camonna Tong Thief',
				'Faction: Camonna Tong',
				'Location: Camonna Tong Operations',
				'Role: Performs theft missions.',
				'Notes: Dark Elf thief'
			},

			['traldrisa tervayn'] = {
				'Traldrisa Tervayn',
				'Camonna Tong Savant',
				'Faction: Camonna Tong',
				'Location: Camonna Tong Archives',
				'Role: Conducts research.',
				'Notes: Dark Elf scholar'
			},

			['gilan daynes'] = {
				'Gilan Daynes',
				'Camonna Tong Smith',
				'Faction: Camonna Tong',
				'Location: Camonna Tong Forge',
				'Role: Crafts weapons and armor.',
				'Notes: Dark Elf blacksmith'
			},

			['llavesa drom'] = {
				'Llavesa Drom',
				'Camonna Tong Master-at-Arms',
				'Faction: Camonna Tong',
				'Location: Camonna Tong Training Grounds',
				'Role: Oversees combat training.',
				'Notes: Dark Elf instructor'
			},

			['nevos urns'] = {
				'Nevos Urns',
				'Camonna Tong Drillmaster',
				'Faction: Camonna Tong',
				'Location: Camonna Tong Barracks',
				'Role: Conducts drills.',
				'Notes: Dark Elf drillmaster'
			},

			['sovali uvayn'] = {
				'Sovali Uvayn',
				'Hlaalu Thief',
				'Faction: Hlaalu',
				'Location: Hlaalu Operations',
				'Role: Performs theft missions.',
				'Notes: Dark Elf thief'
			},

			['nalasa sarothren'] = {
				'Nalasa Sarothren',
				'Hlaalu Scout',
				'Faction: Hlaalu',
				'Location: Hlaalu Outposts',
				'Role: Gathers intelligence.',
				'Notes: Dark Elf scout'
			},

			['arvama rathri'] = {
				'Arvama Rathri',
				'Hlaalu Scout',
				'Faction: Hlaalu',
				'Location: Hlaalu Outposts',
				'Role: Gathers intelligence.',
				'Notes: Dark Elf scout'
			},

			['rirnas athren'] = {
				'Rirnas Athren',
				'Temple Priest',
				'Faction: Temple',
				'Location: Temple Sanctuaries',
				'Role: Conducts religious services.',
				'Notes: Dark Elf priest'
			},

			['llaalamu sathren'] = {
				'Llaalamu Sathren',
				'Temple Healer',
				'Faction: Temple',
				'Location: Temple Healing Halls',
				'Role: Provides medical aid.',
				'Notes: Dark Elf healer'
			},

			['garer danoran'] = {
				'Garer Danoran',
				'Hlaalu Agent',
				'Faction: Hlaalu',
				'Location: Hlaalu Intelligence',
				'Role: Conducts espionage.',
				'Notes: Dark Elf agent'
			},

			['galasa uvayn'] = {
				'Galasa Uvayn',
				'Hlaalu Agent',
				'Faction: Hlaalu',
				'Location: Hlaalu Intelligence',
				'Role: Conducts espionage.',
				'Notes: Dark Elf agent'
			},

			['elo arethan'] = {
				'Elo Arethan',
				'Hlaalu Savant',
				'Faction: Hlaalu',
				'Location: Hlaalu Archives',
				'Role: Conducts research.',
				'Notes: Dark Elf scholar'
			},

			['alveno andules'] = {
				'Alveno Andules',
				'Hlaalu Pawnbroker',
				'Faction: Hlaalu',
				'Location: Hlaalu Markets',
				'Role: Manages loans.',
				'Notes: Dark Elf pawnbroker'
			},

			['nads taren'] = {
				'Nads Taren',
				'Thieves Guild Thief',
				'Faction: Thieves Guild',
				'Location: Thieves Guild Headquarters',
				'Role: Performs theft missions.',
				'Notes: Dark Elf thief'
			},

			['brelda quintella'] = {
				'Brelda Quintella',
				'Temple Witchhunter',
				'Faction: Temple',
				'Location: Temple Operations',
				'Role: Hunts supernatural threats.',
				'Notes: Dark Elf witchhunter'
			},

			['chargen class'] = {
				'Chargen Class',
				'Census and Excise Agent',
				'Faction: Census and Excise',
				'Location: Census Offices',
				'Role: Conducts investigations.',
				'Notes: Breton agent'
			},

			['olumba gro-boglar'] = {
				'Olumba gro-Boglar',
				'Imperial Cult Monk',
				'Faction: Imperial Cult',
				'Location: Imperial Temples',
				'Role: Practices meditation.',
				'Notes: Orc monk'
			},

			['senise thindo'] = {
				'Senise Thindo',
				'Telvanni Battlemage',
				'Faction: Telvanni',
				'Location: Telvanni Towers',
				'Role: Combines magic and combat.',
				'Notes: Dark Elf battlemage'
			},

			['brarayni sarys'] = {
				'Brarayni Sarys',
				'Telvanni Alchemist',
				'Faction: Telvanni',
				'Location: Telvanni Laboratories',
				'Role: Creates potions.',
				'Notes: Dark Elf alchemist'
			},

			['felara andrethi'] = {
				'Felara Andrethi',
				'Telvanni Healer',
				'Faction: Telvanni',
				'Location: Telvanni Healing Chambers',
				'Role: Provides medical aid.',
				'Notes: Dark Elf healer'
			},

			['barusi venim'] = {
				'Barusi Venim',
				'Telvanni Enchanter',
				'Faction: Telvanni',
				'Location: Telvanni Enchanter Chambers',
				'Role: Imbues items with magic.',
				'Notes: Dark Elf enchanter'
			},

			['irna maryon'] = {
				'Irna Maryon',
				'Telvanni Apothecary',
				'Faction: Telvanni',
				'Location: Telvanni Apothecary',
				'Role: Prepares potions.',
				'Notes: Dark Elf apothecary'
			},

			['anora'] = {
				'Anora',
				'Telvanni Spellsword',
				'Faction: Telvanni',
				'Location: Telvanni Towers',
				'Role: Combines magic and combat.',
				'Notes: Redguard spellsword'
			},

			['rinina'] = {
				'Rinina',
				'Telvanni Spellsword',
				'Faction: Telvanni',
				'Location: Telvanni Towers',
				'Role: Combines magic and combat.',
				'Notes: Redguard spellsword'
			},

			['emusette bracques'] = {
				'Emusette Bracques',
				'Mages Guild Spellsword',
				'Faction: Mages Guild',
				'Location: Mages Guild Towers',
				'Role: Combines magic and combat.',
				'Notes: Breton spellsword'
			},

			['Arver Rethul'] = {
				'Arver Rethul',
				'Thieves Guild Drillmaster',
				'Faction: Thieves Guild',
				'Location: Thieves Guild Training Grounds',
				'Role: Conducts drills.',
				'Notes: Dark Elf drillmaster'
			},

			['Aebondeius Jucanis'] = {
				'Aebondeius Jucanis',
				'Hlaalu Warrior',
				'Faction: Hlaalu',
				'Location: Hlaalu Battlegrounds',
				'Role: Engages in combat.',
				'Notes: Imperial warrior'
			},

			['Hrargal the Crow'] = {
				'Hrargal the Crow',
				'Hlaalu Warrior',
				'Faction: Hlaalu',
				'Location: Hlaalu Battlegrounds',
				'Role: Engages in combat.',
				'Notes: Nord warrior'
			},

			['Frinnius Posuceius'] = {
				'Frinnius Posuceius',
				'Hlaalu Herder',
				'Faction: Hlaalu',
				'Location: Hlaalu Farmlands',
				'Role: Tends to livestock.',
				'Notes: Imperial herder'
			},

			['mavus ules'] = {
				'Mavus Ules',
				'Hlaalu Warrior',
				'Faction: Hlaalu',
				'Location: Hlaalu Battlegrounds',
				'Role: Engages in combat.',
				'Notes: Dark Elf warrior'
			},

			['Hlevala Madavel'] = {
				'Hlevala Madavel',
				'Hlaalu Warrior',
				'Faction: Hlaalu',
				'Location: Hlaalu Battlegrounds',
				'Role: Engages in combat.',
				'Notes: Dark Elf warrior'
			},

			['Avus Belvilo'] = {
				'Avus Belvilo',
				'Hlaalu Agent',
				'Faction: Hlaalu',
				'Location: Hlaalu Intelligence',
				'Role: Conducts espionage.',
				'Notes: Dark Elf agent'
			},

			['Mathesa Helvi'] = {
				'Mathesa Helvi',
				'Camonna Tong Scout',
				'Faction: Camonna Tong',
				'Location: Camonna Tong Outposts',
				'Role: Gathers intelligence.',
				'Notes: Dark Elf scout'
			},

			['Guldrise Dralor'] = {
				'Guldrise Dralor',
				'Thieves Guild Savant',
				'Faction: Thieves Guild',
				'Location: Thieves Guild Archives',
				'Role: Conducts research.',
				'Notes: Dark Elf scholar'
			},

			['Ivrosa Verethi'] = {
				'Ivrosa Verethi',
				'Thieves Guild Master-at-Arms',
				'Faction: Thieves Guild',
				'Location: Thieves Guild Training Grounds',
				'Role: Oversees combat training.',
				'Notes: Dark Elf instructor'
			},

			['Bolayn Rethan'] = {
				'Bolayn Rethan',
				'Hlaalu Battlemage',
				'Faction: Hlaalu',
				'Location: Hlaalu Battlegrounds',
				'Role: Combines magic and combat.',
				'Notes: Dark Elf battlemage'
			},

			['Vaval Orethi'] = {
				'Vaval Orethi',
				'Hlaalu Archer',
				'Faction: Hlaalu',
				'Location: Hlaalu Ranges',
				'Role: Provides ranged support.',
				'Notes: Dark Elf archer'
			},

			['Gathal Llethri'] = {
				'Gathal Llethri',
				'Hlaalu Knight',
				'Faction: Hlaalu',
				'Location: Hlaalu Battlegrounds',
				'Role: Leads cavalry.',
				'Notes: Dark Elf knight'
			},

			['Llaro Llethri'] = {
				'Llaro Llethri',
				'Hlaalu Knight',
				'Faction: Hlaalu',
				'Location: Hlaalu Battlegrounds',
				'Role: Leads cavalry.',
				'Notes: Dark Elf knight'
			},

			['Virene Mene'] = {
				'Virene Mene',
				'Hlaalu Warrior',
				'Faction: Hlaalu',
				'Location: Hlaalu Battlegrounds',
				'Role: Engages in combat.',
				'Notes: Breton warrior'
			},

			['Mash gro-Burol'] = {
				'Mash gro-Burol',
				'Hlaalu Warrior',
				'Faction: Hlaalu',
				'Location: Hlaalu Battlegrounds',
				'Role: Engages in combat.',
				'Notes: Orc warrior'
			},

			['Ushamph gro-Shamub'] = {
				'Ushamph gro-Shamub',
				'Hlaalu Warrior',
				'Faction: Hlaalu',
				'Location: Hlaalu Battlegrounds',
				'Role: Engages in combat.',
				'Notes: Orc warrior'
			},

			['Orvas Dren'] = {
				'Orvas Dren',
				'Camonna Tong Warrior',
				'Faction: Camonna Tong',
				'Location: Camonna Tong Strongholds',
				'Role: Engages in combat.',
				'Notes: Dark Elf warrior'
			},

			['Galos Farethi'] = {
				'Galos Farethi',
				'Hlaalu Warrior',
				'Faction: Hlaalu',
				'Location: Hlaalu Battlegrounds',
				'Role: Engages in combat.',
				'Notes: Dark Elf warrior'
			},

			['berengeval'] = {
				'Berengeval',
				'Telvanni Archer',
				'Faction: Telvanni',
				'Location: Telvanni Ranges',
				'Role: Provides ranged support.',
				'Notes: Wood Elf archer'
			},

			['velanda omani'] = {
				'Velanda Omani',
				'Hlaalu Noble',
				'Faction: Hlaalu',
				'Location: Hlaalu Courts',
				'Role: Advises leadership.',
				'Notes: Dark Elf noble'
			},

			['enar releth'] = {
				'Enar Releth',
				'Telvanni Sorcerer',
				'Faction: Telvanni',
				'Location: Telvanni Towers',
				'Role: Practices arcane magic.',
				'Notes: Dark Elf sorcerer'
			},

			['omesu hlarys'] = {
				'Omese Hlarys',
				'Hlaalu Enforcer',
				'Faction: Hlaalu',
				'Location: Hlaalu Enforcement',
				'Role: Maintains order.',
				'Notes: Dark Elf enforcer'
			},

			['talare arvel'] = {
				'Talare Arvel',
				'Hlaalu Noble',
				'Faction: Hlaalu',
				'Location: Hlaalu Courts',
				'Role: Advises leadership.',
				'Notes: Dark Elf noble'
			},

			['dredase arvel'] = {
				'Dredase Arvel',
				'Hlaalu Noble',
				'Faction: Hlaalu',
				'Location: Hlaalu Courts',
				'Role: Advises leadership.',
				'Notes: Dark Elf noble'
			},

			['urene arvel'] = {
				'Urene Arvel',
				'Hlaalu Noble',
				'Faction: Hlaalu',
				'Location: Hlaalu Courts',
				'Role: Advises leadership.',
				'Notes: Dark Elf noble'
			},

			['sedrane arvel'] = {
				'Sedrane Arvel',
				'Hlaalu Noble',
				'Faction: Hlaalu',
				'Location: Hlaalu Courts',
				'Role: Advises leadership.',
				'Notes: Dark Elf noble'
			},

			['galviso heran'] = {
				'Galviso Heran',
				'Redoran Warrior',
				'Faction: Redoran',
				'Location: Redoran Strongholds',
				'Role: Engages in combat.',
				'Notes: Dark Elf warrior'
			},

			['thoryn samori'] = {
				'Thoryn Samori',
				'Redoran Commoner',
				'Faction: Redoran',
				'Location: Redoran Settlements',
				'Role: Performs daily tasks.',
				'Notes: Dark Elf commoner'
			},

			['danasi ralen'] = {
				'Danasi Ralen',
				'Redoran Commoner',
				'Faction: Redoran',
				'Location: Redoran Settlements',
				'Role: Performs daily tasks.',
				'Notes: Dark Elf commoner'
			},

			['barnand erelie'] = {
				'Barnand Erelie',
				'Mages Guild Healer',
				'Faction: Mages Guild',
				'Location: Mages Guild Healing Chambers',
				'Role: Provides medical aid.',
				'Notes: Breton healer'
			},

			['darvasa vedas'] = {
				'Darvasa Vedas',
				'Telvanni Sorcerer',
				'Faction: Telvanni',
				'Location: Telvanni Towers',
				'Role: Practices arcane magic.',
				'Notes: Dark Elf sorcerer'
			},

			['dreyns telmon'] = {
				'Dreyns Telmon',
				'Telvanni Sorcerer',
				'Faction: Telvanni',
				'Location: Telvanni Towers',
				'Role: Practices arcane magic.',
				'Notes: Dark Elf sorcerer'
			},

			['seras gavos'] = {
				'Seras Gavos',
				'Telvanni Sorcerer',
				'Faction: Telvanni',
				'Location: Telvanni Towers',
				'Role: Practices arcane magic.',
				'Notes: Dark Elf sorcerer'
			},

			['muldroni rendas'] = {
				'Muldroni Rendas',
				'Telvanni Spellsword',
				'Faction: Telvanni',
				'Location: Telvanni Towers',
				'Role: Combines magic and combat.',
				'Notes: Dark Elf spellsword'
			},

			['aredhel'] = {
				'Aredhel',
				'Telvanni Enforcer',
				'Faction: Telvanni',
				'Location: Telvanni Enforcement',
				'Role: Maintains order.',
				'Notes: Wood Elf enforcer'
			},

			['godros'] = {
				'Godros',
				'Telvanni Agent',
				'Faction: Telvanni',
				'Location: Telvanni Intelligence',
				'Role: Conducts espionage.',
				'Notes: Wood Elf agent'
			},

			['monthadan'] = {
				'Monthadan',
				'Telvanni Healer',
				'Faction: Telvanni',
				'Location: Telvanni Healing Chambers',
				'Role: Provides medical aid.',
				'Notes: Wood Elf healer'
			},

			['gorchalas'] = {
				'Gorchalas',
				'Telvanni Sharpshooter',
				'Faction: Telvanni',
				'Location: Telvanni Ranges',
				'Role: Provides ranged support.',
				'Notes: Wood Elf sharpshooter'
			},

			['gils drelas'] = {
				'Gils Drelas',
				'Telvanni Alchemist',
				'Faction: Telvanni',
				'Location: Telvanni Laboratories',
				'Role: Creates potions.',
				'Notes: Dark Elf alchemist'
			},

			['felen maryon'] = {
				'Felen Maryon',
				'Telvanni Sorcerer',
				'Faction: Telvanni',
				'Location: Telvanni Towers',
				'Role: Practices arcane magic.',
				'Notes: Dark Elf sorcerer'
			},

			['mertisi andavel'] = {
				'Mertisi Andavel',
				'Telvanni Nightblade',
				'Faction: Telvanni',
				'Location: Telvanni Shadows',
				'Role: Performs covert missions.',
				'Notes: Dark Elf nightblade'
			},

			['mollimo of cloudrest'] = {
				'Mollimo of Cloudrest',
				'Telvanni Warrior',
				'Faction: Telvanni',
				'Location: Telvanni Strongholds',
				'Role: Engages in combat.',
				'Notes: High Elf warrior'
			},

			['ennah'] = {
				'Ennah',
				'Telvanni Sharpshooter',
				'Faction: Telvanni',
				'Location: Telvanni Ranges',
				'Role: Provides ranged support.',
				'Notes: Redguard sharpshooter'
			},

			['balis favani'] = {
				'Balis Favani',
				'Telvanni Spellsword',
				'Faction: Telvanni',
				'Location: Telvanni Towers',
				'Role: Combines magic and combat.',
				'Notes: Dark Elf spellsword'
			},

			['trerayna dalen'] = {
				'Trerayna Dalen',
				'Telvanni Enchanter',
				'Faction: Telvanni',
				'Location: Telvanni Enchanter Chambers',
				'Role: Imbues items with magic.',
				'Notes: Dark Elf enchanter'
			},

			['cun'] = {
				'Cun',
				'Telvanni Sharpshooter',
				'Faction: Telvanni',
				'Location: Telvanni Ranges',
				'Role: Provides ranged support.',
				'Notes: Wood Elf sharpshooter'
			},

			['estinan'] = {
				'Estinan',
				'Telvanni Enforcer',
				'Faction: Telvanni',
				'Location: Telvanni Enforcement',
				'Role: Maintains order.',
				'Notes: Wood Elf enforcer'
			},

			['irwaen'] = {
				'Irwaen',
				'Telvanni Sharpshooter',
				'Faction: Telvanni',
				'Location: Telvanni Ranges',
				'Role: Provides ranged support.',
				'Notes: Wood Elf sharpshooter'
			},

			['endring'] = {
				'Endring',
				'Telvanni Enforcer',
				'Faction: Telvanni',
				'Location: Telvanni Enforcement',
				'Role: Maintains order.',
				'Notes: Wood Elf enforcer'
			},

			['borwen'] = {
				'Borwen',
				'Ashlanders Scout',
				'Faction: Ashlanders',
				'Location: Ashlander Camps',
				'Role: Gathers intelligence.',
				'Notes: Wood Elf scout'
			},

			['gaelion'] = {
				'Gaelion',
				'Telvanni Enforcer',
				'Faction: Telvanni',
				'Location: Telvanni Enforcement',
				'Role: Maintains order.',
				'Notes: Dark Elf enforcer'
			},

			['adrusu rothrano'] = {
				'Adrusu Rothrano',
				'Temple Pilgrim',
				'Faction: Temple',
				'Location: Temple Pilgrimage Sites',
				'Role: Leads pilgrimages.',
				'Notes: Dark Elf pilgrim'
			},

			['delmene helas'] = {
				'Delmene Helas',
				'Temple Pilgrim',
				'Faction: Temple',
				'Location: Temple Pilgrimage Sites',
				'Role: Leads pilgrimages.',
				'Notes: Dark Elf pilgrim'
			},

			['alvela saram'] = {
				'Alvela Saram',
				'Temple Crusader',
				'Faction: Temple',
				'Location: Temple Battlegrounds',
				'Role: Leads crusades.',
				'Notes: Dark Elf crusader'
			},
			['danso indules'] = {
				'Danso Indules',
				'Temple',
				'Healer Service',
				'Location: Temple Healing Halls',
				'Role: Provides medical aid.',
				'Notes: Dark Elf healer'
			},

			['endryn llethan'] = {
				'Endryn Llethan',
				'Temple',
				'Monk Service',
				'Location: Temple Monastery',
				'Role: Practices meditation.',
				'Notes: Dark Elf monk'
			},

			['tuls valen'] = {
				'Tuls Valen',
				'Temple',
				'Monk Service',
				'Location: Temple Monastery',
				'Role: Practices meditation.',
				'Notes: Dark Elf monk'
			},

			['uvoo llaren'] = {
				'Uvoo Llaren',
				'Temple',
				'Monk Service',
				'Location: Temple Monastery',
				'Role: Practices meditation.',
				'Notes: Dark Elf monk'
			},

			['tharer rotheloth'] = {
				'Tharer Rothelot',
				'Temple',
				'Monk Service',
				'Location: Temple Monastery',
				'Role: Practices meditation.',
				'Notes: Dark Elf monk'
			},

			['feldrelo sadri'] = {
				'Feldrelo Sadri',
				'Temple',
				'Monk Service',
				'Location: Temple Monastery',
				'Role: Practices meditation.',
				'Notes: Dark Elf monk'
			},

			['tanusea veloth'] = {
				'Tanusea Veloth',
				'Temple',
				'Pilgrim',
				'Location: Temple Pilgrimage Sites',
				'Role: Leads pilgrimages.',
				'Notes: Dark Elf pilgrim'
			},

			['assantushansar'] = {
				'Assantushansar',
				'Ashlanders',
				'Barbarian',
				'Location: Ashlander Camps',
				'Role: Engages in melee combat.',
				'Notes: Dark Elf barbarian'
			},

			['sendus sathis'] = {
				'Sendus Sathis',
				'Temple',
				'Monk',
				'Location: Temple Monastery',
				'Role: Practices meditation.',
				'Notes: Dark Elf monk'
			},

			['relyn sarano'] = {
				'Relyn Sarano',
				'Hlaalu',
				'Drillmaster',
				'Location: Hlaalu Barracks',
				'Role: Conducts drills.',
				'Notes: Dark Elf drillmaster'
			},

			['breyns randas'] = {
				'Breyns Randas',
				'Hlaalu',
				'Noble',
				'Location: Hlaalu Courts',
				'Role: Advises leadership.',
				'Notes: Dark Elf noble'
			},

			['fruscia abitius'] = {
				'Fruscia Abitius',
				'Hlaalu',
				'Noble',
				'Location: Hlaalu Courts',
				'Role: Advises leadership.',
				'Notes: Imperial noble'
			},

			['serer andrano'] = {
				'Serer Andrano',
				'Hlaalu',
				'Noble',
				'Location: Hlaalu Courts',
				'Role: Advises leadership.',
				'Notes: Dark Elf noble'
			},

			['drolora salen'] = {
				'Drolora Salen',
				'Hlaalu',
				'Drillmaster',
				'Location: Hlaalu Barracks',
				'Role: Conducts drills.',
				'Notes: Dark Elf drillmaster'
			},

			['Daynasa Telandas'] = {
				'Daynasa Telandas',
				'Hlaalu',
				'Farmer',
				'Location: Hlaalu Farmlands',
				'Role: Tends to crops.',
				'Notes: Dark Elf farmer'
			},

			['llerusa hlaalu'] = {
				'Llerusa Hlaalu',
				'Hlaalu',
				'Noble',
				'Location: Hlaalu Courts',
				'Role: Advises leadership.',
				'Notes: Dark Elf noble'
			},

			['direr arano'] = {
				'Direr Arano',
				'Hlaalu',
				'Noble',
				'Location: Hlaalu Courts',
				'Role: Advises leadership.',
				'Notes: Dark Elf noble'
			},

			['velsa salaron'] = {
				'Velsa Salaron',
				'Camonna Tong',
				'Alchemist',
				'Location: Camonna Tong Laboratories',
				'Role: Creates potions.',
				'Notes: Dark Elf alchemist'
			},

			['llaynasa othran'] = {
				'Llaynasa Othran',
				'Camonna Tong',
				'Smuggler',
				'Location: Camonna Tong Outposts',
				'Role: Manages smuggling operations.',
				'Notes: Dark Elf smuggler'
			},

			['volrina quarra'] = {
				'Volrina Quarra',
				'Clan Quarra',
				'Rogue',
				'Location: Clan Quarra Territory',
				'Role: Performs covert missions.',
				'Notes: Imperial rogue'
			},

			['areas'] = {
				'Areas',
				'Clan Quarra',
				'Barbarian',
				'Location: Clan Quarra Territory',
				'Role: Engages in melee combat.',
				'Notes: Nord barbarian'
			},

			['igna'] = {
				'Igna',
				'Clan Quarra',
				'Barbarian',
				'Location: Clan Quarra Territory',
				'Role: Engages in melee combat.',
				'Notes: Nord barbarian'
			},

			['siri'] = {
				'Siri',
				'Clan Quarra',
				'Crusader',
				'Location: Clan Quarra Territory',
				'Role: Leads crusades.',
				'Notes: Nord crusader'
			},

			['mororurg'] = {
				'Mororurg',
				'Clan Aundae',
				'Alchemist',
				'Location: Clan Aundae Territory',
				'Role: Creates potions.',
				'Notes: High Elf alchemist'
			},

			['moranarg'] = {
				'Moranarg',
				'Clan Aundae',
				'Sorcerer',
				'Location: Clan Aundae Territory',
				'Role: Practices arcane magic.',
				'Notes: High Elf sorcerer'
			},

			['gladroon'] = {
				'Gladroon',
				'Clan Aundae',
				'Smith',
				'Location: Clan Aundae Forge',
				'Role: Crafts weapons and armor.',
				'Notes: High Elf blacksmith'
			},

			['tarerane'] = {
				'Tarerane',
				'Clan Aundae',
				'Nightblade',
				'Location: Clan Aundae Shadows',
				'Role: Performs covert missions.',
				'Notes: High Elf nightblade'
			},

			['lorurmend'] = {
				'Lorurmend',
				'Clan Aundae',
				'Witch',
				'Location: Clan Aundae Ritual Grounds',
				'Role: Practices dark magic.',
				'Notes: High Elf witch'
			},

			['mirkrand'] = {
				'Mirkrand',
				'Clan Aundae',
				'Sorcerer',
				'Location: Clan Aundae Territory',
				'Role: Practices arcane magic.',
				'Notes: High Elf sorcerer'
			},

			['iroroon'] = {
				'Iroroon',
				'Clan Aundae',
				'Nightblade',
				'Location: Clan Aundae Shadows',
				'Role: Performs covert missions.',
				'Notes: High Elf nightblade'
			},

			['tragrim'] = {
				'Tragrim',
				'Clan Aundae',
				'Sorcerer',
				'Location: Clan Aundae Territory',
				'Role: Practices arcane magic.',
				'Notes: High Elf sorcerer'
			},

			['pelf'] = {
				'Pelf',
				'Clan Quarra',
				'Barbarian',
				'Location: Clan Quarra Territory',
				'Role: Engages in melee combat.',
				'Notes: Nord barbarian'
			},

			['kjeld'] = {
				'Kjeld',
				'Clan Quarra',
				'Smith',
				'Location: Clan Quarra Forge',
				'Role: Crafts weapons and armor.',
				'Notes: Nord blacksmith'
			},

			['knurguri'] = {
				'Knurguri',
				'Clan Quarra',
				'Rogue',
				'Location: Clan Quarra Shadows',
				'Role: Performs covert missions.',
				'Notes: Nord rogue'
			},

			['gergio'] = {
				'Gergio',
				'Clan Berne',
				'Monk',
				'Location: Clan Berne Monastery',
				'Role: Practices meditation.',
				'Notes: Imperial monk'
			},

			['leone'] = {
				'Leone',
				'Clan Berne',
				'Acrobat',
				'Location: Clan Berne Training Grounds',
				'Role: Performs acrobatic feats.',
				'Notes: Imperial acrobat'
			},

			['germia'] = {
				'Germia',
				'Clan Berne',
				'Agent',
				'Location: Clan Berne Intelligence',
				'Role: Conducts espionage.',
				'Notes: Imperial agent'
			},

			['arenara'] = {
				'Arenara',
				'Clan Berne',
				'Smith',
				'Location: Clan Berne Forge',
				'Role: Crafts weapons and armor.',
				'Notes: Imperial blacksmith'
			},

			['eloe'] = {
				'Eloe',
				'Clan Berne',
				'Bard',
				'Location: Clan Berne Halls',
				'Role: Performs music and storytelling.',
				'Notes: Imperial bard'
			},

			['clasomo'] = {
				'Clasomo',
				'Clan Berne',
				'Monk',
				'Location: Clan Berne Monastery',
				'Role: Practices meditation.',
				'Notes: Imperial monk'
			},

			['Ildogesto'] = {
				'Ildogesto',
				'Clan Berne',
				'Enforcer',
				'Location: Clan Berne Enforcement',
				'Role: Maintains order.',
				'Notes: Imperial enforcer'
			},

			['fammana'] = {
				'Fammana',
				'Clan Berne',
				'Bard',
				'Location: Clan Berne Halls',
				'Role: Performs music and storytelling.',
				'Notes: Imperial bard'
			},

			['reberio'] = {
				'Reberio',
				'Clan Berne',
				'Acrobat',
				'Location: Clan Berne Training Grounds',
				'Role: Performs acrobatic feats.',
				'Notes: Imperial acrobat'
			},

			['natesse'] = {
				'Natesse',
				'Thieves Guild',
				'Scout',
				'Location: Thieves Guild Outposts',
				'Role: Gathers intelligence.',
				'Notes: Wood Elf scout'
			},

			['daynali dren'] = {
				'Daynali Dren',
				'Telvanni',
				'Alchemist Service',
				'Location: Telvanni Laboratories',
				'Role: Creates potions.',
				'Notes: Dark Elf alchemist'
			},

			['sadela areth'] = {
				'Sadela Aret',
				'Telvanni',
				'Sorcerer',
				'Location: Telvanni Towers',
				'Role: Practices arcane magic.',
				'Notes: Dark Elf sorcerer'
			},

			['tinaso alan'] = {
				'Tinaso Alan',
				'Telvanni',
				'Mage Service',
				'Location: Telvanni Towers',
				'Role: Practices magic.',
				'Notes: Dark Elf mage'
			},

			['diren vendu'] = {
				'Diren Vendu',
				'Telvanni',
				'Sorcerer Service',
				'Location: Telvanni Towers',
				'Role: Practices arcane magic.',
				'Notes: Dark Elf sorcerer'
			},

			['salam andrethi'] = {
				'Salama Andrethi',
				'Telvanni',
				'Nightblade Service',
				'Location: Telvanni Shadows',
				'Role: Performs covert missions.',
				'Notes: Dark Elf nightblade'
			},

			['katie'] = {
				'Katie',
				'Telvanni',
				'Enforcer',
				'Location: Telvanni Enforcement',
				'Role: Maintains order.',
				'Notes: Redguard enforcer'
			},

			['margonet'] = {
				'Margonet',
				'Telvanni',
				'Battlemage',
				'Location: Telvanni Battlegrounds',
				'Role: Combines magic and combat.',
				'Notes: Redguard battlemage'
			},

			['gelduin'] = {
				'Gelduin',
				'Telvanni',
				'Hunter',
				'Location: Telvanni Hunting Grounds',
				'Role: Tracks and hunts game.',
				'Notes: Wood Elf hunter'
			},

			['elphiron'] = {
				'Elphiron',
				'Telvanni',
				'Warrior',
				'Location: Telvanni Strongholds',
				'Role: Engages in combat.',
				'Notes: Wood Elf warrior'
			},

			['nathien'] = {
				'Nathien',
				'Telvanni',
				'Spellsword',
				'Location: Telvanni Towers',
				'Role: Combines magic and combat.',
				'Notes: Wood Elf spellsword'
			},

			['foronir'] = {
				'Foronir',
				'Telvanni',
				'Sharpshooter',
				'Location: Telvanni Ranges',
				'Role: Provides ranged support.',
				'Notes: Wood Elf sharpshooter'
			},

			['nina'] = {
				'Nina',
				'Telvanni',
				'Enforcer',
				'Location: Telvanni Enforcement',
				'Role: Maintains order.',
				'Notes: Dark Elf enforcer'
			},

			['emelin'] = {
				'Emelin',
				'Telvanni',
				'Enforcer',
				'Location: Telvanni Enforcement',
				'Role: Maintains order.',
				'Notes: Wood Elf enforcer'
			},

			['eldrilu dalen'] = {
				'Eldrilu Dalen',
				'Temple',
				'Priest Service',
				'Location: Temple Sanctuaries',
				'Role: Conducts religious services.',
				'Notes: Dark Elf priest'
			},

			['hairan mannanalit'] = {
				'Hairan Mannanalit',
				'Ashlanders',
				'Scout',
				'Location: Ashlander Camps',
				'Role: Gathers intelligence.',
				'Notes: Dark Elf scout'
			},

			['gadayn andarys'] = {
				'Gadayn Andarys',
				'Hlaalu',
				'Trader Service',
				'Location: Hlaalu Markets',
				'Role: Manages trade.',
				'Notes: Dark Elf trader'
			},

			['eloroth'] = {
				'Eloroth',
				'Hlaalu',
				'Monk',
				'Location: Hlaalu Monastery',
				'Role: Practices meditation.',
				'Notes: Wood Elf monk'
			},

			['bratheru oran'] = {
				'Bratheru Oran',
				'Hlaalu',
				'Nightblade Service',
				'Location: Hlaalu Shadows',
				'Role: Performs covert missions.',
				'Notes: Dark Elf nightblade'
			},

			['dals sadri'] = {
				'Dals Sadri',
				'Hlaalu',
				'Mage',
				'Location: Hlaalu Towers',
				'Role: Practices magic.',
				'Notes: Dark Elf mage'
			},

			['salora salobar'] = {
				'Salora Salobar',
				'Telvanni',
				'Sorcerer',
				'Location: Telvanni Towers',
				'Role: Practices arcane magic.',
				'Notes: Dark Elf sorcerer'
			},

			['tolmera relenim'] = {
				'Tolmera Relenim',
				'Hlaalu',
				'Enchanter',
				'Location: Hlaalu Enchanter Chambers',
				'Role: Imbues items with magic.',
				'Notes: Dark Elf enchanter'
			},

			['cirges adrard'] = {
				'Cirges Adrard',
				'Telvanni',
				'Archer',
				'Location: Telvanni Ranges',
				'Role: Provides ranged support.',
				'Notes: Breton archer'
			},

			['cirwedh'] = {
				'Cirwedh',
				'Telvanni',
				'Scout',
				'Location: Telvanni Outposts',
				'Role: Gathers intelligence.',
				'Notes: Wood Elf scout'
			},

			['ciel nestal'] = {
				'Ciel Nestal',
				'Telvanni',
				'Spellsword',
				'Location: Telvanni Towers',
				'Role: Combines magic and combat.',
				'Notes: Breton spellsword'
			},

			['silius fulcinius'] = {
				'Silius Fulcinius',
				'Telvanni',
				'Agent',
				'Location: Telvanni Intelligence',
				'Role: Conducts espionage.',
				'Notes: Imperial agent'
			},

			['ferarilie riscel'] = {
				'Ferarilie Riscel',
				'Telvanni',
				'Nightblade',
				'Location: Telvanni Shadows',
				'Role: Performs covert missions.',
				'Notes: Breton nightblade'
			},

			['manara othan'] = {
				'Manara Othan',
				'Telvanni',
				'Publican',
				'Location: Telvanni Markets',
				'Role: Manages tavern.',
				'Notes: Dark Elf publican'
			},

			['arvyn llerayn'] = {
				'Arvyn Llerayn',
				'Telvanni',
				'Mage',
				'Location: Telvanni Towers',
				'Role: Practices magic.',
				'Notes: Dark Elf mage'
			},

			['fendel hlaren'] = {
				'Fendel Hlaren',
				'Telvanni',
				'Noble',
				'Location: Telvanni Courts',
				'Role: Advises leadership.',
				'Notes: Dark Elf noble'
			},

			['kalorter'] = {
				'Kalorter',
				'Telvanni',
				'Warrior',
				'Location: Telvanni Battlegrounds',
				'Role: Engages in combat.',
				'Notes: Redguard warrior'
			},

			['gonk gra-gurub'] = {
				'Gonk Gra-Gurub',
				'Telvanni',
				'Warrior',
				'Location: Telvanni Battlegrounds',
				'Role: Engages in combat.',
				'Notes: Orc warrior'
			},

			['nannithon'] = {
				'Nannithon',
				'Telvanni',
				'Warrior',
				'Location: Telvanni Battlegrounds',
				'Role: Engages in combat.',
				'Notes: Redguard warrior'
			},

			['landa'] = {
				'Landa',
				'Telvanni',
				'Warrior',
				'Location: Telvanni Battlegrounds',
				'Role: Engages in combat.',
				'Notes: Redguard warrior'
			},

			['ethal seloth'] = {
				'Ethal Seloth',
				'Telvanni',
				'Sorcerer',
				'Location: Telvanni Towers',
				'Role: Practices arcane magic.',
				'Notes: Dark Elf sorcerer'
			},

			['idroso vendu'] = {
				'Idroso Vendu',
				'Telvanni',
				'Mage',
				'Location: Telvanni Towers',
				'Role: Practices magic.',
				'Notes: Dark Elf mage'
			},

			['tadas llendu'] = {
				'Tadas Llendu',
				'Telvanni',
				'Commoner',
				'Location: Telvanni Settlements',
				'Role: Performs daily tasks.',
				'Notes: Dark Elf commoner'
			},

			['audenian valius'] = {
				'Audenian Valius',
				'Telvanni',
				'Enchanter Service',
				'Location: Telvanni Enchanter Chambers',
				'Role: Imbues items with magic.',
				'Notes: Imperial enchanter'
			},

			['salver lleran'] = {
				'Salver Lleran',
				'Telvanni',
				'Sorcerer Service',
				'Location: Telvanni Towers',
				'Role: Practices arcane magic.',
				'Notes: Dark Elf sorcerer'
			},

			['galuro belan'] = {
				'Galuro Belan',
				'Telvanni',
				'Apothecary Service',
				'Location: Telvanni Apothecary',
				'Role: Prepares potions.',
				'Notes: Dark Elf apothecary'
			},

			['melie frenck'] = {
				'Melie Frenck',
				'Temple',
				'Healer Service',
				'Location: Temple Healing Halls',
				'Role: Provides medical aid.',
				'Notes: Breton healer'
			},

			['mavon drenim'] = {
				'Mavon Drenim',
				'Telvanni',
				'Mage',
				'Location: Telvanni Towers',
				'Role: Practices magic.',
				'Notes: Dark Elf mage'
			},

			['rogdul gro-bularz'] = {
				'Rogdul Gro-Bularz',
				'Morag Tong',
				'Assassin Service',
				'Location: Morag Tong Operations',
				'Role: Performs assassinations.',
				'Notes: Orc assassin'
			},

			['eno hlaalu'] = {
				'Eno Hlaalu',
				'Morag Tong',
				'Assassin',
				'Location: Morag Tong Operations',
				'Role: Performs assassinations.',
				'Notes: Dark Elf assassin'
			},

			['turedus talanian'] = {
				'Turedus Talanian',
				'Telvanni',
				'Warrior',
				'Location: Telvanni Battlegrounds',
				'Role: Engages in combat.',
				'Notes: Imperial warrior'
			},

			['milar maryon'] = {
				'Milar Maryon',
				'Telvanni',
				'Healer Service',
				'Location: Telvanni Healing Chambers',
				'Role: Provides medical aid.',
				'Notes: Dark Elf healer'
			},

			['alenus vendu'] = {
				'Alenus Vendu',
				'Telvanni',
				'Enchanter Service',
				'Location: Telvanni Enchanter Chambers',
				'Role: Imbues items with magic.',
				'Notes: Dark Elf enchanter'
			},

			['mirvon andrethi'] = {
				'Mirvon Andrethi',
				'Telvanni',
				'Monk Service',
				'Location: Telvanni Monastery',
				'Role: Practices meditation.',
				'Notes: Dark Elf monk'
			},

			['cania mico'] = {
				'Cania Mico',
				'Telvanni',
				'Warrior',
				'Location: Telvanni Battlegrounds',
				'Role: Engages in combat.',
				'Notes: Imperial warrior'
			},

			['cidius caro'] = {
				'Cidius Caro',
				'Telvanni',
				'Battlemage',
				'Location: Telvanni Battlegrounds',
				'Role: Combines magic and combat.',
				'Notes: Imperial battlemage'
			},

			['luspinian hertarian'] = {
				'Luspinian Hertarian',
				'Telvanni',
				'Sharpshooter',
				'Location: Telvanni Ranges',
				'Role: Provides ranged support.',
				'Notes: Imperial sharpshooter'
			},

			["ra'kothre"] = {
				"Ra'Kothre",
				'Telvanni',
				'Warrior',
				'Location: Telvanni Battlegrounds',
				'Role: Engages in combat.',
				'Notes: Khajiit warrior'
			},

			['ronerelie philulanie'] = {
				'Ronerelie Philulanie',
				'Telvanni',
				'Assassin',
				'Location: Telvanni Shadows',
				'Role: Performs assassinations.',
				'Notes: Breton assassin'
			},

			['rimintil'] = {
				'Rimintil',
				'Telvanni',
				'Crusader',
				'Location: Telvanni Battlegrounds',
				'Role: Leads crusades.',
				'Notes: High Elf crusader'
			},

			['goler andrethi'] = {
				'Goler Andrethi',
				'Telvanni',
				'Witchhunter',
				'Location: Telvanni Operations',
				'Role: Hunts supernatural threats.',
				'Notes: Dark Elf witchhunter'
			},

			['esar-don dunsamsi'] = {
				'Esar-Don Dunsamsi',
				'Ashlanders',
				'Scout',
				'Location: Ashlander Camps',
				'Role: Gathers intelligence.',
				'Notes: Dark Elf scout'
			},

			['hreirek the lean'] = {
				'Hreirek the Lean',
				'Thieves Guild',
				'Thief Service',
				'Location: Thieves Guild Operations',
				'Role: Performs theft missions.',
				'Notes: Nord thief'
			},

			['nedeni tenim'] = {
				'Nedeni Tenim',
				'Temple',
				'Witchhunter',
				'Location: Temple Operations',
				'Role: Hunts supernatural threats.',
				'Notes: Dark Elf witchhunter'
			},

			['nalmila thelas'] = {
				'Nalmila Thelas',
				'Temple',
				'Crusader',
				'Location: Temple Battlegrounds',
				'Role: Leads crusades.',
				'Notes: Dark Elf crusader'
			},

			['radene hlaalu'] = {
				'Radene Hlaalu',
				'Temple',
				'Ordinator Guard',
				'Location: Temple Guard Posts',
				'Role: Maintains order.',
				'Notes: Dark Elf ordinator'
			},

			['nervana verelas'] = {
				'Nervana Verelas',
				'Temple',
				'Crusader',
				'Location: Temple Battlegrounds',
				'Role: Leads crusades.',
				'Notes: Dark Elf crusader'
			},

			['elam andas'] = {
				'Elam Andas',
				'Temple',
				'Crusader',
				'Location: Temple Battlegrounds',
				'Role: Leads crusades.',
				'Notes: Dark Elf crusader'
			},

			['tarer braryn'] = {
				'Tarer Braryn',
				'Temple',
				'Crusader',
				'Location: Temple Battlegrounds',
				'Role: Leads crusades.',
				'Notes: Dark Elf crusader'
			},

			['melvure rindu'] = {
				'Melvure Rindu',
				'Temple',
				'Witchhunter',
				'Location: Temple Operations',
				'Role: Hunts supernatural threats.',
				'Notes: Dark Elf witchhunter'
			},

			['felmena falavel'] = {
				'Felmena Falavel',
				'Temple',
				'Ordinator',
				'Location: Temple Guard Posts',
				'Role: Maintains order.',
				'Notes: Dark Elf ordinator'
			},

			['aroa nethalen'] = {
				'Aroa Nethalen',
				'Temple',
				'Ordinator',
				'Location: Temple Guard Posts',
				'Role: Maintains order.',
				'Notes: Dark Elf ordinator'
			},

			['suryn athones'] = {
				'Suryn Athones',
				'Temple',
				'Ordinator',
				'Location: Temple Guard Posts',
				'Role: Maintains order.',
				'Notes: Dark Elf ordinator'
			},

			['garyne uvenim'] = {
				'Garyne Uvenim',
				'Temple',
				'Pilgrim',
				'Location: Temple Pilgrimage Sites',
				'Role: Leads pilgrimages.',
				'Notes: Dark Elf pilgrim'
			},

			['nevil malvayn'] = {
				'Nevil Malvayn',
				'Temple',
				'Pilgrim',
				'Location: Temple Pilgrimage Sites',
				'Role: Leads pilgrimages.',
				'Notes: Dark Elf pilgrim'
			},

			['brerayne raloran'] = {
				'Brerayne Raloran',
				'Temple',
				'Pilgrim',
				'Location: Temple Pilgrimage Sites',
				'Role: Leads pilgrimages.',
				'Notes: Dark Elf pilgrim'
			},

			['dileno lloran'] = {
				'Dileno Lloran',
				'Temple',
				'Priest Service',
				'Location: Temple Sanctuaries',
				'Role: Conducts religious services.',
				'Notes: Dark Elf priest'
			},

			['llandris thirandus'] = {
				'Llandris Thirandus',
				'Temple',
				'Enchanter Service',
				'Location: Temple Enchanter Chambers',
				'Role: Imbues items with magic.',
				'Notes: Dark Elf enchanter'
			},

			['eris telas'] = {
				'Eris Telas',
				'Temple',
				'Apothecary Service',
				'Location: Temple Apothecary',
				'Role: Prepares potions.',
				'Notes: Dark Elf apothecary'
			},

			['balver sarethan'] = {
				'Balver Sarethan',
				'Temple',
				'Pilgrim',
				'Location: Temple Pilgrimage Sites',
				'Role: Leads pilgrimages.',
				'Notes: Dark Elf pilgrim'
			},

			['velms sadryon'] = {
				'Velms Sadryon',
				'Temple',
				'Savant',
				'Location: Temple Archives',
				'Role: Conducts research.',
				'Notes: Dark Elf scholar'
			},

			['raig'] = {
				'Raig',
				'Fighters Guild',
				'Master-at-Arms',
				'Location: Fighters Guild Training Grounds',
				'Role: Oversees combat training.',
				'Notes: Redguard instructor'
			},

			['baurin'] = {
				'Baurin',
				'Fighters Guild',
				'Scout',
				'Location: Fighters Guild Outposts',
				'Role: Gathers intelligence.',
				'Notes: Wood Elf scout'
			},

			['bashag gro-snagdu'] = {
				'Bashag Gro-Snagdu',
				'Fighters Guild',
				'Commoner',
				'Location: Fighters Guild Settlements',
				'Role: Performs daily tasks.',
				'Notes: Orc commoner'
			},

			['flacassia fauseius'] = {
				'Flacassia Fauseius',
				'Mages Guild',
				'Guild Guide',
				'Location: Mages Guild Towers',
				'Role: Guides newcomers.',
				'Notes: Imperial guide'
			},

			['craeita jullalian'] = {
				'Craeita Jullalian',
				'Mages Guild',
				'Alchemist Service',
				'Location: Mages Guild Laboratories',
				'Role: Creates potions.',
				'Notes: Imperial alchemist'
			},

			['janand maulinie'] = {
				'Janand Maulinie',
				'Mages Guild',
				'Enchanter Service',
				'Location: Mages Guild Enchanter Chambers',
				'Role: Imbues items with magic.',
				'Notes: Breton enchanter'
			},

			['hylf the harrier'] = {
				'Hylf the Harrier',
				'Fighters Guild',
				'Barbarian',
				'Location: Fighters Guild Strongholds',
				'Role: Engages in melee combat.',
				'Notes: Nord barbarian'
			},

			['bethes sarothril'] = {
				'Bethes Sarothril',
				'Temple',
				'Witchhunter',
				'Location: Temple Operations',
				'Role: Hunts supernatural threats.',
				'Notes: Dark Elf witchhunter'
			},

			['drores arvel'] = {
				'Drores Arvel',
				'Temple',
				'Witchhunter',
				'Location: Temple Operations',
				'Role: Hunts supernatural threats.',
				'Notes: Dark Elf witchhunter'
			},

			['daral thirelot'] = {
				'Daral Thirelot',
				'Temple',
				'Witchhunter',
				'Location: Temple Operations',
				'Role: Hunts supernatural threats.',
				'Notes: Dark Elf witchhunter'
			},

			['salvas arelet'] = {
				'Salvas Arelet',
				'Temple',
				'Witchhunter',
				'Location: Temple Operations',
				'Role: Hunts supernatural threats.',
				'Notes: Dark Elf witchhunter'
			},

			['uresa omoril'] = {
				'Uresa Omoril',
				'Temple',
				'Ordinator',
				'Location: Temple Guard Posts',
				'Role: Maintains order.',
				'Notes: Dark Elf ordinator'
			},

			['endroni dalas'] = {
				'Endroni Dalas',
				'Temple',
				'Ordinator',
				'Location: Temple Guard Posts',
				'Role: Maintains order.',
				'Notes: Dark Elf ordinator'
			},

			['nals indrano'] = {
				'Nals Indrano',
				'Temple',
				'Witchhunter',
				'Location: Temple Operations',
				'Role: Hunts supernatural threats.',
				'Notes: Dark Elf witchhunter'
			},

			['gilas inlador'] = {
				'Gilas Inlador',
				'Mages Guild',
				'Sorcerer',
				'Location: Mages Guild Towers',
				'Role: Practices arcane magic.',
				'Notes: Dark Elf sorcerer'
			},

			['darane mencele'] = {
				'Darane Mencele',
				'Mages Guild',
				'Sorcerer',
				'Location: Mages Guild Towers',
				'Role: Practices arcane magic.',
				'Notes: Dark Elf sorcerer'
			},

			['urim gro-bulag'] = {
				'Urim Gro-Bulag',
				'Mages Guild',
				'Warrior',
				'Location: Mages Guild Battlegrounds',
				'Role: Engages in combat.',
				'Notes: Orc warrior'
			},

			['durzub gro-bagamakh'] = {
				'Durzub Gro-Bagamakh',
				'Mages Guild',
				'Barbarian',
				'Location: Mages Guild Strongholds',
				'Role: Engages in melee combat.',
				'Notes: Orc barbarian'
			},

			['murzush gra-bulфим'] = {
				'Murzush Gra-Bulфим',
				'Mages Guild',
				'Warrior',
				'Location: Mages Guild Battlegrounds',
				'Role: Engages in combat.',
				'Notes: Orc warrior'
			},

			['edril vules'] = {
				'Edril Vules',
				'Telvanni',
				'Sorcerer',
				'Location: Telvanni Towers',
				'Role: Practices arcane magic.',
				'Notes: Dark Elf sorcerer'
			},

			['roggvar blue-tooth'] = {
				'Roggvar Blue-Tooth',
				'Telvanni',
				'Warrior',
				'Location: Telvanni Battlegrounds',
				'Role: Engages in combat.',
				'Notes: Nord warrior'
			},

			['hirnir'] = {
				'Hirnir',
				'Telvanni',
				'Barbarian',
				'Location: Telvanni Strongholds',
				'Role: Engages in melee combat.',
				'Notes: Nord barbarian'
			},

			['ringvild'] = {
				'Ringvild',
				'Telvanni',
				'Rogue',
				'Location: Telvanni Shadows',
				'Role: Performs covert missions.',
				'Notes: Nord rogue'
			},

			['abbard the wild'] = {
				'Abbard the Wild',
				'Telvanni',
				'Barbarian',
				'Location: Telvanni Strongholds',
				'Role: Engages in melee combat.',
				'Notes: Nord barbarian'
			},

			['salen ravel'] = {
				'Salen Ravel',
				'Temple',
				'Priest Service',
				'Location: Temple Sanctuaries',
				'Role: Conducts religious services.',
				'Notes: Dark Elf priest'
			},

			['sedris omalen'] = {
				'Sedris Omalen',
				'Redoran',
				'Priest Service',
				'Location: Redoran Sanctuaries',
				'Role: Conducts religious services.',
				'Notes: Dark Elf priest'
			},

			['alds baro'] = {
				'Alds Baro',
				'Redoran',
				'Smith',
				'Location: Redoran Forge',
				'Role: Crafts weapons and armor.',
				'Notes: Dark Elf blacksmith'
			},

			['saryn sarothril'] = {
				'Saryn Sarothril',
				'Redoran',
				'Master-at-Arms',
				'Location: Redoran Training Grounds',
				'Role: Oversees combat training.',
				'Notes: Dark Elf instructor'
			},

			['nuleno tedas'] = {
				'Nuleno Tedas',
				'Redoran',
				'Scout',
				'Location: Redoran Outposts',
				'Role: Gathers intelligence.',
				'Notes: Dark Elf scout'
			},

			['minnibi selkin-adda'] = {
				'Minnibi Selkin-Adda',
				'Morag Tong',
				'Nightblade Service',
				'Location: Morag Tong Operations',
				'Role: Performs covert missions.',
				'Notes: Dark Elf nightblade'
			},

			['ulmesi baryon'] = {
				'Ulmesi Baryon',
				'Morag Tong',
				'Agent',
				'Location: Morag Tong Intelligence',
				'Role: Conducts espionage.',
				'Notes: Dark Elf agent'
			},

			['serul dathren'] = {
				'Serul Dathren',
				'Morag Tong',
				'Monk Service',
				'Location: Morag Tong Monastery',
				'Role: Practices meditation.',
				'Notes: Dark Elf monk'
			},

			['ganalyn saram'] = {
				'Ganalyn Saram',
				'Hlaalu',
				'Alchemist Service',
				'Location: Hlaalu Laboratories',
				'Role: Creates potions.',
				'Notes: Dark Elf alchemist'
			},

			['garas seloth'] = {
				'Garas Seloth',
				'Telvanni',
				'Alchemist Service',
				'Location: Telvanni Laboratories',
				'Role: Creates potions.',
				'Notes: Dark Elf alchemist'
			},

			['arvela falas'] = {
				'Arvela Falas',
				'Hlaalu',
				'Nightblade',
				'Location: Hlaalu Shadows',
				'Role: Performs covert missions.',
				'Notes: Dark Elf nightblade'
			},

			['falso sadrys'] = {
				'Falso Sadrys',
				'Hlaalu',
				'Commoner',
				'Location: Hlaalu Settlements',
				'Role: Performs daily tasks.',
				'Notes: Dark Elf commoner'
			},

			['ginadura andrethi'] = {
				'Ginadura Andrethi',
				'Hlaalu',
				'Noble',
				'Location: Hlaalu Courts',
				'Role: Advises leadership.',
				'Notes: Dark Elf noble'
			},

			['llathyno hlaalu'] = {
				'Llathyno Hlaalu',
				'Temple',
				'Priest Service',
				'Location: Temple Sanctuaries',
				'Role: Conducts religious services.',
				'Notes: Dark Elf priest'
			},

			['llarara omayn'] = {
				'Llarara Omayn',
				'Temple',
				'Priest Service',
				'Location: Temple Sanctuaries',
				'Role: Conducts religious services.',
				'Notes: Dark Elf priest'
			},

			['telis salvani'] = {
				'Telis Salvani',
				'Temple',
				'Healer Service',
				'Location: Temple Healing Halls',
				'Role: Provides medical aid.',
				'Notes: Dark Elf healer'
			},

			['ilen faveran'] = {
				'Ilen Faveran',
				'Temple',
				'Enchanter Service',
				'Location: Temple Enchanter Chambers',
				'Role: Imbues items with magic.',
				'Notes: Dark Elf enchanter'
			},

			['dralval andrano'] = {
				'Dralval Andrano',
				'Temple',
				'Apothecary Service',
				'Location: Temple Apothecary',
				'Role: Prepares potions.',
				'Notes: Dark Elf apothecary'
			},

			['bervaso thenim'] = {
				'Bervaso Thenim',
				'Temple',
				'Apothecary Service',
				'Location: Temple Apothecary',
				'Role: Prepares potions.',
				'Notes: Dark Elf apothecary'
			},

			['sortis rathryon'] = {
				'Sortis Rathryon',
				'Temple',
				'Monk',
				'Location: Temple Monastery',
				'Role: Practices meditation.',
				'Notes: Dark Elf monk'
			},

			['dethresa saren'] = {
				'Dethresa Saren',
				'Temple',
				'Monk',
				'Location: Temple Monastery',
				'Role: Practices meditation.',
				'Notes: Dark Elf monk'
			},

			['llevana salaren'] = {
				'Llevana Salaren',
				'Temple',
				'Acrobat',
				'Location: Temple Training Grounds',
				'Role: Performs acrobatic feats.',
				'Notes: Dark Elf acrobat'
			},

			['Chanil_Lee'] = {
				'Chanil Lee',
				'Mages Guild',
				'Sorcerer',
				'Location: Mages Guild Towers',
				'Role: Practices arcane magic.',
				'Notes: Argonian sorcerer'
			},

			['heem_la'] = {
				'Heem La',
				'Mages Guild',
				'Mage Service',
				'Location: Mages Guild Towers',
				'Role: Practices magic.',
				'Notes: Argonian mage'
			},

			['tongue_toad'] = {
				'Tongue Toad',
				'Thieves Guild',
				'Savant Service',
				'Location: Thieves Guild Archives',
				'Role: Conducts research.',
				'Notes: Argonian scholar'
			},

			['nine_toes'] = {
				'Nine Toes',
				'Blades',
				'Hunter',
				'Location: Blades Outposts',
				'Role: Tracks and hunts game.',
				'Notes: Argonian hunter'
			},

			['skinkintreesshade'] = {
				'Skink-in-Tree-Shade',
				'Mages Guild',
				'Sorcerer',
				'Location: Mages Guild Towers',
				'Role: Practices arcane magic.',
				'Notes: Argonian sorcerer'
			},

			['Im_Kilaya'] = {
				'Im Kilaya',
				'Twin Lamps',
				'Mage',
				'Location: Twin Lamps Sanctum',
				'Role: Practices magic.',
				'Notes: Argonian mage'
			},

			['Geel_Lah'] = {
				'Geel Lah',
				'Twin Lamps',
				'Monk',
				'Location: Twin Lamps Monastery',
				'Role: Practices meditation.',
				'Notes: Argonian monk'
			},

			['An_Deesei'] = {
				'An Deesei',
				'Twin Lamps',
				'Monk',
				'Location: Twin Lamps Monastery',
				'Role: Practices meditation.',
				'Notes: Argonian monk'
			},

			['smokeskin_killer'] = {
				'Smokeskin Killer',
				'Telvanni',
				'Warrior',
				'Location: Telvanni Battlegrounds',
				'Role: Engages in combat.',
				'Notes: Argonian warrior'
			},

			['naral othreleth'] = {
				'Naral Othreleth',
				'Temple',
				'Miner',
				'Location: Temple Mining Sites',
				'Role: Extracts minerals.',
				'Notes: Dark Elf miner'
			},

			['assallit assunbahanammu'] = {
				'Assallit Ashshunbahanammu',
				'Ashlanders',
				'Miner',
				'Location: Ashlander Mining Sites',
				'Role: Extracts minerals.',
				'Notes: Dark Elf miner'
			},

			['yan-ahhe darirnaddunumm'] = {
				'Yan-Ahhe Darirnaddunumm',
				'Ashlanders',
				'Miner',
				'Location: Ashlander Mining Sites',
				'Role: Extracts minerals.',
				'Notes: Dark Elf miner'
			},

			['tubilalk mirathrernenum'] = {
				'Tubilalk Mirathrernenum',
				'Ashlanders',
				'Miner',
				'Location: Ashlander Mining Sites',
				'Role: Extracts minerals.',
				'Notes: Dark Elf miner'
			},

			['darns tedalen'] = {
				'Darns Tedalen',
				'Redoran',
				'Crusader',
				'Location: Redoran Battlegrounds',
				'Role: Leads crusades.',
				'Notes: Dark Elf crusader'
			},

			['star'] = {
				'Star',
				'Hlaalu',
				'Spellsword',
				'Location: Hlaalu Towers',
				'Role: Combines magic and combat.',
				'Notes: Nord spellsword'
			},

			['shagar gra-snagarz'] = {
				'Shagar Gra-Snagarz',
				'Hlaalu',
				'Bard',
				'Location: Hlaalu Halls',
				'Role: Performs music and storytelling.',
				'Notes: Orc bard'
			},

			['faulgor'] = {
				'Faulgor',
				'Hlaalu',
				'Agent',
				'Location: Hlaalu Intelligence',
				'Role: Conducts espionage.',
				'Notes: Wood Elf agent'
			},

			['methal seran'] = {
				'Methal Seran',
				'Temple',
				'Priest Service',
				'Location: Temple Sanctuaries',
				'Role: Conducts religious services.',
				'Notes: Dark Elf priest'
			},

			['folvys andalor'] = {
				'Folvys Andalor',
				'Temple',
				'Healer Service',
				'Location: Temple Healing Halls',
				'Role: Provides medical aid.',
				'Notes: Dark Elf healer'
			},

			['danoso andrano'] = {
				'Danoso Andrano',
				'Temple',
				'Apothecary Service',
				'Location: Temple Apothecary',
				'Role: Prepares potions.',
				'Notes: Dark Elf apothecary'
			},

			['ureso drath'] = {
				'Ureso Drath',
				'Temple',
				'Enchanter Service',
				'Location: Temple Enchanter Chambers',
				'Role: Imbues items with magic.',
				'Notes: Dark Elf enchanter'
			},

			['nilvyn drothan'] = {
				'Nilvin Drothan',
				'Temple',
				'Priest Service',
				'Location: Temple Sanctuaries',
				'Role: Conducts religious services.',
				'Notes: Dark Elf priest'
			},

			['ralyn othravel'] = {
				'Ralin Othravel',
				'Temple',
				'Crusader',
				'Location: Temple Battlegrounds',
				'Role: Leads crusades.',
				'Notes: Dark Elf crusader'
			},

			['rilvase avani'] = {
				'Rilvase Avani',
				'Temple',
				'Healer Service',
				'Location: Temple Healing Halls',
				'Role: Provides medical aid.',
				'Notes: Dark Elf healer'
			},

			['ulmiso maloren'] = {
				'Ulmiso Maloren',
				'Temple',
				'Healer Service',
				'Location: Temple Healing Halls',
				'Role: Provides medical aid.',
				'Notes: Dark Elf healer'
			},

			['faras thirano'] = {
				'Faras Thirano',
				'Temple',
				'Enchanter Service',
				'Location: Temple Enchanter Chambers',
				'Role: Imbues items with magic.',
				'Notes: Dark Elf enchanter'
			},

			['teril savani'] = {
				'Teril Savani',
				'Temple',
				'Apothecary Service',
				'Location: Temple Apothecary',
				'Role: Prepares potions.',
				'Notes: Dark Elf apothecary'
			},

			['dronos llervu'] = {
				'Dronos Llervu',
				'Redoran',
				'Smith',
				'Location: Redoran Forge',
				'Role: Crafts weapons and armor.',
				'Notes: Dark Elf blacksmith'
			},

			['taluro athren'] = {
				'Taluro Athren',
				'Redoran',
				'Master-at-Arms',
				'Location: Redoran Training Grounds',
				'Role: Oversees combat training.',
				'Notes: Dark Elf instructor'
			},

			['mandran indrano'] = {
				'Mandran Indrano',
				'Redoran',
				'Drillmaster Service',
				'Location: Redoran Barracks',
				'Role: Conducts drills.',
				'Notes: Dark Elf drillmaster'
			},

			['fonas retheran'] = {
				'Fonas Retheran',
				'Redoran',
				'Trader Service',
				'Location: Redoran Markets',
				'Role: Manages trade.',
				'Notes: Dark Elf trader'
			},

			['berela andrano'] = {
				'Berela Andrano',
				'Redoran',
				'Savant Service',
				'Location: Redoran Archives',
				'Role: Conducts research.',
				'Notes: Dark Elf scholar'
			},

			['galdal omayn'] = {
				'Galdal Omayn',
				'Temple',
				'Buoyant Armiger',
				'Location: Temple Guard Posts',
				'Role: Maintains order.',
				'Notes: Dark Elf armiger'
			},

			['drelyne llenim'] = {
				'Drelene Llenim',
				'Temple',
				'Buoyant Armiger',
				'Location: Temple Guard Posts',
				'Role: Maintains order.',
				'Notes: Dark Elf armiger'
			},

			['enar dralor'] = {
				'Enar Dralor',
				'Temple',
				'Buoyant Armiger',
				'Location: Temple Guard Posts',
				'Role: Maintains order.',
				'Notes: Dark Elf armiger'
			},

			['aron andaren'] = {
				'Aron Andaren',
				'Telvanni',
				'Commoner',
				'Location: Telvanni Settlements',
				'Role: Performs daily tasks.',
				'Notes: Dark Elf commoner'
			},

			['avoni dren'] = {
				'Avoni Dren',
				'Telvanni',
				'Noble',
				'Location: Telvanni Courts',
				'Role: Advises leadership.',
				'Notes: Dark Elf noble'
			},

			['eldrar fathyron'] = {
				'Eldrar Fathyron',
				'Telvanni',
				'Merchant',
				'Location: Telvanni Markets',
				'Role: Manages trade.',
				'Notes: Dark Elf merchant'
			},

			['selmen relas'] = {
				'Selmen Relas',
				'Temple',
				'Ordinator',
				'Location: Temple Guard Posts',
				'Role: Maintains order.',
				'Notes: Dark Elf ordinator'
			},

			['ferone veran'] = {
				'Ferone Veran',
				'Temple',
				'Ordinator',
				'Location: Temple Guard Posts',
				'Role: Maintains order.',
				'Notes: Dark Elf ordinator'
			},

			['selman relas'] = {
				'Selman Relas',
				'Temple',
				'Ordinator',
				'Location: Temple Guard Posts',
				'Role: Maintains order.',
				'Notes: Dark Elf ordinator'
			},

			['galore salvi'] = {
				'Galore Salvi',
				'Redoran',
				'Publican',
				'Location: Redoran Markets',
				'Role: Manages tavern.',
				'Notes: Dark Elf publican'
			},

			['nevrasa dralor'] = {
				'Nevrasa Dralor',
				'Temple',
				'Pilgrim',
				'Location: Temple Pilgrimage Sites',
				'Role: Leads pilgrimages.',
				'Notes: Dark Elf pilgrim'
			},

			['viatrix petilia'] = {
				'Viatrix Petilia',
				'Temple',
				'Pilgrim',
				'Location: Temple Pilgrimage Sites',
				'Role: Leads pilgrimages.',
				'Notes: Imperial pilgrim'
			},

			['lucan ostorius'] = {
				'Lucan Ostorius',
				'Thieves Guild',
				'Thief',
				'Location: Thieves Guild Operations',
				'Role: Performs theft missions.',
				'Notes: Imperial thief'
			},

			['yak gro-skandar'] = {
				'Yak Gro-Skandar',
				'Thieves Guild',
				'Thief',
				'Location: Thieves Guild Operations',
				'Role: Performs theft missions.',
				'Notes: Orc thief'
			},

			['sason'] = {
				'Sason',
				'Redoran',
				'Commoner',
				'Location: Redoran Settlements',
				'Role: Performs daily tasks.',
				'Notes: Redguard commoner'
			},

			['emul-ran'] = {
				'Emul-Ran',
				'Ashlanders',
				'Hunter',
				'Location: Ashlander Camps',
				'Role: Tracks and hunts game.',
				'Notes: Dark Elf hunter'
			},

			['kashtes ilabael'] = {
				'Kashtes Ilabael',
				'Ashlanders',
				'Hunter',
				'Location: Ashlander Camps',
				'Role: Tracks and hunts game.',
				'Notes: Dark Elf hunter'
			},

			['tinti'] = {
				'Tinti',
				'Ashlanders',
				'Hunter',
				'Location: Ashlander Camps',
				'Role: Tracks and hunts game.',
				'Notes: Dark Elf hunter'
			},

			['hairan'] = {
				'Hairan',
				'Ashlanders',
				'Hunter',
				'Location: Ashlander Camps',
				'Role: Tracks and hunts game.',
				'Notes: Dark Elf hunter'
			},

			['ulwaen'] = {
				'Ulwaen',
				'Imperial Legion',
				'Master-at-Arms',
				'Location: Imperial Legion Training Grounds',
				'Role: Oversees combat training.',
				'Notes: Wood Elf instructor'
			},

			['Relam Arinith'] = {
				'Relam Arinith',
				'Camonna Tong',
				'Smuggler',
				'Location: Camonna Tong Outposts',
				'Role: Manages smuggling operations.',
				'Notes: Dark Elf smuggler'
			},

			['an-zaw'] = {
				'An-Zaw',
				'Mages Guild',
				'Nightblade',
				'Location: Mages Guild Shadows',
				'Role: Performs covert missions.',
				'Notes: Argonian nightblade'
			},

			['sakin sanammasour'] = {
				'Sakin Sanammasour',
				'Ashlanders',
				'Commoner',
				'Location: Ashlander Settlements',
				'Role: Performs daily tasks.',
				'Notes: Dark Elf commoner'
			},

			['elynu saren'] = {
				'Elynu Saren',
				'Temple',
				'Priest Service',
				'Location: Temple Sanctuaries',
				'Role: Conducts religious services.',
				'Notes: Dark Elf priest'
			},

			['ravoso aryon'] = {
				'Ravoso Aryon',
				'Hlaalu',
				'Pawnbroker',
				'Location: Hlaalu Markets',
				'Role: Manages pawn shop.',
				'Notes: Dark Elf pawnbroker'
			},

			['odron omoran'] = {
				'Odrone Omoran',
				'Temple',
				'Buoyant Armiger',
				'Location: Temple Guard Posts',
				'Role: Maintains order.',
				'Notes: Dark Elf armiger'
			},

			['dreyns nelas'] = {
				'Dreyns Nelas',
				'Temple',
				'Buoyant Armiger',
				'Location: Temple Guard Posts',
				'Role: Maintains order.',
				'Notes: Dark Elf armiger'
			},

			['llevena sendas'] = {
				'Llevena Sendas',
				'Temple',
				'Buoyant Armiger',
				'Location: Temple Guard Posts',
				'Role: Maintains order.',
				'Notes: Dark Elf armiger'
			},

			['ervesa romandas'] = {
				'Ervesa Roman',
				'Temple',
				'Buoyant Armiger',
				'Location: Temple Guard Posts',
				'Role: Maintains order.',
				'Notes: Dark Elf armiger'
			},

			['vuvil senim'] = {
				'Vuvil Senim',
				'Thieves Guild',
				'Thief',
				'Location: Thieves Guild Hideout',
				'Role: Performs theft missions.',
				'Notes: Dark Elf thief'
			},

			['jocien ancois'] = {
				'Jocien Ancois',
				'Imperial Cult',
				'Priest',
				'Location: Imperial Cult Temple',
				'Role: Conducts religious ceremonies.',
				'Notes: Breton priest'
			},

			['madura seran'] = {
				'Madura Seran',
				'Temple',
				'Pilgrim',
				'Location: Temple Pilgrimage Sites',
				'Role: Leads pilgrimages.',
				'Notes: Dark Elf pilgrim'
			},

			['golana giralvel'] = {
				'Golana Giralvel',
				'Redoran',
				'Archer',
				'Location: Redoran Battlegrounds',
				'Role: Provides ranged support.',
				'Notes: Dark Elf archer'
			},

			['salyn sarethi'] = {
				'Salyn Sarethi',
				'Temple',
				'Buoyant Armiger',
				'Location: Temple Guard Posts',
				'Role: Maintains order.',
				'Notes: Dark Elf armiger'
			},

			['berel sala'] = {
				'Berel Sala',
				'Temple',
				'Ordinator',
				'Location: Temple Guard Posts',
				'Role: Maintains order.',
				'Notes: Dark Elf ordinator'
			},

			['endar drenim'] = {
				'Endar Drenim',
				'Telvanni',
				'Sorcerer',
				'Location: Telvanni Towers',
				'Role: Practices arcane magic.',
				'Notes: Dark Elf sorcerer'
			},

			['vanel serven'] = {
				'Vanel Serven',
				'Telvanni',
				'Battlemage',
				'Location: Telvanni Battlegrounds',
				'Role: Combines magic and combat.',
				'Notes: Dark Elf battlemage'
			},

			['drodos galen'] = {
				'Drodos Galen',
				'Telvanni',
				'Sorcerer',
				'Location: Telvanni Towers',
				'Role: Practices arcane magic.',
				'Notes: Dark Elf sorcerer'
			},

			['vares reram'] = {
				'Vares Reram',
				'Telvanni',
				'Battlemage',
				'Location: Telvanni Battlegrounds',
				'Role: Combines magic and combat.',
				'Notes: Dark Elf battlemage'
			},

			['savesea mothryon'] = {
				'Savesea Mothryon',
				'Telvanni',
				'Mage',
				'Location: Telvanni Towers',
				'Role: Practices magic.',
				'Notes: Dark Elf mage'
			},

			['faldan'] = {
				'Faldan',
				'Telvanni',
				'Archer',
				'Location: Telvanni Ranges',
				'Role: Provides ranged support.',
				'Notes: Wood Elf archer'
			},

			['new_shoes bragor'] = {
				'New_Shoes Bragor',
				'Thieves Guild',
				'Thief',
				'Location: Thieves Guild Hideout',
				'Role: Performs theft missions.',
				'Notes: Wood Elf thief'
			},

			['manis virmaulese'] = {
				'Manis Virmaulese',
				'Mages Guild',
				'Mage',
				'Location: Mages Guild Halls',
				'Role: Practices magic.',
				'Notes: Breton mage'
			},

			['melvona marvayn'] = {
				'Melvona Marvayn',
				'Hlaalu',
				'Enforcer',
				'Location: Hlaalu Enforcement',
				'Role: Maintains order.',
				'Notes: Dark Elf enforcer'
			},

			['ranor dralas'] = {
				'Ranor Dralas',
				'Hlaalu',
				'Nightblade',
				'Location: Hlaalu Shadows',
				'Role: Performs covert missions.',
				'Notes: Dark Elf nightblade'
			},

			['tredyn venim'] = {
				'Tredyn Venim',
				'Hlaalu',
				'Bard',
				'Location: Hlaalu Halls',
				'Role: Entertains and boosts morale.',
				'Notes: Dark Elf bard'
			},

			['gorven menas'] = {
				'Gorven Menas',
				'Telvanni',
				'Alchemist Service',
				'Location: Telvanni Laboratories',
				'Role: Creates potions and elixirs.',
				'Notes: Dark Elf alchemist'
			},

			['farena arelas'] = {
				'Farena Arelas',
				'Telvanni',
				'Mage Service',
				'Location: Telvanni Towers',
				'Role: Assists with magical research.',
				'Notes: Dark Elf mage'
			},

			['hlendrisa seleth'] = {
				'Hlendrisa Seleth',
				'Telvanni',
				'Enchanter Service',
				'Location: Telvanni Enchanter Chambers',
				'Role: Imbues items with magic.',
				'Notes: Dark Elf enchanter'
			},

			['tunila omavel'] = {
				'Tunila Omavel',
				'Telvanni',
				'Healer Service',
				'Location: Telvanni Healing Chambers',
				'Role: Provides medical aid.',
				'Notes: Dark Elf healer'
			},

			['beldrose dralor'] = {
				'Beldrose Dralor',
				'Redoran',
				'Noble',
				'Location: Redoran Courts',
				'Role: Advises leadership.',
				'Notes: Dark Elf noble'
			},

			['tunipu shamirbasour'] = {
				'Tunipu Shamirbasour',
				'Ashlanders',
				'Wise Woman',
				'Location: Ashlander Camps',
				'Role: Provides guidance and healing.',
				'Notes: Dark Elf wise woman'
			},

			['avron gols'] = {
				'Avron Gols',
				'Hlaalu',
				'Scout',
				'Location: Hlaalu Outposts',
				'Role: Gathers intelligence.',
				'Notes: Dark Elf scout'
			},

			['sernsi drelas'] = {
				'Sernsі Drelas',
				'Hlaalu',
				'Pawnbroker',
				'Location: Hlaalu Markets',
				'Role: Manages pawn shop.',
				'Notes: Dark Elf pawnbroker'
			},

			['treram milar'] = {
				'Treram Milar',
				'Redoran',
				'Warrior',
				'Location: Redoran Battlegrounds',
				'Role: Engages in combat.',
				'Notes: Dark Elf warrior'
			},

			['ienas nadus'] = {
				'Ienas Nadus',
				'Redoran',
				'Battlemage',
				'Location: Redoran Battlegrounds',
				'Role: Combines magic and combat.',
				'Notes: Dark Elf battlemage'
			},

			['galvene othrobar'] = {
				'Galvene Othrobar',
				'Redoran',
				'Archer',
				'Location: Redoran Ranges',
				'Role: Provides ranged support.',
				'Notes: Dark Elf archer'
			},

			['viras guls'] = {
				'Viras Guls',
				'Redoran',
				'Master-at-Arms',
				'Location: Redoran Training Grounds',
				'Role: Oversees combat training.',
				'Notes: Dark Elf instructor'
			},

			['broder garil'] = {
				'Broder Garil',
				'Redoran',
				'Spellsword',
				'Location: Redoran Battlegrounds',
				'Role: Combines magic and swordsmanship.',
				'Notes: Dark Elf spellsword'
			},

			['gaden folvyn'] = {
				'Gaden Folvyn',
				'Redoran',
				'Farmer',
				'Location: Redoran Farmlands',
				'Role: Cultivates crops and livestock.',
				'Notes: Dark Elf farmer'
			},

			['gilyne omoren'] = {
				'Gilyne Omoren',
				'Redoran',
				'Smith',
				'Location: Redoran Forge',
				'Role: Crafts weapons and armor.',
				'Notes: Dark Elf blacksmith'
			},

			['arvs raram'] = {
				'Arvs Raram',
				'Redoran',
				'Master-at-Arms',
				'Location: Redoran Training Grounds',
				'Role: Oversees combat training.',
				'Notes: Dark Elf instructor'
			},

			['lliros tures'] = {
				'Lliros Tures',
				'Redoran',
				'Trader Service',
				'Location: Redoran Markets',
				'Role: Manages trade.',
				'Notes: Dark Elf trader'
			},

			['uvele berendas'] = {
				'Uvele Berendas',
				'Redoran',
				'Priest Service',
				'Location: Redoran Sanctuaries',
				'Role: Conducts religious services.',
				'Notes: Dark Elf priest'
			},

			['garila vedas'] = {
				'Garila Vedas',
				'Redoran',
				'Scout',
				'Location: Redoran Outposts',
				'Role: Gathers intelligence.',
				'Notes: Dark Elf scout'
			},

			['mavis nadram'] = {
				'Mavis Nadram',
				'Redoran',
				'Drillmaster Service',
				'Location: Redoran Barracks',
				'Role: Conducts drills.',
				'Notes: Dark Elf drillmaster'
			},

			['uvren tures'] = {
				'Uvren Tures',
				'Hlaalu',
				'Monk Service',
				'Location: Hlaalu Monastery',
				'Role: Practices meditation.',
				'Notes: Dark Elf monk'
			},

			['unila berendas'] = {
				'Unila Berendas',
				'Hlaalu',
				'Agent',
				'Location: Hlaalu Intelligence',
				'Role: Conducts espionage.',
				'Notes: Dark Elf agent'
			},

			['lliryn fendyn'] = {
				'Lliryn Fendyn',
				'Hlaalu',
				'Thief Service',
				'Location: Hlaalu Shadows',
				'Role: Performs theft missions.',
				'Notes: Dark Elf thief'
			},

			['hlodala savel'] = {
				'Hlodala Savel',
				'Hlaalu',
				'Savant Service',
				'Location: Hlaalu Archives',
				'Role: Conducts research.',
				'Notes: Dark Elf scholar'
			},

			['joncis dalomax'] = {
				'Joncis Dalomax',
				'Imperial Legion',
				'Knight',
				'Location: Imperial Legion Forts',
				'Role: Leads military operations.',
				'Notes: Breton knight'
			},

			['telvon llethan'] = {
				'Telvon Llethan',
				'Hlaalu',
				'Smith',
				'Location: Hlaalu Forge',
				'Role: Crafts weapons and armor.',
				'Notes: Dark Elf blacksmith'
			},

			['drelse dralor'] = {
				'Drelse Dralor',
				'Redoran',
				'Noble',
				'Location: Redoran Courts',
				'Role: Advises leadership.',
				'Notes: Dark Elf noble'
			},

			['larrius varro'] = {
				'Larrius Varro',
				'Imperial Legion',
				'Warrior',
				'Location: Imperial Legion Barracks',
				'Role: Engages in combat.',
				'Notes: Imperial warrior'
			},

			['fevyn ralen'] = {
				'Fevyn Ralen',
				'Telvanni',
				'Mage Service',
				'Location: Telvanni Towers',
				'Role: Assists with magical research.',
				'Notes: Dark Elf mage'
			},

			['lauravenya'] = {
				'Lauravenya',
				'Imperial Cult',
				'Mage Service',
				'Location: Imperial Cult Sanctum',
				'Role: Assists with magical rituals.',
				'Notes: Dark Elf mage'
			},

			['trivura arenim'] = {
				'Trivura Arenim',
				'Redoran',
				'Trader Service',
				'Location: Redoran Markets',
				'Role: Manages trade.',
				'Notes: Dark Elf trader'
			},

			['orero omothan'] = {
				'Oreto Omothan',
				'Redoran',
				'Smith',
				'Location: Redoran Forge',
				'Role: Crafts weapons and armor.',
				'Notes: Dark Elf blacksmith'
			},

			['sedam omalen'] = {
				'Sedam Omalen',
				'Redoran',
				'Trader Service',
				'Location: Redoran Markets',
				'Role: Manages trade.',
				'Notes: Dark Elf trader'
			},

			['natalinus flavonius'] = {
				'Natalinus Flavonius',
				'Mages Guild',
				'Battlemage',
				'Location: Mages Guild Towers',
				'Role: Combines magic and combat.',
				'Notes: Imperial battlemage'
			},

			['goron lleran'] = {
				'Goron Lleran',
				'Temple',
				'Pilgrim',
				'Location: Temple Pilgrimage Sites',
				'Role: Leads pilgrimages.',
				'Notes: Dark Elf pilgrim'
			},

			['drelse dralor'] = {
				'Drelse Dralor',
				'Redoran',
				'Noble',
				'Location: Redoran Courts',
				'Role: Advises leadership.',
				'Notes: Dark Elf noble'
			},

			['larrius varro'] = {
				'Larrius Varro',
				'Imperial Legion',
				'Warrior',
				'Location: Imperial Legion Barracks',
				'Role: Engages in combat.',
				'Notes: Imperial warrior'
			},

			['fevyn ralen'] = {
				'Fevyn Ralen',
				'Telvanni',
				'Mage Service',
				'Location: Telvanni Towers',
				'Role: Assists with magical research.',
				'Notes: Dark Elf mage'
			},

			['lauravenya'] = {
				'Lauravenya',
				'Imperial Cult',
				'Mage Service',
				'Location: Imperial Cult Sanctum',
				'Role: Assists with magical rituals.',
				'Notes: Dark Elf mage'
			},

			['trivura arenim'] = {
				'Trivura Arenim',
				'Redoran',
				'Trader Service',
				'Location: Redoran Markets',
				'Role: Manages trade.',
				'Notes: Dark Elf trader'
			},

			['orero omothan'] = {
				'Oreto Omothan',
				'Redoran',
				'Smith',
				'Location: Redoran Forge',
				'Role: Crafts weapons and armor.',
				'Notes: Dark Elf blacksmith'
			},

			['sedam omalen'] = {
				'Sedam Omalen',
				'Redoran',
				'Trader Service',
				'Location: Redoran Markets',
				'Role: Manages trade.',
				'Notes: Dark Elf trader'
			},

			['natalinus flavonius'] = {
				'Natalinus Flavonius',
				'Mages Guild',
				'Battlemage',
				'Location: Mages Guild Towers',
				'Role: Combines magic and combat.',
				'Notes: Imperial battlemage'
			},

			['goron lleran'] = {
				'Goron Lleran',
				'Temple',
				'Pilgrim',
				'Location: Temple Pilgrimage Sites',
				'Role: Leads pilgrimages.',
				'Notes: Dark Elf pilgrim'
			},

			['processus vitellius'] = {
				'Processus Vitellius',
				'Imperial Cult',
				'Agent',
				'Location: Imperial Cult Intelligence',
				'Role: Conducts espionage.',
				'Notes: Imperial agent'
			},

			['taros dral'] = {
				'Taros Dral',
				'Morag Tong',
				'Assassin',
				'Location: Morag Tong Operations',
				'Role: Performs assassinations.',
				'Notes: Dark Elf assassin'
			},

			['urshamusa rapli'] = {
				'Urshamusa Rapli',
				'Ashlanders',
				'Wise Woman',
				'Location: Ashlander Camps',
				'Role: Provides guidance and healing.',
				'Notes: Dark Elf wise woman'
			},

			['methas hlaalu'] = {
				'Methas Hlaalu',
				'Morag Tong',
				'Noble',
				'Location: Morag Tong Courts',
				'Role: Advises leadership.',
				'Notes: Dark Elf noble'
			},

			['Fothyna Herothran'] = {
				'Fothyna Herothran',
				'Thieves Guild',
				'Rogue',
				'Location: Thieves Guild Hideout',
				'Role: Performs covert missions.',
				'Notes: Dark Elf rogue'
			},

			['Sathasa Nerothren'] = {
				'Sathasa Nerothren',
				'Thieves Guild',
				'Healer',
				'Location: Thieves Guild Infirmary',
				'Role: Provides medical aid.',
				'Notes: Dark Elf healer'
			},

			['Goren Andarys'] = {
				'Goren Andarys',
				'Morag Tong',
				'Monk Service',
				'Location: Morag Tong Monastery',
				'Role: Practices meditation.',
				'Notes: Dark Elf monk'
			},

			['Hoki'] = {
				'Hoki',
				'Morag Tong',
				'Agent',
				'Location: Morag Tong Intelligence',
				'Role: Conducts espionage.',
				'Notes: Nord agent'
			},

			['Lassour Zenammu'] = {
				'Lassour Zenammu',
				'Morag Tong',
				'Assassin Service',
				'Location: Morag Tong Operations',
				'Role: Performs assassinations.',
				'Notes: Dark Elf assassin'
			},

			['Salyni Nelvayn'] = {
				'Salyni Nelvayn',
				'Morag Tong',
				'Nightblade Service',
				'Location: Morag Tong Shadows',
				'Role: Performs covert missions.',
				'Notes: Dark Elf nightblade'
			},

			['Jon Hawker'] = {
				'Jon Hawker',
				'Imperial Cult',
				'Trader',
				'Location: Imperial Cult Markets',
				'Role: Manages trade.',
				'Notes: Redguard trader'
			},

			['Gurag gro-Yarzol'] = {
				'Gurag gro-Yarzol',
				'Hlaalu',
				'Commoner',
				'Location: Hlaalu Settlements',
				'Role: Performs daily tasks.',
				'Notes: Orc commoner'
			},

			['lucan ostorius2'] = {
				'Lucan Ostorius',
				'Thieves Guild',
				'Thief',
				'Location: Thieves Guild Hideout',
				'Role: Performs theft missions.',
				'Notes: Imperial thief'
			},

			['thanelen velas'] = {
				'Thanelen Velas',
				'Camonna Tong',
				'Smith',
				'Location: Camonna Tong Forge',
				'Role: Crafts weapons and armor.',
				'Notes: Dark Elf blacksmith'
			},

			['dondos driler'] = {
				'Dondos Driler',
				'Hlaalu',
				'Noble',
				'Location: Hlaalu Courts',
				'Role: Advises leadership.',
				'Notes: Dark Elf noble'
			},

			['alveleg'] = {
				'Alveleg',
				'Thieves Guild',
				'Scout',
				'Location: Thieves Guild Outposts',
				'Role: Gathers intelligence.',
				'Notes: Wood Elf scout'
			},

			['galero andaram'] = {
				'Galero Andaram',
				'Temple',
				'Healer Service',
				'Location: Temple Healing Halls',
				'Role: Provides medical aid.',
				'Notes: Dark Elf healer'
			},

			['hloris farano'] = {
				'Hloris Farano',
				'Temple',
				'Monk Service',
				'Location: Temple Monastery',
				'Role: Practices meditation.',
				'Notes: Dark Elf monk'
			},

			['miraso seran'] = {
				'Miraso Seran',
				'Temple',
				'Enchanter Service',
				'Location: Temple Enchanter Chambers',
				'Role: Imbues items with magic.',
				'Notes: Dark Elf enchanter'
			},

			['tendris vedran'] = {
				'Tendris Vedran',
				'Temple',
				'Apothecary Service',
				'Location: Temple Apothecary',
				'Role: Prepares potions.',
				'Notes: Dark Elf apothecary'
			},

			['llunela hleran'] = {
				'Llunela Hleran',
				'Telvanni',
				'Enchanter',
				'Location: Telvanni Enchanter Chambers',
				'Role: Imbues items with magic.',
				'Notes: Dark Elf enchanter'
			},

			['Shardie'] = {
				'Shardie',
				'Imperial Legion',
				'Crusader',
				'Location: Imperial Legion Barracks',
				'Role: Leads crusades.',
				'Notes: Redguard crusader'
			},

			['imperial templar_ebon'] = {
				'Jonus Maximus',
				'Imperial Legion',
				'Guard',
				'Location: Imperial Legion Forts',
				'Role: Maintains order.',
				'Notes: Imperial guard'
			},

			['balyn omavel-DEAD'] = {
				'Balyn Omavel',
				'Morag Tong',
				'Assassin',
				'Location: Morag Tong Operations',
				'Role: Performs assassinations.',
				'Notes: Dark Elf assassin (deceased)'
			},

			['sanvyn llethri'] = {
				'Sanvyn Lletri',
				'Redoran',
				'Noble',
				'Location: Redoran Courts',
				'Role: Advises leadership.',
				'Notes: Dark Elf noble'
			},

			['calvario'] = {
				'Calvario',
				'Clan Berne',
				'Acrobat',
				'Location: Clan Berne Training Grounds',
				'Role: Performs acrobatic feats.',
				'Notes: Imperial acrobat'
			},

			['vedran balen'] = {
				'Vedran Balen',
				'Hlaalu',
				'Assassin Service',
				'Location: Hlaalu Shadows',
				'Role: Performs assassinations.',
				'Notes: Dark Elf assassin'
			},

			['golveso senim'] = {
				'Golveso Senim',
				'Telvanni',
				'Monk Service',
				'Location: Telvanni Monastery',
				'Role: Practices meditation.',
				'Notes: Dark Elf monk'
			},

			['anruin'] = {
				'Anruin',
				'Telvanni',
				'Smith',
				'Location: Telvanni Forge',
				'Role: Crafts weapons and armor.',
				'Notes: Wood Elf blacksmith'
			},

			['manicky'] = {
				'Manicky',
				'Telvanni',
				'Smith',
				'Location: Telvanni Forge',
				'Role: Crafts weapons and armor.',
				'Notes: Redguard blacksmith'
			},

			['ancola'] = {
				'Ancola',
				'Telvanni',
				'Trader Service',
				'Location: Telvanni Markets',
				'Role: Manages trade.',
				'Notes: Redguard trader'
			},

			['Heniele Milielle'] = {
				'Heniele Milielle',
				'Redoran',
				'Commoner',
				'Location: Redoran Settlements',
				'Role: Performs daily tasks.',
				'Notes: Breton commoner'
			},

			['emelia duronia'] = {
				'Emelia Duronia',
				'Mages Guild',
				'Guild Guide',
				'Location: Mages Guild Halls',
				'Role: Assists new members.',
				'Notes: Imperial guide'
			},

			['Voruse Bethrimo'] = {
				'Voruse Bethrimo',
				'Temple',
				'Buoyant Armiger',
				'Location: Temple Guard Posts',
				'Role: Maintains order.',
				'Notes: Dark Elf armiger'
			},

			['Angahran'] = {
				'Angahran',
				'Morag Tong',
				'Assassin',
				'Location: Morag Tong Operations',
				'Role: Performs assassinations.',
				'Notes: Dark Elf assassin'
			},

			['Nerile Andaren'] = {
				'Nerile Andaren',
				'Temple',
				'Healer Service',
				'Location: Temple Healing Halls',
				'Role: Provides medical aid.',
				'Notes: Dark Elf healer'
			},

			['Tienius Delitian'] = {
				'Tienius Delitian',
				'Royal Guard',
				'Guard',
				'Location: Royal Guard Barracks',
				'Role: Protects royalty.',
				'Notes: Imperial guard'
			},

			['Anrel'] = {
				'Anrel',
				'Hlaalu',
				'Warrior',
				'Location: Hlaalu Battlegrounds',
				'Role: Engages in combat.',
				'Notes: Wood Elf warrior'
			},

			['Donus Serethi'] = {
				'Donus Serethi',
				'Hlaalu',
				'Spellsword',
				'Location: Hlaalu Towers',
				'Role: Combines magic and combat.',
				'Notes: Dark Elf spellsword'
			},

			['Galsa Andrano'] = {
				'Galsa Andrano',
				'Temple',
				'Healer Service',
				'Location: Temple Healing Halls',
				'Role: Provides medical aid.',
				'Notes: Dark Elf healer'
			},

			['Milvela Dralen'] = {
				'Milvela Dralen',
				'Royal Guard',
				'Crusader',
				'Location: Royal Guard Forts',
				'Role: Leads crusades.',
				'Notes: Dark Elf crusader'
			},

			['Ivulen Irano'] = {
				'Ivulen Irano',
				'Royal Guard',
				'Guard',
				'Location: Royal Guard Barracks',
				'Role: Maintains order.',
				'Notes: Dark Elf guard'
			},

			['Aleri Aren'] = {
				'Aleri Aren',
				'Royal Guard',
				'Crusader',
				'Location: Royal Guard Forts',
				'Role: Leads crusades.',
				'Notes: Dark Elf crusader'
			},

			['Diradeni Farano'] = {
				'Diradeni Farano',
				'Royal Guard',
				'Guard',
				'Location: Royal Guard Barracks',
				'Role: Maintains order.',
				'Notes: Dark Elf guard'
			},

			['Ervis Verano'] = {
				'Ervis Verano',
				'Royal Guard',
				'Crusader',
				'Location: Royal Guard Forts',
				'Role: Leads crusades.',
				'Notes: Dark Elf crusader'
			},

			['Evo Othreloth'] = {
				'Evo Othreloth',
				'Royal Guard',
				'Guard',
				'Location: Royal Guard Barracks',
				'Role: Maintains order.',
				'Notes: Dark Elf guard'
			},

			['Drusus Gratus'] = {
				'Drusus Gratus',
				'Royal Guard',
				'Guard',
				'Location: Royal Guard Barracks',
				'Role: Maintains order.',
				'Notes: Imperial guard'
			},

			['Alusannah'] = {
				'Alusannah',
				'Royal Guard',
				'Crusader',
				'Location: Royal Guard Forts',
				'Role: Leads crusades.',
				'Notes: Redguard crusader'
			},

			['Forven Berano'] = {
				'Forven Berano',
				'Hlaalu',
				'Noble',
				'Location: Hlaalu Courts',
				'Role: Advises leadership.',
				'Notes: Dark Elf noble'
			},

			['Bedal Alen'] = {
				'Bedal Alen',
				'Hlaalu',
				'Merchant',
				'Location: Hlaalu Markets',
				'Role: Manages trade.',
				'Notes: Dark Elf merchant'
			},

			['Hloggar the Bloody'] = {
				'Hloggar the Bloody',
				'Hlaalu',
				'Barbarian',
				'Location: Hlaalu Battlegrounds',
				'Role: Engages in melee combat.',
				'Notes: Nord barbarian'
			},

			['dandras vules'] = {
				'Dandras Vules',
				'Dark Brotherhood',
				'Assassin',
				'Location: Dark Brotherhood Sanctuary',
				'Role: Performs assassinations.',
				'Notes: Dark Elf assassin'
			},

			['gavas drin'] = {
				'Gavas Drin',
				'Temple',
				'Priest',
				'Location: Temple Sanctuaries',
				'Role: Conducts religious services.',
				'Notes: Dark Elf priest'
			},

			['Veros Nerethi'] = {
				'Veros Nerethi',
				'Telvanni',
				'Enforcer',
				'Location: Telvanni Enforcement',
				'Role: Maintains order.',
				'Notes: Dark Elf enforcer'
			},

			['mehra helas'] = {
				'Mehra Helas',
				'Temple',
				'Healer Service',
				'Location: Temple Healing Halls',
				'Role: Provides medical aid.',
				'Notes: Dark Elf healer'
			},

			['Myn Farr'] = {
				'Myn Farr',
				'Clan Berne',
				'Knight',
				'Location: Clan Berne Strongholds',
				'Role: Engages in combat.',
				'Notes: Breton knight'
			},

			['drals indobar'] = {
				'Drals Indobar',
				'Hands of Almalexia',
				'Warrior',
				'Location: Hands of Almalexia Outposts',
				'Role: Engages in combat.',
				'Notes: Dark Elf warrior'
			},

			['arnas therethi'] = {
				'Arnas Therethi',
				'Hands of Almalexia',
				'Warrior',
				'Location: Hands of Almalexia Outposts',
				'Role: Engages in combat.',
				'Notes: Dark Elf warrior'
			},

			['savor hlan'] = {
				'Savor Hlan',
				'Hands of Almalexia',
				'Warrior',
				'Location: Hands of Almalexia Outposts',
				'Role: Engages in combat.',
				'Notes: Dark Elf warrior'
			},

			['sadas mavandes'] = {
				'Sadas Mavandes',
				'Hands of Almalexia',
				'Warrior',
				'Location: Hands of Almalexia Outposts',
				'Role: Engages in combat.',
				'Notes: Dark Elf warrior'
			},

			['vonos veri'] = {
				'Vonos Veri',
				'Hands of Almalexia',
				'Warrior',
				'Location: Hands of Almalexia Outposts',
				'Role: Engages in combat.',
				'Notes: Dark Elf warrior'
			},

			['Crito Olcinius'] = {
				'Crito Olcinius',
				'Imperial Cult',
				'Priest Service',
				'Location: Imperial Cult Temple',
				'Role: Conducts religious services.',
				'Notes: Imperial priest'
			},

			['Carnius Magius'] = {
				'Carnius Magius',
				'East Empire Company',
				'Noble',
				'Location: East Empire Company Headquarters',
				'Role: Oversees company operations.',
				'Notes: Imperial noble'
			},

			['Falco Galenus'] = {
				'Falco Galenus',
				'East Empire Company',
				'Noble',
				'Location: East Empire Company Headquarters',
				'Role: Manages trade routes.',
				'Notes: Imperial noble'
			},

			['Gidar Verothan'] = {
				'Gidar Verothan',
				'East Empire Company',
				'Commoner',
				'Location: East Empire Company Outposts',
				'Role: Performs daily tasks.',
				'Notes: Dark Elf commoner'
			},

			['Gamin Girith'] = {
				'Gamin Girith',
				'East Empire Company',
				'Commoner',
				'Location: East Empire Company Outposts',
				'Role: Assists with logistics.',
				'Notes: Dark Elf commoner'
			},

			['Sabinus Oranius'] = {
				'Sabinus Oranius',
				'East Empire Company',
				'Commoner',
				'Location: East Empire Company Outposts',
				'Role: Manages shipments.',
				'Notes: Imperial commoner'
			},

			['erna the quiet'] = {
				'Erna the Quiet',
				'Skaal',
				'Commoner',
				'Location: Skaal Village',
				'Role: Performs daily tasks.',
				'Notes: Nord commoner'
			},

			['tymvaul'] = {
				'Tymvaul',
				'Skaal',
				'Necromancer',
				'Location: Skaal Ritual Grounds',
				'Role: Practices dark magic.',
				'Notes: Nord necromancer'
			},

			['lassnr'] = {
				'Lassnr',
				'Skaal',
				'Barbarian',
				'Location: Skaal Battlegrounds',
				'Role: Engages in melee combat.',
				'Notes: Nord barbarian'
			},

			['falx carius'] = {
				'Falx Carius',
				'Imperial Legion',
				'Guard',
				'Location: Imperial Legion Forts',
				'Role: Maintains order.',
				'Notes: Imperial guard'
			},

			['gaea artoria'] = {
				'Gaea Artoria',
				'Imperial Legion',
				'Guard',
				'Location: Imperial Legion Forts',
				'Role: Protects territory.',
				'Notes: Imperial guard'
			},

			['raccan'] = {
				'Raccan',
				'Imperial Legion',
				'Guard',
				'Location: Imperial Legion Forts',
				'Role: Maintains order.',
				'Notes: Redguard guard'
			},

			['valgus statlilius'] = {
				'Valgus Statlilius',
				'Imperial Legion',
				'Guard',
				'Location: Imperial Legion Forts',
				'Role: Protects borders.',
				'Notes: Imperial guard'
			},

			['vilbia herennia'] = {
				'Vilbia Herennia',
				'Imperial Legion',
				'Guard',
				'Location: Imperial Legion Forts',
				'Role: Enforces laws.',
				'Notes: Imperial guard'
			},

			['zeno faustus'] = {
				'Zeno Faustus',
				'Imperial Legion',
				'Guard',
				'Location: Imperial Legion Forts',
				'Role: Maintains order.',
				'Notes: Imperial guard'
			},

			['tharsten heart-fang'] = {
				'Tharsten Heart-Fang',
				'Skaal',
				'Barbarian',
				'Location: Skaal Battlegrounds',
				'Role: Leads war parties.',
				'Notes: Nord barbarian'
			},

			['korst wind-eye'] = {
				'Korst Wind-Eye',
				'Skaal',
				'Shaman',
				'Location: Skaal Ritual Grounds',
				'Role: Performs rituals.',
				'Notes: Nord shaman'
			},

			['hagrad the stone'] = {
				'Hagrad the Stone',
				'Skaal',
				'Barbarian',
				'Location: Skaal Village',
				'Role: Engages in melee combat.',
				'Notes: Nord barbarian'
			},

			['ingmar'] = {
				'Ingmar',
				'Skaal',
				'Warrior',
				'Location: Skaal Battlegrounds',
				'Role: Engages in combat.',
				'Notes: Nord warrior'
			},

			['Apronia Alfena'] = {
				'Apronia Alfena',
				'East Empire Company',
				'Commoner',
				'Location: East Empire Company Outposts',
				'Role: Performs daily tasks.',
				'Notes: Imperial commoner'
			},

			['mirisa'] = {
				'Mirisa',
				'Imperial Cult',
				'Monk',
				'Location: Imperial Cult Temple',
				'Role: Practices meditation.',
				'Notes: Redguard monk'
			},

			['jeleen'] = {
				'Jeleen',
				'Imperial Cult',
				'Priest Service',
				'Location: Imperial Cult Sanctuaries',
				'Role: Conducts religious services.',
				'Notes: Redguard priest'
			},

			['engar ice-mane'] = {
				'Engar Ice-mane',
				'Skaal',
				'Warrior',
				'Location: Skaal Battlegrounds',
				'Role: Engages in combat.',
				'Notes: Nord warrior'
			},

			['rigmor halfhand'] = {
				'Rigmor Halfhand',
				'Skaal',
				'Savant',
				'Location: Skaal Archives',
				'Role: Conducts research.',
				'Notes: Nord scholar'
			},

			['risi ice-mane'] = {
				'Risi Ice-mane',
				'Skaal',
				'Farmer',
				'Location: Skaal Farmlands',
				'Role: Cultivates crops.',
				'Notes: Nord farmer'
			},

			['alvring whitebeard'] = {
				'Alvring Whitebeard',
				'Skaal',
				'Warrior',
				'Location: Skaal Battlegrounds',
				'Role: Engages in combat.',
				'Notes: Nord warrior'
			},

			['horski tallowhand'] = {
				'Horski Tallowhand',
				'Skaal',
				'Warrior',
				'Location: Skaal Battlegrounds',
				'Role: Engages in combat.',
				'Notes: Nord warrior'
			},

			['Uryn Maren'] = {
				'Uryn Maren',
				'East Empire Company',
				'Commoner',
				'Location: East Empire Company Outposts',
				'Role: Performs daily tasks.',
				'Notes: Dark Elf commoner'
			},

			['Aldam Berendus'] = {
				'Aldam Berendus',
				'East Empire Company',
				'Commoner',
				'Location: East Empire Company Outposts',
				'Role: Performs daily tasks.',
				'Notes: Dark Elf commoner'
			},

			['Seler Favelnim'] = {
				'Seler Favelnim',
				'East Empire Company',
				'Commoner',
				'Location: East Empire Company Outposts',
				'Role: Performs daily tasks.',
				'Notes: Dark Elf commoner'
			},

			['Dralora Favelnim'] = {
				'Dralora Favelnim',
				'East Empire Company',
				'Commoner',
				'Location: East Empire Company Outposts',
				'Role: Performs daily tasks.',
				'Notes: Dark Elf commoner'
			},

			['severia gratius'] = {
				'Severia Gratius',
				'Imperial Legion',
				'Guard',
				'Location: Imperial Legion Forts',
				'Role: Maintains order.',
				'Notes: Imperial guard'
			},

			['rolf long-tooth'] = {
				'Rolf Long-tooth',
				'Skaal',
				'Warrior',
				'Location: Skaal Battlegrounds',
				'Role: Engages in combat.',
				'Notes: Nord warrior'
			},

			['Constans Atrius'] = {
				'Constans Atrius',
				'East Empire Company',
				'Noble',
				'Location: East Empire Company Headquarters',
				'Role: Oversees company operations.',
				'Notes: Imperial noble'
			},

			['grerid axe-wife'] = {
				'Grerid Axe-Wife',
				'Skaal',
				'Warrior',
				'Location: Skaal Battlegrounds',
				'Role: Engages in combat.',
				'Notes: Nord warrior'
			},

			['sattir the bold'] = {
				'Sattir the Bold',
				'Skaal',
				'Warrior',
				'Location: Skaal Battlegrounds',
				'Role: Leads war parties.',
				'Notes: Nord warrior'
			},

			['snedbrir the smith'] = {
				'Snedbrir the Smith',
				'Skaal',
				'Smith',
				'Location: Skaal Forge',
				'Role: Crafts weapons and armor.',
				'Notes: Nord blacksmith'
			},

			['Unel Lloran'] = {
				'Unel Lloran',
				'East Empire Company',
				'Commoner',
				'Location: East Empire Company Outposts',
				'Role: Performs daily tasks.',
				'Notes: Dark Elf commoner'
			},

			['Garnas Uvalen'] = {
				'Garnas Uvalen',
				'East Empire Company',
				'Commoner',
				'Location: East Empire Company Outposts',
				'Role: Assists with logistics.',
				'Notes: Dark Elf commoner'
			},

			['Garnas Uvalen_guard'] = {
				'Garnas Uvalen',
				'East Empire Company',
				'Guard',
				'Location: East Empire Company Forts',
				'Role: Maintains order.',
				'Notes: Dark Elf guard'
			},

			['Gratian Caerellius'] = {
				'Gratian Caerellius',
				'East Empire Company',
				'Commoner',
				'Location: East Empire Company Outposts',
				'Role: Manages shipments.',
				'Notes: Imperial commoner'
			},

			['Gratian Caerellius_guar'] = {
				'Gratian Caerellius',
				'East Empire Company',
				'Guard',
				'Location: East Empire Company Forts',
				'Role: Protects territory.',
				'Notes: Imperial guard'
			},

			['Afer Flaccus'] = {
				'Afer Flaccus',
				'East Empire Company',
				'Commoner',
				'Location: East Empire Company Outposts',
				'Role: Performs daily tasks.',
				'Notes: Imperial commoner'
			},

			['Afer Flaccus_guard'] = {
				'Afer Flaccus',
				'East Empire Company',
				'Guard',
				'Location: East Empire Company Forts',
				'Role: Maintains order.',
				'Notes: Imperial guard'
			},

			['Sathyn Andrano'] = {
				'Sathyn Andrano',
				'East Empire Company',
				'Trader Service',
				'Location: East Empire Company Markets',
				'Role: Manages trade.',
				'Notes: Dark Elf trader'
			},

			['mirisa_shrine'] = {
				'Mirisa',
				'Imperial Cult',
				'Monk',
				'Location: Imperial Cult Shrine',
				'Role: Practices meditation.',
				'Notes: Redguard monk'
			},

			['Alcedonia Amnis'] = {
				'Alcedonia Amnis',
				'East Empire Company',
				'Publican',
				'Location: East Empire Company Taverns',
				'Role: Manages tavern.',
				'Notes: Imperial publican'
			},

			['bronrod_the_roarer'] = {
				'Bronrod the Roarer',
				'Skaal',
				'Healer Service',
				'Location: Skaal Healing Halls',
				'Role: Provides medical aid.',
				'Notes: Nord healer'
			},

			['falx carius2'] = {
				'Falx Carius',
				'Imperial Legion',
				'Warrior',
				'Location: Imperial Legion Barracks',
				'Role: Engages in combat.',
				'Notes: Imperial warrior'
			},

			['tharsten heart-fang2'] = {
				'Tharsten Heart-Fang',
				'Skaal',
				'Barbarian',
				'Location: Skaal Battlegrounds',
				'Role: Leads war parties.',
				'Notes: Nord barbarian'
			}
        }
    }
}