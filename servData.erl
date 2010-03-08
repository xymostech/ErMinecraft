-module (servData).
-export ([setupServData/5,servData/7]).

setupServData(Port,MaxPlayers,Public,Name,Motd) ->
	random:seed(now()),
	spawn(servData,servData,[Port,MaxPlayers,lists:duplicate(MaxPlayers,0),Public,random:uniform(16#ffffff),Name,Motd]).

servData(Port,MaxPlayers,Playerlist,Public,Salt,Name,Motd) ->
	receive
		{newID,Sender} ->
			{NewList,NewID}=getNewID(Playerlist),
			if
				NewID < MaxPlayers ->
					Sender ! {newID,NewID},
					servData(Port,MaxPlayers,NewList,Public,Salt,Name,Motd);
				true ->
					Sender ! {newID,-1},
					servData(Port,MaxPlayers,Playerlist,Public,Salt,Name,Motd)
			end;
		{releaseID,ID} ->
			servData(Port,MaxPlayers,lists:sublist(Playerlist,1,ID+1)++[0]++lists:nthtail(ID+3,Playerlist),Public,Salt,Name,Motd);
		{data,Sender} ->
			Sender ! {data,Port,lists:sum(Playerlist),MaxPlayers,Name,Public,Salt},
			servData(Port,MaxPlayers,Playerlist,Public,Salt,Name,Motd);
		{name,Sender} ->
			Sender ! {name,{Name,Motd}},
			servData(Port,MaxPlayers,Playerlist,Public,Salt,Name,Motd)
	end.
			
			
getNewID(List) ->
	getNewID(List,[],0).

getNewID([Start|Rest],Begin,Num) ->
	if
		Start == 0 ->
			{Begin++[1]++Rest,Num};
		true ->
			getNewID(Rest,lists:append(Begin,[Start]),Num+1)
	end.