local class = require("CES/class")

local CES = {
    _VERSION = "0.7",
    _AUTHOR = "Zly - https://twitter.com/zly_u",

    --ENUMS
    TL_CONTINUOUS   = "continuous",
    TL_REPEATING    = "repeating",
    TL_RHYTHM       = "rhythm",
    E_TRIGGER       = "trigger",
    E_REPEAT_UNTIL  = "repeat-until",

    timelineTypes = {
        continuous  = {},
        repeating   = {},
        rhythm      = {}
    },

    easings = {
        --linear interpolation
        lerp = function(a, b, t)
            return a*(1-t) + b*t
        end,
        --reverse linear interpolation
        invLerp = function(a, b, t)
            return (t-a) / (b-a)
        end
    },

    currentTime = 0,

    debug = false,
}

local timelineTypes_mt = {
    __newindex = function(self, key, value)
        error("Can't assign a new timeline type")
    end
}
setmetatable(CES.timelineTypes, timelineTypes_mt)


local timelineBase = {
    name = "",
    type = nil,

    launchTime          = 0,
    currentTime         = 0,
    repeatTime          = 0,
    passedTimeOnPause   = 0,

    isPaused    = false,
    isStopped   = true,


    events = {
        trigger = {},
        repeatUntil = {},
    },

    init = function(self, name, type, duration)
        if CES.debug then
            print(name, type, duration)
        end
        self.name       = name
        self.type       = type      or "continuous"
        self.repeatTime = duration  or (type == "repeating") and error("Timeline duration has been not set for a repeating type") or 0

        CES.timelineTypes[self.type][self.name] = self
    end,


    state = function(self)
        local state =   self.isPaused   and "paused"    or
                        self.isStopped  and "stopped"   or
                        "running"
        return state
    end,

    getCurTime = function(self)
        return self.currentTime
    end,

    isReachedEnd = function(self)
        if self.type == CES.TL_REPEATING then
            return self.currentTime >= self.repeatTime and true or false
        else
            return false
        end
    end,

    newTriggerEvent = function(_self, start, func)
        local event = {
            startTime   = start,
            func        = func,

            isTriggered = false,

            check = function(self, time)
                if not self.isTriggered then
                    if time >= self.startTime then
                        self.func()
                        self.isTriggered = true
                    end
                end
            end
        }

        return event
    end,

    newRepeatingEvent = function(_self, start, duration, func_easing, func)
        local event = {
            startTime   = start,
            duration    = duration or 0,
            func        = func and func or func_easing, --if `func` is declared that means easing function was used to interpolate something


            check = function(self, time, dt)
                if time >= self.startTime and time <= self.startTime+self.duration then
                    if not func then
                        self.func(dt)
                    else
                        self.func(dt, self.easing:calc(time))
                    end
                end
            end
        }

        if func then --if `func` is declared that means easing function was used to interpolate something
            event["easing"] = {
                func        = CES.easings.invLerp,
                start       = start,
                duration    = duration,

                calc = function(self, time)
                    return self.func(self.start, self.start+self.duration, time)
                end
            }
        end

        return event
    end,

    --Overloaded function for all types of events
    setEvent = function(self, start, type_func, duration, func_easing, func)
        local event, event_type
        if type(type_func) == "function" or type_func == "trigger" then
            event = self:newTriggerEvent(start, type_func)
            event_type = "trigger"
        elseif type_func == "repeat-until" or type_func == "ru" then
            event = self:newRepeatingEvent(start, duration, func_easing, func)
            event_type = "repeatUntil"
        else
            error(type_func and "Unrecognized event type: "..type_func or "The fuck why there is nil")
        end

        table.insert(self.events[event_type], event)

        --return event_type, #self.events[event_type] --returns a type and an id of the event if you will need to refer to the particular envent
        return self.events[event_type][#self.events[event_type]] --returns a referense to your event
    end,

    start = function(self)
        if self.isPaused then
            self.launchTime = self.launchTime + self.passedTimeOnPause
            print(self.passedTimeOnPause)
            self.isPaused = false
        end
        if self.isStopped then
            self.launchTime = os.clock()
            self.isStopped = false
        end
        self.passedTimeOnPause = 0
    end,

    stop = function(self)
        self.isStopped  = true
        self.launchTime = 0
        self:restart()
    end,

    pause = function(self)
        self.isPaused = true
    end,

    restart = function(self)
        self:resetAllTrigEvents()
        self.launchTime = os.clock()
    end,

    update = function(self, dt)
        if not self.isStopped then
            local time = math.floor((os.clock() - self.launchTime) * 1000) / 1000
            if not self.isPaused then
                self.currentTime = time
                self:checkEvents(dt)
            else
                self.passedTimeOnPause = time - self.currentTime
            end

            if self.type == "repeating" and self.currentTime >= self.repeatTime then
                self:restart()
            end
        end
    end,

    checkEvents = function(self, dt)
        for _, eventType in pairs(self.events) do
            for _, event in pairs(eventType) do
                event:check(self.currentTime, dt)
            end
        end
    end,

    resetAllTrigEvents = function(self)
        for _, event in pairs(self.events["trigger"]) do
            event.isTriggered = false
        end
    end
}
--local timelineClass = class(class(), timelineBase)
local timelineClass = class(class(), timelineBase)

--TODO:THIS V
local rhythmTimeline = {
    name = "",
    type = nil,

    launchTime          = 0,
    currentTime         = 0,
    repeatTime          = 0,
    passedTimeOnPause   = 0,

    isPaused    = false,
    isStopped   = true,


    --Rhythm
    BPM = 120,
    timeSignature   = "4/4",
    notesPerMeasure = nil,
    noteType        = nil,

    timeBetweenBeats    = 0,
    currentBeat         = 0,
    currentMeasire      = 0,
    currentMeasureBeat  = 0,


    events = {
        trigger = {},
        repeatUntil = {},
    },

    init = function(self, name, type, duration)
        if CES.debug then
            print(name, type, duration)
        end
        self.name       = name
        self.type       = type      or "continuous"
        self.repeatTime = duration  or (type == "repeating") and error("Timeline duration has been not set for a repeating type") or 0

        self.beatsPerMeasure, self.beatType = unpack(self.timeSignature:split("/"))
        self.timeBetweenBeats = (60/self.BPM)*(4/self.noteType)


        CES.timelineTypes[self.type][self.name] = self
    end,


    state = function(self)
        local state =   self.isPaused   and "paused"    or
                        self.isStopped  and "stopped"   or
                        "running"
        return state
    end,

    getCurTime = function(self)
        return self.currentTime
    end,
    getCurBeat = function(self)
        return self.currentBeat
    end,
    getCurMeasure = function(self)
        return self.currentMeasire
    end,
    getCurMeasureBeat = function(self)
        return self.currentMeasureBeat
    end,


    --TODO:Lerp functionality and beat detection
    newTriggerEvent = function(self, start, func)
        local event = {
            startTime   = start,
            func        = func,

            isTriggered = false,

            check = function(self, time, dt)
                if not self.isTriggered then
                    if time >= self.startTime then
                        self.func(dt)
                        self.isTriggered = true
                    end
                end
            end
        }
        return event
    end,

    --TODO:Lerp functionality and beat detection
    newRepeatingEvent = function(self, start, duration, func)
        local event = {
            startTime   = start,
            duration    = duration or 0,
            func        = func,

            check = function(self, time, dt)
                if time >= self.startTime and time <= self.startTime+self.duration then
                    self.func(dt)
                end
            end
        }

        return event
    end,

    --TODO:Lerp functionality and beat detection
    --Overloaded function for all types of events
    setEvent = function(self, start, type_func, duration, func)
        local event, event_type
        if type(type_func) == "function" then
            event = self:newTriggerEvent(start, type_func)
            event_type = "trigger"
        elseif type_func == "repeat-until" or type_func == "ru" then
            event = self:newRepeatingEvent(start, duration, func)
            event_type = "repeatUntil"
        else
            error("Wrong event type: "..type_func)
        end

        table.insert(self.events[event_type], event)

        return event_type, #self.events[event_type] --returns a type and an id of the event if you will need to refer to the particular envent
    end,



    --[[

    ev1: type|startMeasure|startBeat|UntilMeasure|UntilBeat|function(lerp<-(start, end)\..., ...)]

    --]]



    start = function(self)
        if self.isPaused then
            self.launchTime = self.launchTime + self.passedTimeOnPause
            self.isPaused = false
        end
        if self.isStopped then
            self.launchTime = os.clock()
            self.isStopped = false
        end
        self.passedTimeOnPause = 0
    end,

    stop = function(self)
        self.isStopped  = true
        self.launchTime = 0
        self:restart()
    end,

    pause = function(self)
        self.isPaused = true
    end,

    restart = function(self)
        self:resetAllTrigEvents()
        self.launchTime = os.clock()
    end,


    update = function(self, dt)
        if not self.isStopped then
            local time = math.floor((os.clock() - self.launchTime) * 1000) / 1000
            if not self.isPaused then
                self.currentTime = time
                self:checkEvents(dt)
            else
                self.passedTimeOnPause = time - self.currentTime
            end


            --Rhythm
            if self.beatsPerMeasure and self.beatType then
                self.currentBeat        = 1+(self.currentTIme/self.timeBetweenBeats)
                self.currentMeasureBeat = 1+((self.currentTIme/self.timeBetweenBeats)%4)
                self.currentMeasire     = math.floor(1+((self.currentTIme/self.timeBetweenBeats)/self.beatsPerMeasure))
            end

            if self.type == "repeating" and self.currentTime >= self.repeatTime then
                self:restart()
            end
        end
    end,

    checkEvents = function(self, dt)
        for _, eventType in pairs(self.events) do
            for _, event in pairs(eventType) do
                event:check(self.currentTime, dt)
            end
        end
    end,

    resetAllTrigEvents = function(self)
        for _, event in pairs(self.events["trigger"]) do
            event.isTriggered = false
        end
    end
}

function CES:UpdateAll(dt)
    for _, timelineType in pairs(self.timelineTypes) do
        for _, timeline in pairs(timelineType) do
            timeline:update(dt)
        end
    end
end

function CES:ResetAll(resetType)
    for _, timelineType in pairs(self.timelineTypes) do
        for _, timeline in pairs(timelineType) do
            if resetType == "restart" then
                timeline:restart()
            elseif resetType == "stop" then
                timeline:stop()
            end
        end
    end
end


local CES_mt = {
    __call = function(self, name, type, duration)
        return timelineClass(name, type, duration)
    end
}
setmetatable(CES, CES_mt)
return CES