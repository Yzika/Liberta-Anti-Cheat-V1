local function ValidPlayer(ply)
	return (IsValid(ply) and not ply:IsBot() and not ply:IsTimingOut() and ply:PacketLoss() < 70 and ply:Ping() < 800)
end

local function Punish(ply)
	if (not IsValid(ply)) then return end
	ServerLog(string.format("[Liberta-Anti-Cheat] | Timestamp: %s | Kicked %s \n", os.date("%H:%M:%S - %d/%m/%Y", os.time()), ply:SteamID()))
	ply:Kick("[Liberta-Anti-Cheat] \n Vous avez été kick \n Raison: Cheating ")
end

local СvarFlags = bit.bor(FCVAR_CHEAT, FCVAR_NOT_CONNECTED, FCVAR_USERINFO, FCVAR_UNREGISTERED, FCVAR_UNLOGGED)
local СvarValue = "val"

local AEPayload = string.format([[CreateConVar('external','%s',%d) CreateConVar('require','%s',%d)]], СvarValue, СvarFlags, СvarValue, СvarFlags)
local AEPlayers = {}

local function AERoutine()
	for ply, _ in pairs(AEPlayers) do 
		if (not IsValid(ply)) then AEPlayers[ply] = nil continue end
		if (not ValidPlayer(ply)) then continue end

		local name = ply:GetInfo("name") or ''
		if (name == '') then continue end

		local external = ply:GetInfo("external") or ''
		local require = ply:GetInfo("require") or ''

		if ((external ~= СvarValue) or (require ~= СvarValue)) then
			AEPlayers[ply] = (AEPlayers[ply] or 0) + 1
			ply:SendLua(AEPayload)
		else
			AEPlayers[ply] = nil
			continue
		end

		if (AEPlayers[ply] > 5) then
			AEPlayers[ply] = nil
			Punish(ply)
		end
	end

	timer.Simple(5, AERoutine)
end

AERoutine()

local function AEInitPlayer(ply, mv, cmd)
	if (ply and mv and cmd and ValidPlayer(ply) and not cmd:IsForced() and not ply.AEInitialized) then
		ply.AEInitialized = true
		ply:SendLua(AEPayload)
		AEPlayers[ply] = 0
	end
end

hook.Add("SetupMove", "AEInitialize", AEInitPlayer)
