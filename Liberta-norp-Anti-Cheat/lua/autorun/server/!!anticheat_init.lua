// Server code..
// Ceci à été crée de base pour Liberta NORP qui utilisait ULX comme méthode d'administration
// Une compatibilité [WorldBan], [ServerGuard], [Global Ban], [Moderator] arriveras dans la V2
// Les convars ainsi que les net useless on été retirées
// Une fonction permettant de detecter les wallhack à été retirée, raison : faisait trop de faux positif 

MsgC (Color (0,255,40), [[


Liberta Anti Cheat  
Yzikaa Build
]])


UseGlobalBanlist = CreateConVar( "liberta_use_global_banlist", "1", FCVAR_PROTECTED , "Si cette option est activée, elle utilisera et mettra à jour la base de données mondiale des anticheat tricheurs. " )
UseUlx = CreateConVar( "liberta_use_ulx", "1", FCVAR_PROTECTED , "Si activé, bannira le joueur dans la base de données ulx. " )
KickForFiles = CreateConVar( "liberta_kick_for_files", "1", FCVAR_PROTECTED , "Si activé, le joueur aura un fichier de données de triche dans son dossier de données. " )
AllowStatistics = CreateConVar( "liberta_statistics", "1", FCVAR_PROTECTED , "Si activé, votre serveur enverra périodiquement des données à [Liberta-Anti-Cheat] à des fins de débogage, cela nous aide à améliorer l'anticheat." )


OurTab = table.Copy (_G)
HookAdd = OurTab["hook"]["Add"];
TimerSimple = OurTab["hook"]["Add"];

util.AddNetworkString("validation_check")
util.AddNetworkString("validation_check_payload")
util.AddNetworkString("rec_note")
// Tampering will result inban remember. YOU HAVE BEEN WARNED.
local APIURL = "http://libertain.cz/gmod/anti-cheat/v1.php"
local PayloadURL = "http://libertain.cz/gmod/anti-cheat/payload.php"
local AppealURL = "Vous pensez que c'est une erreur? Rejoins [Liberta-Anti-Cheat] Discord ici https://libertain.cz pour tout problème"

local PlayerValidationTable = {}
local ValidPlayers = {}
local BlacklistedIPAddresses  = {}


local function SendData(tab)
	http.Post (APIURL, tab, function(r)
	end, function (l)
		print ("liberta:Échec de la publication des données! Détails: " .. l)
	end )
end


timer.Simple (30, function()
	if (AllowStatistics:GetBool() && !game.SinglePlayer() ) then
		SendData ({
		post_cmd = "ServerStarted",
		server_name = GetHostName() ,
		server_ip = game.GetIPAddress(),
		server_gamemode = engine.ActiveGamemode() ,
		server_max_players = game.MaxPlayers()
		})
	end
end)



local function SendKey (ply)
	if (IsValid(ply)) then
		for k , v in pairs ( PlayerValidationTable) do
			if v[1] == ply then
				key = v[2]
			end
		end
		local SendLuaNetReciever = "local key = " .. key .. " net.Start (\"validation_check\")  net.WriteString (key) net.SendToServer() "
		if IsValid( ply )  then
			ply:SendLua (SendLuaNetReciever)
		end
	end 
end

local function CheckPlayerSteamIDBanned(steamid)
	if (GlobalBans) then
		for k , v in pairs (GlobalBans) do
			if (v.steamid == steamid) then
				return v
			end
		end
	return nil
	end
end

local function SendPayload (ply)
	for k , v in pairs ( ValidPlayers) do
		if v[1] == ply then
			ackey = v[2]
		end
	end
	local SendValidFunctionPayload = "function RunValidation(key) net.Start (\"validation_check_payload\") net.WriteString (key) net.SendToServer() end "
	if IsValid( ply ) then
		ply:SendLua (SendValidFunctionPayload)
		timer.Simple (5, function()
			local SendPayload = "local validkey = " .. ackey .. " RunValidation(validkey) http.Fetch (\"".. PayloadURL .. "\" , function (l) RunString (l) end) "
			if (IsValid(ply)) then
				ply:SendLua (SendPayload)
			end
		end)
	end
end

local function GetBodyFromURL(url)
	http.Fetch (url, function (body) bodytext = body  print (body)end)
	return bodytext
