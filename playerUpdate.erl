-module (playerUpdate).
-export ([playerUp/1]).

-record (rot, {x,y}).

playerUp(SockD) ->
	receive
		{load,Level,Name,Motd} ->
			gen_tcp:send(SockD,[0,7,util:space(Name,64),util:space(Motd,64),0]),
			level:sendLevel(SockD,Level);
		{spawn,ID,Name,Pos,Rot} ->
			io:format("Spawning ~s (~p) @ ~p,~p~n",[string:strip(Name),ID,Pos,Rot]),
			gen_tcp:send(SockD,[7,ID,util:space(Name,64)]++lists:flatten(lists:map(fun(A) -> util:inttolist(A,2) end,lists:nthtail(1,tuple_to_list(Pos))))++[Rot#rot.x,Rot#rot.y]);
		{despawn,ID} ->
			gen_tcp:send(SockD,[16#c,ID]);
		{block,Pos,Type} ->
			gen_tcp:send(SockD,[6]++lists:flatten(lists:map(fun(A) -> util:inttolist(A,2) end,lists:nthtail(1,tuple_to_list(Pos))))++[Type]);
		{pos,ID,Pos,Rot} ->
			gen_tcp:send(SockD,[9,ID]++lists:flatten(lists:map(fun(A) -> util:inttolist(A,2) end,lists:nthtail(1,tuple_to_list(Pos))))++[Rot#rot.x,Rot#rot.y]);
		_ ->
			ok
	end,
	playerUp(SockD).