local tags={"detect_cheat","_Detect"}
for i=1,#tags do
	util.AddNetworkString(tags[i])
	net.Receive(tags[i],function(_,ply)
		ply:Ban(0,true)
	end)
end