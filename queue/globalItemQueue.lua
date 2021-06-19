local ItemQueueBase = require("queue.itemQueueBase")
local sounds = require("systems.sounds")

local GlobalItemQueue = {}
GlobalItemQueue.__index = GlobalItemQueue

setmetatable(GlobalItemQueue, {
    __index = ItemQueueBase,
    __call = function(cls, ...)
        local self = setmetatable({}, cls)
        self:_init(...)
        return self
    end
})

--- Create a new GlobalTopicQueue.
--- @param oldRep Rep last playing Rep object.
function GlobalItemQueue:_init(oldRep)
    ItemQueueBase._init(self, "Global Item Queue", oldRep,
                         function(reps) return self:subsetter(reps) end)
end

function GlobalItemQueue:activate()
    self:loadRep(self.reptable:current_scheduled(), self.oldRep)
    sounds.play("global_item_queue")
end

function GlobalItemQueue:subsetter(reps)
    local subset = {}
    for i, v in ipairs(reps) do
        subset[i] = v
    end
    return subset
end

return GlobalItemQueue