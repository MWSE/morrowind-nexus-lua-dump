local ashfall = include("mer.ashfall.interop")
if ashfall then

    ashfall.registerActivators{
		x32_Flora_TreeRed01 = "tree",
		x32_Flora_TreeRed02 = "tree"
		x32_Flora_TreeRed03 = "tree",
		x32_Flora_TreeRed04 = "tree",
		x32_Flora_TreeRed05 = "tree",
		x32_Furn_GardenSpigot = "well",
		x32_Furn_GardenFountain = "partial"
    }

    ashfall.registerWaterContainers{
        x32_Misc_GardenWateringCan = { capacity = 200 },
    }

    ashfall.registerFoods{
		x32_IngFlor_Saffron = "herb"
    }

    ashfall.registerHeatSources{
		x32_In_SwordGold01 = 50,
		x32_In_SwordGold02 = 50,
		x32_In_SwordGold03 = 50,
		x32_In_SwordGold04 = 50,
		x32_In_SwordGold05 = 50,
    }

	ashfall.registerTeas{
		['x32_IngFlor_Saffron'] = {
			teaName = "Чай из шафрана",
			teaDescription = "Ароматный чай, заваренный из нитей шафрана. Его тонкий пряный вкус наполняет пьющего безмятежной уверенностью в причудах судьбы.",
			effectDescription = "Улучшение удачи 5 п.",
			spell = {
				id = "x32_sp_SaffronTea",
				spellType = tes3.spellType.spell,
				effects = {
					{
						id = tes3.effect.fortifyAttribute,
						attribute = tes3.attribute.luck,
						amount = 5,
						duration = 30
					},
				}
			}
		}
	}


end