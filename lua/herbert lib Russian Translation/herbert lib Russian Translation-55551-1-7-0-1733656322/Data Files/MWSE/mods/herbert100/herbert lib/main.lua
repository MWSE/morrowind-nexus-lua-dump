-- really super contrived file structure time

do -- write init message, load config
    local hlib = require("herbert100.herbert lib")
    local log = Herbert_Logger()
    local cfg = hlib.load_config("Herbert Lib", {log_level = log.LEVEL.INFO})
    log:set_level(cfg.log_level)
    log:write_init_message()
    event.register("modConfigReady", function()
        local MCM = hlib.MCM.new{mod_name = "Herbert Lib", config = cfg}
        MCM:register()
        local page = MCM:new_page{}
        page:add_log_settings(log)
        page = nil
        MCM = nil
        log = nil
        cfg = nil
        hlib = nil
    end, {doOnce=true})
end
