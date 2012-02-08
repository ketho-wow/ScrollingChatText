local _, S = ...
local SCR = ScrollingChatText

local profile

function SCR:RefreshDB3()
	profile = self.db.profile
end

local unpack = unpack
local format, gsub = format, gsub
local GetGuildRosterInfo = GetGuildRosterInfo

	---------------
	--- Methods ---
	---------------

local validateMsgLevel = {
	icon = true,
	time = true,
	chan = true,
	name = true,
	level = true,
}

function SCR:SetLevelMessage(i, v)
	profile[i[#i]] = (v:trim() == "") and S.defaults.profile[i[#i]] or v
	for k in gmatch(v, "%b<>") do
		local s = strlower(gsub(k, "[<>]", ""))
		if not validateMsgLevel[s] then
			self:Print(ERROR_CAPS..": |cffFFFF00"..k.."|r")
		end
	end
end

function SCR:SetValueLevel(i, v)
	profile[i[#i]] = v
	
	-- require both LevelParty and LevelRaid being disabled, in order to unregister UNIT_LEVEL
	local event = S.levelremap[i[#i]]
	v = (event == "UNIT_LEVEL") and S.LevelGroup() or v
	self[v and "RegisterEvent" or "UnregisterEvent"](self, event)
end

function SCR:RefreshLevelEvents()
	for option, event in pairs(S.levelremap) do
		local v = (event == "UNIT_LEVEL") and S.LevelGroup() or profile[option]
		self[v and "RegisterEvent" or "UnregisterEvent"](self, event)
	end
end

local args, cd = {}, {0, 0, 0, 0}
local group, guild, friend, friendbnet = {}, {}, {}, {}
local friendColor = {r = 0.51, g = 0.77, b = 1}

	-------------
	--- Group ---
	-------------

function SCR:UNIT_LEVEL(unit)
	if time() > cd[1] then
		cd[1] = time() + 2
		local isChat = S.LibSinkChat[profile.sink20OutputSink]
		
		local numParty = profile.LevelParty and GetNumPartyMembers() or 0
		local numRaid = profile.LevelRaid and GetNumRaidMembers() or 0

		local numGroup = (numRaid > 0) and numRaid or (numParty > 0) and numParty or 0
		local groupType = (numRaid > 0) and "raid" or (numParty > 0) and "party"
		local color = (numRaid > 0) and profile.color.RAID or (numParty > 0) and profile.color.PARTY
		
		for i = 1, numGroup do
			local guid = UnitGUID(groupType..i)
			local name, realm = UnitName(groupType..i)
			local level = UnitLevel(groupType..i)
			-- level can return as 0 when party members are not yet in the instance/zone
			if guid and level and level > 0 then
				if group[guid] and group[guid] > 0 and level > group[guid] and name ~= S.playerName then
					local class = select(2, UnitClass(groupType..i))
					local race = select(2, UnitRace(groupType..i))
					local sex = UnitSex(groupType..i)
					
					local classColor = S.classCache[select(2, UnitClass(groupType..i))]
					local raceIcon = format("|T%s:%s:%s:0:0:256:512:%s|t", S.racePath, profile.IconSize, profile.IconSize, strjoin(":", unpack(S.RACE_ICON_TCOORDS_256[strupper(race).."_"..S.sexremap[sex]])))
					local classIcon = format("|T%s:%s:%s:0:0:256:256:%s|t", S.classPath, profile.IconSize, profile.IconSize, strjoin(":", unpack(S.CLASS_ICON_TCOORDS_256[class])))
					args.time = (profile.Timestamp > 1) and "|cff979797"..BetterDate(S.timestamps[profile.Timestamp], time()).."|r" or ""
					args.icon = (profile.IconSize > 1 and not isChat) and raceIcon..classIcon or ""
					args.name = (not isChat) and format("|cff%s|Hplayer:%s|h%s|h|r", classColor, name..(realm and "-"..realm or ""), name) or name
					args.level = "|cffADFF2F"..level.."|r"
					self:Output(args, profile.LevelMessage, color)
				end
				group[guid] = level
			end
		end
	end
end

	-------------
	--- Guild ---
	-------------

function SCR:GUILD_ROSTER_UPDATE()
	if IsInGuild() and time() > cd[2] then
		cd[2] = time() + 10
		local isChat = S.LibSinkChat[profile.sink20OutputSink]
		
		for i = 1, GetNumGuildMembers() do
			local name, _, _, level, _, _, _, _, _, _, class = GetGuildRosterInfo(i)
			-- sanity checks
			if name and guild[name] and level > guild[name] and name ~= S.playerName then
				local classIcon = format("|T%s:%s:%s:0:0:256:256:%s|t", S.classPath, profile.IconSize, profile.IconSize, strjoin(":", unpack(S.CLASS_ICON_TCOORDS_256[class])))
				args.time = (profile.Timestamp > 1) and "|cff979797"..BetterDate(S.timestamps[profile.Timestamp], time()).."|r" or ""
				args.icon = (profile.IconSize > 1 and not isChat) and classIcon or ""
				args.name = (not isChat) and format("|cff%s|Hplayer:%s|h%s|h|r",  S.classCache[class], name, name) or name
				args.level = "|cffADFF2F"..level.."|r"
				self:Output(args, profile.LevelMessage, profile.color.GUILD)
			end
			guild[name] = level
		end
	end
end

	---------------
	--- Friends ---
	---------------

function SCR:FRIENDLIST_UPDATE()
	if time() > cd[3] then
		cd[3] = time() + 2
		local isChat = S.LibSinkChat[profile.sink20OutputSink]
		
		for i = 1, select(2, GetNumFriends()) do
			local name, level, class = GetFriendInfo(i)
			if name then -- name is sometimes nil
				if friend[name] and level > friend[name] then
					local classCoords = S.CLASS_ICON_TCOORDS_256[S.revLOCALIZED_CLASS_NAMES[class]]
					local classIcon = format("|T%s:%s:%s:0:0:256:256:%s|t", S.classPath, profile.IconSize, profile.IconSize, strjoin(":", unpack(classCoords)))
					args.icon = (profile.IconSize > 1 and not isChat) and classIcon or ""
					args.time = (profile.Timestamp > 1) and "|cff979797"..BetterDate(S.timestamps[profile.Timestamp], time()).."|r" or ""
					args.name = (not isChat) and format("|cff%s|Hplayer:%s|h%s|h|r",  S.classCache[S.revLOCALIZED_CLASS_NAMES[class]], name, name) or name
					args.level = "|cffADFF2F"..level.."|r"
					self:Output(args, profile.LevelMessage, friendColor)
				end
				friend[name] = level
			end
		end
	end
end

	-----------------------
	--- Real ID Friends ---
	-----------------------

function SCR:BN_FRIEND_INFO_CHANGED()
	if time() > cd[4] then
		cd[4] = time() + 2
		local isChat = S.LibSinkChat[profile.sink20OutputSink]
		
		for i = 1, select(2, BNGetNumFriends()) do
			local presID, firstname, surname, toonName2, toonID = BNGetFriendInfo(i)
			local _, toonName, client, realm, _, _, race, class, _, _, level = BNGetToonInfo(presID)
			if client == BNET_CLIENT_WOW then
				level = tonumber(level) -- why is level a string type
				if toonName and friendbnet[toonName] and friendbnet[toonName] > 0 and level and level > friendbnet[toonName] then
					local classCoords = S.CLASS_ICON_TCOORDS_256[S.revLOCALIZED_CLASS_NAMES[class]]
					local classIcon = format("|T%s:%s:%s:0:0:256:256:%s|t", S.classPath, profile.IconSize, profile.IconSize, strjoin(":", unpack(classCoords)))
					args.icon = (profile.IconSize > 1 and not isChat) and classIcon or ""
					
					-- "|Kg49|k00000000|k": f BNplayer; g firstname; s surname
					local fixedName = firstname:gsub("g", "f")
					local fullName = firstname.." "..surname
					-- the "BNplayer" hyperlink might actually taint whatever it calls on rightclick >.<
					args.name = format("|cff%s|HBNplayer:%s:%s|h%s|r |cff%s%s|h|r", "82C5FF", fixedName, presID, fullName, S.classCache[S.revLOCALIZED_CLASS_NAMES[class]], toonName)
					
					args.level = "|cffADFF2F"..level.."|r"
					
					self:Output(args, profile.LevelMessage, profile.color.BN_WHISPER)
				end
				friendbnet[toonName] = level
			end
		end
	end
end
