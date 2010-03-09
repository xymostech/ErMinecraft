-module (playerRecv).
-export ([playerRecv/2]).

-record (size, {x,y,z}).
-record (rot, {x,y}).

playerRecv(Player,SockD) ->
	case gen_tcp:recv(SockD,1) of
		{ok,Sock} ->
			case Sock of
				[0] ->
					{ok,[7]}=gen_tcp:recv(SockD,1),
					{ok,Name}=gen_tcp:recv(SockD,64),
					{ok,MD5}=gen_tcp:recv(SockD,64),
					{ok,_}=gen_tcp:recv(SockD,1),
					Player ! {login,Name,MD5};
				[5] ->
					{ok,Block}=gen_tcp:recv(SockD,8),
					Recv=lists:map(fun(X) -> util:listtoint(X,big) end,util:splitat(Block,[2,4,6,7,8])),
					Pos=#size{x=lists:nth(1,Recv),y=lists:nth(2,Recv),z=lists:nth(3,Recv)},
					Player ! {block,Pos,lists:nth(4,Recv),lists:nth(5,Recv)};
				[8] ->
					{ok,[_|Pos]}=gen_tcp:recv(SockD,9),
					Recv=lists:map(fun(X) -> util:listtoint(X,big) end,util:splitat(Pos,[2,4,6,7,8])),
					NewPos=#size{x=lists:nth(1,Recv),y=lists:nth(2,Recv),z=lists:nth(3,Recv)},
					Rot=#rot{x=lists:nth(4,Recv),y=lists:nth(5,Recv)},
					Player ! {pos,NewPos,Rot};
				[16#d] ->
					{ok,[_|Chat]}=gen_tcp:recv(SockD,65),
					Player ! {chat,Chat};
				_ ->
					ok
			end,
			playerRecv(Player,SockD);
		{error,close} ->
			Player ! close;
		_ ->
			Player ! close
	end.