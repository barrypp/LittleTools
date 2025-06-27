package.path = package.path .. ";" .. debug.getinfo(1).source:match("@?(.*/)") .. "?.lua"
require 'tool'

local rife = "vapoursynth=\"~~/vs/MEMC_RIFE_NV.vpy\""
local vf_f = "d3d11vpp=format=nv12:scale=%f:scaling-mode=nvidia"
local vf = ""
local af_f = "sofalizer=lfegain=15:sofa=\"" .. mp.command_native({"expand-path", "~~/sofalizer/ClubFritz4.sofa"}) .. "\",volume=volume=%d"
local af = ""
local volume_gain = 0

local is_seek = false
function restore()
    mp.set_property("vf", vf) --导致丢帧1s左右
    mp.set_property_native("volume-gain", 0)
    mp.set_property("af", af)
    is_seek = false
end

local last_time_pos = 0
local timer = nil
function on_seek()
    local time_pos = mp.get_property_native("time-pos")
    if (time_pos == nil) then return end
    if (math.abs(time_pos - last_time_pos) < 0.1) then return end -- 多半是非人为的
    last_time_pos = time_pos
    is_seek = true
    mp.set_property("vf", "")
    mp.set_property("af", "")
    mp.set_property_native("volume-gain", volume_gain)
    timer = kill_and_add_timeout(timer, 3, restore)
end
mp.register_event("seek", on_seek)

function on_playback_restart()
    mp.unregister_event(on_playback_restart)
    --
    local fps = mp.get_property_native("container-fps")
    local width = mp.get_property_native("width")
    local height = mp.get_property_native("height")
    local primaries = mp.get_property_native("video-params/primaries")
    local channel = mp.get_property_native("audio-params/channel-count")
    vf = ""
    if (not is_img() and fps ~= nil and fps >= 23 and fps <= 30) then
        vf = rife
    end
    if (not is_img() and width ~= nil and width <= 2000) then
        if (vf ~= '') then
            vf = vf .. ","
        end
        vf = vf .. string.format(vf_f,math.min(2160/height,3840/width))
        if (primaries ~= "bt.2020") then
            vf = vf .. ":nvidia-true-hdr"
        end
    end
    if (channel == nil) then
        volume_gain = 0
        af = ""
    else
        if (channel >= 8) then
            volume_gain = 2
            af = string.format(af_f,8)
        elseif (channel >= 6) then
            volume_gain = 9
            af = string.format(af_f,9)
        end
    end
    if (not is_seek) then
        restore()
    end
end

function on_start_file()
    mp.register_event("playback-restart", on_playback_restart)
end
mp.register_event("start-file", on_start_file)