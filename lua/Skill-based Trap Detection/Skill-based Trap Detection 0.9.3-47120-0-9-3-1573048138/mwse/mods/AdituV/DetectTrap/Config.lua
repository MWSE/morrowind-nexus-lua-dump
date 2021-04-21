local defaultConfig = {
    version = "0.9.2",
    debugEnabled = false,
    
    alwaysSuppressBlacklist = false,

    forgetDuration = 5 * 60, -- 5 minutes, real time
    
    trapDifficulty = {
        steepness = 0.05,
        midpoint = 70
    },
    
    blacklist = {
        ["tramaroot_06"] = true
    },
    
    whitelist = {
        -- vanilla content
        ["barrel_01_ahnassi_drink"] = true,
        ["barrel_01_ahnassi_food"] = true,
        ["com_chest_02_mg_supply"] = true,
        ["com_chest_02_fg_supply"] = true,
        -- tamriel rebuilt
        ["t_mwcom_furn_ch2fguild"] = true,
        ["t_mwcom_furn_ch2mguild"] = true,
        ["tr_com_sack_02_i501_mry"] = true,
        ["tr_i3-295-de_p_drinks"] = true,
        ["tr_i3-672_de_rm_deskalc"] = true,
        ["tr_m2_com_sack_i501_bg"] = true,
        ["tr_m2_com_sack_i501_sl"] = true,
        ["tr_m2_com_sack_i501_ww"] = true,
        ["tr_m2_q_27_fgchest"] = true,
        ["tr_m2_q_29_fgchest"] = true,
        ["tr_m3_i395_sack_local1"] = true,
        ["tr_m3_ingchest_i3-390-i"] = true,
        ["tr_m3_oe_anjzhirra_sack"] = true,
        ["tr_m3_soil_i3-390-ind"] = true,
    },
    
    effects = {
      ["adv_dt_untrap"] = {
        numId = 6301,
        baseCost = 5,
        speed = 1,
        lighting = { 0, 0, 0 },
      }
    },
};

defaultConfig.__index = defaultConfig;
local mwseConfig = mwse.loadConfig("detectTrap") or {};

-- Set values in the user's saved config to default to those in
-- the default config if they are missing
setmetatable(mwseConfig, defaultConfig);

return mwseConfig;
