local onion = require("sb_onion.interop")

local glasses = {
    { "_RV_Glasses1",
      {
          ["Imperial"] = { 0, 0, 0 },
          ["Dark Elf"] = { 0, -1, 0 },
		  ["High Elf"] = { 0, -1, 0 },
		  ["Wood Elf"] = { 0, -1, 0 },
		  ["Breton"] = { 0, 0, 0 },
		  ["Redguard"] = { 0, 0, 0 },
		  ["Nord"] = { 0, 0, 0 },
		  ["Orc"] = { 0, 0, 0 },
		  ["Argonian"] = { 0, 0, 0 },
		  ["Khajiit"] = { 0, 0, 0 }
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
          ["Imperial"] = { 0, 0, 0 },
          ["Dark Elf"] = { 0, -1, 0 },
		  ["High Elf"] = { 0, -1, 0 },
		  ["Wood Elf"] = { 0, -1, 0 },
		  ["Breton"] = { 0, 0, 0 },
		  ["Redguard"] = { 0, 0, 0 },
		  ["Nord"] = { 0, 0, 0 },
		  ["Orc"] = { 0, 0, 0 },
		  ["Argonian"] = { 0, 0, 0 },
		  ["Khajiit"] = { 0, 0, 0 }
      },
      {
      }
	  },
	     { "_RV_Glasses3",
      {
          ["Imperial"] = { 0, 0, 0 },
          ["Dark Elf"] = { 0, -1, 0 },
		  ["High Elf"] = { 0, -1, 0 },
		  ["Wood Elf"] = { 0, -1, 0 },
		  ["Breton"] = { 0, 0, 0 },
		  ["Redguard"] = { 0, 0, 0 },
		  ["Nord"] = { 0, 0, 0 },
		  ["Orc"] = { 0, 0, 0 },
		  ["Argonian"] = { 0, 0, 0 },
		  ["Khajiit"] = { 0, 0, 0 }
      },
      {
      }
	  },
	      { "_RV_Glasses4",
      {
          ["Imperial"] = { 0, 0, 0 },
          ["Dark Elf"] = { 0, -1, 0 },
		  ["High Elf"] = { 0, -1, 0 },
		  ["Wood Elf"] = { 0, -1, 0 },
		  ["Breton"] = { 0, 0, 0 },
		  ["Redguard"] = { 0, 0, 0 },
		  ["Nord"] = { 0, 0, 0 },
		  ["Orc"] = { 0, 0, 0 },
		  ["Argonian"] = { 0, 0, 0 },
		  ["Khajiit"] = { 0, 0, 0 }
      },
      {
      }
	  },
	  { "_RV_Glasses1s",
      {
          ["Imperial"] = { 0, 0, 0 },
          ["Dark Elf"] = { 0, -1, 0 },
		  ["High Elf"] = { 0, -1, 0 },
		  ["Wood Elf"] = { 0, -1, 0 },
		  ["Breton"] = { 0, 0, 0 },
		  ["Redguard"] = { 0, 0, 0 },
		  ["Nord"] = { 0, 0, 0 },
		  ["Orc"] = { 0, 0, 0 },
		  ["Argonian"] = { 0, 0, 0 },
		  ["Khajiit"] = { 0, 0, 0 }
      },
      {
	  }
	  },
    { "_RV_Glasses2s",
      {
          ["Imperial"] = { 0, 0, 0 },
          ["Dark Elf"] = { 0, -1, 0 },
		  ["High Elf"] = { 0, -1, 0 },
		  ["Wood Elf"] = { 0, -1, 0 },
		  ["Breton"] = { 0, 0, 0 },
		  ["Redguard"] = { 0, 0, 0 },
		  ["Nord"] = { 0, 0, 0 },
		  ["Orc"] = { 0, 0, 0 },
		  ["Argonian"] = { 0, 0, 0 },
		  ["Khajiit"] = { 0, 0, 0 }
      },
      {
      }
	  },
	      { "_RV_Glasses4s",
      {
          ["Imperial"] = { 0, 0, 0 },
          ["Dark Elf"] = { 0, -1, 0 },
		  ["High Elf"] = { 0, -1, 0 },
		  ["Wood Elf"] = { 0, -1, 0 },
		  ["Breton"] = { 0, 0, 0 },
		  ["Redguard"] = { 0, 0, 0 },
		  ["Nord"] = { 0, 0, 0 },
		  ["Orc"] = { 0, 0, 0 },
		  ["Argonian"] = { 0, 0, 0 },
		  ["Khajiit"] = { 0, 0, 0 }
      },
      {
      }
	  },
	      { "_RV_Goggles1",
      {
          ["Imperial"] = { 0, 0, 0 },
          ["Dark Elf"] = { 0, 0, 0 },
		  ["High Elf"] = { 0, 0, 0 },
		  ["Wood Elf"] = { 0, 0, 0 },
		  ["Breton"] = { 0, 0, 0 },
		  ["Redguard"] = { 0, 0, 0 },
		  ["Nord"] = { 0, 0, 0 },
		  ["Orc"] = { 0, 0, 0 },
		  ["Argonian"] = { 0, 0, 0 },
		  ["Khajiit"] = { 0, 0, 0 }
      },
      {
      }
	  },
	{ "_RV_Goggles2",
      {
          ["Imperial"] = { 0, 0, 0 },
          ["Dark Elf"] = { 0, -0.5, 0 },
		  ["High Elf"] = { 0, -0.5, 0 },
		  ["Wood Elf"] = { 0, -0.5, 0 },
		  ["Breton"] = { 0, 0, 0 },
		  ["Redguard"] = { 0, 0, 0 },
		  ["Nord"] = { 0, 0, 0 },
		  ["Orc"] = { 0, 0, 0 },
		  ["Argonian"] = { 0, 0, 0 },
		  ["Khajiit"] = { 0, 0, 0 }
      },
      {
      }
	  },
	{ "_RV_Goggles3",
      {
          ["Imperial"] = { 0, 0, 0 },
          ["Dark Elf"] = { 0, -0.5, 0 },
		  ["High Elf"] = { 0, -0.5, 0 },
		  ["Wood Elf"] = { 0, -0.5, 0 },
		  ["Breton"] = { 0, 0, 0 },
		  ["Redguard"] = { 0, 0, 0 },
		  ["Nord"] = { 0, 0, 0 },
		  ["Orc"] = { 0, 0, 0 },
		  ["Argonian"] = { 0, 0, 0 },
		  ["Khajiit"] = { 0, 0, 0 }
      },
      {
      }
	  },
	{ "_RV_Goggles4",
      {
          ["Imperial"] = { 0, 0, 0 },
          ["Dark Elf"] = { 0, -1, 0 },
		  ["High Elf"] = { 0, -1, 0 },
		  ["Wood Elf"] = { 0, -1, 0 },
		  ["Breton"] = { 0, 0, 0 },
		  ["Redguard"] = { 0, 0, 0 },
		  ["Nord"] = { 0, 0, 0 },
		  ["Orc"] = { 0, 0, 0 },
		  ["Argonian"] = { 0, 0, 0 },
		  ["Khajiit"] = { 0, 0, 0 }
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
