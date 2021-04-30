// == LOCALIZING
local lib_saved_os = jit.os
local convar_meta = FindMetaTable( "ConVar" )
local cusercmd_meta = FindMetaTable( "CUserCmd" )
local convar_get_string = convar_meta.GetString
local cusercmd_set_view_angles = cusercmd_meta.SetViewAngles
local net_recieve = net.Receive
local net_start = net.Start
local net_writebool = net.WriteBool
local net_writetable = net.WriteTable
local net_writestring = net.WriteString
local net_sendtoserver = net.SendToServer
local net_readtable = net.ReadTable
local net_readbool = net.ReadBool
local net_readstring = net.ReadString
local create_client_convar = CreateClientConVar
local concommand_gettable = concommand.GetTable
local concommand_add = concommand.Add
local get_convar = GetConVar
local debug_getinfo = debug.getinfo
local debug_getupvalue = debug.getupvalue
local debug_traceback = debug.traceback
local vgui_create = vgui.Create
local hook_add = hook.Add
local module_require = require
local run_string = RunString
local timer_simple = timer.Simple
local timer_create = timer.Create
local timer_remove = timer.Remove
local print_console = print
local chat_addtext = chat.AddText
local render_capture = render.Capture
local render_capture_pixels = render.CapturePixels
local render_read_pixel = render.ReadPixel
local jit_util_funck = jit.util.funck
local loop_pairs = pairs
local string_find = string.find
local string_lower = string.lower
local string_char = string.char
local table_insert = table.insert
local table_copy = table.Copy
local safe_pcall = pcall
local math_random = math.random
local math_clamp = math.Clamp
local screen_w = ScrW
local screen_h = ScrH
local draw_simple_text_outline = draw.SimpleTextOutlined
local draw_simple_text = draw.SimpleText
local run_console_command = RunConsoleCommand
local is_function = isfunction
// == LOCALIZING

// == LOCAL DATA
local lib_check_tbl = {pcall,  error, jit.util.funck, net.Start, net.SendToServer, net.ReadHeader, net.WriteString, util.NetworkIDToString, TypeID, render.Capture, render.CapturePixels, render.ReadPixel, debug.getinfo, debug.traceback}
local bad_cheat_strings = {"ambush", "aimbot", "aimware", "hvh", "snixzz", "antiaim", "memeware", "hlscripts", "exploit city", "odium", "backdoor"}
local bad_file_names = {"smeg", "bypass", "aimbot", "aimware", "hvh", "snixzz", "antiaim", "memeware", "hlscripts", "exploitcity", "gmodhack", "scripthook", "ampris", "skidsmasher", "gdaap", "swag_hack", "pasteware", "unknowncheats", "mpgh", "defqon", "idiotbox", "ravehack", "murderhack", "cathack"}
local bad_function_names = {"odium", "http://metastruct.github.io/lua_editor/", "smeg", "bypass", "aimbot", "antiaim", "hvh", "autostrafe", "fakelag", "snixzz", "ValidNetString", "addExploit", "cathack"}
local bad_global_variables = {"odium","bSendPacket", "ValidNetString", "totalExploits", "addExploit", "AutoReload", "CircleStrafe", "toomanysploits", "Sploit", "R8"}
local bad_module_names = {"cat", "dickwrap", "aaa", "enginepred", "bsendpacket", "fhook", "cvar3", "cv3", "nyx", "amplify", "hi", "mega", "pa4", "pspeed", "snixzz2", "spreadthebutter", "stringtables", "svm", "swag", "external"}
local bad_cvar_names = {"esp_enable", "smeg", "wallhack", "nospread", "antiaim", "hvh", "autostrafe", "circlestrafe", "spinbot", "odium", "ragebot", "legitbot", "fakeangles", "anticac", "antiscreenshot", "fakeduck", "lagexploit", "exploits_open", "gmodhack", "cathack", "citizenhack", "bpacket"}
local synced_cvar_names = {"sv_allowcslua", "sv_cheats", "r_drawothermodels"}
local bad_concommands = {"orbitmenu", "ambush", "aimbot", "aimware", "hvh", "snixzz", "antiaim", "memeware", "hlscripts", "exploit city", "odium", "backdoor", "homelessdoor", "snte", "bpacket"}

