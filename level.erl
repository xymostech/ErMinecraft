-module (level).
-export ([levelLoad/1,getBlock/4,setBlock/5,levelSave/2,sendLevel/2,levelStart/1,level/1]).
-import (util, [inttolist/2,inttolist/3,listtoint/1,space/2,wait/1]).
-record (size, {x,y,z}).
-record (rot, {x,y}).
-record (level, {data,size,spawnpos,spawnrot}).

levelStart(Level) ->
	spawn(?MODULE,level,[Level]).

level(Level) ->
	NewLevel=receive
		{data,Sender} ->
			Sender ! {data,Level#level.data},
			same;
		{size,Sender} ->
			Sender ! {size,Level#level.size},
			same;
		{spawn,Sender} ->
			Sender ! {spawn,{Level#level.spawnpos,Level#level.spawnrot}},
			same;
		{get,Sender,Place} ->
			Size=Level#level.size,
			Sender ! {get,lists:nth(Size#size.x*Size#size.z*Place#size.y+Size#size.x*Place#size.z+Place#size.x,Level#level.data)},
			same;
		{set,_,New,Place} ->
			Size=Level#level.size,
			Pos = Size#size.x*Size#size.z*Place#size.y+Size#size.x*Place#size.z+Place#size.x,
			Level#level{data=lists:sublist(Level#level.data,1,Pos-1)++[New]++lists:nthtail(Pos+1,Level#level.data)};
		{update} ->
			update
	end,
	case NewLevel of
		same ->
			level(Level);
		update ->
			level:level(Level);
		_ ->
			level(NewLevel)
	end.

levelLoad(Name) ->
	{ok,CompressedFile} = file:read_file(Name),
	CFile = binary_to_list(CompressedFile),
	Size = listtoint(lists:sublist(CFile,1,4)),
	CompressedData = list_to_binary(lists:sublist(CFile,5,Size)),
	Uncomp = binary_to_list(zlib:gunzip(CompressedData)),
	MapSize=#size{x=listtoint(lists:sublist(CFile,Size+5,2)),y=listtoint(lists:sublist(CFile,Size+7,2)),z=listtoint(lists:sublist(CFile,Size+9,2))},
	SpawnPos=#size{x=listtoint(lists:sublist(CFile,Size+11,2)),y=listtoint(lists:sublist(CFile,Size+13,2)),z=listtoint(lists:sublist(CFile,Size+15,2))},
	SpawnRot=#rot{x=listtoint(lists:sublist(CFile,Size+17,1)),y=listtoint(lists:sublist(CFile,Size+18,1))},
	#level{data=Uncomp,size=MapSize,spawnpos=SpawnPos,spawnrot=SpawnRot}.

levelSave({Data, Size, SpawnPos, SpawnRot}, Name) ->
	{ok,File}=file:open(Name,write),
	Comp=zlib:gzip(list_to_binary(Data)),
	file:write(File,list_to_binary(inttolist(length(binary_to_list(Comp)),4,little))),
	file:write(File,Comp),
	file:write(File,list_to_binary(inttolist(Size#size.x,2))),
	file:write(File,list_to_binary(inttolist(Size#size.y,2))),
	file:write(File,list_to_binary(inttolist(Size#size.z,2))),
	file:write(File,list_to_binary(inttolist(SpawnPos#size.x,2))),
	file:write(File,list_to_binary(inttolist(SpawnPos#size.y,2))),
	file:write(File,list_to_binary(inttolist(SpawnPos#size.z,2))),
	file:write(File,list_to_binary(inttolist(SpawnRot#rot.x,1))),
	file:write(File,list_to_binary(inttolist(SpawnRot#rot.y,1))),
	ok.

sendLevel(SockD,Level) when is_pid(Level) ->
	Data = util:getInfo(data,Level),
	gen_tcp:send(SockD,[2]),
	sendLevel(SockD,binary_to_list(zlib:gzip(inttolist(length(Data),4)++Data))),
	Size = util:getInfo(size,Level),
	gen_tcp:send(SockD,[4]),
	gen_tcp:send(SockD,inttolist(Size#size.x,2)),
	gen_tcp:send(SockD,inttolist(Size#size.y,2)),
	gen_tcp:send(SockD,inttolist(Size#size.z,2)),
	done;
sendLevel(SockD,Data) when is_list(Data) ->
	sendLevel(SockD,Data,length(Data)).

sendLevel(SockD,Data,DataLen) when length(Data) > 0 ->
	{Tosend,Rest}=case Data of
		Dat when length(Dat) > 1024 ->
			lists:split(1024,Dat);
		Otherwise ->
			{Otherwise,[]}
	end,
	gen_tcp:send(SockD,[3]++inttolist(1024,2)),
	gen_tcp:send(SockD,space(Tosend,1024)),
	gen_tcp:send(SockD,[trunc((DataLen-length(Data))/DataLen*100)]),
	sendLevel(SockD,Rest,DataLen);
sendLevel(_,[],_) ->
	done.

getBlock({Data,{Sizex,_,Sizez},_,_},X,Y,Z) ->
	lists:nth(Sizex*Sizez*Y+Sizex*Z+X,Data).

setBlock({Data,{Sizex,_,Sizez},_,_},X,Y,Z,New) ->
	Pos = Sizex*Sizez*Y+Sizex*Z+X,
	lists:sublist(Data,1,Pos-1)++[New]++lists:nthtail(Pos+1,Data).