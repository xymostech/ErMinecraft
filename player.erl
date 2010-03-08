-module (player).
-export ([playerSetup/4]).
-import (playerRecv, [playerRecv/2]).
-import (playerUpdate, [playerUp/1]).
-import (util, [md5_hex/1,space/2,inttolist/2,addr_to_string/1]).
-import (level, [getInfo/2,sendLevel/2]).

-record (player, {id,updater,name,pos,rot}).

% {ID,Updater,Name,Pos,Rot}

playerSetup(UpdateControl,ServData,Level,SockD) ->
	io:format("Starting...~n"),
	spawn(playerRecv,playerRecv,[self(),SockD]),
	Upd = spawn(playerUpdate,playerUp,[SockD]),
	player(UpdateControl,ServData,Level,SockD,Upd,#player{id=0,updater=Upd,name="",pos=0,rot=0}).

player(UpdateControl,ServData,Level,SockD,Upd,Player) ->
	NewPlayer=receive
		{login,Name,MPPass} ->
			{ok,{IP,_}}=inet:peername(SockD),
			io:format("~s joined at IP ~p~n",[string:strip(Name),addr_to_string(IP)]),
			MD5Test = md5_hex("1234"++string:strip(Name)),
			case string:strip(MPPass) of
				MD5Test ->
					io:format("Name is verified!~n");
				_ ->
					io:format("Name is not verified...~n")
			end,
			
			UpdateControl ! {add,#player{id=0,updater=Upd,name=Name,pos=0,rot=0},self()},
			receive
				{id,ID} ->
					Player#player{id=ID,name=Name}
			end;
		{block,Pos,Mode,Type} ->
			io:format("Player got block @ ~p~n",Pos),
			UpdateControl ! {block,Player,Pos,Mode,Type},
			same;
		{pos,Pos,Rot} ->
			UpdateControl ! {pos,Player,Pos,Rot},
			same;
		close ->
			io:format("Closing player...~n"),
			UpdateControl ! {remove,Player},
			exit(Upd,done),
			exit(self(),done);
		_ ->
			ok
	end,
	case NewPlayer of
		same ->
			player(UpdateControl,ServData,Level,SockD,Upd,Player);
		_ ->
			player(UpdateControl,ServData,Level,SockD,Upd,NewPlayer)
	end.