local UIUpdater = {
	_pendingUpdates = {},
	_head = nil,
	_tail = nil,
}

function UIUpdater:defer(callback)
	local node = {}
	self:queue(node, callback)
	return node
end

function UIUpdater:queue(node, fn)
	if self._pendingUpdates[node] then
		return
	end

	local entry = { node = node, fn = fn, next = nil, prev = self._tail }
	self._pendingUpdates[node] = entry

	if self._tail then
		self._tail.next = entry
	end

	self._tail = entry

	if self._head == nil then
		self._head = entry
	end
end

function UIUpdater:cancel(node)
	local entry = self._pendingUpdates[node]
	if not entry then
		return
	end

	if entry.prev then
		entry.prev.next = entry.next
	end

	if entry.next then
		entry.next.prev = entry.prev
	end

	self._pendingUpdates[node] = nil
end

-- Should be called onFrame. This prevents updates being off by 1 frame.
function UIUpdater:flush()
	while self._head do
		---@diagnostic disable
		local entry = self._head
		-- Repeatedly reassigning self._head makes this more recoverable from callback errors.
		self._head = entry.next
		-- Removing from pendingUpdates before invoking means that any callbacks calling :cancel()
		-- will return early, making sure no duplicate work happens.
		self._pendingUpdates[entry.node] = nil

		entry.fn(entry.node)
		---@diagnostic enable
	end

	self._tail = nil
end

return UIUpdater
