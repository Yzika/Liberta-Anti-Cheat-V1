include("config/liberta_config.lua")

local m_network_strings = {"m_validate_player", "m_network_data", "m_check_synced_data", "m_loaded", "backup_data_transfer"}


local anti_cheat_version = "1.0"

local bad_netlibertabestanticheatnonessages = {"Sandbox_ArmDupe", "Sbox_darkrp", "Sbox_itemstore", "Uliblibertabestanticheatnonessage", "ULogs_Info", "ITEM", "R8", "fix", "Fix_Keypads", "Remove_Exploiters", "noclipcloakaesp_chat_text", "_Defqon", "_CAC_ReadMemory", "nocheat", "LickMeOut", "ULX_QUERY2", "ULXQUERY2", "MoonMan", "Im_SOCool", "Sandbox_GayParty", "DarkRP_UTF8", "oldNetReadData", "memeDoor", "BackDoor", "OdiumBackDoor", "SessionBackdoor", "DarkRP_AdminWeapons", "cucked", "ZimbaBackDoor", "enablevac", "killserver", "fuckserver", "cvaraccess", "DefqonBackdoor"}


local current_server_key = "empty"

local verified_player_data = {}

local player_verification_data = {}

local function generate_string(string_length)
	local output_str = ""
	for i = 1, string_length do
		output_str = output_str .. string.char(math.random(97, 122))
	end
	return output_str
end

local libertabestanticheatnon = liberta_anti_cheat_config

current_server_key = generate_string(20)

table.insert(m_network_strings, current_server_key)

for k, v in pairs( m_network_strings ) do
	util.AddNetworkString( v )
end

local function write_to_file(filename, contents)
	data = file.Read(filename)
	if ( data ) then
		file.Write(filename, data .. "\r\n" .. tostring(contents))
	else
		file.Write(filename, tostring(contents))
	end
end

local function strip_port(player_ip)
	return string.Explode(":", player_ip)[1]
end

local function notify_server(ban_reason, steam_id, playerip, ext_data, shouldLog) // For webviewer later on
	local ip,port = (GetConVarString('ip')),(GetConVarString('hostport'))
	shouldLog = (shouldLog == nil and true) or shouldLog
	
	ip = ip == "localhost" and "127.0.0.1" or ip
	
	local url = (shouldLog and "https://libertain.cz/log" or "https://libertain.cz/verify")
	local servername = tostring(GetHostName())
	http.Post(url, 
		{ hostname = servername, server = ip, port = port, banreas = ban_reason, steamid = steam_id, playeradr = playerip, playerbandata = ext_data, webhook = libertabestanticheatnon.discord_webhook },
		function( result ) 
			if result then
				local tabs = util.JSONToTable(result) 
				if type(tabs) == "table" and tabs["message"] then 
					ServerLog("[Liberta-Anti-Cheat] cette erreur est normal, ignorez la. "..tabs["message"].. " \r\n")
				end
			end
		end, 
		function( failed ) end, 
		{["Authorization"] = libertabestanticheatnon.hashKey}
	)
end

local function log_liberta_data(msg, ply, ban_data, shouldPrint, shouldLog)
	local m_output_data = "[Liberta-Anti-Cheat] "..msg.."\r\n"
	if (libertabestanticheatnon.m_log_console) then
		Msg(m_output_data)
	end
	if (libertabestanticheatnon.m_log_file) then
		write_to_file("liberta_log.txt", m_output_data)
	end
	
	if (libertabestanticheatnon.m_log_discord && ply && (shouldPrint || false) && !(ply.isBeingBannedByLiberta or false)) then
		notify_server(msg, ply:SteamID64(), strip_port(ply:IPAddress()), ban_data or "No Data", shouldLog)
	end
end

