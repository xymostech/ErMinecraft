-module (heartbeat).
-export ([beat/6,default/0]).

% default: heartbeat:beat(25565,1,1,"Testing...",true,1234).

default() ->
	timer:apply_interval(20000,heartbeat,beat,[25565,1,1,"Testing...",true,1234]).

beat(Port,Players,Max,Name,Public,Salt) ->
	inets:start(),
	Body = "port=" ++ integer_to_list(Port) ++ "&users=" ++ integer_to_list(Players) ++ "&max=" ++ integer_to_list(Max) ++ "&name=" ++ Name ++ "&public=" ++ atom_to_list(Public) ++ "&version=7&salt=" ++ integer_to_list(Salt),
	{ok,{{"HTTP/1.1",200,"OK"},_,URL}} = http:request(post, {"http://www.minecraft.net/heartbeat.jsp",[],"application/x-www-form-urlencoded",Body},[],[]),
	io:format("URL:~p~n",[string:sub_string(URL,1,string:len(URL)-4)]).