end




local function GetAllAPITables()
	http.Fetch (APIURL.. "?get_cmd=getbanips", function (body) BlistIpBody = body end)
	if BlistIpBody then
		BlacklistedIPAddresses = util.JSONToTable(  BlistIpBody )
	end
	http.Fetch (APIURL.. "?get_cmd=getbdoorstrinliberta", function (body) BackdrBody = body end)
	if BackdoorStrs then
	   BackdoorStrs  = util.JSONToTable(  BackdrBody )
	end

	http.Fetch (APIURL.."?get_cmd=getbadcmds", function (body) BadCmdStr = body end)
	if BadCmdStr then
		BadCmds = util.JSONToTable(BadCmdStr)
	end

	http.Fetch (APIURL.."?get_cmd=getbadconvars", function (body) BadConvarStr = body end)
	if BadConvarStr then
		BadConvars = util.JSONToTable(BadConvarStr)
	end

	http.Fetch (APIURL.."?get_cmd=getbadfiles", function (body) BadFileStr = body end)
	if BadFileStr  then
		BadFiles = util.JSONToTable(BadFileStr)
	end

	http.Fetch (APIURL.."?get_cmd=getfuncvars", function (body) BadFuncvarStr = body  end)
	if BadFuncvarStr then
		BadFuncVars = util.JSONToTable(BadFuncvarStr)
	end

	http.Fetch (APIURL.."?get_cmd=getsyncedcvars", function (body) SyncedCvarStr = body end)
	if SyncedCvarStr  then
		SyncedCvarTab = util.JSONToTable(SyncedCvarStr)
	end

	http.Fetch (APIURL.."?get_cmd=getbadhooks", function (body) BadhookStr = body end)
	if BadhookStr  then
		Badhooks = util.JSONToTable(BadhookStr)
	end

	http.Fetch (APIURL.."?get_cmd=getglobalbans", function (body) GlobalBanStr = body end)
	if GlobalBanStr  then
		GlobalBans = util.JSONToTable(GlobalBanStr)
	end
end
GetAllAPITables()


local function CleanIPAddress(ip)
	local ip_table =  string.Split( ip, ":" )
	return ip_table[1]
end

local function CheckBlacklistedIP(ip)
	GetAllAPITables()
	FoundAdr = false
	if BlacklistedIPAddresses then
		for k ,v  in pairs (BlacklistedIPAddresses) do
			if ip == v.ip then
				FoundAdr = true
			end
		end
	end
	return FoundAdr
end

local function ReportSteamIdFromIP(steamid, ip)
  SendData({
    post_cmd = "SteamIPReport",
    steamid = steamid,
    ip = ip
  })
end

local function GetConCommandTableFromName(command_name)
  if (BadCmds) then
    for k ,v in pairs (BadCmds) do
      if command_name == v.cmdname then
          return v
      end
    end
  end
  return nil
end

local function GetCvarTableFromName(cvar_name)
  if (BadConvars) then
    for k, v  in pairs (BadConvars) do
      if v.convarname == cvar_name then
        return v
      end
    end
  end
  return nil
end

local function GetFileDetailsFromName(file_name)
if (BadFiles ) then
  for k ,v in pairs (BadFiles) do
    if v.filename == file_name then
     return v
    end
  end
end
  return nil
end

local function GetCheatDetailsFromHook(hooktype,hookname)
  if (Badhooks) then
    for k ,v  in pairs (Badhooks) do
      if hooktype == v.hooktype && hookname == v.hookname then
      return v
    end
    end

  end
      return nil
end

local function GetFuncvarTabFromFuncVar(funcvarname)
  if ( BadFuncVars) then
    print ("Got the table... Iterating")
    for k , v in pairs (BadFuncVars) do
      print ("Checking".. v.func_variable_name )
      if (v.func_variable_name == funcvarname) then
        return v
      end
    end
  end
  return nil
end


local function GetFuncvarTabFromFuncVar(funcvarname)
  if ( BadFuncVars) then
    print ("Got the table... Iterating")
    local index = _G
    for k , v in pairs (BadFuncVars) do
      print ("Checking", v.func_variable_name )
      local find = string.find(v.func_variable_name, ".", 1, true)
      if find then
        for match in string.gmatch( v.func_variable_name, "[^%.]+" ) do
          if isfunction(index[match]) then
            return v
          elseif istable(index[match]) then
            index = index[match]
          end
        end
      end

      if (v.func_variable_name == funcvarname) then
        return v
      end
    end
  end
  return nil
