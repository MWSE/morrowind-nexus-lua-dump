--(C) sciloaf aka MatrixS_Master, 2020
--
--You can use, modify and redistribute this file according to MIT license
--
--No guarantee, support or even comments given :)

if (arg[1] == nil or arg[2] == nil or arg[3] == nil) then
    print("Usage: lua gen_romscript.lua <sourcefile> <scriptname> <romslot_name>")
    return
end

f = io.open(arg[1])
if not f then
    print("Unable to open ".. arg[1])
	return
end

n = 0
data = {}

while true do
	data[n] = f:read("*n")
	if data[n] == nil then
		break
	end

	n = n + 1
end

print("Begin ".. arg[2].. '\n')

print("short OnPCDrop")
print("short load")
print("long i")
print("long block")
print("long addr")
print("float tmp\n")

print("if (OnPCDrop == 1)")
print("\tif (GetDistance ".. arg[3].. " <= 2.0)")
print("\t\tset i to 0")
print("\t\tset load to 1")
print("\telse")
print("\t\tset load to 0")
print("\tendif")
print("\tset i to 0")
print("\tset OnPCDrop to 0")
print("endif\n")

print("if (OnActivate == 1)")
print("\tif (load > 1)")
print("\t\treturn")
print("\telse")
print("\t\tset load to 0")
print("\t\tset ROMPROGRESS to 0")
print("\t\tActivate")
print("\tendif")
print("endif\n")

print("if (load == 0)")
print("\treturn")
print("elseif (load == 1)")
print("\tset load to (ROMLOADING + 1)")
print("\treturn")
print("endif\n")

print("if (RAMADDRH >= 0)")
print("\treturn")
print("endif\n")

print("if (i == ".. n.. ")")
print("\tset load to 0")
print("\tset RAMWR to 0")
print("\tset ROMPROGRESS to 1") --to make sure there'll be no rounding errors at the end
--print('\t;MessageBox "ROM copy finished" "OK"')
print("\treturn")
print("endif\n")

print("set tmp to (i)") --convert to float
print("set ROMPROGRESS to (tmp / ".. n.. ".0)")
print("set block to (i / 1024)")
print("set addr to (block * 1024)")
print("set addr to (i - addr)\n")

for i = 0,n-1 do
	if i == 0 then
		print("if (i == 0)")
	else
		print("elseif (i == ".. i.. ")")
	end

	print("\tset RAMDATA to ".. data[i])
end

print("endif\n")

print("set i to (i + 1)\n")

print("set RAMWR to 1")
print("set RAMADDRL to (addr)")
print("set RAMADDRH to (block)\n")

print("End")
