local os_time_start = os.time()
local delay = 3
local timer_restore = nil
local p = {
    last_time_pos = 0,
}
local on_wait = false
local vf = "vapoursynth=\"~~/vs/MEMC_RIFE_NV.vpy\""

function print_time(...)
    print("+" .. os.time() - os_time_start .. "s", ...)
end

function Set (t) -- from autoload.lua
    local set = {}
    for _, v in pairs(t) do set[v] = true end
    return set
end

ext_img = Set { -- from autoload.lua with modify
    'avif', 'bmp', 'j2k', 'jp2', 'jpeg', 'jpg', 'jxl', 'png',
    'svg', 'tga', 'tif', 'tiff', 'webp', 'psd'
}

function get_extension(path) -- from autoload.lua
    match = string.match(path, "%.([^%.]+)$" )
    if match == nil then
        return "nomatch"
    else
        return match
    end
end

function kill_timeout(timer)
    if (timer ~= nil and timer:is_enabled()) then
        timer:kill()
    end
end

function kill_and_add_timeout(timer,...)
    kill_timeout(timer)
    return mp.add_timeout(...)
end

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

function restore()
    mp.set_property_native("vf", vf) --导致丢帧1s左右
    on_wait = false
    print_time("rife on")
end

function on_seek()
    p.time_pos = mp.get_property_native("time-pos")
    if (p.time_pos == nil) then return end
    print_time("on_seek", p.time_pos, p.last_time_pos, p.time_pos - p.last_time_pos)
    if (math.abs(p.time_pos - p.last_time_pos) < 0.1) then return end -- 多半是非人为的
    p.last_time_pos = p.time_pos
    mp.set_property("vf", "")
    print_time("rife off")
    on_wait = true
    timer_restore = kill_and_add_timeout(timer_restore, delay, restore)
end

function on_file_loaded()
    ext = get_extension(mp.get_property_native("filename"))
    fps = mp.get_property_native("container-fps")
    width = mp.get_property_native("width")
    if (ext_img[string.lower(ext)] ~= nil or fps < 23 or fps > 30 or width > 2000) then
        kill_timeout(timer_restore)
        on_wait = false
        mp.unregister_event(on_seek)
        mp.set_property("vf", "")
    else
        mp.register_event("seek", on_seek)
        if (not on_wait) then
            mp.set_property("vf", vf)
            print_time("rife on")
        end
    end
end

mp.register_event("start-file", on_start_file)
mp.register_event("file-loaded", on_file_loaded)