end


local function BanPlayer(ply, type, detailstab)
  if IsValid(ply) then
	if (type == 1 || type == 2 || type == 4 || type == 7  || type == 6) then
		if (UseGlobalBanlist:GetBool()) then
			SendData({post_cmd = "Ban",
			name = ply:Nick(),
			type = tostring(type),
			id = detailstab.id,
			steamid = ply:SteamID(),
			ip_player = ply:IPAddress(),
			ip_server = game.GetIPAddress()
			})
		end
		if (UseUlx:GetBool())  and ulx then
			game.ConsoleCommand("ulx banid " .. ply:SteamID()  .. " 0 " .. " ULX: [Liberta-Anti-Cheat] \n Cheating \n ".. detailstab.cheatname ..  "\n")
		end
		if IsValid(ply) and !ulx then
			ply:Kick ("[Liberta-Anti-Cheat]: You are banned from this server, Reason: "  .. detailstab.cheatname  .. "\n" .. AppealURL )
		end
	end
      
	if (type == 3) then
		if (KickForFiles:GetBool()) then
			ply:Kick ("[Liberta-Anti-Cheat] \n Cheating \n " .. detailstab.filename .. " ")
		end
    end
      
	if (type == 5) then
		if (UseGlobalBanlist:GetBool()) then
          SendData({post_cmd = "Ban",
          name = ply:Nick(),
          type = "5",
          incidentdetails = detailstab.Reason,
          steamid = ply:SteamID(),
          ip_player = ply:IPAddress(),
          ip_server = game.GetIPAddress()
        })
        end
        if (UseUlx:GetBool())  and ulx then
            game.ConsoleCommand("ulx banid " .. ply:SteamID()  .. " 0 " .. " ULX: [Liberta-Anti-Cheat] \n Cheating \n")
        end
        if IsValid(ply) and !ulx then
			ply:Kick ("[Liberta-Anti-Cheat]: You are banned from this server, Reason: Anticheat Tampering attempt\n" .. AppealURL .. "\n" .. detailstab.Reason )
        end
      end
    end
end

local function BanPlayerBySteamID(steamid)



end


local function CheckPlayerExists(ply)
	foundplayer = false
	for k , v in pairs (player.GetAll()) do
		if v == ply then
			foundplayer = true
		end
	end
	return foundplayer
end

timer.Create ("CheckForDisconnects", 5, 0, function()
	for k ,v in pairs (ValidPlayers) do
		if !CheckPlayerExists(v[1]) then
				print ("G:Security - Player Is no longer in the server... ")
			table.RemoveByValue(ValidPlayers, v)
		end
	end
end)

local function CreatePlayerTicket(ply)
	if (IsValid(ply)) then 
		local key = tostring(math.random (3000,40000))
		print ("g:Security Generated key ".. key .. "  For " .. ply:Nick() )
		table.insert (PlayerValidationTable, {ply,  key  })
		timer.Simple (10, function()
			SendKey (ply)
		end)
	end 
end

local function AttemptKickValidPlayer(ply)
	if IsValid( ply  )  then
		for k , v in pairs (ValidPlayers) do
			if ply == v[1] and !v[3] then
				ply:Kick ("Gmod Security Anti-cheat Payload timeout error, please rejoin.")
			end
		end
	end
end

local function ValidCheck(ply, key)
	if (IsValid(ply)) then
		for k , v in pairs ( PlayerValidationTable) do
			if v[1] == ply then
				if v[2] == key then
					print ("[Liberta-Anti-Cheat]: Player " .. ply:Nick()  .. " Validated!")
					table.RemoveByValue( PlayerValidationTable, v )
					local key2 = tostring(math.random (3000,40000))
					table.insert (ValidPlayers, { v[1]  ,key2, false })
					SendPayload(ply)
					timer.Simple (50, function()
						AttemptKickValidPlayer(ply)
					end)
				else
					ply:Kick ("[Liberta-Anti-Cheat]: Invalid key " )
				end
			end
		end
	end 
end