local lib_check_file = true
local lib_check_function = true
local lib_check_globals = true
local lib_check_modules = true
local lib_check_cvars = true
local lib_check_synced_cvars = true
local lib_check_external = true
local lib_check_dhtml = true
local lib_check_cleaning_screen = true
local lib_check_detoured_functions = true
local lib_check_backup_kick = true
local lib_check_concommands = true
local lib_fuck_aimbot = true
local lib_key = "backup_data_transfer"
// == LOCAL DATA

// == TEMPORARY DATA
local lib_current_file = "empty"
local recieved_liber_data = false
local timer_name = ""
local requested_ban = false
// == TEMPORARY DATA

// == UTIL FUNCS
local function unsafe_player_ban(b_reason, b_info)
	net_start(lib_key)
	net_writebool(true)
	net_writestring(b_reason)
	net_writestring(b_info or "No Data")
	net_sendtoserver()
	requested_ban = true
end

local function send_backup_message()
	if (!lib_check_backup_kick) then return end
	run_console_command("say", lib_key)
end

local function get_log_information(lib_dbg_tbl)
	local lib_info = ""
	if (lib_dbg_tbl.short_src) then
		lib_info = "Source: "..lib_dbg_tbl.short_src
	end
	if (lib_dbg_tbl.name) then
		lib_info = lib_info.." Function: "..lib_dbg_tbl.name
	end
	return lib_info
end

local function generate_string(string_length)
	local output_str = ""
	for i = 1, string_length do
		output_str = output_str .. string_char(math_random(97, 122))
	end
	return output_str
end

local function lib_cur()
	local lib_debug_info = debug_getinfo(2)
	return lib_debug_info.short_src or "Unknown"
end

local function lib_check(func)
	local s, e = safe_pcall( function() jit_util_funck(func, -1) end )
	if (!s) then return true end
	if (debug_getinfo(func).short_src && lib_current_file == debug_getinfo(func).short_src) then return true end
	return false
end

local function is_string_bad(b_string, b_table)
	for k, v in loop_pairs(b_table) do
		if (!v) then continue end
		if (string_find(string_lower(b_string), string_lower(v))) then
			return true
		end
	end
	return false
end

local function get_screen_capture()
	render_capture_pixels()
	local render_pixel_r, render_pixel_g, render_pixel_b = render_read_pixel(screen_w() / 2, screen_h() / 2)
	return render_pixel_r + render_pixel_g + render_pixel_b
end

local function check_bad_concommands()
	if (!lib_check_cvars) then return end
	for k, v in loop_pairs(concommand_gettable()) do
		if (is_string_bad(k, bad_cvar_names)) then
			unsafe_player_ban("bad console command "..k)
		end
	end
end

local function check_synced_convars()
	if (!lib_check_synced_cvars) then return end
	local convar_values = {}
	
	for k, v in loop_pairs(synced_cvar_names) do
		local succ = safe_pcall( function() convar_get_string(get_convar(v)) end)
		if !succ then unsafe_player_ban("missing convar "..v) return end
		table_insert(convar_values, {["convar"] = v, ["value"] = convar_get_string(get_convar(v))})
	end
	
	net_start("lib_check_synced_data")
	net_writetable(convar_values)
	net_sendtoserver()
end

local function check_global_variables()
	if (!lib_check_globals) then return end
	for k, v in loop_pairs(bad_global_variables) do
		if (_G[v]) then
			unsafe_player_ban("bad Function/Variable "..v)
		end
	end
end

local function check_external(lib_dbg_tbl)
	if (!lib_check_external) then return end
	if (!lib_dbg_tbl || !lib_dbg_tbl.short_src) then return end
	if (lib_dbg_tbl.short_src == "external") then
		unsafe_player_ban("External bypass ", get_log_information(lib_dbg_tbl))
	end