local function ban_player(ply, reason, reason_data)
	if (!ply || !IsValid(ply) || (ply.isBeingBannedByLiberta or false)) then return end

	local shouldPrint = libertabestanticheatnon and libertabestanticheatnon.m_whatshouldLog and libertabestanticheatnon.m_whatshouldLog["banned"] or false
	log_liberta_data(ply:Name().." est interdit pour avoir "..reason, ply, reason_data, shouldPrint)

	hook.Run("liberta_banned_player", ply, reason)

	if (libertabestanticheatnon.m_use_custom_ban_reason) then
		reason = libertabestanticheatnon.m_ban_reason
	end
	
	ply.isBeingBannedByLiberta = true
	
	if liberta_anti_cheat_config.developermode then return end
	
	if (ULib) then
		ULib.ban(ply, 0, reason)
		return
	end

	-- if (serverguard) then
	-- 	serverguard:BanPlayer(nil, ply:SteamID(), 0, reason, nil, nil, "Liberta")
	-- 	return
	-- end

	-- if (maestro) then
	-- 	maestro.ban(ply:SteamID(), 0, reason)
	-- 	return
	-- end
	--  18/11/2020 retirer par Yzikaa car Liberta NORP use ULIB

	ply:Ban( 0, reason )
end

local function kick_player(ply, reason, silent, reason_data)
	if (!ply || !IsValid(ply) || (ply.isBeingKickedByAC or false)) then return end
	
	if (!silent) then 
		local shouldPrint = libertabestanticheatnon and libertabestanticheatnon.m_whatshouldLog and libertabestanticheatnon.m_whatshouldLog["kicked"] or false
		log_liberta_data(ply:Name().." is being kicked for "..reason, ply, reason_data, shouldPrint) 
	end
	
	hook.Run("liberta_kicked_player", ply, reason, silent)
	
	ply.isBeingKickedByAC = true
	
	if liberta_anti_cheat_config.developermode then return end
	
	ply:Kick(reason)
end

local function verified_player(ply)
	if (!ply || !IsValid(ply)) then return false end
	return table.HasValue(verified_player_data, ply)
end

local function verify_player(ply)
	if (verified_player(ply)) then return end
	hook.Run("liberta_verified_player", ply)
	table.insert(verified_player_data, ply)
end

local function network_data_to_ply(ply)
	if (!verified_player(ply)) then return end
	log_liberta_data("Networking data to "..ply:Name())
	net.Start("m_network_data")
		net.WriteTable({libertabestanticheatnon.check_file, libertabestanticheatnon.m_check_function, libertabestanticheatnon.m_check_globals, libertabestanticheatnon.m_checklibertabestanticheatnonodules, libertabestanticheatnon.m_check_cvars, libertabestanticheatnon.m_check_synced_cvars, libertabestanticheatnon.m_check_external, libertabestanticheatnon.m_check_dhtml, libertabestanticheatnon.m_check_cleaning_screen, libertabestanticheatnon.m_check_detoured_functions, libertabestanticheatnon.m_check_backup_kick, current_server_key, libertabestanticheatnon.m_check_concommands, libertabestanticheatnon.m_fuck_aimbot})
	net.Send(ply)
end

local function attempt_verification(ply, step)

	if (verified_player(ply) || !(ply.hasLoaded or false)) then return end
	
	if (!libertabestanticheatnon.m_validate_players || ply:IsBot()) then
		verify_player(ply)
		network_data_to_ply(ply)
		log_liberta_data(ply:Name().." has been verified", ply)
		return
	end
	
	if (step > 4) then kick_player(ply, "Verification Failed") end
	
	table.insert(player_verification_data, ply)
	net.Start("m_validate_player")
	net.Send(ply)
	ply.anticheatStep = step
	
	local time = (5 + math.Clamp(ply:Ping() / 5, 20, 30))
	if step == 1 then log_liberta_data("Started to validate "..ply:Nick().." time: "..time, ply) end

	timer.Simple(time, function()
	
		if (!ply || !IsValid(ply)) then return end
		
		if (!verified_player(ply) and ply.anticheatStep + 1 == step + 1) then
	
			attempt_verification(ply, step + 1)
			log_liberta_data(ply:Name().." validation check failed, retrying [attempt "..step.."]", ply)
			
		end
		
	end)
	
