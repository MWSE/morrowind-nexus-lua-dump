local ashfall = include('mer.ashfall.interop')
if ashfall then
    
    ashfall.registerFoods{
        tm_blk01 = "herb",
		tm_blk02 = "herb",
		tm_blk03 = "herb",
		tm_blk04 = "herb",
		tm_blk05 = "herb",
		tm_blk06 = "herb",
		tm_blk07 = "herb",
		tm_blk08 = "herb",
		tm_blk09 = "herb",
		tm_grn07 = "herb",
		tm_grn01 = "herb",
		tm_grn04 = "herb",
		tm_grn06 = "herb",
		tm_grn02 = "herb",
		tm_grn05 = "herb",
		tm_grn03 = "herb",
		tm_herb01 = "herb",
		tm_herb02 = "herb",
		tm_herb03 = "herb",
		tm_herb05 = "herb",
		tm_herb06 = "herb",
		tm_puerh01 = "herb",
		tm_puerh03 = "herb",
		tm_puerh02 = "herb",
		tm_white01 = "herb",
		tm_white02 = "herb",
		tm_herb07 = "herb",
		tm_herb08 = "herb",
		tm_herb09 = "herb",
		tm_herb04 = "herb",
		tm_coffee_03 = "herb",
		tm_coffee_06 = "herb",
		tm_coffee_01 = "herb",
		tm_coffee_04 = "herb",
		tm_coffee_02 = "herb",
		tm_coffee_05 = "herb",
		tmt_chocolate_03 = "food",
		tmt_cake_berry = "food",
		tm_ko_frostedcake = "food",
		tmt_chocolate_04 = "food",
		tmt_chocolate_05 = "food",
		tmt_chocolate_02 = "food",
		tm_ko_sweetcakemini = "food",
		tm_ko_biscuit = "food",
		tmt_chocolate_01 = "food",
		tmt_chocolate_06 = "food",
		tm_honeycomb = "food",
		tm_coffee_choc = "food",
		tm_coffee_g03 = "herb",
		tm_coffee_g06 = "herb",
		tm_coffee_g01 = "herb",
		tm_coffee_g04 = "herb",
		tm_coffee_g02 = "herb",
		tm_coffee_g05 = "herb"
		
		
    }
    
    ashfall.registerTeas{
        ["tm_blk01"] = {
            teaName = "Corinthe Black Tea",
            teaDescription = "A common black tea with a cleaner and less pungent taste than other black tea varieties. It's known to improve the drinker's agility after a tiring day.",
            effectDescription = "Fortify Agility 10 points and Restore Fatigue 1 point",
			duration = 2,
            spell = {
                id = "corinthebt_spell_effect",
                effects = {
                    {
                        id = tes3.effect.fortifyAttribute,
						attribute = tes3.attribute.agility,
						amount = 10
					},
					{
                        id = tes3.effect.restoreFatigue,
						amount = 1
					}
                }
            }
        },
		["tm_blk02"] = {
		teaName = "Orcrest Chai Tea",
            teaDescription = "Made with the finest spices in the Elsweyr tradition, Orcrest Chai black tea is known to make the drinker quicker.",
            effectDescription = "Fortify Speed 10 points and Restore Fatigue 1 point",
			duration = 2,
            spell = {
                id = "orcrestbt_spell_effect",
                effects = {
                    {
                        id = tes3.effect.fortifyAttribute,
						attribute = tes3.attribute.speed,
						amount = 10
					},
					{
                        id = tes3.effect.restoreFatigue,
						amount = 1
					}
                }
            }
        },
		["tm_blk03"] = {
		teaName = "Wayrest Breakfast Tea",
            teaDescription = "A strongly flavoured and popular variety of black tea, particularly among Bretons, Wayrest Breakfast tea will keep the drinker on their feet by improving their stamina.",
            effectDescription = "Fortify Fatigue 50 points and Restore Fatigue 1 point",
			duration = 2,
            spell = {
                id = "wayrestbt_spell_effect",
                effects = {
                    {
                        id = tes3.effect.fortifyFatigue,
						amount = 50
					},
					{
                        id = tes3.effect.restoreFatigue,
						amount = 1
					}
                }
            }
        },
		["tm_blk04"] = {
		teaName = "Riverhold Berry Tea",
            teaDescription = "The berries give this tea a slightly tart fruity sweetness that sets it apart from other types of black tea. It increases the imbiber's willpower and determination.",
            effectDescription = "Fortify Willpower 10 points and Restore Fatigue 1 point",
			duration = 2,
            spell = {
                id = "riverholdbt_spell_effect",
                effects = {
                    {
                        id = tes3.effect.fortifyAttribute,
						attribute = tes3.attribute.willpower,
						amount = 10
					},
					{
                        id = tes3.effect.restoreFatigue,
						amount = 1
					}
                }
            }
        },
		["tm_blk05"] = {
		teaName = "Rimmen Black Tea",
            teaDescription = "A local favorite in Elsweyr, this black tea is renowned for its pleasant scent, nutty flavor and the relaxing, edifying effect it has on the drinker's constitution and endurance.",
            effectDescription = "Fortify Endurance 10 points and Restore Fatigue 1 point",
			duration = 2,
            spell = {
                id = "rimmenbt_spell_effect",
                effects = {
                    {
                        id = tes3.effect.fortifyAttribute,
						attribute = tes3.attribute.endurance,
						amount = 10
					},
					{
                        id = tes3.effect.restoreFatigue,
						amount = 1
					}
                }
            }
        },
		["tm_blk06"] = {
		teaName = "Stoneflower Black Tea",
            teaDescription = "While the stoneflower, by itself, can be used to brew tea, mixing the flower's crushed and dried petals with Corinthe tea leaf will result in a black tea known for keeping the imbiber hale and strong.",
            effectDescription = "Fortify Strength 10 points and Restore Fatigue 1 point",
			duration = 2,
            spell = {
                id = "stoneflowerbt_spell_effect",
                effects = {
                    {
                        id = tes3.effect.fortifyAttribute,
						attribute = tes3.attribute.strength,
						amount = 10
					},
					{
                        id = tes3.effect.restoreFatigue,
						amount = 1
					}
                }
            }
        },
		["tm_blk07"] = {
		teaName = "Senchal Whitetip Tea",
            teaDescription = "Favored by intellectuals, this fine Elsweyr black tea has a delicate flavor and is notorious for keeping the drinker's mind sharp.",
            effectDescription = "Fortify Intelligence 10 points and Restore Fatigue 1 point",
			duration = 2,
            spell = {
                id = "senchalbt_spell_effect",
                effects = {
                    {
                        id = tes3.effect.fortifyAttribute,
						attribute = tes3.attribute.intelligence,
						amount = 10
					},
					{
                        id = tes3.effect.restoreFatigue,
						amount = 1
					}
                }
            }
        },
		["tm_blk08"] = {
		teaName = "Willowflower Black Tea",
            teaDescription = "Mixing the dried flowers of the willow anther commonly found in Vvardenfell with the Corinthe tea leaf blend results in a calming, confidence raising, black tea that, according to many, makes the drinker feel luckier.",
            effectDescription = "Fortify Luck 10 points and Restore Fatigue 1 point",
			duration = 2,
            spell = {
                id = "willowflowerbt_spell_effect",
                effects = {
                    {
                        id = tes3.effect.fortifyAttribute,
						attribute = tes3.attribute.luck,
						amount = 10
					},
					{
                        id = tes3.effect.restoreFatigue,
						amount = 1
					}
                }
            }
        },
		["tm_blk09"] = {
		teaName = "Corinthe Black Anther Tea",
            teaDescription = "While the black anther flower, by itself, can be used to brew tea, mixing the flower's crushed and dried petals with Corinthe tea leaf blend will result in a black tea so fragrant and tasty that it's known to improve the drinker's personality temporarily.",
            effectDescription = "Fortify Personality 10 points and Restore Fatigue 1 point",
			duration = 2,
            spell = {
                id = "blackantherbt_spell_effect",
                effects = {
                    {
                        id = tes3.effect.fortifyAttribute,
						attribute = tes3.attribute.personality,
						duration = 2,
						amount = 10
					},
					{
                        id = tes3.effect.restoreFatigue,
						duration = 2,
						amount = 1
					}
                }
            }
        },
		["tm_grn07"] = {
		teaName = "Jorval Green Tea",
            teaDescription = "Originating in Elsweyr, this green tea is liked for its medidicinal properties more than its taste. Nobles, particularly, favor its use as a protection against poisons.",
            effectDescription = "Resist Poison 20 points and Restore Health 1 point",
            spell = {
                id = "jorvalgt_spell_effect",
				spellType = tes3.spellType.spell,
                effects = {
                    {
                        id = tes3.effect.resistPoison,
						duration = 120,
						amount = 20
					},
					{
                        id = tes3.effect.restoreHealth,
						duration = 30,
						amount = 1
					}
                }
            }
        },
		["tm_grn01"] = {
		teaName = "Deshaan Green Tea",
            teaDescription = "Produced in the Deshaan district of Morrowind by Great House Dres, this variety of green tea is particularly resistant against diseases and the tea made from it imbues the drinker with similar properties.",
            effectDescription = "Resist Common Disease 20 points and Restore Health 1 point",
            spell = {
                id = "deshaangt_spell_effect",
				spellType = tes3.spellType.spell,
                effects = {
                    {
                        id = tes3.effect.resistCommonDisease,
						duration = 120,
						amount = 20
					},
					{
                        id = tes3.effect.restoreHealth,
						duration = 30,
						amount = 1
					}
                }
            }
        },
		["tm_grn04"] = {
		teaName = "Deshaan Saltrice Tea",
            teaDescription = "Combining the nutty flavor of roasted saltrice with the light vegetable flavor of green tea, this tea blend is well regarded for its invigorating properties as well.",
            effectDescription = "Restore Fatigue 5 points and Restore Health 1 point",
            spell = {
                id = "deshaansaltricegt_spell_effect",
				spellType = tes3.spellType.spell,
                effects = {
                    {
                        id = tes3.effect.restoreFatigue,
						duration = 30,
						amount = 5
					},
					{
                        id = tes3.effect.restoreHealth,
						duration = 30,
						amount = 1
					}
                }
            }
        },
		["tm_grn06"] = {
		teaName = "Willowflower Green Tea",
            teaDescription = "Blending the crushed and dried petals of the willow anther flower with the Deshaan green tea blend results in what is considered the finest Deshaan tea. It's said to be a restorative for those who've been paralyzed.",
            effectDescription = "Cure Paralyzation and Restore Health 1 point",
            spell = {
                id = "willowflowergt_spell_effect",
				spellType = tes3.spellType.spell,
                effects = {
                    {
                        id = tes3.effect.cureParalyzation,
						duration = 1,
						amount = 1
					},
					{
                        id = tes3.effect.restoreHealth,
						duration = 30,
						amount = 1
					}
                }
            }
        },
		["tm_grn02"] = {
		teaName = "Akaviri Jasmine Tea",
            teaDescription = "A rare tea originating in Akavir, notable for its delicate flavor and light fragrance. This green tea is favored by the elderly due to its ability to prevent the stiffening of joints.",
            effectDescription = "Resist Paralysis 40 points and Restore Health 1 point",
            spell = {
                id = "jasminegt_spell_effect",
				spellType = tes3.spellType.spell,
                effects = {
                    {
                        id = tes3.effect.resistParalysis,
						duration = 120,
						amount = 40
					},
					{
                        id = tes3.effect.restoreHealth,
						duration = 30,
						amount = 1
					}
                }
            }
        },
		["tm_grn05"] = {
		teaName = "Akaviri Sencha Tea",
            teaDescription = "One of the cleanest tasting teas if prepared properly, yet bitter, if not. Akaviri sencha green tea is renowned for its powerful, even magical, purifying properties.",
            effectDescription = "Dispel 100 points and Restore Health 1 point",
            spell = {
                id = "akavirisenchagt_spell_effect",
				spellType = tes3.spellType.spell,
                effects = {
                    {
                        id = tes3.effect.dispel,
						duration = 1,
						amount = 100
					},
					{
                        id = tes3.effect.restoreHealth,
						duration = 30,
						amount = 1
					}
                }
            }
        },
		["tm_grn03"] = {
		teaName = "Akaviri Matcha Tea",
            teaDescription = "The most common akaviri tea and a central focus of their the continent's tea tradition, this fine powder results in a green tea famous for its powers as an antitoxin.",
            effectDescription = "Cure Poison and Restore Health 1 point",
            spell = {
                id = "akavirimatchagt_spell_effect",
				spellType = tes3.spellType.spell,
                effects = {
                    {
                        id = tes3.effect.curePoison,
						duration = 1,
						amount = 1
					},
					{
                        id = tes3.effect.restoreHealth,
						duration = 30,
						amount = 1
					}
                }
            }
        },
		["tm_herb01"] = {
            teaName = "Canis Root Tea",
            teaDescription = "An acquired taste, the infusion of the canis root results in a drink with a very strong flavor that can even be poisonous if prepared improperly. It's popular among Orcs and Nords for its strengthening properties.",
            effectDescription = "Fortify Strength 10 points and Fortify Attack 10 points",
			duration = 1,
            spell = {
                id = "canisrootht_spell_effect",
                effects = {
                    {
                        id = tes3.effect.fortifyAttribute,
						attribute = tes3.attribute.strength,
						amount = 10
					},
					{
                        id = tes3.effect.fortifyAttack,
						amount = 10
					}
                }
            }
        },
		["tm_herb02"] = {
            teaName = "Evermore Chamomile Tea",
            teaDescription = "Common in High Rock, chamomile infusions have a slight apple scent and sweet flavor. The drinkers often find themselves being more likeable, but also sneakier.",
            effectDescription = "Fortify Personality 10 points and Chameleon 10 points",
			duration = 1,
            spell = {
                id = "chamomileht_spell_effect",
                effects = {
                    {
                        id = tes3.effect.fortifyAttribute,
						attribute = tes3.attribute.personality,
						amount = 10
					},
					{
                        id = tes3.effect.chameleon,
						amount = 10
					}
                }
            }
        },
		["tm_herb03"] = {
            teaName = "Dragonstar Hibiscus Tea",
            teaDescription = "This deep red infusion's flavor is just the perfect mix between tartness and sweetness according to many. Altmer, in particular, enjoy the hibiscus infusion's beneficial effects as they increase the drinker's resistance to hostile magic.",
            effectDescription = "Fortify Willpower 10 points and Resist Magicka 10 points",
			duration = 1,
            spell = {
                id = "hibiscusht_spell_effect",
                effects = {
                    {
                        id = tes3.effect.fortifyAttribute,
						attribute = tes3.attribute.willpower,
						amount = 10
					},
					{
                        id = tes3.effect.resistMagicka,
						amount = 10
					}
                }
            }
        },
		["tm_herb05"] = {
            teaName = "Mournhold Lemongrass Tea",
            teaDescription = "As the name suggests, this infusion has a tart, lemony flavor and aroma. It's also notable for having beneficial effects on one's speed and reflexes.",
            effectDescription = "Fortify Speed 10 points and Fortify Agility 10 points",
			duration = 1,
            spell = {
                id = "lemongrassht_spell_effect",
                effects = {
                    {
                        id = tes3.effect.fortifyAttribute,
						attribute = tes3.attribute.speed,
						amount = 10
					},
					{
                        id = tes3.effect.fortifyAttribute,
						attribute = tes3.attribute.agility,
						amount = 10
					}
                }
            }
        },
		["tm_herb06"] = {
            teaName = "Cloudrest Mint Tea",
            teaDescription = "Mint has a characteristic freshness and is naturally sweet. The infusion made from it is no different. When properly prepared, the infusion is known to improve the drinker's magical abilities.",
            effectDescription = "Fortify Magicka 50 points and Spell Absorption 5 points",
			duration = 1,
            spell = {
                id = "mintht_spell_effect",
                effects = {
                    {
                        id = tes3.effect.spellAbsorption,
						amount = 5
					},
					{
                        id = tes3.effect.fortifyMagicka,
						amount = 50
					}
                }
            }
        },
		["tm_puerh01"] = {
            teaName = "Soulrest Oolong Tea",
            teaDescription = "Fermented and produced according to Argonian traditions, oolong tea has a rich golden hue, a delicate nutty flavor, and is consumed far and wide in Tamriel. Its mode of production seems to imbue the tea with some of Black Marsh's own characteristics.",
            effectDescription = "Water Breathing and Fortify Fatigue 50 points",
            spell = {
                id = "oolong_spell_effect",
				spellType = tes3.spellType.spell,
                effects = {
                    {
                        id = tes3.effect.waterBreathing,
						duration = 60
					},
					{
                        id = tes3.effect.fortifyFatigue,
						duration = 120,
						amount = 50
					}
                }
            }
        },
		["tm_puerh03"] = {
            teaName = "Blackrose Pu erh Tea",
            teaDescription = "Fermented and produced according to Argonian traditions, the black Pu erh tea cake becomes buoyant and will float in the water unless it is crushed beforehand. Similarly, those who drink it often show some increased buoyancy as well.",
            effectDescription = "Water Walking and Fortify Fatigue 50 points",
            spell = {
                id = "blackrosepuerh_spell_effect",
				spellType = tes3.spellType.spell,
                effects = {
                    {
                        id = tes3.effect.waterWalking,
						duration = 60
					},
					{
                        id = tes3.effect.fortifyFatigue,
						duration = 120,
						amount = 50
					}
                }
            }
        },
		["tm_puerh02"] = {
            teaName = "Gideon Green Pu erh Tea",
            teaDescription = "A greet tea variety, fermented and produced according to Argonian traditions. Fresher and tastier than most Argonian teas, it's also the tea of choice for athletes and swimmers, in particular.",
            effectDescription = "Swift Swim 30 points and Fortify Endurance 20 points",
            spell = {
                id = "gideonpuerh_spell_effect",
				spellType = tes3.spellType.spell,
                effects = {
                    {
                        id = tes3.effect.swiftSwim,
						duration = 60,
						amount = 30
					},
					{
                        id = tes3.effect.fortifyAttribute,
						attribute = tes3.attribute.endurance,
						duration = 120,
						amount = 20
					}
                }
            }
        },
		["tm_white01"] = {
		teaName = "Cloudrest White Tea",
            teaDescription = "A fine tea from the Summerset Isles. An Altmer favorie, Cloudrest white tea has a delicate flavor and is said to make the drinker feel light as the clouds.",
            effectDescription = "Feather 25 points and Restore Magicka 1 point",
            spell = {
                id = "cloudrestwt_spell_effect",
				spellType = tes3.spellType.spell,
                effects = {
                    {
                        id = tes3.effect.feather,
						duration = 120,
						amount = 25
					},
					{
                        id = tes3.effect.restoreMagicka,
						duration = 30,
						amount = 1
					}
                }
            }
        },
		["tm_white02"] = {
		teaName = "Shimmerene Silver Tea",
            teaDescription = "A fine tea from the Summerset Isles. Known as 'silver' due to its color and the fact that its made with more buds than leaves, this tea is favored by the Altmer and renowned for its protective abilities as well as its magicka enhancing ones.",
            effectDescription = "Sanctuary 20 points and Restore Magicka 1 point",
            spell = {
                id = "cloudrestwt_spell_effect",
				spellType = tes3.spellType.spell,
                effects = {
                    {
                        id = tes3.effect.sanctuary,
						duration = 120,
						amount = 20
					},
					{
                        id = tes3.effect.restoreMagicka,
						duration = 30,
						amount = 1
					}
                }
            }
        },
		["tm_herb07"] = {
            teaName = "Skaven Redbush Tea",
            teaDescription = "With a malty, slightly nutty flavor and a somewhat bitter aftertaste, redbush tea is often served with copious amounts of honey, milk or sugar. In addition to its known health benefits, many claim it protects the drinker from electricity.",
            effectDescription = "Resist Shock 10 points and Fortify Health 20 points",
			duration = 1,
            spell = {
                id = "redbushht_spell_effect",
                effects = {
                    {
                        id = tes3.effect.resistShock,
						amount = 10
					},
					{
                        id = tes3.effect.fortifyHealth,
						amount = 20
					}
                }
            }
        },
		["tm_herb08"] = {
            teaName = "Skaven Redbush Chai Tea",
            teaDescription = "A custom blend of the traditional Skaven redbush tea with sweet spices, this variant of redbush tea is reminiscent of chai, yet its properties are still those of the redbush blends, offering improved health to the drinker as well as increasing their resistance to fire.",
            effectDescription = "Resist Fire 10 points and Fortify Health 20 points",
			duration = 1,
            spell = {
                id = "redbushchaiht_spell_effect",
                effects = {
                    {
                        id = tes3.effect.resistFire,
						amount = 10
					},
					{
                        id = tes3.effect.fortifyHealth,
						amount = 20
					}
                }
            }
        },
		["tm_herb09"] = {
            teaName = "Dragonstar Berry Redbush Tea",
            teaDescription = "A blend of redbush with comberry and willow flower results in a red tea that has less need of extra sweetening than usual. It's best served hot during winter, due to its ability to stave off the cold.",
            effectDescription = "Resist Frost 10 points and Fortify Health 20 points",
			duration = 1,
            spell = {
                id = "dragonstarberryht_spell_effect",
                effects = {
                    {
                        id = tes3.effect.resistFrost,
						amount = 10
					},
					{
                        id = tes3.effect.fortifyHealth,
						amount = 20
					}
                }
            }
        },
		["tm_herb04"] = {
            teaName = "Janeth Honeybush Tea",
            teaDescription = "As the name implies, honeybush tea is similar to redbush yet naturally sweeter. It makes the imbiber thougher and more resistant to blows as well but it's also thought to raise one's fortunes as well.",
            effectDescription = "Resist Normal Weapons 10 points and Fortify Luck 10 points",
			duration = 1,
            spell = {
                id = "janethhoneyht_spell_effect",
                effects = {
                    {
                        id = tes3.effect.resistNormalWeapons,
						amount = 10
					},
					{
                        id = tes3.effect.fortifyAttribute,
						attribute = tes3.attribute.luck,
						amount = 20
					}
                }
            }
        },
		["tm_coffee_g03"] = {
            teaName = "Cespar Light Robusta Coffee",
            teaDescription = "Not as popular as other roasts, robusta coffee is stronger and has an earthier flavor than other coffee types. Coffee is a notorious stimulant and this particular kind can, when taken in large amounts, make the drinker jumpy.",
            effectDescription = "Fortify Speed 10 points, Fortify Fatigue 10 points and Jump 10 points",
			duration = 1,
            spell = {
                id = "cesparlight_spell_effect",
                effects = {
                    {
                        id = tes3.effect.fortifyAttribute,
						attribute = tes3.attribute.speed,
						amount = 10
					},
					{
                        id = tes3.effect.fortifyFatigue,
						amount = 20
					},
					{
                        id = tes3.effect.jump,
						amount = 10
					}
                }
            }
        },
		["tm_coffee_g06"] = {
            teaName = "Cespar Dark Robusta Coffee",
            teaDescription = "Not as popular as other roasts, robusta coffee is stronger and has an earthier flavor than other coffee types. Coffee is a notorious stimulant and some swear that the dark robusta roast is strong enough to make one fly.",
            effectDescription = "Fortify Speed 10 points, Fortify Fatigue 20 points and Levitate 1 point",
			duration = 1,
            spell = {
                id = "cespardark_spell_effect",
                effects = {
                    {
                        id = tes3.effect.fortifyAttribute,
						attribute = tes3.attribute.speed,
						amount = 10
					},
					{
                        id = tes3.effect.fortifyFatigue,
						amount = 20
					},
					{
                        id = tes3.effect.levitate,
						amount = 1
					}
                }
            }
        },
		["tm_coffee_g01"] = {
            teaName = "Corinthe Light Arabica Coffee",
            teaDescription = "Milder than other types of coffee, arabica roasts are the drink of choice in Elsweyr. Besides the Khajiit, night watchmen also favor this type of coffee, praising its effects as a stimulant and in raising awareness in the dark.",
            effectDescription = "Fortify Speed 10 points, Fortify Fatigue 20 points and Night Eye 10 points",
			duration = 1,
            spell = {
                id = "corinthelight_spell_effect",
                effects = {
                    {
                        id = tes3.effect.fortifyAttribute,
						attribute = tes3.attribute.speed,
						amount = 10
					},
					{
                        id = tes3.effect.fortifyFatigue,
						amount = 20
					},
					{
                        id = tes3.effect.nightEye,
						amount = 10
					}
                }
            }
        },
		["tm_coffee_g04"] = {
            teaName = "Corinthe Dark Arabica Coffee",
            teaDescription = "Milder than other types of coffee, arabica roasts are the drink of choice in Elsweyr. The dark roast is stronger than the lighter is is known to dilate the pupils in addition to the usual effects of coffee. Drinkers are advised to avoid strong lights.",
            effectDescription = "Fortify Speed 10 points, Fortify Fatigue 20 points and Light 10 points",
			duration = 1,
            spell = {
                id = "corinthedark_spell_effect",
                effects = {
                    {
                        id = tes3.effect.fortifyAttribute,
						attribute = tes3.attribute.speed,
						amount = 10
					},
					{
                        id = tes3.effect.fortifyFatigue,
						amount = 20
					},
					{
                        id = tes3.effect.light,
						amount = 10
					}
                }
            }
        },
		["tm_coffee_g02"] = {
            teaName = "Skaven Golden Arabica Coffee",
            teaDescription = "A tasty but milder brew than the red arabica roast, it is, nevertheless, a strong stimulant and esteemed by warriors in Hammerfell. A cup before a fight helps keep the drinkers quick on their feet.",
            effectDescription = "Fortify Speed 10 points, Fortify Agility 10 points and Fortify Fatigue 20 points",
			duration = 1,
            spell = {
                id = "skavengolden_spell_effect",
                effects = {
                    {
                        id = tes3.effect.fortifyAttribute,
						attribute = tes3.attribute.speed,
						amount = 10
					},
					{
                        id = tes3.effect.fortifyFatigue,
						amount = 20
					},
					{
                        id = tes3.effect.fortifyAttribute,
						attribute = tes3.attribute.agility,
						amount = 10
					}
                }
            }
        },
		["tm_coffee_g05"] = {
            teaName = "Skaven Red Arabica Coffee",
            teaDescription = "A potent coffee roast with a strong, tasty, nutty flavor to it. This particular brew is a powerful stimulant and is known to imbue the drinker with a 'fighting spirit.' For this reason, it is believed to cause some restlessness and intemperance if consumed in large amounts.",
            effectDescription = "Fortify Speed 10 points, Fortify Attack 10 points and Fortify Fatigue 20 points",
			duration = 1,
            spell = {
                id = "skavenred_spell_effect",
                effects = {
                    {
                        id = tes3.effect.fortifyAttribute,
						attribute = tes3.attribute.speed,
						amount = 10
					},
					{
                        id = tes3.effect.fortifyFatigue,
						amount = 20
					},
					{
                        id = tes3.effect.fortifyAttack,
						amount = 10
					}
                }
            }
        },
		["tm_coffee_g06"] = {
            teaName = "Cespar Dark Robusta Coffee",
            teaDescription = "Not as popular as other roasts, robusta coffee is stronger and has an earthier flavor than other coffee types. Coffee is a notorious stimulant and some swear that the dark robusta roast is strong enough to make one fly.",
            effectDescription = "Fortify Speed 10 points, Fortify Fatigue 20 points and Levitate 1 point",
			duration = 1,
            spell = {
                id = "cespardark_spell_effect",
                effects = {
                    {
                        id = tes3.effect.fortifyAttribute,
						attribute = tes3.attribute.speed,
						amount = 10
					},
					{
                        id = tes3.effect.fortifyFatigue,
						amount = 20
					},
					{
                        id = tes3.effect.levitate,
						amount = 1
					}
                }
            }
        },
		["tm_coffee_g01"] = {
            teaName = "Corinthe Light Arabica Coffee",
            teaDescription = "Milder than other types of coffee, arabica roasts are the drink of choice in Elsweyr. Besides the Khajiit, night watchmen also favor this type of coffee, praising its effects as a stimulant and in raising awareness in the dark.",
            effectDescription = "Fortify Speed 10 points, Fortify Fatigue 20 points and Night Eye 10 points",
			duration = 1,
            spell = {
                id = "corinthelight_spell_effect",
                effects = {
                    {
                        id = tes3.effect.fortifyAttribute,
						attribute = tes3.attribute.speed,
						amount = 10
					},
					{
                        id = tes3.effect.fortifyFatigue,
						amount = 20
					},
					{
                        id = tes3.effect.nightEye,
						amount = 10
					}
                }
            }
        },
		["tm_coffee_g04"] = {
            teaName = "Corinthe Dark Arabica Coffee",
            teaDescription = "Milder than other types of coffee, arabica roasts are the drink of choice in Elsweyr. The dark roast is stronger than the lighter is is known to dilate the pupils in addition to the usual effects of coffee. Drinkers are advised to avoid strong lights.",
            effectDescription = "Fortify Speed 10 points, Fortify Fatigue 20 points and Light 10 points",
			duration = 1,
            spell = {
                id = "corinthedark_spell_effect",
                effects = {
                    {
                        id = tes3.effect.fortifyAttribute,
						attribute = tes3.attribute.speed,
						amount = 10
					},
					{
                        id = tes3.effect.fortifyFatigue,
						amount = 20
					},
					{
                        id = tes3.effect.light,
						amount = 10
					}
                }
            }
        },
		["tm_coffee_g02"] = {
            teaName = "Skaven Golden Arabica Coffee",
            teaDescription = "A tasty but milder brew than the red arabica roast, it is, nevertheless, a strong stimulant and esteemed by warriors in Hammerfell. A cup before a fight helps keep the drinkers quick on their feet.",
            effectDescription = "Fortify Speed 10 points, Fortify Agility 10 points and Fortify Fatigue 20 points",
			duration = 1,
            spell = {
                id = "skavengolden_spell_effect",
                effects = {
                    {
                        id = tes3.effect.fortifyAttribute,
						attribute = tes3.attribute.speed,
						amount = 10
					},
					{
                        id = tes3.effect.fortifyFatigue,
						amount = 20
					},
					{
                        id = tes3.effect.fortifyAttribute,
						attribute = tes3.attribute.agility,
						amount = 10
					}
                }
            }
        },
		["tm_coffee_g05"] = {
            teaName = "Skaven Red Arabica Coffee",
            teaDescription = "A potent coffee roast with a strong, tasty, nutty flavor to it. This particular brew is a powerful stimulant and is known to imbue the drinker with a 'fighting spirit.' For this reason, it is believed to cause some restlessness and intemperance if consumed in large amounts.",
            effectDescription = "Fortify Speed 10 points, Fortify Attack 10 points and Fortify Fatigue 20 points",
			duration = 1,
            spell = {
                id = "skavenred_spell_effect",
                effects = {
                    {
                        id = tes3.effect.fortifyAttribute,
						attribute = tes3.attribute.speed,
						amount = 10
					},
					{
                        id = tes3.effect.fortifyFatigue,
						amount = 20
					},
					{
                        id = tes3.effect.fortifyAttack,
						amount = 10
					}
                }
            }
        }
    }
end