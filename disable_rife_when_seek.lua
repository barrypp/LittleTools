local delay = 2
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

function restore()
    print_time("restore")
    mp.set_property("vf", p.vf)
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
    mp.osd_message("temporarily disable vf")
    timer_restore = kill_and_add_timeout(timer_restore, delay, restore)
end

mp.register_event("seek", on_seek)