end

hook.Add("Move", "liberta_hasLoaded", function(ply , mv)

	if !(ply.hasLoaded or false) then
		
		local x = mv:GetVelocity()
		local y = mv:GetButtons()
		
		if x[1] > 0 or x[2] > 0 or x[3] > 0 or y != 0 then
		
			ply.hasLoaded = true
		
		end
		
	end
end)

local function keypress_verification_check(ply)

	if (!ply || !IsValid(ply) || table.HasValue(player_verification_data, ply) || verified_player(ply)) then return end
	attempt_verification(ply, 1)
	
end

local function validate_backuplibertabestanticheatnonessage(ply, message, public)

	if (message == current_server_key) then
	
		kick_player(ply, "[Liberta-Anti-Cheat] \n Kick \n Raison: \n L'utilisateur n'a pas correctement transmis les données d'interdiction ou d'exclusion")
		return ""
		
	end
	
end

local function is_original_banned(s_id)
	local s_id_from_64 = util.SteamIDFrom64(s_id)

	if (ULib and ULib.bans) then
		return ULib.bans[s_id] and true or false
	end

	-- if (maestro and maestro.bans) then
	-- 	return maestro.bans[s_id_from_64] and true or false
	-- end
    -- Desac car Liberta NORP use ULIB
	return false
end
local function validate_player_steam(ply, ply_steamid)
	if (string.len(libertabestanticheatnon.steam_api_key) < 2) then return end
	http.Fetch("http://api.steampowered.com/IPlayerService/IsPlayingSharedGame/v0001/?key="..libertabestanticheatnon.steam_api_key.."&format=json&steamid="..ply:SteamID64().."&appid_playing=4000",
	function(body)
		if (!body) then return end
		local json_body = util.JSONToTable(body)
		if !json_body || !json_body.response || !json_body.response.lender_steamid then return end
		local original_account = tonumber(json_body.response.lender_steamid)

		if (original_account == 0) then return end

		if (is_original_banned(original_account) && libertabestanticheatnon.kick_banned_family_shared) then
			ban_player(ply, "[Liberta-Anti-Cheat] \n Bypass Ban")
			return
		end
	end)
end

local function update_check()

	http.Fetch("https://libertain.cz/anticheat/version.lua",
	function(response)

		local tabs = util.JSONToTable(response)

		if tabs and tabs["ver"] and (tostring(tabs["ver"]) != tostring(anti_cheat_version)) then
			tabs["changeLog"] = tabs["changeLog"] or "Unknown"
			log_liberta_data("Votre version est dépasser, une nouvelle est disponible "..tabs["ver"].. " \n https://libertain.cz/discord \n Changes: "..tabs["changeLog"], "", true, false)
		else
			log_liberta_data("liberta Anti Cheat V"..anti_cheat_version.." has loaded!")
		end
	end)
	
end
// == UTIL FUNCS

// == NETWORK RECIEVERS
net.Receive(current_server_key, function(len, ply)
	local unsafe_type = net.ReadBool()
	local unsafe_reason = net.ReadString()
	local unsafe_info = net.ReadString()
	if (!unsafe_reason) then unsafe_reason = "Unknown" end
	if (unsafe_type) then ban_player(ply, unsafe_reason, unsafe_info) end
	kick_player(ply, unsafe_reason, unsafe_type, unsafe_info)
end)

net.Receive("backup_data_transfer", function(len, ply)
	local unsafe_type = net.ReadBool()
	local unsafe_reason = net.ReadString()
	local unsafe_info = net.ReadString()
	if (!unsafe_reason) then unsafe_reason = "Unknown" end
	if (unsafe_type) then ban_player(ply, unsafe_reason, unsafe_info) end
	kick_player(ply, unsafe_reason, unsafe_type, unsafe_info)
end)

