-module (updateServer).
-export ([updateServ/2,updateServ/3]).

-record (player, {id,updater,name,pos,rot}).

updateServ(Level,ServData) ->
	spawn(?MODULE,updateServ,[Level,ServData,[]]).

updateServ(Level,ServData,Players) ->
	receive
		{add,Player,Play} ->
			NewID = util:getInfo(newID,ServData),
			Play ! {id,NewID},
			{Name,Motd} = util:getInfo(name,ServData),
			Player#player.updater ! {load,Level,Name,Motd},
			{SpawnPos,SpawnRot} = util:getInfo(spawn,Level),
			Player#player.updater ! {spawn,16#ff,Name,SpawnPos,SpawnRot},
			lists:map(fun(P) -> P#player.updater ! {spawn,NewID,Name,SpawnPos,SpawnRot} end,Players),
			
			updateServ(Level,ServData,[Player#player{id=NewID,pos=SpawnPos,rot=SpawnRot}|Players]);
		{remove,Player} ->
			lists:map(fun(P) -> if Player#player.id==P#player.id -> ok; true -> P#player.updater ! {despawn,Player#player.id} end end,Players),
			updateServ(Level,ServData,lists:dropwhile(fun(P) -> P#player.id == Player#player.id end,Players));
		{pos,Player,Pos,Rot} ->
			NewP = lists:map(fun(P) -> if Player#player.id==P#player.id -> P#player{pos=Pos}; true -> P#player.updater!{pos,Player#player.id,Pos,Rot}, P end end,Players),
			updateServ(Level,ServData,NewP);
		{block,_,Pos,Mode,Type} ->
			Level ! {set,self(),case Mode of 0 -> 0; 1 -> Type end,Pos},
			lists:map(fun(P) -> P#player.updater ! {block,Pos,Mode,Type} end,Players),
			updateServ(Level,ServData,Players);
		_ ->
			updateServ(Level,ServData,Players)
	end.