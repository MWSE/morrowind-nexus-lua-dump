local EasyMCM = require("easyMCM.EasyMCM");
local Config  = require("AdituV.DetectTrap.Config");
local Strings = require("AdituV.DetectTrap.Strings");

local template = EasyMCM.createTemplate(Strings.mcm.modName);
template:saveOnClose("detectTrap", Config);
template:register();

local page = template:createSideBarPage({
  label = Strings.mcm.settings,
});
local settings = page:createCategory(Strings.mcm.settings);


settings:createOnOffButton({
  label = Strings.mcm.modEnabled,
  description = Strings.mcm.modEnabledDesc,
  variable = EasyMCM.createTableVariable {
    id = "modEnabled",
    table = Config
  }
});

settings:createOnOffButton({
  label = Strings.mcm.debugMode,
  description = Strings.mcm.debugModeDesc,
  variable = EasyMCM.createTableVariable {
    id = "debugEnabled",
    table = Config
  }
});

settings:createOnOffButton({
  label = Strings.mcm.enchantEffect,
  description = Strings.mcm.enchantEffectDesc,
  variable = EasyMCM.createTableVariable {
    id = "enchantEffect",
    table = Config
  }
});

settings:createSlider({
  label = Strings.mcm.forgetAfter,
  max = 2 * 60 * 60, -- 2 hours
  description = Strings.mcm.forgetAfterDesc,
  variable = EasyMCM.createTableVariable {
    id = "forgetDuration",
    table = Config
  }
});

local difficulty = page:createCategory(Strings.mcm.difficulty);
difficulty:createSlider({
  label = Strings.mcm.maxLockLevel,
  min = 100,
  max = 500,
  description = Strings.mcm.maxLockLevelDesc,
  variable = EasyMCM.createTableVariable {
    id = "maxLockLevel",
    table = Config.trapDifficulty;
  }
});

difficulty:createSlider({
  label = Strings.mcm.midpoint,
  max = 130,
  description = Strings.mcm.midpointDesc,
  variable = EasyMCM.createTableVariable {
    id = "midpoint",
    table = Config.trapDifficulty;
  }
});

difficulty:createSlider({
  label = Strings.mcm.steepness,
  description = Strings.mcm.steepnessDesc,
  min = 0,
  max = 100,
  step = 1,
  jump = 20,
  variable = EasyMCM.createVariable {
    get = function (self)
      return 100 * Config.trapDifficulty.steepness;
    end,
    set = function (self, value)
      Config.trapDifficulty.steepness = value / 100;
    end
  }
});