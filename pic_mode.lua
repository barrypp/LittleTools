local os_time_start = os.time()

function print_time(...)
    print("+" .. os.time() - os_time_start .. "s", ...)
end


function on_start_file()
    name = mp.get_property_native("filename")
    if (name:match("%.png$") or name:match("%.jpg$")) then
        print_time("pic_mode on")
        mp.set_property_native("pause", true)
        mp.add_forced_key_binding("WHEEL_UP","playlist-prev-file",function () mp.command("playlist-prev") end)
        mp.add_forced_key_binding("WHEEL_DOWN","playlist-next-file",function () mp.command("playlist-next") end)
    elseif (name:match("%.gif$")) then
        print_time("gif_mode on")
        mp.set_property_native("pause", false)
        mp.add_forced_key_binding("WHEEL_UP","seek_1s_prev",function () mp.command("seek -1 exact") end)
        mp.add_forced_key_binding("WHEEL_DOWN","seek_1s_next",function () mp.command("seek 1 exact") end)
    else
        print_time("pic_mode off")
        mp.set_property_native("pause", false)
        mp.remove_key_binding("playlist-prev-file")
        mp.remove_key_binding("playlist-next-file")
        mp.remove_key_binding("seek_1s_next")
        mp.remove_key_binding("seek_1s_prev")
    end
end

mp.register_event("start-file", on_start_file)
