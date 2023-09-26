local os_time_start = os.time()
local last_pos = 0
local is_mouse_down = false

function print_time(...)
    print("+" .. os.time() - os_time_start .. "s", ...)
end

function on_first_frame(_,value)
    if (value ~= nil) then
        if (is_mouse_down) then
            mp.observe_property("mouse-pos", "native", on_mouse_move)
        end
    end
end

function on_mouse_move(_,mouse)
    playlist_count = mp.get_property_native("playlist-count")
    osd_width = mp.get_property_native("osd-width")
    if (mouse.hover) then
        next_pos = math.floor(playlist_count*mouse.x/osd_width)
        if (last_pos ~= next_pos) then
            mp.unobserve_property(on_mouse_move)
            mp.set_property_number("playlist-pos",next_pos)
            last_pos = next_pos
        end
    end
end

function on_MBTN_LEFT(s)
    if (s.event == "down") then
        is_mouse_down = true
        mp.observe_property("mouse-pos", "native", on_mouse_move)
    else
        is_mouse_down = false
        mp.unobserve_property(on_mouse_move)
    end
end

mp.observe_property("estimated-vf-fps", "native", on_first_frame)
mp.add_forced_key_binding("MBTN_LEFT","MBTN_LEFT",on_MBTN_LEFT,{complex=true})

