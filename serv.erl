-module (serv).
-export ([servStart/0]).

servStart() ->
	Level=level:levelLoad("server_level.data"),
	LevelProc=level:levelStart(Level),
	ServData=servData:setupServData(25565,16,true,"Hello, world!","&4Your friendly neighborhood server (chat working!)"),
	timer:apply_interval(60000,heartbeat,beat,[ServData]),
	UpdateServ=updateServer:updateServ(LevelProc,ServData),
	acceptor:start(UpdateServ,ServData,LevelProc).