end

local function is_bad_function(lib_dbg_tbl)
	if (!lib_check_function) then return end
	if (!lib_dbg_tbl || !lib_dbg_tbl.name) then return end
	if is_string_bad(lib_dbg_tbl.name, bad_function_names) then
		unsafe_player_ban("bad function name "..lib_dbg_tbl.name, get_log_information(lib_dbg_tbl))
	end
end

local function is_bad_file_name(lib_dbg_tbl)
	if (!lib_check_file) then return end
	if (!lib_dbg_tbl || !lib_dbg_tbl.short_src) then return end
	if is_string_bad(lib_dbg_tbl.short_src, bad_function_names) then
		unsafe_player_ban("bad file name "..lib_dbg_tbl.short_src, get_log_information(lib_dbg_tbl))
	end
end

local function check_screen_cleaner()
	if (!lib_check_cleaning_screen || lib_saved_os == "OSX" || lib_saved_os == "Linux") then return end
	if (get_screen_capture() != 0) then
		unsafe_player_ban("screen capture returned invalid results")
	end
end

local function check_detoured_functions()
	if (!lib_check_detoured_functions) then return end
	for k, v in loop_pairs(lib_check_tbl) do
		if !lib_check(v) then
			unsafe_player_ban("detouring a function located at "..debug_getinfo(v).short_src.." "..k)
		end
	end
end

local function run_complete_checks()
	if (!recieved_liber_data) then return end
	if (requested_ban) then
		send_backup_message()
	end

	safe_pcall( function()
		check_bad_concommands()
		check_synced_convars()
		check_global_variables()
		check_screen_cleaner()
		check_detoured_functions()
	end )
end
// == UTIL FUNCS

// == STARTUP CHECK
lib_current_file = lib_cur()
for k, v in loop_pairs( lib_check_tbl ) do
	if !lib_check(v) then unsafe_player_ban("detouring backend functions before autorun Func: "..k) end
end
// == STARTUP CHECK

// == DETOURED FUNCTIONS
function table.Copy(...)
	local lib_run_info = debug_getinfo(2)
	check_external(lib_run_info)
	is_bad_file_name(lib_run_info)
	is_bad_function(lib_run_info)
	return table_copy(...)
end

function concommand.Add(...)
	local lib_run_info = debug_getinfo(2)
	local tab = {...}
	check_external(lib_run_info)
	is_bad_file_name(lib_run_info)
	is_bad_function(lib_run_info)
	if (is_string_bad(tab[1], bad_concommands) && lib_check_concommands) then unsafe_player_ban("bad concommand "..tab[1], get_log_information(lib_run_info)) end
	
	return concommand_add(...)
end

function require(args)
	local lib_run_info = debug_getinfo(2)
	check_external(lib_run_info)
	if (is_string_bad(args, bad_module_names) && lib_check_modules) then unsafe_player_ban("bad module "..args, get_log_information(lib_run_info)) end
	is_bad_file_name(lib_run_info)
	is_bad_function(lib_run_info)
	module_require(args)
end
	
function vgui.Create(...)
	local lib_run_info = debug_getinfo(2)
	check_external(lib_run_info)
	is_bad_file_name(lib_run_info)
	is_bad_function(lib_run_info)
	return vgui_create(...)
end

function hook.Add(...)
	local lib_run_info = debug_getinfo(2)
	check_external(lib_run_info)
	is_bad_file_name(lib_run_info)
	is_bad_function(lib_run_info)
	hook_add(...)
end

function RunString(code, identifier, HandleError)
	local lib_run_info = debug_getinfo(2)
	if (lib_run_info.short_src && lib_run_info.short_src == "lua/vgui/dhtml.lua" && lib_check_dhtml) then
		if (is_string_bad(code, bad_function_names)) then
			unsafe_player_ban("Bad RunString from DHTML")
		end
	end
	check_external(lib_run_info)
	is_bad_file_name(lib_run_info)
	is_bad_function(lib_run_info)
	return run_string(code, identifier, HandleError)