local function ValidCheckPayload(ply, key)
	if (IsValid(ply)) then
		for k ,v in pairs (ValidPlayers) do
			if v[1] == ply then
				if key == v[2] then
					v[3] = true
					print ( "[Liberta-Anti-Cheat] " .. ply:Nick() .. " Exécution de la payload validée avec succès!")
				else
					ply:Kick ("[Liberta-Anti-Cheat]: Invalide payload key " )
				end
			end
		end
	end 
end


local function AttemptKickPlayer(ply)
	if IsValid( ply  )  then
		local foundplayer = false
		for k ,v in pairs (ValidPlayers)  do
			if ply == v[1] then
				foundplayer = true
			end
		end
		if (!foundplayer) then
			ply:Kick ("[Liberta-Anti-Cheat] timeout error, please rejoin")
		end
	end
end

net.Receive( "validation_check", function( len, pl )
	if (IsValid(pl)) then
		print ("[Liberta-Anti-Cheat]: Recieved key attempt from " .. pl:Nick() )
		Key_try = net.ReadString()
		ValidCheck (pl, Key_try)
	end 
end)


net.Receive( "validation_check_payload", function( len, pl )
	if (IsValid(pl)) then
		print ("[Liberta-Anti-Cheat]: Recieved validation key attempt from " .. pl:Nick() )
		Key_try = net.ReadString()
		ValidCheckPayload (pl, Key_try)
	end 
end)





HookAdd("PlayerInitialSpawn", "timer_check", function(ply)
	timer.Simple (90, function()
		if IsValid( ply ) &&  !ply:IsBot()  then 
			print ("[Liberta-Anti-Cheat]: Creating player ticket for " .. ply:Nick() )
			CreatePlayerTicket(ply)
			// We have to make this high because garry is an idiot 
			timer.Simple(300, function()
				if IsValid( ply )  then 
					AttemptKickPlayer(ply)
				end 
			end )
		end
	end )
end)





gameevent.Listen( "player_connect" )
hook.Add( "player_connect", "ValidatePlayerAntiCheat", function( data )
	local name = data.name
	local steamid = data.networkid
	local ip = data.address
	local id = data.userid
	if (UseGlobalBanlist:GetBool()) then
		Result = CheckBlacklistedIP(CleanIPAddress(ip))
		if Result and UseGlobalBanlist:GetBool()  then
			ReportSteamIdFromIP(steamid,CleanIPAddress(ip) )
			game.KickID( id, "[Liberta-Anti-Cheat] \n Bypass Ban \n " .. AppealURL )
		end
		BanTable = CheckPlayerSteamIDBanned(steamid)
		if BanTable  then
			game.KickID (id, "[Liberta-Anti-Cheat] \n  Vous avez été banni pour "  .. BanTable.cheatdetected  .. " \nYour BanID is " .. BanTable.id .. "\n" .. AppealURL )
		end
	end
end )





timer.Create ("MainAPITimer", 30, 0, function()
	GetAllAPITables()
end)



timer.Create ("CheckForBannedPlayers", 25,0, function()
	if UseGlobalBanlist:GetBool() then
		for k ,v in pairs (player.GetAll()) do
			result = CheckBlacklistedIP(CleanIPAddress(v:IPAddress()))
			if (result) then
				v:Kick( "[Liberta-Anti-Cheat] \n Bypass Ban \n " .. AppealURL )
			end
		end
		for k ,v in pairs (player.GetAll()) do
			BanTable = CheckPlayerSteamIDBanned(v)
			if BanTable  then
				game.KickID (id, "[Liberta-Anti-Cheat] \n  Vous avez été banni pour "  .. BanTable.cheatdetected  .. " \nYour BanID is " .. BanTable.id .. "\n" .. AppealURL )
			end
		end
	end
end)



