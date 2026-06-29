-- Daggerfall-compatibility-inspired RNG helper.
-- NOTE: The exact original bounded sampling behavior is uncertain.
-- v1 intentionally uses modulo reduction as a conservative compatibility assumption.
--
-- Lua 5.1/OpenMW 0.49/0.50 note:
-- Do not depend on bit32 here. Lua 5.1 does not provide it by default, and
-- direct 32-bit multiply/mod arithmetic can lose precision with doubles.
-- This implementation keeps the LCG exact by operating on 16-bit halves.

local rng = {}

local MOD16 = 0x10000
local MOD32 = 0x100000000

local A_HI = 0x41C6
local A_LO = 0x4E6D
local C = 12345

local function normalizeSeed(seed)
  local normalized = math.floor(seed or 0) % MOD32
  if normalized < 0 then
    normalized = normalized + MOD32
  end
  return normalized
end

local function step32(state)
  local hi = math.floor(state / MOD16)
  local lo = state % MOD16

  local low = (A_LO * lo) + C
  local low16 = low % MOD16
  local carry = math.floor(low / MOD16)

  local high = (A_HI * lo) + (A_LO * hi) + carry
  high = high % MOD16

  return (high * MOD16) + low16
end

function rng.new(seed)
  return {
    seed = normalizeSeed(seed),
    state = normalizeSeed(seed),
  }
end

function rng.fromState(seed, state)
  return {
    seed = normalizeSeed(seed),
    state = normalizeSeed(state),
  }
end

function rng.next15(r)
  r.state = step32(r.state)
  return math.floor(r.state / MOD16) % 0x8000
end

function rng.roll0to10(r)
  return rng.next15(r) % 11
end

function rng.roll6to14(r)
  return (rng.next15(r) % 9) + 6
end

return rng
