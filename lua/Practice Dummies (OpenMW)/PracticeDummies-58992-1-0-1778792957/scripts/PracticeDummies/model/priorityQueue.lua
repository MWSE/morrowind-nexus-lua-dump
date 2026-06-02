---@class PriorityQueue
---@field private _heap number[]
---@field private _size integer
local PriorityQueue = {}
PriorityQueue.__index = PriorityQueue

---@return PriorityQueue
function PriorityQueue.new()
    return setmetatable({ _heap = {}, _size = 0 }, PriorityQueue)
end

---@param heap number[]
---@param i integer
---@param j integer
local function swap(heap, i, j)
    heap[i], heap[j] = heap[j], heap[i]
end

---@param i integer
---@return integer
local function parentOf(i) return math.floor(i / 2) end

---@param i integer
---@return integer
local function leftOf(i) return i * 2 end

---@param i integer
---@return integer
local function rightOf(i) return i * 2 + 1 end

---@private
---@param i integer
function PriorityQueue:_bubbleUp(i)
    while i > 1 do
        local p = parentOf(i)
        if self._heap[p] <= self._heap[i] then break end
        swap(self._heap, p, i)
        i = p
    end
end

---@private
---@param i integer
function PriorityQueue:_sinkDown(i)
    while true do
        local smallest = i
        local l, r = leftOf(i), rightOf(i)

        if l <= self._size and self._heap[l] < self._heap[smallest] then
            smallest = l
        end
        if r <= self._size and self._heap[r] < self._heap[smallest] then
            smallest = r
        end

        if smallest == i then break end
        swap(self._heap, i, smallest)
        i = smallest
    end
end

---Pushes a timestamp onto the queue.
---@param timestamp number
function PriorityQueue:push(timestamp)
    self._size = self._size + 1
    self._heap[self._size] = timestamp
    self:_bubbleUp(self._size)
end

---Removes and returns the smallest timestamp, or nil if empty.
---@return number?
function PriorityQueue:pop()
    if self._size == 0 then return nil end

    local top = self._heap[1]
    self._heap[1] = self._heap[self._size]
    self._heap[self._size] = nil
    self._size = self._size - 1

    if self._size > 0 then
        self:_sinkDown(1)
    end

    return top
end

---Returns the smallest timestamp without removing it, or nil if empty.
---@return number?
function PriorityQueue:peek()
    return self._heap[1]
end

---@return boolean
function PriorityQueue:isEmpty()
    return self._size == 0
end

---@return integer
function PriorityQueue:size()
    return self._size
end

return PriorityQueue
