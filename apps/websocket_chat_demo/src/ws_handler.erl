-module(ws_handler).
-behaviour(cowboy_websocket_handler).

-export([init/3]).
-export([websocket_init/3]).
-export([websocket_handle/3]).
-export([websocket_info/3]).
-export([websocket_terminate/3]).
-export([select/0, select/1]).


-include("table.hrl").
-include_lib("stdlib/include/qlc.hrl").
-define(TABLE, client_list).
-define(LOG(X), io:format("~n==========log========{~p,~p}==============~n~p~n", [?MODULE,?LINE,X])).
% -define(LOG(X), true).

do(Q) ->
    F = fun() -> qlc:e(Q) end,
    {atomic,Val} = mnesia:transaction(F),
    Val.

select() ->
    do(qlc:q([X || X <- mnesia:table(?TABLE)])).

select(Uid) ->
    do(qlc:q([X || X <- mnesia:table(?TABLE),
                X#?TABLE.uid =/= Uid
            ])).

add(Uid, Pid) ->
    Row = #?TABLE{uid = Uid, pid = Pid},
    F = fun() ->
            mnesia:write(Row)
    end,
    mnesia:transaction(F).

uid() -> 
	esnowflake:generate_id().

broadcast([], _) -> 
	ok;
broadcast(Clients, Msg) ->
	lists:foreach(fun(Client) -> 
		?LOG({Client#?TABLE.pid, Msg}),
		Client#?TABLE.pid ! {broadcast, Msg}
	end, Clients),
	ok.

init({tcp, http}, _Req, _Opts) ->
	{upgrade, protocol, cowboy_websocket}.

websocket_init(_TransportName, Req, _Opts) ->
	% erlang:start_timer(1000, self(), <<"Hello!">>),
	Uid = uid(),
	?LOG({login, Uid}),
	add(Uid, self()),
	{ok, Req, {state, Uid}}.

websocket_handle({text, Msg}, Req, {_, Uid} = State) ->
	?LOG({Uid, Msg}),
	Clients = select(Uid),
	?LOG(Clients),
	broadcast(Clients, Msg),
	{ok, Req, State};
	% {reply, {text, << "That's what she said! ", Msg/binary >>}, Req, State};
websocket_handle(_Data, Req, State) ->
	?LOG("XX"),
	{ok, Req, State}.

websocket_info({broadcast, Msg}, Req, {_, Uid} = State) ->
	?LOG({broadcast, Msg}),
	{reply, {text, << "That's what she said! ", Msg/binary >>}, Req, State};
websocket_info({timeout, _Ref, Msg}, Req, State) ->
	% erlang:start_timer(1000, self(), <<"How' you doin'?">>),
	{reply, {text, Msg}, Req, State};
websocket_info(_Info, Req, State) ->
	{ok, Req, State}.

websocket_terminate(_Reason, _Req, _State) ->
	ok.
