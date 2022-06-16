local onion = require("sb_onion.interop")

--[[
 TEMPLATE
 { "(ITEM ID)",
      {
          ["(RACE)"] = { (X VALUE), (y VALUE), (Z VALUE) },
      },
      {
          ["(RACE)"] = (SCALE VALUE)
      }	 
	  }
(Generally you'll want to leave the z value as 0 and the scale as 1, 
but the options are there if you want them.)  
--]]

local glasses = {
    { "_RV_Glasses1",
      {
          ["Imperial"] = { 1, 1, 0 },
          ["Dark Elf"] = { 1, 0.5, 0 },
		  ["High Elf"] = { 1, 0.5, 0 },
		  ["Wood Elf"] = { 1, 0.5, 0 },
		  ["Breton"] = { 1, 1, 0 },
		  ["Redguard"] = { 1, 1.5, 0 },
		  ["Nord"] = { 1, 1.5, 0 },
		  ["Orc"] = { 1, 1.5, 0 },
		  ["Argonian"] = { 1, 1.5, 0 },
		  ["Khajiit"] = { 1, 1.5, 0 }
      },
      {
          ["Imperial"] = 1,
          ["Dark Elf"] = 1,
		  ["High Elf"] = 1,
		  ["Wood Elf"] = 1,
		  ["Breton"] = 1,
		  ["Redguard"] = 1,
		  ["Nord"] = 1,
		  ["Orc"] = 1,
		  ["Argonian"] = 1,
		  ["Khajiit"] = 1
      }
	  },
    { "_RV_Glasses2",
      {
          ["Imperial"] = { 1, 1, 0 },
          ["Dark Elf"] = { 1, 0.5, 0 },
		  ["High Elf"] = { 1, 0.5, 0 },
		  ["Wood Elf"] = { 1, 0.5, 0 },
		  ["Breton"] = { 1, 1, 0 },
		  ["Redguard"] = { 1, 1, 0 },
		  ["Nord"] = { 1, 1, 0 },
		  ["Orc"] = { 1, 1, 0 },
		  ["Argonian"] = { 1, 1, 0 },
		  ["Khajiit"] = { 1, 1, 0 }
      },
      {
      }
	  },
	     { "_RV_Glasses3",
      {
          ["Imperial"] = { 1, 1, 0 },
          ["Dark Elf"] = { 1, 0.5, 0 },
		  ["High Elf"] = { 1, 0.5, 0 },
		  ["Wood Elf"] = { 1, 0.5, 0 },
		  ["Breton"] = { 1, 1, 0 },
		  ["Redguard"] = { 1, 1, 0 },
		  ["Nord"] = { 1, 1, 0 },
		  ["Orc"] = { 1, 1, 0 },
		  ["Argonian"] = { 1, 1, 0 },
		  ["Khajiit"] = { 1, 1, 0 }
      },
      {
      }
	  },
	      { "_RV_Glasses4",
      {
          ["Imperial"] = { 1, 1.5, 0 },
          ["Dark Elf"] = { 1, 0.5, 0 },
		  ["High Elf"] = { 1, 0.5, 0 },
		  ["Wood Elf"] = { 1, 0.5, 0 },
		  ["Breton"] = { 1, 1.5, 0 },
		  ["Redguard"] = { 1, 1.5, 0 },
		  ["Nord"] = { 1, 1.5, 0 },
		  ["Orc"] = { 1, 1.5, 0 },
		  ["Argonian"] = { 1, 1.5, 0 },
		  ["Khajiit"] = { 1, 1.5, 0 }
      },
      {
      }
	  },
	  { "_RV_Glasses1s",
      {
          ["Imperial"] = { 1, 1, 0 },
          ["Dark Elf"] = { 1, 0.5, 0 },
		  ["High Elf"] = { 1, 0.5, 0 },
		  ["Wood Elf"] = { 1, 0.5, 0 },
		  ["Breton"] = { 1, 1, 0 },
		  ["Redguard"] = { 1, 1.5, 0 },
		  ["Nord"] = { 1, 1.5, 0 },
		  ["Orc"] = { 1, 1.5, 0 },
		  ["Argonian"] = { 1, 1.5, 0 },
		  ["Khajiit"] = { 1, 1.5, 0 }
      },
      {
	  }
	  },
    { "_RV_Glasses2s",
      {
          ["Imperial"] = { 1, 1, 0 },
          ["Dark Elf"] = { 1, 0.5, 0 },
		  ["High Elf"] = { 1, 0.5, 0 },
		  ["Wood Elf"] = { 1, 0.5, 0 },
		  ["Breton"] = { 1, 1, 0 },
		  ["Redguard"] = { 1, 1, 0 },
		  ["Nord"] = { 1, 1, 0 },
		  ["Orc"] = { 1, 1, 0 },
		  ["Argonian"] = { 1, 1, 0 },
		  ["Khajiit"] = { 1, 1, 0 }
      },
      {
      }
	  },
	      { "_RV_Glasses4s",
      {
          ["Imperial"] = { 1, 1.5, 0 },
          ["Dark Elf"] = { 1, 0.5, 0 },
		  ["High Elf"] = { 1, 0.5, 0 },
		  ["Wood Elf"] = { 1, 0.5, 0 },
		  ["Breton"] = { 1, 1.5, 0 },
		  ["Redguard"] = { 1, 1.5, 0 },
		  ["Nord"] = { 1, 1.5, 0 },
		  ["Orc"] = { 1, 1.5, 0 },
		  ["Argonian"] = { 1, 1.5, 0 },
		  ["Khajiit"] = { 1, 1.5, 0 }
      },
      {
      }
	  },
	      { "_RV_Goggles1",
      {
          ["Imperial"] = { 1, 1.5, 0 },
          ["Dark Elf"] = { 1, 1, 0 },
		  ["High Elf"] = { 1, 1, 0 },
		  ["Wood Elf"] = { 1, 1, 0 },
		  ["Breton"] = { 1, 1.5, 0 },
		  ["Redguard"] = { 1, 1.5, 0 },
		  ["Nord"] = { 1, 1.5, 0 },
		  ["Orc"] = { 1, 1.5, 0 },
		  ["Argonian"] = { 1, 1, 0 },
		  ["Khajiit"] = { 1, 1, 0 }
      },
      {
      }
	  },
	{ "_RV_Goggles2",
      {
          ["Imperial"] = { 1, 1.5, 0 },
          ["Dark Elf"] = { 1, 1, 0 },
		  ["High Elf"] = { 1, 1, 0 },
		  ["Wood Elf"] = { 1, 1, 0 },
		  ["Breton"] = { 1, 1.5, 0 },
		  ["Redguard"] = { 1, 1.5, 0 },
		  ["Nord"] = { 1, 1.5, 0 },
		  ["Orc"] = { 1, 1.5, 0 },
		  ["Argonian"] = { 1, 1, 0 },
		  ["Khajiit"] = { 1, 1, 0 }
      },
      {
      }
	  },
	{ "_RV_Goggles3",
      {
          ["Imperial"] = { 1, 1, 0 },
          ["Dark Elf"] = { 1, 0.5, 0 },
		  ["High Elf"] = { 1, 0.5, 0 },
		  ["Wood Elf"] = { 1, 0.5, 0 },
		  ["Breton"] = { 1, 1, 0 },
		  ["Redguard"] = { 1, 1, 0 },
		  ["Nord"] = { 1, 1, 0 },
		  ["Orc"] = { 1, 1, 0 },
		  ["Argonian"] = { 1, 1, 0 },
		  ["Khajiit"] = { 1, 1, 0 }
      },
      {
      }
	  },
	{ "_RV_Goggles4",
      {
          ["Imperial"] = { 0.5, 1, 0 },
          ["Dark Elf"] = { 1, 0, 0 },
		  ["High Elf"] = { 1, 0, 0 },
		  ["Wood Elf"] = { 1, 0, 0 },
		  ["Breton"] = { 0.5, 1, 0 },
		  ["Redguard"] = { 0.5, 1, 0 },
		  ["Nord"] = { 0.5, 1, 0 },
		  ["Orc"] = { 0.5, 1, 0 },
		  ["Argonian"] = { 1, 1, 0 },
		  ["Khajiit"] = { 1, 1, 0 }
      },
      {
      }
	  },
	  	{ "_RV_Goggles5",
      {
          ["Imperial"] = { 1, 1, 0 },
          ["Dark Elf"] = { 1, 0, 0 },
		  ["High Elf"] = { 1, 0, 0 },
		  ["Wood Elf"] = { 1, 0, 0 },
		  ["Breton"] = { 1, 1, 0 },
		  ["Redguard"] = { 1, 1, 0 },
		  ["Nord"] = { 1, 1, 0 },
		  ["Orc"] = { 1, 1, 0 },
		  ["Argonian"] = { 1, 1, 0 },
		  ["Khajiit"] = { 1, 1, 0 }
      },
      {
      }
	  },
	  	{ "_RV_Goggles6",
      {
          ["Imperial"] = { 1, 1, 0 },
          ["Dark Elf"] = { 1, 0, 0 },
		  ["High Elf"] = { 1, 0, 0 },
		  ["Wood Elf"] = { 1, 0, 0 },
		  ["Breton"] = { 1, 1, 0 },
		  ["Redguard"] = { 1, 1, 0 },
		  ["Nord"] = { 1, 1, 0 },
		  ["Orc"] = { 1, 1, 0 },
		  ["Argonian"] = { 1, 1, 0 },
		  ["Khajiit"] = { 1, 1, 0 }
      },
      {
      }
	  },
	  	{ "_RV_Goggles7",
      {
          ["Imperial"] = { 1, 1, 0 },
          ["Dark Elf"] = { 1, 0, 0 },
		  ["High Elf"] = { 1, 0, 0 },
		  ["Wood Elf"] = { 1, 0, 0 },
		  ["Breton"] = { 1, 1, 0 },
		  ["Redguard"] = { 1, 1, 0 },
		  ["Nord"] = { 1, 1, 0 },
		  ["Orc"] = { 1, 1, 0 },
		  ["Argonian"] = { 1, 1, 0 },
		  ["Khajiit"] = { 1, 1, 0 }
      },
      {
      }
	  },
	  	{ "_RV_Goggles8",
      {
          ["Imperial"] = { 1, 1, 0 },
          ["Dark Elf"] = { 1, 0, 0 },
		  ["High Elf"] = { 1, 0, 0 },
		  ["Wood Elf"] = { 1, 0, 0 },
		  ["Breton"] = { 1, 1, 0 },
		  ["Redguard"] = { 1, 1, 0 },
		  ["Nord"] = { 1, 1, 0 },
		  ["Orc"] = { 1, 1, 0 },
		  ["Argonian"] = { 1, 1, 0 },
		  ["Khajiit"] = { 1, 1, 0 }
      },
      {
      }
	  },
	  	  	{ "_RV_Lenses1",
      {
          ["Imperial"] = { 1, 1, 0 },
          ["Dark Elf"] = { 1, 0, 0 },
		  ["High Elf"] = { 1, 0, 0 },
		  ["Wood Elf"] = { 1, 0, 0 },
		  ["Breton"] = { 1, 1, 0 },
		  ["Redguard"] = { 1, 1, 0 },
		  ["Nord"] = { 1, 1, 0 },
		  ["Orc"] = { 1, 1, 0 },
		  ["Argonian"] = { 1, 1, 0 },
		  ["Khajiit"] = { 1, 1, 0 }
      },
      {
      }
	  },
	  { "_RV_Lenses2",
      {
          ["Imperial"] = { 1, 1, 0 },
          ["Dark Elf"] = { 1, 0, 0 },
		  ["High Elf"] = { 1, 0, 0 },
		  ["Wood Elf"] = { 1, 0, 0 },
		  ["Breton"] = { 1, 1, 0 },
		  ["Redguard"] = { 1, 1, 0 },
		  ["Nord"] = { 1, 1, 0 },
		  ["Orc"] = { 1, 1, 0 },
		  ["Argonian"] = { 1, 1, 0 },
		  ["Khajiit"] = { 1, 1, 0 }
      },
      {
      }
	  },
	  	  	  	{ "_RV_Blindfold1",
      {
          ["Imperial"] = { 1, 1, 0 },
          ["Dark Elf"] = { 1, 0, 0 },
		  ["High Elf"] = { 1, 0, 0 },
		  ["Wood Elf"] = { 1, 0, 0 },
		  ["Breton"] = { 1, 1, 0 },
		  ["Redguard"] = { 1, 1, 0 },
		  ["Nord"] = { 1, 1, 0 },
		  ["Orc"] = { 1, 1, 0 },
		  ["Argonian"] = { 1, 1, 0 },
		  ["Khajiit"] = { 1, 1, 0 }
      },
      {
      }
	  },
	  	  	  	  	{ "_RV_Eyepatch1R",
      {
          ["Imperial"] = { 1, 1, 0 },
          ["Dark Elf"] = { 1, 0, 0 },
		  ["High Elf"] = { 1, 0, 0 },
		  ["Wood Elf"] = { 1, 0, 0 },
		  ["Breton"] = { 1, 1, 0 },
		  ["Redguard"] = { 1, 1, 0 },
		  ["Nord"] = { 1, 1, 0 },
		  ["Orc"] = { 1, 1, 0 },
		  ["Argonian"] = { 1, 1, 0 },
		  ["Khajiit"] = { 1, 1, 0 }
      },
      {
      }
	  },
	  	  	  	  	  	{ "_RV_Eyepatch1L",
      {
          ["Imperial"] = { 1, 1, 0 },
          ["Dark Elf"] = { 1, 0, 0 },
		  ["High Elf"] = { 1, 0, 0 },
		  ["Wood Elf"] = { 1, 0, 0 },
		  ["Breton"] = { 1, 1, 0 },
		  ["Redguard"] = { 1, 1, 0 },
		  ["Nord"] = { 1, 1, 0 },
		  ["Orc"] = { 1, 1, 0 },
		  ["Argonian"] = { 1, 1, 0 },
		  ["Khajiit"] = { 1, 1, 0 }
      },
      {
      }
	  }
	  }



local function initializedCallback(e)
    for _, glasses in ipairs(glasses) do
        onion.registerWearable(glasses[1], onion.types.eyewear, {}, glasses[2], glasses[3])
    end
end
event.register("initialized", initializedCallback, { priority = 361 })
