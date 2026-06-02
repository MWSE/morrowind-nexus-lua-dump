-- scripts/arcane_illumination/data/attach_light_blacklist.lua
-- Returns a lowercase-keyed set: id -> true

local raw = [[
uvi_buglamp_gothren
light_com_lantern_bm_unique
torch_infinite_time
torch_infinite_time_unique
light_com_lantern_02_inf
light_de_buglamp_01_64
light_de_buglamp_01
light_com_torch_burnedout_01
light_com_candle_03_64
light_com_candle_03
light_com_candle_01
light_com_candle_01_64
light_de_candle_ivory_dead
tr_m3_q_theriftcandle
tr_m3_q_theriftcandleoff
tr_m3_a9_q_ritualcandle
tr_m3_raathimtorch01
tr_m3_raathimtorch02
tr_m3_raathimtorch03
tr_m3_lgt_candle
tr_m3_oe_mg_ritualcandle
tr_m3_oe_mg_ritualcandle_lit
tr_m1_fw_tg2_candlestick
tr_m2_kaishi_lantern
tr_m3_q_a7_nethrillantern
tr_m3_tt_rip_ritualcandle
tr_m2_q_14_candle02
tr_m2_q_14_candle01
pc_m1_garage_candle
pc_m1_garage_lightvarla
pc_m1_wormusoel_lightvarla
pc_m1_lindasael_lightvarla
pc_m1_gulaida_lightvarla
]]

local set = {}
for line in raw:gmatch("[^\r\n]+") do
    local id = line:match("^%s*(.-)%s*$")
    if id ~= "" and id:sub(1, 1) ~= "#" then
        set[id:lower()] = true
    end
end

return set