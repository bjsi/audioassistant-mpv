local log = require("utils.log")
local mpu = require("mp.utils")
local ext = require("utils.ext")
local fs = require("systems.fs")

local EDL = {}
EDL.__index = EDL

function EDL.new(outputPath)
    local self = setmetatable({}, EDL)
    self.outputPath = outputPath
    self.header = "# mpv EDL v0\n"
    return self
end

function EDL:open(mode)
    local handle = io.open(self.outputPath, mode)
    if handle == nil then
        log.err("Failed to open EDL file: " .. self.outputPath)
        return nil
    end
    return handle
end

function EDL:pre_cloze(parentPath, parentStart, clozeStart)
    local _, fname = mpu.split_path(parentPath)
    local preClozeLength = clozeStart - parentStart
    return table.concat(
        {
            fname,
            parentStart,
            preClozeLength
        }, ",")
end

function EDL:cloze(clozeEnd, clozeStart)
    local _, fname = mpu.split_path(fs.sine)
    local clozeLength = clozeEnd - clozeStart
    return table.concat(
        {
            fname,
            0,
            clozeLength
        }, ",")
end

function EDL:post_cloze(parentPath, clozeEnd, parentEnd)
    local _, fname = mpu.split_path(parentPath)
    local postClozeLength = parentEnd - clozeEnd
    return table.concat(
        {
            fname,
            clozeEnd,
            postClozeLength
        }, ",")
end

function EDL:write(parentPath, parentStart, parentEnd, clozeStart, clozeEnd, media)
    local handle = self:open("w")
    if handle == nil then
        log.err("Failed to open EDL file for writing.")
        return false
    end

    handle:write(self.header)
    handle:write(self:pre_cloze(parentPath, parentStart, clozeStart) .. "\n")
    handle:write(self:cloze(clozeEnd, clozeStart) .. "\n")
    handle:write(self:post_cloze(parentPath, clozeEnd, parentEnd) .. "\n")
    if media then
        handle:write("!new_stream\n")
        handle:write(media .. "\n")
    end

    handle:close()

    log.debug("Successfully wrote EDL file: " .. self.outputPath)
    return true
end

function EDL:read()
    local handle = self:open("r")
    if handle == nil then 
        log.err("Failed to open EDL file: " .. self.outputPath)
        return
    end

    local content = handle:read("*all")
    handle:close()

    local match = content:gmatch("([^\n]*)\n?")
    if not (match() == "# mpv EDL v0") then
        log.err("Invalid EDL file header.")
        return nil
    end

    local preCloze = self:parse_line(match())
    local cloze = self:parse_line(match())
    local postCloze = self:parse_line(match())
    match() -- !new_stream header
    local media = match()

    local function pred(arr) return arr == nil or #arr ~= 3 end
    if ext.list_any(pred, {preCloze, cloze, postCloze}) then
        log.err("Invalid EDL data.")
        return nil
    end

    local parentPath = preCloze[1]
    local parentStart = tonumber(preCloze[2])

    local preClozeLength = tonumber(preCloze[3])
    local clozeStart = parentStart + preClozeLength

    local clozeLength = tonumber(cloze[3])
    local clozeEnd = clozeStart + clozeLength

    local postClozeLength = tonumber(postCloze[3])
    local parentEnd = clozeEnd + postClozeLength

    log.debug("Successfully parsed EDL file: " .. self.outputPath)
    return parentPath, parentStart, parentEnd, clozeStart, clozeEnd, media
end

function EDL:adjust_cloze(postpone, start)
    local adj = 0.02
    local advance = not postpone
    local stop = not start

    local parentPath, parentStart, parentEnd, clozeStart, clozeEnd, media = self:read()
    if advance and start then
        clozeStart = clozeStart - adj
    elseif postpone and start then
        clozeStart = clozeStart + adj
    elseif advance and stop then
        clozeEnd = clozeEnd - adj
    elseif postpone and stop then
        clozeEnd = clozeEnd + adj
    end

    -- TODO: validate!!!

    local succ = self:write(parentPath, parentStart, parentEnd, clozeStart, clozeEnd, media)
    return succ and clozeStart - parentStart, clozeEnd - parentStart or nil, nil
end

function EDL:parse_line(line)
    local ret = {}
    for v in string.gmatch(line, "[^,]*") do
        if not ext.empty(v) then
            ret[#ret+1] = v
        end
    end
    return ret
end

return EDL
