local os_time_start = os.time()
local last_pos = 0
local next_pos_frac = -1
local is_mouse_down = false
local is_walk = false

function print_time(...)
    print("+" .. os.time() - os_time_start .. "s", ...)
end

function on_first_frame(_,value)
    if (value == nil) then return end
    mp.unobserve_property(on_first_frame)
    if (is_mouse_down) then
        mp.observe_property("mouse-pos", "native", on_mouse_move)
    end
end

function on_start_file()
    mp.observe_property("estimated-vf-fps", "native", on_first_frame)
end

function on_file_loaded()
    if (next_pos_frac ~= -1) then
        mp.set_property_number("percent-pos",next_pos_frac*100)
        next_pos_frac = -1
    end
end

function on_fullscreen(_,value)
    if (not value) then
        mp.unobserve_property(on_mouse_move)
    end
end

function on_mouse_move(_,mouse)
    playlist_count = mp.get_property_native("playlist-count")
    osd_width = mp.get_property_native("osd-width")
    if (mouse.hover) then
        x = playlist_count*mouse.x/osd_width
        next_pos = math.floor(x)
        next_pos_frac = x - next_pos
        if (last_pos ~= next_pos) then
            mp.unobserve_property(on_mouse_move)
            mp.set_property_number("playlist-pos",next_pos)
            last_pos = next_pos
        else
            mp.set_property_number("percent-pos",next_pos_frac*100)
        end
    end
end

function on_MBTN_LEFT(s)
    if (s.event == "down" and mp.get_property_native("fullscreen")) then
        is_mouse_down = true
        mp.observe_property("mouse-pos", "native", on_mouse_move)
    else
        is_mouse_down = false
        mp.unobserve_property(on_mouse_move)
    end
end

mp.register_event("start-file", on_start_file)
mp.register_event("file-loaded", on_file_loaded)
mp.observe_property("fullscreen", "native", on_fullscreen)
mp.add_forced_key_binding("MBTN_LEFT","MBTN_LEFT",on_MBTN_LEFT,{complex=true})
