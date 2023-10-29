package.path = package.path .. ";" .. debug.getinfo(1).source:match("@?(.*/)") .. "?.lua"
require 'tool'

-- function on_estimated_vf_fps(_,value) --使用estimated_vf_fps来判断vf是否准备完毕以避免跳帧
    -- print_time("on_estimated_vf_fps",value)
    -- if (value == nil) then
    --     return
    -- end
    -- mp.unobserve_property(on_estimated_vf_fps)
    -- p.time_pos_of_restore_pause = nil
    -- mp.set_property_bool("pause", p.pause)
-- end

-- function restore() --pause后再设置vf的方案导致视频暂停播放长达1.5~2s
--     print_time("restore")
--     p.pause = mp.get_property_native("pause")
--     mp.set_property_bool("pause", true)
--     p.last_time_pos = mp.get_property_native("time-pos") -- pause后会产生一个额外的seek事件
--     mp.set_property("vf", p.vf)
--     mp.osd_message("restore vf, vf=" .. p.vf)
--     mp.observe_property("estimated-vf-fps", "native", on_estimated_vf_fps)
-- end

local vf = "vapoursynth=\"~~/vs/MEMC_RIFE_NV.vpy\""
function restore()
    mp.set_property_native("vf", vf) --导致丢帧1s左右
    on_wait = false
    -- print_time("rife on")
end

local p = {
    last_time_pos = 0,
}
local on_wait = false
local timer = nil
function on_seek()
    p.time_pos = mp.get_property_native("time-pos")
    if (p.time_pos == nil) then return end
    --print_time("on_seek", p.time_pos, p.last_time_pos, p.time_pos - p.last_time_pos)
    if (math.abs(p.time_pos - p.last_time_pos) < 0.1) then return end -- 多半是非人为的
    p.last_time_pos = p.time_pos
    mp.set_property("vf", "")
    --print_time("rife off")
    on_wait = true
    timer = kill_and_add_timeout(timer, 3, restore)
end

function on_file_loaded()
    local fps = mp.get_property_native("container-fps")
    local width = mp.get_property_native("width")
    if (is_img() or fps == nil or fps < 23 or fps > 30 or width == nil or width > 2000) then
        kill_timeout(timer)
        on_wait = false
        mp.unregister_event(on_seek)
        mp.set_property("vf", "")
    else
        mp.register_event("seek", on_seek)
        if (not on_wait) then
            mp.set_property("vf", vf)
            --print_time("rife on")
        end
    end
end

mp.register_event("file-loaded", on_file_loaded)
