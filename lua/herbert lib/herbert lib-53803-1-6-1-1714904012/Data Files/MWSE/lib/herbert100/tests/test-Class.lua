local uw = require("unitwind").new{
    enabled = true,
    --- ... other settings ...
    highlight=false
}
local Class = require("herbert100.Class")

local function reload_class()
    Class = dofile("herbert100.Class")    
end
local function expect(thing,tobe)
    uw:expect(thing).toBe(tobe)
end
uw:start("test fields")

uw:test("default values", function()
    local cls = Class.new{
        name = "test class",
        fields = {
            {"f1", default=10},
            {"f2", default="apple"},
            {"f3", default="pineapple"},
        },
    } ---@type herbert.Class
    
    local obj1 = cls{f1=15, f2=20}
    uw:expect(obj1.f1).toBe(15)
    uw:expect(obj1.f2).toBe(20)
    uw:expect(obj1.f3).toBe("pineapple")

    local obj2 = cls()
    uw:expect(obj2.f1).toBe(10)
    uw:expect(obj2.f2).toBe("apple")
    uw:expect(obj2.f3).toBe("pineapple")

end)

uw:test("tostring", function()
     ---@type herbert.Class
    local cls2 = Class.new{
        name = "test class2",
        fields = {
            {"f1", default=10, tostring = function (x) return 1/x end},
            {"f2", default="apple", tostring=false},
            {"f3", default="pineapple", tostring=true},
            {"f4", default={10,11,12}, tostring=require("inspect")},
            {"f5", default={name="two",value="20"}, tostring=function (v) return v.name end},
            {"f6", }
        },
    }
    print(cls2{f6="hello world"})
    local obj1 = cls2{f1=15, f2=20}
    uw:expect(tostring(obj1)).toBe(('test_class2(f1=' .. 1/15 .. ', f3="pineapple", f4={ 10, 11, 12 }, f5=two, f6=nil)'))
    uw:expect(obj1.f1).toBe(15)
    uw:expect(obj1.f2).toBe(20)
    uw:expect(obj1.f3).toBe("pineapple")

    local obj2 = cls2()
    uw:expect(obj2.f1).toBe(10)
    uw:expect(obj2.f2).toBe("apple")
    uw:expect(obj2.f3).toBe("pineapple")

end)

uw:test("tostring (inheritance)", function()
    ---@type herbert.Class
   local cls3 = Class.new{
       name = "test class3",
       fields = {
           {"f1", default=10, tostring = function (x) return 1/x end},
           {"f2", default="apple", tostring=false},
           {"f3", default="pineapple", tostring=true},
           {"f4", default={10,11,12}, tostring=require("inspect")},
           {"f5", default={name="two",value="20"}, tostring=function (v) return v.name end},
           {"f6", }
       },
   }
   local child3_1 = Class.new{name="child3_1", parents={cls3}, 
        fields ={
            {"g1", },
            {"f1", default=25,},
            {"f2", },
            {"f3", tostring=function (v) return v .. " child" end},
            {"f4", tostring=false},
        }
    }
   print(child3_1{f6="hello world"})
   local obj311 = child3_1{f2=20,g1=100}
   uw:expect(tostring(obj311)).toBe(('child3_1(g1=100, f1=' .. 1/25 .. ', f3=pineapple child, f5=two, f6=nil)'))
   uw:expect(obj311.f1).toBe(25)
   uw:expect(obj311.f2).toBe(20)
   uw:expect(obj311.f3).toBe("pineapple")


   local obj31 = cls3{f1=15, f2=20}
   print(obj31)
   uw:expect(tostring(obj31)).toBe(('test_class3(f1=' .. 1/15 .. ', f3="pineapple", f4={ 10, 11, 12 }, f5=two, f6=nil)'))
   uw:expect(obj31.f1).toBe(15)
   uw:expect(obj31.f2).toBe(20)
   uw:expect(obj31.f3).toBe("pineapple")

end)

