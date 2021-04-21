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
  label = Strings.mcm.debugMode,
  description = Strings.mcm.debugModeDesc,
  variable = EasyMCM.createTableVariable {
    id = "debugEnabled",
    table = Config
  }
});

settings:createOnOffButton({
  label = Strings.mcm.alwaysSuppressBlacklist,
  description = Strings.mcm.alwaysSuppressBlacklistDesc,
  variable = EasyMCM.createTableVariable {
    id = "alwaysSuppressBlacklist",
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

local getContainersAndDoors = function()
  local list = {}
  for obj in tes3.iterateObjects(tes3.objectType.container) do
    list[#list+1] = (obj.baseObject or obj).id:lower()
  end
  for obj in tes3.iterateObjects(tes3.objectType.door) do
    list[#list+1] = (obj.baseObject or obj).id:lower()
  end
  table.sort(list)
  
  return list
end

template:createExclusionsPage({
  label = Strings.mcm.blacklist,
  description = Strings.mcm.blacklistDesc,
  leftListLabel = Strings.mcm.blacklist,
  rightListLabel = Strings.mcm.objects,
  
  variable = EasyMCM:createTableVariable({
    id = "blacklist",
    table = Config
  });
  
  filters = {
    { callback = getContainersAndDoors }
  }
});

template:createExclusionsPage({
  label = Strings.mcm.whitelist,
  description = Strings.mcm.whitelistDesc,
  leftListLabel = Strings.mcm.whitelist,
  rightListLabel = Strings.mcm.objects,
  
  variable = EasyMCM:createTableVariable({
    id = "whitelist",
    table = Config
  });
  
  filters = {
    { callback = getContainersAndDoors }
  }
});