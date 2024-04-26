--[=[=========================-[~]-=========================]=]--
--[=[==============-[Advanced Event Creator]-===============]=]--
--[=[====================-[VER: 1.2.1]-=====================]=]--
--[=[==================-[Written By Zly]-===================]=]--
--[=[==========-[Based on Spyro's Anti-Cheat code]-=========]=]--
--[=[=========================-[~]-=========================]=]--

--[=[Thanks to:
--		Spyro(aka Oshisaure),
--      Lyrit Zian,
-- 		Hexadorsip,
--		Exschwasion,
-- 			and
-- 		Alpha
--      for the help and inspiration to make stuff in OH
]=]--

AEC = {};
AEC.TimeLines = { default = {}, repeating = {}};
AEC.Events = {};
AEC.Functions = {};

local CurTime = 0;
local LaunchTime = 0;

local debug = false;
local isMatrixExists = false;

function AEC:SetMatrix(type, timeLine_index, duration__event_num, event_num)
	if type == "default" then
		AEC:setDefMatrix(type, timeLine_index, duration__event_num)
	elseif type == "repeating" then
		AEC:setRepMatrix(type, timeLine_index, duration__event_num, event_num)
	end
	isMatrixExists = true;
end

function AEC:setDefMatrix(type, timeLine_index, event_num)
	isMatrixExists = false;
	self.TimeLines[type][timeLine_index] = {};
	for j=1, event_num do   		
		self.TimeLines[type][timeLine_index][j] = {};

		self.TimeLines[type][timeLine_index][j][1] = ""; 					
		self.TimeLines[type][timeLine_index][j][2] = -666;  				
		self.TimeLines[type][timeLine_index][j][3] = function() end;  	
		self.TimeLines[type][timeLine_index][j][4] = 0;  				
		self.TimeLines[type][timeLine_index][j][5] = 0;  				
	end
	LaunchTime = os.clock();
end

function AEC:setRepMatrix(type, timeLine_index, duration, event_num)
	isMatrixExists = false;
	self.TimeLines[type][timeLine_index] = {};
	self.TimeLines[type][timeLine_index][1] = os.clock(); 		
	self.TimeLines[type][timeLine_index][2] = 0;  				
	self.TimeLines[type][timeLine_index][3] = duration;  		
	self.TimeLines[type][timeLine_index][4] = {};  				
	self.TimeLines[type][timeLine_index][5] = false;  			
	self.TimeLines[type][timeLine_index][6] = 0;  				
	for n=1, event_num do
		self.TimeLines[type][timeLine_index][4][n] = {};			
		for m=1, 5 do
			self.TimeLines[type][timeLine_index][4][n][m] = {};
		end
		self.TimeLines[type][timeLine_index][4][n][1] = "";					
		self.TimeLines[type][timeLine_index][4][n][2] = -666;					
		self.TimeLines[type][timeLine_index][4][n][3] = function() end; 		
		self.TimeLines[type][timeLine_index][4][n][4] = 0;						
		self.TimeLines[type][timeLine_index][4][n][5] = 0;						
	end
end

function AEC:Debug(bool)
	debug = bool;
end

function AEC:CreateFunction(index, funct)
	self.Functions[index] = funct;
end

function AEC:GetFunction(index)
	return self.Functions[index];
end

--TODO:FIX THIS ALL SHIT CODE!!!!!
--TODO:STFU THIS IS A PROTOTYPE!!!!!
function AEC:SetEvent(type, TimeLineIndex, eventIndex, eventTime, EType, eventUntilTime_eventFunction, eventFunction)
	if EType == "once" then
		self:SetEventOnce(type, TimeLineIndex, eventIndex, eventTime, eventUntilTime_eventFunction)
	elseif EType == "until" then
		self:SetEventUntil(type, TimeLineIndex, eventIndex, eventTime, eventUntilTime_eventFunction, eventFunction)
	end
end

function AEC:SetEventOnce(type, TimeLineIndex, eventIndex, eventTime, eventFunction)
	if type == "default" then
		self.TimeLines[type][TimeLineIndex][eventIndex][1] = "once";
		self.TimeLines[type][TimeLineIndex][eventIndex][2] = eventTime;
		self.TimeLines[type][TimeLineIndex][eventIndex][3] = eventFunction;
	elseif type == "repeating" then
		self.TimeLines[type][TimeLineIndex][4][eventIndex][1] = "once";
		self.TimeLines[type][TimeLineIndex][4][eventIndex][2] = eventTime;
		self.TimeLines[type][TimeLineIndex][4][eventIndex][3] = eventFunction
	end
end
function AEC:SetEventUntil(type, TimeLineIndex, eventIndex, eventTime, eventUntilTime, eventFunction)
	if type == "default" then
		self.TimeLines[type][TimeLineIndex][eventIndex][1] = "until";
		self.TimeLines[type][TimeLineIndex][eventIndex][2] = eventTime;
		self.TimeLines[type][TimeLineIndex][eventIndex][3] = eventFunction;
		self.TimeLines[type][TimeLineIndex][eventIndex][5] = eventUntilTime;
	elseif type == "repeating" then
		self.TimeLines[type][TimeLineIndex][4][eventIndex][1] = "until";
		self.TimeLines[type][TimeLineIndex][4][eventIndex][2] = eventTime;
		self.TimeLines[type][TimeLineIndex][4][eventIndex][3] = eventFunction;
		self.TimeLines[type][TimeLineIndex][4][eventIndex][5] = eventUntilTime;
	end
end

function AEC:GetEventFunction(eventIndex)
	return self.Events[eventIndex][2];
end

function AEC:RReset(TL_index)
	if TL_index ~= "all" then
		for event_index=1, #self.TimeLines["repeating"][TL_index][4] do
			self.TimeLines["repeating"][TL_index][4][event_index][4] = 0;
		end

		self.TimeLines["repeating"][TL_index][1] = os.clock();
	elseif TL_index == "all" then
		for timeline_index=1, #self.TimeLines["repeating"] do
			for event_index=1, #self.TimeLines["repeating"][timeline_index][4] do
				self.TimeLines["repeating"][TL_index][4][event_index][4] = 0;
			end

			self.TimeLines["repeating"][timeline_index][1] = os.clock();
		end
	end
end

function AEC:RepeatCtrl(timeLine_index, bool)
	self.TimeLines["repeating"][timeLine_index][5] = bool;
end

function AEC:Update()
	if isMatrixExists == true then
		CurTime = math.floor((os.clock() - LaunchTime) * 1000) / 1000;
	end
end

local debBegin = true;
function AEC:EventTimeCheck(dt)
	if isMatrixExists == true then
		for iType = 1, 2 do
			if iType == 1 then
				for i = 1, #self.TimeLines["default"] do
					for j=1, #self.TimeLines["default"][i] do
						local EType   		= self.TimeLines["default"][i][j][1];
						local time    		= self.TimeLines["default"][i][j][2];
						local funct   		= self.TimeLines["default"][i][j][3];
						local off     		= self.TimeLines["default"][i][j][4];
						local timeUntil     = self.TimeLines["default"][i][j][5];

						if EType == "once" then
							if CurTime >= time and self.TimeLines["default"][i][j][4] == 0 and time ~= -666 then
								if (debug == true) then
									print("--[[======]]--");
									print("Time Line Type: 'default'");
									print("Time Line:index #"..i);
									print("Event:type: 'once'");
									print("Event:index #"..j);
									print("Event:Time - "..time);
								end

								funct(dt);
								self.TimeLines["default"][i][j][4] = 1;
							end
						elseif EType == "until" then
							if (CurTime >= time and CurTime <= timeUntil) and (time ~= -666 and timeUntil ~= -666) then
								if (debug == true) then
									print("--[[======]]--");
									print("Time Line Type: 'default'");
									print("Time Line:index #"..i);
									print("Event:type: 'until'");
									print("Event:index #"..j);
									print("Event:Time - "..time..":"..timeUntil);
								end

								funct(dt);
								self.TimeLines["default"][i][j][4] = 1;
							end
						end
					end
				end

			elseif iType == 2 then
				for i = 1, #self.TimeLines["repeating"] do
					local LTime 			= self.TimeLines["repeating"][i][1]; --[!]
					local CTime 			= math.floor(self.TimeLines["repeating"][i][2]) / 1000; --[!]
					local TimeLine_duration = self.TimeLines["repeating"][i][3]; --[!][>]

					local IsNotStoped 		= self.TimeLines["repeating"][i][5]; --[!]
					local CTimeOff 			= self.TimeLines["repeating"][i][6]; --[!]

					if CTime >= 0 and CTime <= 1 and debug and debBegin then
						print("--[[===-[TIMELINE INDEX: "..i.." BEGIN]-===]]--");
						debBegin = false;
					end
					for j=1, #self.TimeLines["repeating"][i][4] do

							local EType   		= self.TimeLines["repeating"][i][4][j][1]; --[!]
							local time    		= self.TimeLines["repeating"][i][4][j][2]; --[!]
							local funct   		= self.TimeLines["repeating"][i][4][j][3]; --[!]
							local off     		= self.TimeLines["repeating"][i][4][j][4]; --[!]
							local timeUntil     = self.TimeLines["repeating"][i][4][j][5]; --[!][<]

						if IsNotStoped == false then
							self.TimeLines["repeating"][i][2] = (os.clock() - LTime) * 1000;
							self.TimeLines["repeating"][i][6] = self.TimeLines["repeating"][i][2];
						else
							self.TimeLines["repeating"][i][1] = ((os.clock() * 1000)-CTimeOff)/1000;
						end

						if EType == "once" then
							if CTime >= time and self.TimeLines["repeating"][i][4][j][4] == 0 and time ~= -666 then
								if (debug == true) then
									print("--[[======]]--");
									print("Time Line Type: 'repeating'");
									print("Time Line:index #"..i);
									print("Event:type: 'once'");
									print("Event:index #"..j);
									print("Event:Time - "..time);
								end

								funct(dt);
								self.TimeLines["repeating"][i][4][j][4] = 1;
							end
						elseif EType == "until" then
							if (CTime >= time and CTime <= timeUntil) and (time ~= -666 and timeUntil ~= -666) then
								if (debug == true) then
									print("--[[======]]--");
									print("Time Line Type: 'repeating'");
									print("Time Line:index #"..i);
									print("Event:type: 'until'");
									print("Event:index #"..j);
									print("Event:Time - "..time..":"..timeUntil);
								end

								funct(dt);
								self.TimeLines["repeating"][i][4][j][4] = 1;
							end
						end

					end
					if CTime > TimeLine_duration then
						self:RReset(i);
						if debug then
							print("--[[===-[TIMELINE INDEX: "..i.." END TIME: "..TimeLine_duration.."]-===]]--");
							debBegin = true;
						end
					end
				end
			end
		end
	end
end