uw:test("eq", function()
    ---@type herbert.Class
    local cls4 = Class.new{
        name="test class4",
        fields = {
            {"year", eq=true,default=1900},
            {"id", eq=true,default="001"},
        },
    } 
    local obj1, obj2 = cls4{year=2015,id="B2"}, cls4{year=2016,id="B3"}
    local obj3 = cls4{year=2015, id="B2"}
    expect(obj1 == obj2,false)
    expect(obj1 == obj3, true)
    expect(obj2 == obj3, false)

end)

uw:test("eq doesnt run when nothing asks for it", function()
    ---@type herbert.Class
    local cls4 = Class.new{
        name="test class4",
        fields = {
            {"year", default=1900},
            {"id", default="001"},
        },
    } 
    local obj1, obj2 = cls4{year=2015,id="B2"}, cls4{year=2016,id="B3"}
    local obj3 = cls4{year=2015, id="B2"}
    expect(obj1 == obj2,false)
    expect(obj1 == obj3, false)
    expect(obj2 == obj3, false)

end)


uw:test("eq functions", function()
    ---@type herbert.Class
    local cls4 = Class.new{
        name="test class4",
        fields = {
            {"year", default=1900, eq=function (v) return v % 100 end},
            {"id", default="001", eq = function(v) return #v end},
        },
    } 
    local obj1 = cls4{year=2015,id="B2"}
    local obj2 = cls4{year=2016,id="B3"}
    expect(obj1 == obj2,false)
    
    
    local obj3 = cls4{year=2015, id="B3"}
    expect(obj1 == obj3, true)
    expect(obj2 == obj3, false)

    
    local obj4 = cls4{year=3015,id="z2"}
    expect(obj1 == obj4,true)
    expect(obj2 == obj4,false)
    expect(obj3 == obj4,true)

    local obj5 = cls4{year=4015, id="123"}
    expect(obj1 == obj5,false)
    expect(obj2 == obj5,false)
    expect(obj3 == obj5,false)
    expect(obj4 == obj5,false)
    
end)

uw:test("eq inheritence", function()
    ---@type herbert.Class
    local cls4 = Class.new{
        name="test class4",
        fields = {
            {"year", default=1900, eq=function (v) return v % 100 end},
            {"id", default="001", eq = function(v) return #v end},
        },
    }
    local obj1 = cls4{year=2015,id="B2"}
    local obj2 = cls4{year=2016,id="B3"}
    expect(obj1 == obj2,false)
    
    
    local obj3 = cls4{year=2015, id="B3"}
    expect(obj1 == obj3, true)
    expect(obj2 == obj3, false)

    
    local obj4 = cls4{year=3015,id="z2"}
    expect(obj1 == obj4,true)
    expect(obj2 == obj4,false)
    expect(obj3 == obj4,true)

    local obj5 = cls4{year=4015, id="123"}
    expect(obj1 == obj5,false)
    expect(obj2 == obj5,false)
    expect(obj3 == obj5,false)
    expect(obj4 == obj5,false)
    
end)




local Student = Class.new{name="Student", new_obj_func="no_obj_data_table",
    init=function (self, ...) self.name, self.id = ... end,
    {"id",converter=tonumber, comp=true },
    {"name", comp=true,},
}
local alice10,bob11,charlie12,dan11,penelope9
local sf = string.format
alice10 = Student("alice", 10)
bob11 = Student("bob", 11)
charlie12 = Student("charlie", 12)
dan11 = Student("dan", 11)
penelope9 = Student("penelope", 9)

local function test_students(s1,s2)
    print(sf("%s < %s ? %s", s1, s2, s1 < s2))
end
local function test_students_le(s1,s2)
    print(sf("%s <= %s ? %s", s1, s2, s1 <= s2))
end

print("---------")

test_students(alice10,penelope9)
test_students(penelope9,alice10)
print("---------")

test_students_le(alice10,penelope9)
test_students_le(penelope9, penelope9)
test_students_le(penelope9,alice10)




print(sf("%s < %s ? %s", bob11, dan11, bob11 < dan11))
local students = {alice10,bob11,charlie12,dan11,penelope9}
table.sort(students)
for i,s in ipairs(students) do
    print(sf("%i: %s",i,s))
end
uw:finish()
uw:finish(true)