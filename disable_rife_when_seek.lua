local delay = 3
local timer_restore = nil
local p = {
    last_time_pos = 0,
}
local os_time_start = os.time()

function print_time(...)
    print("+" .. os.time() - os_time_start .. "s", ...)
end

function kill_and_add_timeout(timer,...)
    if (timer ~= nil and timer:is_enabled()) then
        timer:kill()
    end
    return mp.add_timeout(...)
end

-- function restore() --pause后再设置vf的方案导致视频暂停播放长达1.5~2s
--     print_time("restore")
--     p.pause = mp.get_property_native("pause")
--     mp.set_property_bool("pause", true)
--     p.last_time_pos = mp.get_property_native("time-pos") -- pause后会产生一个额外的seek事件
--     mp.set_property("vf", p.vf)
--     mp.osd_message("restore vf, vf=" .. p.vf)
--     mp.observe_property("estimated-vf-fps", "native", on_estimated_vf_fps)
-- end

function restore()
    print_time("restore")
    mp.set_property("vf", p.vf) --导致丢帧1s左右
    mp.osd_message("restore vf, vf=" .. p.vf)
end

function on_seek()
    p.time_pos = mp.get_property_native("time-pos")
    print_time("on_seek", p.time_pos, p.last_time_pos, p.time_pos - p.last_time_pos)
    if (math.abs(p.time_pos - p.last_time_pos) < 0.1) then -- 多半是非人为的
       return
    end
    p.last_time_pos = p.time_pos
    if (timer_restore == nil or (not timer_restore:is_enabled())) then
        p.vf = mp.get_property("vf")
    end
    mp.set_property("vf", "")
    mp.osd_message("temporarily disable vf", delay)
    timer_restore = kill_and_add_timeout(timer_restore, delay, restore)
end

-- function on_estimated_vf_fps(_,value) --使用estimated_vf_fps来判断vf是否准备完毕以避免跳帧
--     print_time("on_estimated_vf_fps",value)
--     if (value == nil) then
--         return
--     end
--     mp.unobserve_property(on_estimated_vf_fps)
--     p.time_pos_of_restore_pause = nil
--     mp.set_property_bool("pause", p.pause)
-- end

-- function on_time_pos(_,value)
--     print_time("on_time_pos",value)
-- end
-- mp.observe_property("time-pos", "native", on_time_pos)

mp.register_event("seek", on_seek)

