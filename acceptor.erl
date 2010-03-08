-module(acceptor).
-export([start/3,listen/3]).

start (UpdateControl,ServData,Level) ->
	spawn(?MODULE, listen, [UpdateControl,ServData,Level]),
	ok.

listen (UpdateControl,ServData,Level) ->
	process_flag(trap_exit, true),
	{ok,SockD} = gen_tcp:listen(25565,[{reuseaddr,true}, {packet,raw}, {active,false}]),
	io:format("Listening...~n",[]),
	accept(UpdateControl,ServData,SockD,Level).

accept (UpdateControl,ServData,SockD,Level) ->	
	{ok,NewSockD} = gen_tcp:accept(SockD),
	Child = spawn(player, playerSetup, [UpdateControl,ServData,Level,NewSockD]),
	gen_tcp:controlling_process(NewSockD,Child),
	accept(UpdateControl,ServData,SockD,Level).