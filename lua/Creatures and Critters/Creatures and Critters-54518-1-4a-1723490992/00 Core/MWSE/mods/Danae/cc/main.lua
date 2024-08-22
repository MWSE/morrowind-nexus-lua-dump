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
--	"aa_cr_Rabbit's Foot" = "meat",
	aa_cr_Royal_Jelly = "seasoning",
	aa_cr_ing_netch_jelly = "seasoning",
    }

end

local CraftingFramework = include("CraftingFramework")
local materials = {
  {
    id = "hide",
    ids = {
      "aa_cr_ing_kriin_hide"
    }
  }
}
if CraftingFramework then
    CraftingFramework.Material:registerMaterials(materials)
end