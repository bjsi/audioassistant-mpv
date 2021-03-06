local ExtractQueueBase = require("queue.extractQueueBase")
local sort = require("reps.reptable.sort")
local UnscheduledExtractRepTable = require("reps.reptable.unscheduledExtracts")
local sounds = require("systems.sounds")
local ext = require("utils.ext")

local LocalExtractQueue = {}
LocalExtractQueue.__index = LocalExtractQueue

setmetatable(LocalExtractQueue, {
    __index = ExtractQueueBase,
    __call = function(cls, ...)
        local self = setmetatable({}, cls)
        self:_init(...)
        return self
    end
})

--- Create a new GlobalTopicQueue.
--- @param oldRep Rep last playing Rep object.
function LocalExtractQueue:_init(oldRep)
    self.sorted = false
    ExtractQueueBase._init(self, "Local Extract Queue", oldRep,
                           UnscheduledExtractRepTable(function(reps) return self:subsetter(oldRep, reps) end)
                         )
end

function LocalExtractQueue:activate()
    if ExtractQueueBase.activate(self) then
        sounds.play("local_extract_queue")
        return true
    end
    return false
end

function LocalExtractQueue:subsetter(oldRep, reps)
    local subset = ext.list_filter(reps, function(r) return r:is_outstanding(false) end)
    local from_topics = (oldRep ~= nil) and (oldRep:type() == "topic")
    local from_items = (oldRep ~= nil) and (oldRep:type() == "item")
    local from_nil = oldRep == nil
    local filter
    
    -- Filtering subset

    if from_topics then

        -- Get all extracts that are children of the current topic
        filter = function (r) return r:is_child_of(oldRep) end
        
    elseif from_items then

        -- Get all extracts where the topic == the item's grandparent
        -- TODO: what if nil
        local parent = ext.first_or_nil(function(r) return r:is_parent_of(oldRep) end, reps)
        filter = function (r)
            return r.row["parent"] == parent.row["parent"]
        end

    elseif from_nil then
        filter = function(r) return r end
    end

    subset = ext.list_filter(subset, filter)

    -- Sorting subset
    self:sort(subset)

    -- Determining first element
    if from_items then
        local pred = function(extract) return oldRep:is_child_of(extract) end
        ext.move_to_first_where(pred, subset)
    end

    return subset, subset[1]
end

function LocalExtractQueue:sort(reps)
    if not self.sorted then
        sort.by_created(reps)
    end
    self.sorted = true
end

return LocalExtractQueue