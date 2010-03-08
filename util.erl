-module (util).
-export ([listtoint/1,listtoint/2,inttolist/2,inttolist/3,space/2,md5_hex/1,splitat/2,wait/1,addr_to_string/1,getInfo/2]).

listtoint(Integer,Endian) ->
	case Endian of
		little ->
			listtoint(Integer);
		big ->
			listtoint(lists:reverse(Integer))
	end.

listtoint(Integer) -> 
	listtoint(Integer,0,0).

listtoint([Head|Tail],Power,Total) ->
	listtoint(Tail,Power+1,Head*math:pow(256,Power)+Total);
listtoint([],_,Total) ->
	trunc(Total).

inttolist(Integer,Size) ->
	inttolist(Integer,Size,0,[],big).

inttolist(Integer,Size,Endian) ->
	inttolist(Integer,Size,0,[],Endian).

inttolist(Integer,Size,Current,Total,Endian) when Current < Size ->
	inttolist(Integer,Size,Current+1,[trunc((Integer rem trunc(math:pow(256,Current+1)))/math:pow(256,Current))|Total],Endian);
inttolist(_,_,_,Total,Endian) ->
	case Endian of
		little ->
			lists:reverse(Total);
		_ ->
			Total
	end.

space(Str,Len) when length(Str) < Len ->
	space(string:concat(Str," "),Len);
space(Str,_) ->
	Str.

md5_hex(S) ->
	Md5_bin =  erlang:md5(S),
	Md5_list = binary_to_list(Md5_bin),
	lists:flatten(list_to_hex(Md5_list)).
	
list_to_hex(L) ->
	lists:map(fun(X) -> int_to_hex(X) end, L).

int_to_hex(N) when N < 256 ->
	[hex(N div 16), hex(N rem 16)].

hex(N) when N < 10 ->
	$0+N;
hex(N) when N >= 10, N < 16 ->
	$a + (N-10).

splitat(List,Splits) ->
	splitat(List,Splits,[],0).

splitat(List,[At|Tail],Total,Start) ->
	{Split,Rest}=lists:split(At-Start,List),
	splitat(Rest,Tail,Total++[Split],At);
splitat(Rest,[],Total,_) when length(Rest) > 0 ->
	Total++[Rest];
splitat(_,[],Total,_) ->
	Total.

addr_to_string({A,B,C,D}) ->
	lists:flatten(io_lib:format("~p.~p.~p.~p",[A,B,C,D])).

wait(Time) ->
	receive
		after 
			Time*1000 ->
				ok
	end.
	

getInfo(Type,Data) ->
	Data ! {Type,self()},
	receive
		{Type,Rest} ->
			Rest
	end.