--[[ DATA ]]

local this = {}

this.revenantList = { -- a list of Vvardenfell tomb guardians
    "ancestor_ghost",
    "bonelord",
    "bonewalker",
    "Bonewalker_Greater",
    "skeleton",
    "skeleton archer",
    "skeleton warrior",
    "skeleton champion"
  }

  this.leveledRevenantList = {
    "in_tomb_all_lev+0",
    "in_tomb_bone_lev+0",
    "in_tomb_skele_lev+0"
}

  this.bmCreatureList = { -- a list of Solstheim tomb and barrow guardians
    "atronach_frost"
  }

  this.locationsMatchList = {  -- add your Vvardenfell locations' names here
    "Tomb",
    "Ancestral Vault",
    "Burial Cavern"
  }

  this.bmLocationsMatchList = {  -- add your Solstheim locations' names here
    "Barrow",
    "Tombs of Skaalara",
    "Glenschul's Tomb",
    "Gandrung Caverns"
  }

  this.miscObjectsMatchList = { -- add your custom activator ids here
    "nc_ashpit"
  }

  this.objectsList = { -- add your container activator ids here
    "chest_tomb",
    "urn_ash"
  }

  this.revenantTauntList = {
    "Who dares to defile the place of my final resting? Now die!",
    "Who interrupts my eternal slumber? Die!",
    "You'll join me soon enough, mortal."
  }

  this.environmentalEffectList = {
    "[A grave chill gives you creeping horripilation as you feel a revenant appear behind you]",
    "[A sudden gust of ice cold wind causes you to freeze for a second]",
    "[A disturbing presence emerges right behind you]"
  }

  this.bmEnvironmentalEffectList = {
    "[You open the chest and feel even colder than before]",
    "[A thin frosty crust starts to appear on the floor as you open the chest]",
    "[As you open the chest, you notice the fires inside the barrow have gone dim]"
  }

  this.bmEnvironmentalEffectListStalhrim = {
    "[As you wave your pick, it gets stuck in the ice. You're not alone here]",
    "[You feel an alien emanation slipping through the cracks and manifesting behind you]",
    "[A cold burst springs from the stalhrim vein]"
  }

return this
