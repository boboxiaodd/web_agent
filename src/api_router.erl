%%%-------------------------------------------------------------------
%%% @author linhaibo
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. Mar 2019 3:46 PM
%%%-------------------------------------------------------------------
-module(api_router).
-author("bobo").

-export([init/2, terminate/3]).
-define(CHS(Str), unicode:characters_to_binary(Str)).

init(Req, Opts) ->
    Path = cowboy_req:path(Req),
    Method = cowboy_req:method(Req),
    Ip = cowboy_req:peer(Req),
    %lager:info("~p",[Req]),
    put(ip, Ip),
    put(method, Method),
    put(path, Path),
    Response = try
                   Data = get_data(Req),
		   lager:info("recv data:~p",[Data]),
                   router(Data)
               catch
                   _:Reason:Trace ->
                       case Reason of
                           {error, Type} ->
                               lager:error("Request ~p Failed => ~p", [Path, Type]),
                               Type;
                           _ ->
                               lager:error("Request ~p Failed => ~p, ~p", [Path, Reason, Trace]),
                               bad_arguments
                       end
               end,
    response(Response, Req),
    {ok, Req, Opts}.

terminate(_Reason, _Req, _State) ->
    %lager:info(server_common:colorformat(blackb, "process terminate with reason:~p"), [Reason]),
    ok.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Private Function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

router(Data) ->
    case binary:split(get(path), <<"/">>, [global]) of
        [_, _, BinModule | BinControl] ->
            Mod = binary_to_existing_atom(<<BinModule/binary, "_control">>, latin1),
            BinControl1 = list_to_binary(BinControl),
            Fun = try
                      binary_to_existing_atom(<<"handle_", BinControl1/binary>>, latin1)
                  catch
                      _:_ ->
                          lager:info(server_common:colorformat(blackb, "can find ~p:handle_~s and retry..."), [Mod, BinControl1]),
                          _ = Mod:module_info(exports),
                          binary_to_existing_atom(<<"handle_", BinControl1/binary>>, latin1)
                  end,
            lager:info("call ~p:~p:~p",[Mod,Fun,Data]),
            apply(Mod, Fun, [Data]);
        _ -> throw({error, bad_command})
    end.

parse_data(<<"POST">>, true, Req0) ->
    case cowboy_req:read_body(Req0) of
        {ok, Body, _} ->
            try
                jiffy:decode(Body, [return_maps])
            catch
                _:_ ->
                    lager:error(server_common:colorformat(red, "bad json:~p"), [Body]),
                    throw({error, bad_json})
            end;
        Error ->
            lager:error(server_common:colorformat(red, "Bad HTTP Request Body! ~p"), [Error]),
            throw({error, error_body})
    end;

parse_data(<<"POST">>, false, _Req0) ->
    #{};

parse_data(<<"GET">>, _, Req0) ->
    List = cowboy_req:parse_qs(Req0),
    maps:from_list(List);

parse_data(_Method, _, _Req) ->
    throw({error, method_not_allow}).


response(ErrorType, Req) when is_atom(ErrorType) ->
    case ErrorType of
        bad_command ->
            cowboy_req:reply(404, Req);
        method_not_allow ->
            cowboy_req:reply(405, Req);
        undefined ->
            cowboy_req:reply(400, Req);
        _ ->
            response(#{ok => 0, msg => server_common:to_binary(ErrorType) }, Req)
    end;

response(#{ok := 303, url := Url}, Req) ->
    cowboy_req:reply(303, #{<<"location">> => list_to_binary(Url)}, <<>>, Req);

response(Response, Req) ->
    case Response of
        #{list := L} ->
            lager:info(server_common:colorformat(green, "SEND Data: ~p"), [Response#{list => length(L)}]);
        _ ->
            lager:info(server_common:colorformat(green, "SEND Data: ~p"), [Response])
    end,
    Reply = jiffy:encode(Response),
    cowboy_req:reply(200, #{
        <<"content-type">> => <<"application/json">>
    }, Reply, Req).

get_data(Req) ->
    case get(method) of
        <<"POST">> ->
            HasBody = cowboy_req:has_body(Req),
            parse_data(<<"POST">>, HasBody, Req);
        Method ->
            parse_data(Method, false, Req)
    end.
