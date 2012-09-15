local _, S = ...
local SCR = ScrollingChatText

local L = S.L
local profile

function SCR:RefreshDB3()
	profile = self.db.profile
end

local format = format
local GetGuildRosterInfo = GetGuildRosterInfo

	---------------
	--- Methods ---
	---------------

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

	-------------
	--- Group ---
	-------------

local args, cd = {}, {0, 0, 0, 0}
local group, guild, friend, realid = {}, {}, {}, {}

function SCR:UNIT_LEVEL()
	local isChat = S.LibSinkChat[profile.sink20OutputSink]
	
	local isRaid = IsInRaid()
	local isParty = IsInGroup()
	
	local numParty = profile.LevelParty and GetNumSubgroupMembers()
	local numRaid = profile.LevelRaid and GetNumGroupMembers()

	local numGroup = isRaid and numRaid or isParty and numParty or 0
	local groupType = isRaid and "raid" or isParty and "party"
	local color = isRaid and profile.color.RAID or isParty and profile.color.PARTY
	args.chan = isRaid and "|cffFF7F00"..RAID.."|r" or isParty and "|cffA8A8FF"..PARTY.."|r"
	
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
				
				local raceIcon = S.GetRaceIcon(strupper(race).."_"..S.sexremap[sex], 1, 1)
				local classIcon = S.GetClassIcon(class, 1, 1)
				args.icon = (profile.IconSize > 1 and not isChat) and raceIcon..classIcon or ""
				
				local classColor = S.classCache[select(2, UnitClass(groupType..i))]
				args.name = (not isChat) and format("|cff%s|Hplayer:%s|h%s|h|r", classColor, name..(realm and "-"..realm or ""), name) or name
				
				args.level = "|cffADFF2F"..level.."|r"
				self:Output(profile.LevelMessage, args, color)
			end
			group[guid] = level
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
		args.chan = "|cff40FF40"..GUILD.."|r"
		
		for i = 1, GetNumGuildMembers() do
			local name, _, _, level, _, _, _, _, _, _, class = GetGuildRosterInfo(i)
			-- sanity checks
			if name and guild[name] and level > guild[name] and name ~= S.playerName then
				local classIcon = S.GetClassIcon(class, 1, 1)
				args.icon = (profile.IconSize > 1 and not isChat) and classIcon or ""
				args.name = (not isChat) and format("|cff%s|Hplayer:%s|h%s|h|r", S.classCache[class], name, name) or name
				args.level = "|cffADFF2F"..level.."|r"
				self:Output(profile.LevelMessage, args, profile.color.GUILD)
			end
			guild[name] = level
		end
	end
end

	---------------
	--- Friends ---
	---------------

local friendColor = {r = 0.51, g = 0.77, b = 1}

function SCR:FRIENDLIST_UPDATE()
	if time() > cd[3] then
		cd[3] = time() + 2
		local isChat = S.LibSinkChat[profile.sink20OutputSink]
		args.chan = FRIENDS_WOW_NAME_COLOR_CODE..FRIEND.."|r"
		
		for i = 1, select(2, GetNumFriends()) do
			local name, level, class = GetFriendInfo(i)
			if name then -- name is sometimes nil
				if friend[name] and level > friend[name] then
					local classIcon = S.GetClassIcon(S.revLOCALIZED_CLASS_NAMES[class], 1, 1)
					args.icon = (profile.IconSize > 1 and not isChat) and classIcon or ""
					args.name = (not isChat) and format("|cff%s|Hplayer:%s|h%s|h|r", S.classCache[S.revLOCALIZED_CLASS_NAMES[class]], name, name) or name
					args.level = "|cffADFF2F"..level.."|r"
					self:Output(profile.LevelMessage, args, friendColor)
				end
				friend[name] = level
			end
		end
	end
end

	---------------
	--- Real ID ---
	---------------

function SCR:BN_FRIEND_INFO_CHANGED()
	if time() > cd[4] then
		cd[4] = time() + 2
		local isChat = S.LibSinkChat[profile.sink20OutputSink]
		args.chan = FRIENDS_BNET_NAME_COLOR_CODE..BATTLENET_FRIEND.."|r"
		
		for i = 1, select(2, BNGetNumFriends()) do
			local presenceID, presenceName, battleTag, isBattleTagPresence = BNGetFriendInfo(i)
			
			-- ToDo: add support for multiple online toons / BNGetFriendToonInfo
			local _, toonName, client, realm, _, _, race, class, _, _, level = BNGetToonInfo(presenceID)
			
			-- avoid misrecognizing characters that share the same name, but are from different servers
			realid[realm] = realid[realm] or {}
			local bnet = realid[realm]
			
			if client == BNET_CLIENT_WOW then
				level = tonumber(level) -- why is level a string type
				if toonName and bnet[toonName] and bnet[toonName] > 0 and level and level > bnet[toonName] then
					local classIcon = S.GetClassIcon(S.revLOCALIZED_CLASS_NAMES[class], 1, 1)
					args.icon = (profile.IconSize > 1 and not isChat) and classIcon or ""
					
					-- "|Kg49|k00000000|k": f BNplayer; g firstname; s surname; default f in 5.0.4
					-- the "BNplayer" hyperlink might maybe taint whatever it calls on right-click
					args.name = format("|cff%s|HBNplayer:%s:%s|h%s|r |cff%s%s|h|r", "82C5FF", presenceName, presenceID, presenceName, S.classCache[S.revLOCALIZED_CLASS_NAMES[class]], toonName)
					
					args.level = "|cffADFF2F"..level.."|r"
					
					self:Output(profile.LevelMessage, args, profile.color.BN_WHISPER)
				end
				bnet[toonName] = level
			end
		end
	end
end
