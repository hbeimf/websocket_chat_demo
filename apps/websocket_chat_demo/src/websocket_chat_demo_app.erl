%%%-------------------------------------------------------------------
%% @doc websocket_chat_demo public API
%% @end
%%%-------------------------------------------------------------------

-module(websocket_chat_demo_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%%====================================================================
%% API
%%====================================================================

start(_StartType, _StartArgs) ->
	Dispatch = cowboy_router:compile([
		{'_', [
			{"/", cowboy_static, {priv_file, websocket_chat_demo, "index.html"}},
			{"/websocket", ws_handler, []},
			{"/static/[...]", cowboy_static, {priv_dir, websocket_chat_demo, "static"}}
		]}
	]),
	{ok, _} = cowboy:start_http(http, 100, [{port, 8899}],
		[{env, [{dispatch, Dispatch}]}]),
    websocket_chat_demo_sup:start_link().

%%--------------------------------------------------------------------
stop(_State) ->
    ok.

%%====================================================================
%% Internal functions
%%====================================================================
