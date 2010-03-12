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
			Player#player.updater ! {spawn,16#ff,Player#player.name,SpawnPos,SpawnRot},
			lists:map(fun(P) -> Player#player.updater ! {spawn,P#player.id,P#player.name,P#player.pos,P#player.rot} end,Players),
			lists:map(fun(P) -> P#player.updater ! {spawn,NewID,Player#player.name,SpawnPos,SpawnRot} end,Players),
			updateServ(Level,ServData,[Player#player{id=NewID,pos=SpawnPos,rot=SpawnRot}|Players]);
		{remove,Player} ->
			lists:map(fun(P) -> if Player#player.id==P#player.id -> ok; true -> P#player.updater ! {despawn,Player#player.id} end end,Players),
			ServData ! {releaseID,Player#player.id},
			updateServ(Level,ServData,lists:dropwhile(fun(P) -> P#player.id == Player#player.id end,Players));
		{pos,Player,Pos,Rot} ->
			NewP = lists:map(fun(P) -> if Player#player.id==P#player.id -> P#player{pos=Pos,rot=Rot}; true -> P#player.updater!{pos,Player#player.id,Pos,Rot}, P end end,Players),
			updateServ(Level,ServData,NewP);
		{block,_,Pos,Type} ->
			Level ! {set,self(),Type,Pos},
			lists:map(fun(P) -> P#player.updater ! {block,Pos,Type} end,Players),
			updateServ(Level,ServData,Players);
		{chat,Player,Text} ->
			lists:map(fun(P) -> P#player.updater ! {chat,Player#player.name++":&f "++util:colorize(Text)} end,Players),
			io:format("~s~n",[Player#player.name++": "++util:colorize(Text)]),
			updateServ(Level,ServData,Players);
		{pchat,Player,ToName,Text} ->
			lists:map(fun(P) -> case string:to_lower(P#player.name) of ToName -> P#player.updater ! {chat,Player#player.name++":&f "++util:colorize(Text)}; _ -> ok end end,Players),
			updateServ(Level,ServData,Players);
		{mess,Text} ->
			lists:map(fun(P) -> P#player.updater ! {chat,Text} end,Players),
			io:format("~s~n",[Text]),
			updateServ(Level,ServData,Players);
		{pmess,ToPlayer,Text} ->
			ToPlayer#player.updater ! {chat,Text},
			updateServ(Level,ServData,Players);
		_ ->
			updateServ(Level,ServData,Players)
	end.