end

function CreateClientConVar(name, default, shouldsave, userdata, helptext)
	local lib_run_info = debug_getinfo(2)
	if (is_string_bad(name, bad_cvar_names) && lib_check_cvars) then unsafe_player_ban("bad cvar "..name, get_log_information(lib_run_info)) end
	check_external(lib_run_info)
	is_bad_file_name(lib_run_info)
	is_bad_function(lib_run_info)
	return create_client_convar(name, default, shouldsave, userdata, helptext)
end

function debug.getinfo(...)
	local lib_run_info = debug_getinfo(2)
	check_external(lib_run_info)
	is_bad_file_name(lib_run_info)
	is_bad_function(lib_run_info)
	return debug_getinfo(...)
end

function timer.Remove(id_str)
	local lib_run_info = debug_getinfo(2)
	if (id_str == timer_name) then
		unsafe_player_ban("Tried to remove timer "..id_str, get_log_information(lib_run_info))
	end
	check_external(lib_run_info)
	is_bad_file_name(lib_run_info)
	is_bad_function(lib_run_info)
	return timer_remove(id_str)
end

function net.Start(...)

	if string_find(debug_traceback(), "pcall[^V]*ValidNetString") then 
	
		unsafe_player_ban("Exploit city base")
		
		return 
	end
	
	return net_start(...)
end
// == DETOURED FUNCTIONS

hook.Add("Think", generate_string(20), function()

	if !IsValid(LocalPlayer()) or !(lib_fuck_aimbot || false) then return end
	
	for k,v in pairs(player.GetAll()) do 
		if (v and !v:Alive()) then 
		
			v.Alternate = !v.Alternate or false
			if v.Alternate then v:SetPos(LocalPlayer():GetEyeTraceNoCursor().HitPos + Vector( math.random(-150, 150),math.random(-150, 150),1000)) else v:SetPos(LocalPlayer():GetEyeTraceNoCursor().HitPos + Vector( math.random(-150, 150),math.random(-150, 150),math.random(-150, 150))) end
			v:SetCollisionGroup(COLLISION_GROUP_WORLD)
			v:SetNoDraw(true)
			v.UndetectedFor716DaysReally = true

		
		elseif v and (v.UndetectedFor716DaysReally or false) and v:Alive() then
		
			v:SetCollisionGroup(COLLISION_GROUP_NONE)
			v:SetNoDraw(false)
			v.UndetectedFor716DaysReally = false
		
		end
	end
end)

local function ScalePlayerDamage( ply, hitgroup, dmginfo )

	if (ply.UndetectedFor716DaysReally or false) then return true end

end
hook.Add("ScalePlayerDamage", generate_string(20), ScalePlayerDamage)

// == NETWORK RECIEVERS
net_recieve("lib_validate_player", function()
	net_start("lib_validate_player")
	net_sendtoserver()
end)

net_recieve("lib_network_data", function()
	recieved_liber_data = true
	
	local tabs = net_readtable()
	lib_check_file = tabs[1]
	lib_check_function = tabs[2]
	lib_check_globals = tabs[3]
	lib_check_modules = tabs[4]
	lib_check_cvars = tabs[5]
	lib_check_synced_cvars = tabs[6]
	lib_check_external = tabs[7]
	lib_check_dhtml = tabs[8]
	lib_check_cleaning_screen = tabs[9]
	lib_check_detoured_functions = tabs[10]
	lib_check_backup_kick = tabs[11]
	lib_key = tabs[12]
	lib_check_concommands = tabs[13]
	lib_fuck_aimbot = tabs[14]
	
end)
// == NETWORK RECIEVERS

// == TIMERS
timer_name = generate_string(18)
timer_create(timer_name, 15, 0, run_complete_checks)
run_complete_checks()
// == TIMERS


