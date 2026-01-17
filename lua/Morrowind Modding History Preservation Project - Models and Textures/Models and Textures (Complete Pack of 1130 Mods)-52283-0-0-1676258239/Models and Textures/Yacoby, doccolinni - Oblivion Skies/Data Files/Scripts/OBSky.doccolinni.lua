--DOES: Changes the MW sky to Oblivion sky textures (doccolinni version)
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

	bsa:extract("cloudsclear02.dds", mwTexDir .. "\\tx_sky_clear.dds")
	bsa:extract("cloudscloudy.dds", mwTexDir .. "\\tx_sky_cloudy.dds")
	bsa:extract("cloudsfog.dds", mwTexDir .. "\\tx_sky_foggy.dds")
	bsa:extract("cloudsoblivionstorm_clouds.dds", mwTexDir .. "\\tx_sky_ashstorm.dds")
	bsa:extract("cloudsoblivionstorm_sky.dds", mwTexDir .. "\\tx_sky_blight.dds")
	bsa:extract("cloudsovercast.dds", mwTexDir .. "\\tx_sky_overcast.dds")
	bsa:extract("cloudsrain.dds", mwTexDir .. "\\tx_sky_rainy.dds")
	bsa:extract("cloudssnow.dds", mwTexDir .. "\\tx_bm_sky_snow.dds")
	bsa:extract("cloudssnow.dds", mwTexDir .. "\\tx_bm_sky_blizzard.dds")
	bsa:extract("coudsthunderstorm.dds", mwTexDir .. "\\tx_sky_thunder.dds")
	bsa:extract("cloudsthunderstormlower.dds", mwTexDir .. "\\tx_sky_stormy.dds")




bsa:closeBSA()

print("Finished...")