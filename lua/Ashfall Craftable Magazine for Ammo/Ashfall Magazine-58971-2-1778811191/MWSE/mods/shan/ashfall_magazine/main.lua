--[[
    Mod: Craftable Magazine
    Author: Shanjaq
    
    This mod allows you to craft ammo magazines with novice bushcrafting skill.
    It serves as an organizer for all types of ammunition.
]] --
local ashfall = include("mer.ashfall.interop")
local CraftingFramework = include("CraftingFramework")
local skillModule = include("OtherSkills.skillModule")
local ItemFilter = require("CraftingFramework.carryableContainers.components.ItemFilter")
local logging = require("logging.logger")

local config = { logLevel = "INFO" }

---@type mwseLogger
local log = logging.new({
  name = "Craftable Magazine",
  logLevel = config.logLevel,
})

local magazineId = "ashfall_magazine_01"

--- @param e CraftingFramework.MenuActivator.RegisteredEvent
local function registerBushcraftingRecipe(e)
  local bushcraftingActivator = e.menuActivator

  ---@type CraftingFramework.CarryableContainers.ItemFilter.data
  local filter = {
    id = "ammunition",
    name = "Ammunition",
    isValidItem = function(item, itemData)
      ---@cast item tes3item
      local isAmmo = item.objectType == tes3.objectType.ammunition
      local isThrown = item.objectType == tes3.objectType.weapon
          and item.type == tes3.weaponType.marksmanThrown
      return isAmmo or isThrown
    end,
  }
  ItemFilter.register(filter)
  log:debug("Registered ammunition item filter")

  --- @type CraftingFramework.Recipe.data
  local recipe = {
    id = magazineId,
    craftableId = magazineId,
    description = "Basic leather magazine for the organization of ammunition.",
    materials = {
      { material = "leather", count = 2 },
      { material = "fabric", count = 1 },
      { material = "rope", count = 1 },
    },
    skillRequirements = {
      ashfall.bushcrafting.survivalTiers.apprentice
    },
    toolRequirements = {
      {
        tool = "knife",
        conditionPerUse = 10,
      },
      {
        tool = "hammer",
        conditionPerUse = 1,
      },
    },
    soundType = "leather",
    category = "Containers",
    containerConfig = {
      capacity = 100,
      weightModifier = 0.6,
      filter = "ammunition",
    },
    additionalMenuOptions = {
      ashfall.bushcrafting.menuOptions.rename
    },
    timeTaken = 30 / 60,
  }
  local recipes = { recipe }
  bushcraftingActivator:registerRecipes(recipes)
  log:debug("Registered magazine recipe")
end

event.register("Ashfall:ActivateBushcrafting:Registered", registerBushcraftingRecipe)
