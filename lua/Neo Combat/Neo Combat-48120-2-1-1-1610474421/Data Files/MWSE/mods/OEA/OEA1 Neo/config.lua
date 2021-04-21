local defaultConfig ={
    attackKey = {
	keyCode = tes3.scanCode.k
    },
    attackKey2 = {
	keyCode = tes3.scanCode.b
    },
    attackKey3 = {
        keyCode = tes3.scanCode.o
    },
    msgkey =
	true
}
local config = mwse.loadConfig("Neo_Combat", defaultConfig)
return config