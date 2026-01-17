--DOES: Changes the MW sky to Oblivion sky textures (Vality7 version)
--BY: Yacoby
--CONTACT: Yacoby on Offical ES Forums
--SCRIPT VER: 0.1


--If I used functions that didn't work in some older version, I would check the version.
--progVer = getProgramVer()


--Get the paths from the registry.
print("Getting paths...")
MWPath = getMWPath()
OBPath = getOBPath()

--Check we are all good.
if MWPath == nil then
	print("Cannot find Morrowind's install location. You must have Morrowind istalled")
	return 0
end

if OBPath == nil then
	print("Cannot find Oblivion's install location. You must have Oblivion istalled")
	return 0
end


--set texture paths.
obTexBSA = OBPath .. "Data\\Oblivion - Textures - Compressed.bsa"
mwTexDir = MWPath .. "Data Files\\Textures"

print("Opening BSA...")

--open the BSA
bsa = TES4BSAFile(obTexBSA)

	print("Extracting Files...")

	--extract the files.
	bsa:extract("cloudsoblivionstorm_clouds.dds", mwTexDir .. "\\Tx_Sky_Ashstorm.dds")
	bsa:extract("oblivion_clouds01.dds", mwTexDir .. "\\Tx_Sky_Blight.dds")
	bsa:extract("cloudsclear02.dds", mwTexDir .. "\\Tx_Sky_Clear.dds")
	bsa:extract("cloudsclear.dds", mwTexDir .. "\\Tx_Sky_Cloudy.dds")
	bsa:extract("cloudsfog.dds", mwTexDir .. "\\Tx_Sky_Foggy.dds")
	bsa:extract("cloudsovercast.dds", mwTexDir .. "\\Tx_Sky_Overcast.dds")
	bsa:extract("cloudsrain.dds", mwTexDir .. "\\Tx_Sky_Rainy.dds")

bsa:closeBSA()

print("Finished...")