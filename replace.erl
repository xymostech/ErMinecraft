-module (replace).
-export ([replaceFun/2,setReplace/3]).

replaceFun([{ToReplace,ReplaceWith}|Tail],Using) -> 
	if 
		ToReplace == Using -> 
			ReplaceWith;
		true -> 
			replaceFun(Tail,Using)
	end;
replaceFun([],Using) ->
	Using.

setReplace(ReplaceTable,Change,To) ->
	setReplace(ReplaceTable,Change,To,[]).

setReplace([{ToReplace,ReplaceWith}|Tail],Change,To,Total) ->
	if
		ToReplace == Change ->
			Total ++ [{Change,To}] ++ Tail;
		true ->
			setReplace(Tail,Change,To,Total++[{ToReplace,ReplaceWith}])
	end;
setReplace([],Change,To,Total) ->
	Total ++ [{Change,To}].