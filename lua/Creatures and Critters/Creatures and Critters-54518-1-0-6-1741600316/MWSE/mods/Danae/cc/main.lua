-- ingredients (and hide) added by Creatures & Critters

local ashfall = include("mer.ashfall.interop")
if ashfall then

    ashfall.registerFoods{
	aa_cr_ing_rabbit_foot = "meat",
	aa_cr_ing_squirrel_tail = "meat",
	aa_cr_ing_kriin_flesh = "meat",
	aa_cr_ant_head = "meat",
	aa_cr_ant_head_black = "meat",
	aa_cr_batwing_ = "meat",
	aa_cr_batwing_large = "meat",
	aa_cr_Penguin_fin = "meat",
	aa_cr_Royal_Jelly = "seasoning",
	aa_cr_ing_netch_jelly = "seasoning",
	T_IngCrea_FrogEye_01 = "meat",
	aa_cr_ing_bear_fat = "meat",
	aa_cr_ing_bear_meat = "meat",
	aa_cr_ing_wolf_meat = "meat",
	aa_cr_ing_kollop_meat = "meat",
	aa_cr_ing_hunger_tongue = "meat",
	aa_cr_ing_ogrim_flesh = "meat",
    }

end

local CraftingFramework = include("CraftingFramework")
local materials = {
  {
    id = "hide",
    ids = {
      "aa_cr_ing_kriin_hide"
    }
  },
  {
    id = "_plume",
    ids = {
      "aa_cr_ing_Twilight_feather"
      "aa_RacerPlumes2"
      "aa_RacerPlumes3"
      "aa_RacerPlumes4"
    }
  }
}
if CraftingFramework then
    CraftingFramework.Material:registerMaterials(materials)
end