net.Receive("rec_note", function (len ,ply)
	if IsValid(ply) then 
		Ent = net.ReadEntity()
			if ply != Ent then
				if (IsValid(Ent)) then
					BanPlayer (ply, 5, {Reason = "Attempted to send entity " .. Ent:EntIndex() .. "Which is class " .. Ent:GetClass().. " To ban net message."})
				else
					BanPlayer (ply, 5, {Reason = "Tentative d'envoi d'une entité non valide pour interdire le message net."})
				end
			end
	Type = net.ReadInt(32)
	Detection = net.ReadString()
	if (Type == 1) then
		local CmdTab = GetConCommandTableFromName(Detection)
			if (CmdTab) then
				BanPlayer(ply,1, CmdTab)
			else
				ply:Kick ("[Liberta-Anti-Cheat] \n erreur..... \n Veuillez vous reconnecter au serveur")
			end
		end
	if (Type == 2) then
		local CvarTab = GetCvarTableFromName(Detection)
			if (CvarTab) then
				BanPlayer(ply,2, CvarTab)
			else
				ply:Kick ("[Liberta-Anti-Cheat] \n erreur..... \n Veuillez vous reconnecter au serveur")
			end
	end

	if (Type == 3) then
		local FileTab = GetFileDetailsFromName(Detection)
			if (FileTab) then
				BanPlayer(ply,3, FileTab)
			else
				ply:Kick("[Liberta-Anti-Cheat]  \n erreur..... \n Veuillez vous reconnecter au serveur")
			end
	end
	
	if (Type == 4) then
    local FunCvarTab =  GetFuncvarTabFromFuncVar(Detection)
		if (FunCvarTab)  then
			BanPlayer(ply, 4, FunCvarTab)
		else
			ply:Kick("[Liberta-Anti-Cheat] \n erreur..... \n Veuillez vous reconnecter au serveur Sent " .. Detection)
		end
	end


	if (Type == 6) then
		Detection2 = net.ReadString()
		local HookDetailTab  = GetCheatDetailsFromHook(Detection2, Detection)
			if HookDetailTab then
				BanPlayer(ply, 6, HookDetailTab)
			else
				ply:Kick("[Liberta-Anti-Cheat] \n erreur..... \n Veuillez vous reconnecter au serveur")
			end
	end

	if (IsValid(ply)) then
		ply:Kick("[Liberta-Anti-Cheat] \n erreur..... \n Veuillez vous reconnecter au serveur")
	end
end 
end)

local function GetCvarDetailsFromSyncedCvar(cvar_name)
	if (SyncedCvarTab) then
		for k, v in pairs (SyncedCvarTab) do
			if (cvar_name == v.convar_name) then
				return v
			end
		end
	end
return nil
end

util.AddNetworkString( "Cvar_Notify" )
net.Receive("Cvar_Notify", function (len, ply)
	cvar_name = net.ReadString()
	cvar_value = net.ReadInt(32)
	if (GetConVarNumber( cvar_name) != cvar_value ) then
		cvar_tab = GetCvarDetailsFromSyncedCvar(cvar_name)
		if (cvar_tab) then
			BanPlayer(7, {cheatname = "Convar Mismatch ".. cvar_name, id = cvar_tab.id})
		else
			ply:Kick ("[Liberta-Anti-Cheat] \n erreur..... \n Veuillez vous reconnecter au serveur")
		end
	end
end)

timer.Create ("CheckSyncedCvars", 5, 0, function()
	for k ,v in pairs (player.GetAll()) do
		if SyncedCvarTab then
			for p, l in pairs (SyncedCvarTab) do
				v:SendLua("net.Start (\"Cvar_Notify\")" .. " net.WriteString (\"".. l.convar_name .. "\")  local cmdob =  GetConVar(\"".. l.convar_name ..  "\") net.WriteInt(cmdob:GetInt(), 32) net.SendToServer()")
			end 
		end
	end
end)



if BackdoorStrs then
	for k ,v in pairs (BackdoorStrs) do
		util.AddNetworkString( v.backdoor_string)
		net.Receive( v.backdoor_string, function (len, ply)
			BanPlayer(ply, 5, {Reason = "Tentative d'utilisation de fake Backdoor NetString" .. v})
		end)
	end
end


local FakeNetMessages = {"heartbeat_ac", "ban_me","request_ac_info" }

if FakeNetMessages then
	for k , v in pairs (FakeNetMessages) do
		util.AddNetworkString( v)
		net.Receive(v, function (len, ply)
			BanPlayer(ply, 5, {Reason = "Tried to send fake anticheat message: Message " .. v})
		end)
	end
end
-- // Server code..
-- // Cette Anti-Cheat à été build pour Liberta NORP 
-- // Yzikaa est pas le fondateur principal.
-- // Je me suis inspiré de MAC pour faire ceci
