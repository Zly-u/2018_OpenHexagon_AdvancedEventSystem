local CES = require("CES")

CES.debug = true

local timeline1 = CES.newTimeline("test1", CES.TL_CONTINUOUS)
local timeline2 = CES.newTimeline("test2", CES.TL_REPEATING, 2)
--[[
print("===========================")
for i, v in pairs(timeline1) do
    print(i, v)
end
print("------------------------")
for i, v in pairs(timeline2) do
    print(i, v)
end
print("===========")
--]]
--
--[[
for nameType, timelineType in pairs(CES.timelineTypes) do
    print(nameType)
    for name, timeline in pairs(timelineType) do
        print(name, timeline)
    end
end
--]]

--tablePrint(timeline1)

---[[
timeline1:setEvent{
    type = CES.E_TRIGGER,

    start = 1,
    func = function(self)
        print("a")
    end,
}:setEvent{
    type = CES.E_TRIGGER,

    start = 2,
    func = function(self)
        print("b")
    end,
}:setEvent{
    type = CES.E_TRIGGER,

    start = 3,
    func = function(self)
        print("c")
        self:restart()
    end,
}

--[[
local function osDotClock() return 10 end
local function timerCalc(self) return self.timeFunction() end
timeline1:setTimeGetFunction(osDotClock):setTimeCalculationFunction(timerCalc):start()
--]]
--]]

---[[start, type_func, duration, func_easing, func CES.easings.invLerp()
---[[
timeline2:setEvent{
    type = CES.E_REPEAT_UNTIL,
    start = 0,
    duration = 1,
    easing = false,
    func = function(self, dt, evaluation)
        print("1:", 20 * evaluation)
    end
}:setEvent{
    type = CES.E_REPEAT_UNTIL,
    start = 1,
    duration = 1,
    easing = false,
    func = function(self, dt, evaluation)
        print("2:", 20 * evaluation)
    end
}
--]]

function love.load()
end

function love.update(dt)
    timeline1:update(dt)
    timeline2:update(dt)
    --print(timeline2:getCurrentTime())
    if timeline2:isEnded() then
        print("================================")
        --timeline2:stop()
    end
    ---[[
    --]]
    --print(timeline1:getCurrentTime())
end

function love.draw()

end

function love.keypressed(key)
    if key == 'e' then
        if timeline1:state() == "running" then
            timeline1:pause()
        else
            timeline1:start()
        end

    elseif key == 'r' then
        timeline1:restart()
    elseif key == 's' then
        timeline1:stop()
    elseif key == 'q' then
        --timeline1:start()
        timeline2:start()
    end
end





















































