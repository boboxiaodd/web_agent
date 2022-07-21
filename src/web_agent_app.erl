%%%-------------------------------------------------------------------
%% @doc web_agent public API
%% @end
%%%-------------------------------------------------------------------

-module(web_agent_app).

-behaviour(application).

%% Application callbacks
-export([start/0, start/2, stop/1, reload/0]).
-define(ROUTER, [
    {'_',
        [
            {"/api/[...]", api_router, []}
        ]
    }
]).
start() ->
    application:start(web_agent).

%%====================================================================
%% API
%%====================================================================

start(_StartType, _StartArgs) ->
    lager:start(),
    inets:start(),
    application:ensure_all_started(cowboy),

    Port = application:get_env(web_agent, port, 8000),
    Dispatch = cowboy_router:compile(?ROUTER),
    {ok, HTTPPId} = cowboy:start_clear(my_web_agent_listener,
        [{port, Port}],
        #{env => #{dispatch => Dispatch}, request_timeout => 120000, max_keepalive => 200}
    ),
    lager:info(server_common:colorformat(magenta, "start http server ~p :~p"), [Port, HTTPPId]),
    {ok, HTTPPId}.

%%--------------------------------------------------------------------
stop(_State) ->
    ok.

reload() ->
    Dispatch = cowboy_router:compile(?ROUTER),
    cowboy:set_env(my_web_agent_listener, dispatch, Dispatch),
    lager:info(server_common:colorformat(red, "web_agent RELOAD")).

%%====================================================================
%% Internal functions
%%====================================================================
