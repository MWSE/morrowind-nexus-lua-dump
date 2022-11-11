local this = {}
this.__index = this

local defaultSeed = 1337

local dot_product = {
    [0x0] = function(x, y, z) return x + y end,
    [0x1] = function(x, y, z) return -x + y end,
    [0x2] = function(x, y, z) return x - y end,
    [0x3] = function(x, y, z) return -x - y end,
    [0x4] = function(x, y, z) return x + z end,
    [0x5] = function(x, y, z) return -x + z end,
    [0x6] = function(x, y, z) return x - z end,
    [0x7] = function(x, y, z) return -x - z end,
    [0x8] = function(x, y, z) return y + z end,
    [0x9] = function(x, y, z) return -y + z end,
    [0xA] = function(x, y, z) return y - z end,
    [0xB] = function(x, y, z) return -y - z end,
    [0xC] = function(x, y, z) return y + x end,
    [0xD] = function(x, y, z) return -y + z end,
    [0xE] = function(x, y, z) return y - x end,
    [0xF] = function(x, y, z) return -y - z end,
}

local function grad(hash, x, y, z)
    return dot_product[hash % 0x10](x, y, z)
end

local function fade(t)
    return t * t * t * (t * (t * 6 - 15) + 10)
end

local function lerp(t, a, b)
    return a + t * (b - a)
end

local function generatePermutation(seed)
    math.randomseed(seed)

    local permutation = { 0 }

    for i = 1, 255 do
        table.insert(permutation, math.random(1, #permutation + 1), i)
    end

    local p = {}

    for i = 0, 255 do
        p[i] = permutation[i + 1]
        p[i + 256] = permutation[i + 1]
    end

    return p
end

function this.noise(self, x, y, z)
    y = y or 0
    z = z or 0

    local xi = math.floor(x) % 0x100
    local yi = math.floor(y) % 0x100
    local zi = math.floor(z) % 0x100

    x = x - math.floor(x)
    y = y - math.floor(y)
    z = z - math.floor(z)

    local u = fade(x)
    local v = fade(y)
    local w = fade(z)

    local A, AA, AB, AAA, ABA, AAB, ABB, B, BA, BB, BAA, BBA, BAB, BBB
    A   = self.p[xi] + yi
    AA  = self.p[A] + zi
    AB  = self.p[A + 1] + zi
    AAA = self.p[AA]
    ABA = self.p[AB]
    AAB = self.p[AA + 1]
    ABB = self.p[AB + 1]

    B   = self.p[xi + 1] + yi
    BA  = self.p[B] + zi
    BB  = self.p[B + 1] + zi
    BAA = self.p[BA]
    BBA = self.p[BB]
    BAB = self.p[BA + 1]
    BBB = self.p[BB + 1]

    return lerp(w,
        lerp(v,
            lerp(u,
                grad(AAA, x, y, z),
                grad(BAA, x - 1, y, z)
            ),
            lerp(u,
                grad(ABA, x, y - 1, z),
                grad(BBA, x - 1, y - 1, z)
            )
        ),
        lerp(v,
            lerp(u,
                grad(AAB, x, y, z - 1), grad(BAB, x - 1, y, z - 1)
            ),
            lerp(u,
                grad(ABB, x, y - 1, z - 1), grad(BBB, x - 1, y - 1, z - 1)
            )
        )
    )
end

setmetatable(this, {
    __call = function(self, seed)
        seed = seed or defaultSeed
        return setmetatable({
            seed = seed,
            p = generatePermutation(seed),
        }, self)
    end,
})

return this
