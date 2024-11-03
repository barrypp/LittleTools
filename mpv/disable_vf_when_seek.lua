package.path = package.path .. ";" .. debug.getinfo(1).source:match("@?(.*/)") .. "?.lua"
require 'tool'

local rife = "vapoursynth=\"~~/vs/MEMC_RIFE_NV.vpy\""
local vsr = "d3d11vpp=format=nv12:scale=%d:scaling-mode=nvidia"
local vf = nil
function restore()
    mp.set_property_native("vf", vf) --导致丢帧1s左右
end

local last_time_pos = 0
local timer = nil
function on_seek()
    local time_pos = mp.get_property_native("time-pos")
    if (time_pos == nil) then return end
    if (math.abs(time_pos - last_time_pos) < 0.1) then return end -- 多半是非人为的
    last_time_pos = time_pos
    mp.set_property("vf", "")
    timer = kill_and_add_timeout(timer, 3, restore)
end

function on_file_loaded()
    local fps = mp.get_property_native("container-fps")
    local width = mp.get_property_native("width")
    local primaries = mp.get_property_native("video-params/primaries")
    kill_timeout(timer)
    if (is_img() or fps == nil or fps < 23 or fps > 30 or width == nil or width > 2000) then
        vf = ""
    else
        vf = rife .. "," .. string.format(vsr,math.floor(3840/width))
        if (primaries ~= "bt.2020") then
            vf = vf .. ":nvidia-true-hdr"
        end
    end
    restore()
end

mp.register_event("file-loaded", on_file_loaded)
mp.register_event("seek", on_seek)
