-module (player).
-export ([playerSetup/4]).
-import (playerRecv, [playerRecv/2]).
-import (playerUpdate, [playerUp/1]).
-import (util, [md5_hex/1,space/2,inttolist/2,addr_to_string/1]).
-import (level, [getInfo/2,sendLevel/2]).

-record (player, {id,updater,name,pos,rot}).

% {ID,Updater,Name,Pos,Rot}

playerSetup(UpdateControl,ServData,Level,SockD) ->
	spawn(playerRecv,playerRecv,[self(),SockD]),
	Upd = spawn(playerUpdate,playerUp,[SockD]),
	player(UpdateControl,ServData,Level,SockD,Upd,#player{id=0,updater=Upd,name="",pos=0,rot=0},[]).

player(UpdateControl,ServData,Level,SockD,Upd,Player,Replace) ->
	receive
		{login,Name,MPPass} ->
			{ok,{IP,_}}=inet:peername(SockD),
			io:format("~s joined at IP ~p~n",[string:strip(Name),addr_to_string(IP)]),
			MD5Test = md5_hex(integer_to_list(util:getInfo(salt,ServData))++string:strip(Name)),
			case string:strip(MPPass) of
				MD5Test ->
					io:format("~s is verified!~n",[string:strip(Name)]);
				_ ->
					io:format("~s is not verified...~n",[string:strip(Name)])
			end,
			
			UpdateControl ! {add,#player{id=0,updater=Upd,name=string:strip(Name),pos=0,rot=0},self()},
			receive
				{id,ID} ->
					io:format("ID: ~p~n",[ID]),
					player(UpdateControl,ServData,Level,SockD,Upd,Player#player{id=ID,name=string:strip(Name)},Replace)
			end;
		{block,Pos,Mode,Type} ->
			UseType = case Mode of 0 -> 0; 1 -> Type end,
			UpdateControl ! {block,Player,Pos,replace:replaceFun(Replace,UseType)},
			player(UpdateControl,ServData,Level,SockD,Upd,Player,Replace);
		{pos,Pos,Rot} ->
			UpdateControl ! {pos,Player,Pos,Rot},
			player(UpdateControl,ServData,Level,SockD,Upd,Player,Replace);
		{chat,Chat} ->
			case lists:nth(1,Chat) of
				$/ ->
					case list_to_atom(lists:sublist(Chat,2,string:str(Chat," ")-2)) of
						 solid ->
							UpdateControl ! {pmess,Player,"Now placing unbreakable stone."},
							player(UpdateControl,ServData,Level,SockD,Upd,Player,replace:setReplace(Replace,1,7));
						normal ->
							UpdateControl ! {pmess,Player,"Now placing normal stone."},
							player(UpdateControl,ServData,Level,SockD,Upd,Player,replace:setReplace(Replace,1,1));
						_ ->
							player(UpdateControl,ServData,Level,SockD,Upd,Player,Replace)
					end;
				_ ->
					UpdateControl ! {chat,Player,string:strip(Chat)},
					player(UpdateControl,ServData,Level,SockD,Upd,Player,Replace)
			end;
		close ->
			io:format("~s disconnected...~n",[string:strip(Player#player.name)]),
			UpdateControl ! {remove,Player},
			exit(Upd,done),
			exit(self(),done);
		_ ->
			player(UpdateControl,ServData,Level,SockD,Upd,Player,Replace)
	end.