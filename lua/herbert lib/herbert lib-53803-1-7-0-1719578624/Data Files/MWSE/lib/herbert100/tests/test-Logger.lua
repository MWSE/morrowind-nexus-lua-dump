local uw = require("unitwind").new{
    enabled = true,
    --- ... other settings ...
    highlight=false
}
local Logger = require "herbert100.Logger" ---@type herbert.Logger

local function reload_logger()
    Logger = dofile("herbert100.Logger")    
end

uw:start("Object creation (no module name)")
uw:test("passing a string", function()
    local log = Logger "my mod1" ---@type herbert.Logger

    uw:expect(log.mod_name).toBe("my mod1")
    uw:expect(log.module_name).toBe(nil)
    uw:expect(log.level).toBe(Logger.LEVEL.INFO)
    uw:expect(log:get_loggers()).toBeType("table")
    uw:expect(#log:get_loggers()).toBe(1)
    uw:expect(log.file).toBe(nil)
    uw:expect(log.write_to_file).toBe(false)
    uw:expect(log.use_colors).toBe(false)
    uw:expect(log.include_timestamp).toBe(false)

 
end)

uw:test("passing a table", function()
    local log = Logger{mod_name="my mod2"} ---@type herbert.Logger

    uw:expect(log.mod_name).toBe("my mod2")
    uw:expect(log.module_name).toBe(nil)
    uw:expect(log.level).toBe(Logger.LEVEL.INFO)
    uw:expect(log:get_loggers()).toBeType("table")
    uw:expect(#log:get_loggers()).toBe(1)
    uw:expect(log.file).toBe(nil)
    uw:expect(log.write_to_file).toBe(false)
    uw:expect(log.use_colors).toBe(false)
    uw:expect(log.include_timestamp).toBe(false)
end)
 
uw:test("with timestamps", function()
    local log = Logger.new{mod_name="my mod3",include_timestamp=true} ---@type herbert.Logger

    uw:expect(log.mod_name).toBe("my mod3")
    uw:expect(log.module_name).toBe(nil)
    uw:expect(log.level).toBe(Logger.LEVEL.INFO)
    uw:expect(log:get_loggers()).toBeType("table")
    uw:expect(#log:get_loggers()).toBe(1)
    uw:expect(log.file).toBe(nil)
    uw:expect(log.write_to_file).toBe(false)
    uw:expect(log.use_colors).toBe(false)
    uw:expect(log.include_timestamp).toBe(true)
end)

uw:test("with colors", function()
    local log = Logger.new{mod_name="my mod4", use_colors=true} ---@type herbert.Logger

    uw:expect(log.mod_name).toBe("my mod4")
    uw:expect(log.module_name).toBe(nil)
    uw:expect(log.level).toBe(Logger.LEVEL.INFO)
    uw:expect(log:get_loggers()).toBeType("table")
    uw:expect(#log:get_loggers()).toBe(1)
    uw:expect(log.file).toBe(nil)
    uw:expect(log.write_to_file).toBe(false)
    uw:expect(log.use_colors).toBe(true)
    uw:expect(log.include_timestamp).toBe(false)
end)

uw:test("with log level", function()
    local log = Logger.new{mod_name="my mod5", level="DEBUG"} ---@type herbert.Logger

    uw:expect(log.mod_name).toBe("my mod5")
    uw:expect(log.module_name).toBe(nil)
    uw:expect(log.level).toBe(Logger.LEVEL.DEBUG)
    uw:expect(log:get_loggers()).toBeType("table")
    uw:expect(#log:get_loggers()).toBe(1)
    uw:expect(log.file).toBe(nil)
    uw:expect(log.write_to_file).toBe(false)
    uw:expect(log.use_colors).toBe(false)
    uw:expect(log.include_timestamp).toBe(false)
end)

uw:finish()
reload_logger()
uw:start("object creation (with module name)")

uw:test("passing a string", function()
    local log = Logger "my mod6/my module" ---@type herbert.Logger

    uw:expect(log.mod_name).toBe("my mod6")
    uw:expect(log.module_name).toBe("my module")
    uw:expect(log.level).toBe(Logger.LEVEL.INFO)
    uw:expect(log:get_loggers()).toBeType("table")
    uw:expect(#log:get_loggers()).toBe(1)
    uw:expect(log.file).toBe(nil)
    uw:expect(log.write_to_file).toBe(false)
    uw:expect(log.use_colors).toBe(false)
    uw:expect(log.include_timestamp).toBe(false)


end)

uw:test("passing a table", function()
    local log = Logger{mod_name="my mod7", module_name="my module"} ---@type herbert.Logger

    uw:expect(log.mod_name).toBe("my mod7")
    uw:expect(log.module_name).toBe("my module")
    uw:expect(log.level).toBe(Logger.LEVEL.INFO)
    uw:expect(log:get_loggers()).toBeType("table")
    uw:expect(#log:get_loggers()).toBe(1)
    uw:expect(log.file).toBe(nil)
    uw:expect(log.write_to_file).toBe(false)
    uw:expect(log.use_colors).toBe(false)
    uw:expect(log.include_timestamp).toBe(false)
end)

uw:test("passing a table, but including the module name in mod_name", function()
    local log = Logger{mod_name="my mod8/my module"} ---@type herbert.Logger

    uw:expect(log.mod_name).toBe("my mod8")
    uw:expect(log.module_name).toBe("my module")
    uw:expect(log.level).toBe(Logger.LEVEL.INFO)
    uw:expect(log:get_loggers()).toBeType("table")
    uw:expect(#log:get_loggers()).toBe(1)
    uw:expect(log.file).toBe(nil)
    uw:expect(log.write_to_file).toBe(false)
    uw:expect(log.use_colors).toBe(false)
    uw:expect(log.include_timestamp).toBe(false)
end)

uw:finish()

uw:start("creating a child logger")

uw:test("via make_child", function()
    local parent = Logger.new{mod_name="my mod9", level="DEBUG",include_timestamp=true,use_colors=true,write_to_file=true} ---@type herbert.Logger
    local child = parent:make_child("child module")
    uw:expect(child.mod_name).toBe(parent.mod_name)
    uw:expect(child.module_name).toBe("child module")
    uw:expect(child.level).toBe(parent.level)
    uw:expect(child:get_loggers()).toBeType("table")
    uw:expect(#child:get_loggers()).toBe(2)
    uw:expect(child.write_to_file).toBe(parent.write_to_file)
    uw:expect(child.use_colors).toBe(parent.use_colors)
    uw:expect(child.include_timestamp).toBe(parent.include_timestamp)

    uw:expect(parent:get_loggers()[1]).toBe(parent)
    uw:expect(parent:get_loggers()[2]).toBe(child)
end)

uw:test("via __concat", function()
    local parent = Logger.new{mod_name="my mod10", level="DEBUG",include_timestamp=true,use_colors=true,write_to_file=true} ---@type herbert.Logger
    local child = parent .. ("child module")
    uw:expect(child.mod_name).toBe(parent.mod_name)
    uw:expect(child.module_name).toBe("child module")
    uw:expect(child.level).toBe(parent.level)
    uw:expect(child:get_loggers()).toBeType("table")
    uw:expect(child.write_to_file).toBe(parent.write_to_file)
    uw:expect(child.use_colors).toBe(parent.use_colors)
    uw:expect(child.include_timestamp).toBe(parent.include_timestamp)

    uw:expect(parent:get_loggers()[1]).toBe(parent)
    uw:expect(parent:get_loggers()[2]).toBe(child)

end)

uw:test("via Logger.new", function()
    local parent = Logger.new{mod_name="my mod12", level="DEBUG",include_timestamp=true,use_colors=true,write_to_file=true} ---@type herbert.Logger
    local child = Logger.new{mod_name="my mod12", module_name="child module"}
    uw:expect(child.mod_name).toBe(parent.mod_name)
    uw:expect(child.module_name).toBe("child module")
    uw:expect(child.level).toBe(parent.level)
    uw:expect(child:get_loggers()).toBeType("table")
    uw:expect(#child:get_loggers()).toBe(2)
    uw:expect(child.write_to_file).toBe(parent.write_to_file)
    uw:expect(child.use_colors).toBe(parent.use_colors)
    uw:expect(child.include_timestamp).toBe(parent.include_timestamp)

    uw:expect(parent:get_loggers()[1]).toBe(parent)
    uw:expect(parent:get_loggers()[2]).toBe(child)
end)


uw:finish()

reload_logger()
uw:start("properties of child loggers")

uw:test("set_level", function()
    local parent = Logger.new{mod_name="my mod13", level="DEBUG",include_timestamp=true,use_colors=true,write_to_file=true} ---@type herbert.Logger
    local child1 = parent .. "child1" ---@type herbert.Logger 
    local child2 = parent .. "child2" ---@type herbert.Logger
    local child3 = parent .. "child3" ---@type herbert.Logger

    uw:expect(child1.level).toBe(parent.level)
    uw:expect(child2.level).toBe(parent.level)
    uw:expect(child3.level).toBe(parent.level)

    child1:set_level(Logger.LEVEL.ERROR)

    uw:expect(child1.level).toBe(parent.level)
    uw:expect(child2.level).toBe(parent.level)
    uw:expect(child3.level).toBe(parent.level)

    child2:set_level(Logger.LEVEL.INFO)

    uw:expect(child1.level).toBe(parent.level)
    uw:expect(child2.level).toBe(parent.level)
    uw:expect(child3.level).toBe(parent.level)

    child3:set_level("TRACE")

    uw:expect(child1.level).toBe(parent.level)
    uw:expect(child2.level).toBe(parent.level)
    uw:expect(child3.level).toBe(parent.level)

    parent:set_level("WARN")

    uw:expect(child1.level).toBe(parent.level)
    uw:expect(child2.level).toBe(parent.level)
    uw:expect(child3.level).toBe(parent.level)



end)

uw:test("include_timestamp", function()
    local parent = Logger.new{mod_name="my mod14", level="DEBUG",include_timestamp=true,use_colors=true,write_to_file=true} ---@type herbert.Logger
    local child1 = parent .. "child1" ---@type herbert.Logger 
    local child2 = parent .. "child2" ---@type herbert.Logger
    local child3 = parent .. "child3" ---@type herbert.Logger

    uw:expect(child1.include_timestamp).toBe(parent.include_timestamp)
    uw:expect(child2.include_timestamp).toBe(parent.include_timestamp)
    uw:expect(child3.include_timestamp).toBe(parent.include_timestamp)

    child1:set_include_timestamp(true)

    
    uw:expect(child1.include_timestamp).toBe(parent.include_timestamp)
    uw:expect(child2.include_timestamp).toBe(parent.include_timestamp)
    uw:expect(child3.include_timestamp).toBe(parent.include_timestamp)

    uw:expect(child1.include_timestamp).toBe(parent.include_timestamp)
    uw:expect(child2.include_timestamp).toBe(parent.include_timestamp)
    uw:expect(child3.include_timestamp).toBe(parent.include_timestamp)

    child1:set_include_timestamp(false)

    
    uw:expect(child1.include_timestamp).toBe(parent.include_timestamp)
    uw:expect(child2.include_timestamp).toBe(parent.include_timestamp)
    uw:expect(child3.include_timestamp).toBe(parent.include_timestamp)

    child2:set_include_timestamp(true)

    
    uw:expect(child1.include_timestamp).toBe(parent.include_timestamp)
    uw:expect(child2.include_timestamp).toBe(parent.include_timestamp)
    uw:expect(child3.include_timestamp).toBe(parent.include_timestamp)

    child3:set_include_timestamp(false)

    
    uw:expect(child1.include_timestamp).toBe(parent.include_timestamp)
    uw:expect(child2.include_timestamp).toBe(parent.include_timestamp)
    uw:expect(child3.include_timestamp).toBe(parent.include_timestamp)

    parent:set_include_timestamp(true)

    
    uw:expect(child1.include_timestamp).toBe(parent.include_timestamp)
    uw:expect(child2.include_timestamp).toBe(parent.include_timestamp)
    uw:expect(child3.include_timestamp).toBe(parent.include_timestamp)


end)
uw:finish()

reload_logger()

uw:start("Printing: _make_header")
uw:test("no module name", function()
    local logger = Logger.new{mod_name="my mod", level="DEBUG"} ---@type herbert.Logger
    uw:expect(logger:_make_header("DEBUG")).toBe("my mod: DEBUG")
end)

uw:test("module name", function()
    local logger = Logger.new{mod_name="my mod", module_name="my module", level="DEBUG"} ---@type herbert.Logger
    uw:expect(logger:_make_header("DEBUG")).toBe("my mod (my module): DEBUG")
end)
uw:finish()


reload_logger()

uw:start("Printing: write")

local test_str

uw:mock(_G, "print", function(s) test_str = s end)


uw:test("no module name", function()
    local logger = Logger.new{mod_name="my mod", level="DEBUG"} ---@type herbert.Logger
    logger:debug("this %s a %s %i", "is", "test", 23)
    uw:expect(test_str).toBe("[my mod: DEBUG] this is a test 23")
end)

uw:test("module name", function()
    local logger = Logger.new{mod_name="my mod", module_name="my module", level="DEBUG"} ---@type herbert.Logger
    logger:debug("this %s a %s %i", "is", "test", 23)
    uw:expect(test_str).toBe("[my mod (my module): DEBUG] this is a test 23")
end)

uw:test("module name (again)", function()
    local logger = Logger.new{mod_name="my mod1", module_name="my module", level="INFO"} ---@type herbert.Logger
    -- other stuff will try to print things, just make sure it's not the expected result
    logger:info("this %s a %s %i", "is", "test", 23)
    uw:expect(test_str).toBe("[my mod1 (my module): INFO] this is a test 23")
end)
test_str = nil


uw:test("printing only happens at appropriate log levels", function()
    local logger = Logger.new{mod_name="my mod1", module_name="my module", level="INFO"} ---@type herbert.Logger
    -- other stuff will try to print things, just make sure it's not the expected result
    logger:debug("this %s a %s %i", "is", "test", 23)
    uw:expect(test_str).NOT.toBe("[my mod1 (my module): DEBUG] this is a test 23")
end)
uw:clearMocks()

uw:finish()


reload_logger()

uw:start("Printing: writet")

test_str = nil

uw:mock(_G, "print", function(s) test_str = s end)


uw:test("msg (no module name)", function()
    local logger = Logger.new{mod_name="my mod", level="DEBUG"} ---@type herbert.Logger
    logger:debugt{msg="this %s a %s %i", args={"is","test", 23}}
    uw:expect(test_str).toBe("[my mod: DEBUG] this is a test 23")
end)

uw:test("msg (w/ module name)", function()
    local logger = Logger.new{mod_name="my mod", module_name="my module", level="DEBUG"} ---@type herbert.Logger
    logger:debugt{msg="this %s a %s %i", args={"is","test", 23}}
    uw:expect(test_str).toBe("[my mod (my module): DEBUG] this is a test 23")
end)


uw:test("sep (no module name)", function()
    local logger = Logger.new{mod_name="my mod", level="DEBUG"} ---@type herbert.Logger
    logger:debugt{sep=", ", args={"printing arguments", "second", "third", "now starting associative arguments", a="first_assoc", b="second_assoc"}}
    uw:expect(test_str).toBe("[my mod: DEBUG] printing arguments, second, third, now starting associative arguments, a=first_assoc, b=second_assoc")
end)

uw:test("sep (w/ module name)", function()
    local logger = Logger.new{mod_name="my mod", module_name="my module", level="DEBUG"} ---@type herbert.Logger
    logger:debugt{sep=", ", args={"printing arguments", "second", "third", "now starting associative arguments", a="first_assoc", b="second_assoc"}}
    uw:expect(test_str).toBe("[my mod (my module): DEBUG] printing arguments, second, third, now starting associative arguments, a=first_assoc, b=second_assoc")
end)

test_str = nil


uw:test("printing only happens at appropriate log levels", function()
    local logger = Logger.new{mod_name="my mod1", module_name="my module", level="INFO"} ---@type herbert.Logger
    logger:debugt{sep=", ", args={"printing arguments", "second", "third", "now starting associative arguments", a="first_assoc", b="second_assoc"}}
    -- other stuff will try to print things, just make sure it's not the expected result
    uw:expect(test_str).NOT.toBe("[my mod1 (my module): DEBUG] printing arguments, second, third, now starting associative arguments, a=first_assoc, b=second_assoc")
end)
-- need to do this so results can be printed
uw:clearMocks()

uw:finish()

uw:finish(true)