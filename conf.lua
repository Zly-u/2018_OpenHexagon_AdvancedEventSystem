function love.conf(t)
    t.window.title  = "CES";
    t.console       = true;
    t.version       = "11.3"

    ---[[
    t.window.width     = 240;
    t.window.height    = 135;
    --]]
    t.window.resizable = false;
    t.window.icon = nil;
    t.window.fullscreen = false;
    t.window.vsync = false;
    t.window.msaa = 0;
end