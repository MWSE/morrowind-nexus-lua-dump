---@class herbert.QLM.common
local common = {
    info_text_cache = {}, ---@type table<string, string> takes in id, spits out text
}
local c = common.info_text_cache
function common.get_text(info)
    local text = c[info.id]
    if not text then
        text = info.text
        c[info.id] = text
    end
    return text
end

return common

