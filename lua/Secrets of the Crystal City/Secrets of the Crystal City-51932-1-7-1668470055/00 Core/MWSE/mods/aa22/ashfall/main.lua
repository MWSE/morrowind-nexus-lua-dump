local ashfall = include("mer.ashfall.interop")
if ashfall then

    ashfall.registerActivators{
		aa22_Fx_WaterAquedCenter = "waterDirty",
		aa22_Fx_WaterAquedEnd = "waterDirty",
		aa22_Fx_WaterAquedShort = "waterDirty"
    }

    ashfall.registerFoods{
		aa22_IngFlor_BleedingCrown = "mushroom",
		aa22_IngFlor_Blisterwort = "mushroom",
		aa22_IngFlor_ImpStool = "mushroom",
		aa22_IngFlor_WispStalk = "mushroom",
		aa22_IngFlor_Aster = "herb"
    }

	ashfall.registerTeas{
		['aa22_IngFlor_Aster'] = {
			teaName = "Aster Tea",
			teaDescription = "An aromatic brew with sweet undertones and a fiery aftertaste. The warmth soothes your throat as you feel your ailments cleansing.",
			effectDescription = "Dispels 30 Points",
			spell = {
				id = "aa22_sp_AsterTea",
				spellType = tes3.spellType.spell,
				effects = {
					{
						id = tes3.effect.dispel,
						amount = 30,
						duration = 1
					},
				}
			}
		}
	}

end