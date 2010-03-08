-module (serv).
-export ([servStart/0]).

servStart() ->
	Level=level:levelLoad("server_level.data"),
	LevelProc=level:levelStart(Level),
	ServData=servData:setupServData(25565,16,true,"Hello, world!","Your friendly neighborhood server (chat not working)"),
	UpdateServ=updateServer:updateServ(LevelProc,ServData),
	acceptor:start(UpdateServ,ServData,LevelProc),
	io:format("Level: ~p~nServData: ~p~nUpdate: ~p~n",[LevelProc,ServData,UpdateServ]).