-module(crashhash).
-export([command/2, server/1, kickstart/0]).

kickstart() ->
    ListenAddr = "127.0.0.1",
    ListenPort = 6767,
    {ok, IP} = inet:parse_address(ListenAddr),
    case gen_tcp:listen(ListenPort, [{ip, IP}, binary, {reuseaddr, true}, {active, false}]) of
        {ok, LSock} -> 
            {ok, Sock} = gen_tcp:accept(LSock),
            Pid = spawn(?MODULE, server, [Sock]),
            {ok, Pid};
        {error, Reason} ->
            io:format("[ERROR] Server could not listen, reason: ~p~n", [Reason]),
            error;
        _ -> 
            io:format("[ERROR] Server got unknown error. ~n"),
            unknown
    end.

server(Sock) ->   
    {{UTC_Year, UTC_Month, UTC_Day}, {UTC_Hour, UTC_Minute, _}} = calendar:universal_time(),
    gen_tcp:send(Sock, io_lib:format("[SERVER] Welcome to crashhash, current time: ~w-~w-~w at ~w:~w~n", 
                                         [UTC_Year, UTC_Month, UTC_Day, UTC_Hour, UTC_Minute])),
    {_, Data} = gen_tcp:recv(Sock, 0),
    spawn(?MODULE, command, [Sock, Data]),
    ok.

command(Sock, Command) ->
    case Command of
        <<"CLOSE\r\n">> -> 
            gen_tcp:send(Sock, io_lib:format("[SERVER] Sorry to see you leave so soon! Adios. ~n", [])),
            gen_tcp:close(Sock),
            closed;
        _ -> 
            gen_tcp:send(Sock, io_lib:format("[ERROR] Invalid provided command status 1. ~n", [])),
            gen_tcp:close(Sock),
            invalid
    end.


% How will carshhash works as low level PoW concept?
% SYN\r\n
% text
% in
% here
% ...
% ACK
% DO <hash>
% YES <suffix + hash>

% SEE <id>

% CLOSE -> Send a close to server and kills connection immediately
