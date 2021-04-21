local Effects = require("AdituV.DetectTrap.Magic.Effects")
local Strings = require("AdituV.DetectTrap.Strings");

local Spells = {};
Spells.definitions = {};
Spells.definitions["adv_dt_untrap_spell"] = {
  name = Strings.spells.untrap,
  effects = {
    [1] = {
      id = "adv_dt_untrap",
      numId = tes3.effect["adv_dt_untrap"],
      rangeType = tes3.effectRange.touch,
      min = 0,
      max = 0,
      duration = 0,
      radius = 0
    }
  }
};

local defaultCost = function(spell)
  local cost = 0;
  for i=1, spell:getActiveEffectCount() do
    local v = spell.effects[i];
    
    if (v ~= nil) then
      local minM = math.max(v.min or 1, 1);
      local maxM = math.max(v.max or 1, 1);
      local dur = math.max(v.duration or 1, 1);
      local area = v.radius or 0;
      local effectCost = 0;
      
      if area == 0 and v.rangeType == tes3.effectRange.self then
        area = 1
      end
      
      effectCost = (minM + maxM) * (dur + 1) + area
      effectCost = effectCost * v.object.baseMagickaCost;
      effectCost = math.floor(effectCost / 40.0);

      cost = cost + effectCost
    end

  end
end

local registerSpell = function(id, def)
  local spell = tes3.getObject(id) or tes3spell.create(id, def.name);
  
  for k,v in ipairs(def.effects) do
    local eff = spell.effects[k];
    
    eff.id = v.numId;
    eff.rangeType = v.rangeType;
    eff.min = v.min;
    eff.max = v.max;
    eff.duration = v.duration;
    eff.radius = v.radius;
  end
  
  spell.magickaCost = def.magickaCost or defaultCost(spell);
end

Spells.registerSpells = function()
  for k,v in pairs(Spells.definitions) do
    registerSpell(k,v);
  end
end

return Spells;