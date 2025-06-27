package.path = package.path .. ";" .. debug.getinfo(1).source:match("@?(.*/)") .. "?.lua"
require 'tool'

function on_start_file()
    mp.register_event("playback-restart", on_playback_restart) -- 若在on_file_loaded时才运行，可能收不到消息
end

local last_seek = mp.get_time()
local do_exact_seek = false
local exact_seek_max_delay = 0
function on_WHEEL_UP()
    local now = mp.get_time()
    if (now - last_seek < exact_seek_max_delay) then
        mp.command("seek -2")
    else
        do_exact_seek = true
        mp.command("seek -2 exact")
    end
    last_seek = now
end

function on_WHEEL_DOWN()
    local now = mp.get_time()
    if (now - last_seek < exact_seek_max_delay) then
        mp.command("seek 2")
    else
        do_exact_seek = true
        mp.command("seek 2 exact")
    end
    last_seek = now
end

function on_playback_restart_seek_done()
    if (do_exact_seek) then
        do_exact_seek = false
        local delay = mp.get_time() - last_seek
        if (exact_seek_max_delay < delay) then
            exact_seek_max_delay = delay
        end
    end
end

function on_playback_restart()
    mp.unregister_event(on_playback_restart)
    if (not is_img()) then
        mp.add_forced_key_binding("WHEEL_UP","WHEEL_UP",on_WHEEL_UP)
        mp.add_forced_key_binding("WHEEL_DOWN","WHEEL_DOWN",on_WHEEL_DOWN)
        --mp.add_forced_key_binding("WHEEL_LEFT","WHEEL_LEFT",on_WHEEL_LEFT,{complex=true}) --WHEEL_LEFT与WHEEL_RIGHT无法识别up与down状态，因此无法用来精确控制playlist-prev/playlist-next
        mp.add_forced_key_binding("HOME","HOME",function () mp.command("add volume 2") end,{repeatable=true})
        mp.add_forced_key_binding("END","END",function () mp.command("add volume -2") end,{repeatable=true})
    end
    
end

mp.register_event("start-file", on_start_file)
mp.register_event("playback-restart", on_playback_restart_seek_done)
