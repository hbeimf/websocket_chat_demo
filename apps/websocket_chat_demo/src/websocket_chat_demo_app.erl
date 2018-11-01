%%%-------------------------------------------------------------------
%% @doc websocket_chat_demo public API
%% @end
%%%-------------------------------------------------------------------

-module(websocket_chat_demo_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).


-include_lib("stdlib/include/qlc.hrl").
%% 定义记录结构
-include("table.hrl").


%%====================================================================
%% API
%%====================================================================

start(_StartType, _StartArgs) ->
	case mnesia:create_schema([node()]) of
    		ok -> 
			    mnesia:start(),
			    mnesia:create_table(client_list, [{attributes,record_info(fields,client_list)}]),
			    ok;
		  _ -> 
		  	mnesia:start()
	 end,

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
