local class = require("CES/class")

local CES = {
_VERSION = "0.7",
_AUTHOR = "Zly - https://twitter.com/zly_u",

--TimeLine ENUMS
TL_CONTINUOUS   = "continuous",
TL_REPEATING    = "repeating",
TL_RHYTHM       = "rhythm",
--Event ENUMS
E_TRIGGER       = "trigger",
E_REPEAT_UNTIL  = "repeatUntil",

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

function CES.newTimeline(name, _type, duration)
local timelineBase = {
name = "",
type = nil,

timeFunction = os.clock,
timeCalculation = function(self)
return math.floor((self.timeFunction() - self.launchTime) * 1000) / 1000
end,

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


init = function(self, name, type, duration) --is called through class function
if CES.debug then
print(name, type, duration)
end

self.name       = name
self.type       = type      or CES.TL_CONTINUOUS
self.repeatTime = duration  or (type == CES.TL_REPEATING) and error("Timeline duration has been not set for a repeating type") or 0

CES.timelineTypes[self.type][self.name] = self
end,

isEnded = function(self)
return (self.type == CES.TL_REPEATING) and (self.currentTime >= self.repeatTime)
end,

isLastEventTriggered = function(self)
return self.events.trigger[#self.events.trigger].isTriggered
end,

--[[============]]--
--[[===EVENTS===]]--
newTriggerEvent = function(tl_self, start, func)
local event = {
startTime   = start,
func        = func,

isTriggered = false,

check = function(self, time)
if self.isTriggered then return end

if time >= self.startTime then
self.isTriggered = true
self.func(tl_self)
end
end,
}
return event
end,

--TODO: redo Easing init through args
newRepeatingEvent = function(_self, args)
assert(type(args.easing) == "boolean", "easing field should be a bool type.")

local event = {
startTime   = args.start,
duration    = args.duration or 0,
func        = args.func, --if `func` is declared that means easing function was used to interpolate something
easing      = args.easing and {
func        = CES.easings.invLerp,
start       = args.start,
duration    = duration,

--TODO: fix this execution on args.easing being a false
evaluate = function(self, time)
return self.func(self.start, self.start+self.duration, time)
end
} or {
evaluate = function() end
},


check = function(self, time, dt)
if time >= self.startTime and time <= self.startTime+self.duration then
self.func(self, self, dt, self.easing:evaluate(time))
end
end
}

local mt = {
setStartTime = function(self, time)
self.startTime = time
end,

setDuration = function(self, duration)
self.duration = duration
end,

setEasingFunction = function(self, func)
self.func = func
end,

setTriggerFunction = function(self, func)
self.func = func
end
}

setmetatable(event, mt)

return event
end,
--[[============]]--
--[[============]]--

--start, type_func, duration, func_easing, func
--Overloaded function for all types of events
--[[
setEvent{
type = CES.E_TRIGGER,
start = 0,
durations = [number]
easing = bool
func = function([dt]) end
}
--]]

setEvent = function(self, args)
--Check on type
if type(args) ~= "table" then error("table expected, got: "..type(args)) end
args.type = args.type or CES.E_TRIGGER --args simplification idk

--Define a specific event type
local event
if args.type == CES.E_TRIGGER then
event = self:newTriggerEvent(args.start, args.func)
elseif args.type == CES.E_REPEAT_UNTIL then
event = self:newRepeatingEvent(args)
else
error("Unrecognized event type: "..args.type)
end

--put into a table of events of that type
table.insert(self.events[args.type], event)

return self, self.events[args.type][#self.events[args.type]] --returns a referense to your event
end,

state = function(self)
local state =   self.isPaused   and "paused"    or
self.isStopped  and "stopped"   or
"running"
return state
end,

getCurrentTime = function(self)
return self.currentTime
end,

start = function(self)
if self.isPaused then
self.launchTime = self.launchTime + self.passedTimeOnPause
self.isPaused = false
end
if self.isStopped then
self.launchTime = self.timeFunction()
self.isStopped = false
end
self.passedTimeOnPause = 0
end,

stop = function(self)
self.isStopped  = true
self.launchTime = 0
end,

pause = function(self)
self.isPaused = true
end,

restart = function(self)
self:resetAllTrigEvents()

self.launchTime = self.timeFunction()
self.isStopped = false
self.passedTimeOnPause = 0
end,

update = function(self, dt)
if self.isStopped then return end

local time = self:timeCalculation()
if not self.isPaused then
self.currentTime = time
self:checkEvents(dt)
else
self.passedTimeOnPause = time - self.currentTime
end

if self:isEnded() then
self:restart()
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
for _, event in pairs(self.events.trigger) do
event.isTriggered = false
end
end,

setTimeGetFunction = function(self, func)
self.timeFunction = func or os.clock

return self
end,

setTimeCalculationFunction = function(self, func)
self.timeCalculation = func or function(self)
return math.floor((self.timeFunction() - self.launchTime) * 1000) / 1000
end

return self
end
}
setmetatable(timelineBase, timelineBase.mt)

timelineBase:init(name, _type, duration)

return timelineBase
end

--local timelineClass = class(class(), timelineBase)

--TODO:THIS V
--TODO:Adjust to better stuff
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

getCurrentTime = function(self)
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
end,

pause = function(self)
self.isPaused = true
end,

restart = function(self)
self:resetAllTrigEvents()
self.launchTime = os.clock()
end,


update = function(self, dt)
if self.isStopped then return end

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

function CES.UpdateAll(dt)
for _, timelineType in pairs(self.timelineTypes) do
for _, timeline in pairs(timelineType) do
timeline:update(dt)
end
end
end

function CES.ResetAll(resetType)
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

--[[
local CES_mt = {
__call = function(self, name, type, duration)
return timelineClass(name, type, duration)
end
}
setmetatable(CES, CES_mt)
--]]
return CES