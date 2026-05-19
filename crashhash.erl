-module(crashhash).
-export([command/2, server/1, kickstart/0]).

kickstart() ->
    ListenAddr = "127.0.0.1",
    ListenPort = 6767,
    {ok, IP} = inet:parse_address(ListenAddr),
    case gen_tcp:listen(ListenPort, [{ip, IP}, binary, {reuseaddr, true}, {active, false}]) of
        {ok, LSock} ->
            Pid = spawn(?MODULE, server, [LSock]),
            {ok, Pid};
        {error, Reason} ->
            io:format("[ERROR] Server could not listen, reason: ~p~n", [Reason]),
            error;
        _ ->
            io:format("[ERROR] Server got unknown error.~n"),
            unknown
    end.

server(LSock) ->
    {ok, Sock} = gen_tcp:accept(LSock),
    spawn(fun() -> handle_client(Sock) end),
    server(LSock).

handle_client(Sock) ->
    {{UTC_Year, UTC_Month, UTC_Day}, {UTC_Hour, UTC_Minute, _}} = calendar:universal_time(),
    gen_tcp:send(Sock, io_lib:format(
        "[SERVER] Welcome to crashhash, current time: ~w-~w-~w at ~w:~w~n",
        [UTC_Year, UTC_Month, UTC_Day, UTC_Hour, UTC_Minute]
    )),
    loop(Sock).

loop(Sock) ->
    case gen_tcp:recv(Sock, 0) of
        {ok, <<"CLOSE\r\n">>} ->
            gen_tcp:send(Sock, "[SERVER] Sorry to see you leave so soon! Adios.\n"),
            gen_tcp:close(Sock);

        {ok, <<"READ ", Id/binary>>} ->
            command(Sock, {see, Id}),
            loop(Sock);                          

        {ok, <<"PUB\r\n", Buffs/binary>>} ->
            command(Sock, {pub, Buffs});

        {ok, _} ->
            gen_tcp:send(Sock, "[ERROR] Invalid command.\n"),
            loop(Sock);                         

        {error, closed} ->
            io:format("[SERVER] Client disconnected.~n"),
            gen_tcp:close(Sock);

        {error, Reason} ->
            io:format("[ERROR] Receive failed: ~p~n", [Reason]),
            gen_tcp:close(Sock)
    end.

command(Sock, {read, Id}) ->
    io:format("[SERVER] Received ID: ~p~n", [Id]),
    gen_tcp:send(Sock, io_lib:format("[SERVER] COMMAND ACCEPTED (READ) -> TODO [~w]~n", [Id]));

command(Sock, {pub, Buffs}) ->
    receive 
        {data, Data} ->
            io:format("[SERVER] Received ID: ~p~n", [Buffs]);
        stop ->
            ok,
    end.
% How will carshhash works as low level PoW concept?
% PUB\r\n
% text
% in
% here
% ...
%
% CHALLENGE <hash>
%
% SUB <preffix + hash>

% READ <id>

% CLOSE -> Send a close to server and kills connection immediately