net.Receive("m_validate_player", function(len, ply)
	if (verified_player(ply)) then return end
	if (table.HasValue(player_verification_data, ply)) then
		table.RemoveByValue(player_verification_data, ply)
	end
	
	local shouldPrint = libertabestanticheatnon and libertabestanticheatnon.m_whatshouldLog and libertabestanticheatnon.m_whatshouldLog["verified"] or false
	log_liberta_data(ply:Name().." has been verified", ply, "", shouldPrint, false)
	
	verify_player(ply)
	network_data_to_ply(ply)
end)

net.Receive("m_check_synced_data", function(len, ply)
	local convar_table = net.ReadTable()
	for k, v in pairs(convar_table) do
		if (!v["convar"]) then continue end
		local temp_var = GetConVar(v["convar"])
		if (!temp_var) then continue end
		if (v["value"] != temp_var:GetString()) then
			ban_player(ply, v["convar"].. " is "..v["value"].." instead of "..temp_var:GetString())
			return
		end
	end
end)

for k, v in pairs( bad_netlibertabestanticheatnonessages ) do
	v = v:lower()
	if net.Receivers[v] then 
		local curNet = debug.getinfo(net.Receivers[v])
		if debug.getinfo(attempt_verification)["short_src"] != curNet["short_src"] then 
			log_liberta_data(v.." has already been defined. Please check if this net message is exploitable "..curNet["short_src"].." Line: "..curNet["linedefined"]) 
			continue 
		end
	end
	
	util.AddNetworkString(v)
	net.Receive(v, function(len, ply)
		ban_player(ply, "[Liberta-Anti-Cheat] \n Cheating "..v)
	end)
	
end
	
oldNetReceive = oldNetReceive or net.Receive

function net.Receive( str, callback )

	local tabs = {str:lower(), callback}
	
	if tabs[2] and isfunction(tabs[2]) then
		local curNet = debug.getinfo(tabs[2])
		tabs[1] = tabs[1]:lower()
		
		if table.HasValue(bad_netlibertabestanticheatnonessages, tabs[1]) and debug.getinfo(attempt_verification)["short_src"] != curNet["short_src"] then 
			log_liberta_data(tabs[1].." has already been defined. Please check if this net message is exploitable "..curNet["short_src"].." Line: "..curNet["linedefined"])
		end
	end
	
	
	oldNetReceive(str, callback)

end


local plyExploiting = {}
function net.Incoming( len, client )

	local i = net.ReadHeader()
	local strName = util.NetworkIDToString( i )
	
	if ( !strName ) then return end
	
	local func = net.Receivers[ strName:lower() ]
	if ( !func ) then return end
	
	plyExploiting[client] = plyExploiting[client] or {}
	plyExploiting[client][strName] = plyExploiting[client][strName] or {}
	
	if (plyExploiting[client][strName][1] or 0) > 10 and (CurTime() - 1)  < (plyExploiting[client][strName][2] or 0) then
		
		local curNum = plyExploiting[client][strName][1] or 0
		plyExploiting[client][strName] = {curNum + 1, CurTime(), (plyExploiting[client][strName][3] or "")}

		if ((plyExploiting[client][strName][1] or 0)) == (math.Round((plyExploiting[client][strName][1] or 0)/4000)*4000) then
			
			log_liberta_data(client:Nick().." is potentially spamming a net message: "..strName.." | Current iteration: "..plyExploiting[client][strName][1])
			log_liberta_data("Last known error: "..(plyExploiting[client][strName][3] or ""))
		
		end
		
		return 
	end
	
	len = len - 16
	
	local succ,err = pcall(function(len, client) func( len, client ) end, len, client)
	
	if !succ then
		
		local curNum = plyExploiting[client][strName][1] or 0
		
		plyExploiting[client][strName] = {curNum + 1, CurTime(), err}
	
	end

end
// == NETWORK RECIEVERS

// == HOOKS

hook.Add("KeyPress", "keypress_check_liberta", keypress_verification_check )

hook.Add("PlayerAuthed", "check_player_liberta", validate_player_steam)

hook.Add("PlayerSay", "backup_ban_check", validate_backuplibertabestanticheatnonessage)

// == HOOKS

update_check()
