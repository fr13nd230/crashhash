-module(crashhash).
-export([session/2, server/1, start/0]).

start() ->
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
    case gen_tcp:accept(LSock) of
        {ok, Sock} -> 
            spawn(?MODULE, session, [{command, <<>>}, Sock]),
            server(LSock);
        {error, closed} ->
            io:format("[SERVER] Connection has been closed from client.", []),
            gen_tcp:close(LSock);
        {error, Reason} ->
            io:format("[ERROR] Unable to accept listening socket ~p~n", [Reason]),
            gen_tcp:close(LSock)
    end,
    server(LSock).

session({command, _}, Sock) ->
    case gen_tcp:recv(Sock, 0) of
            {ok, <<"CLOSE\r\n>>"} -> 
                gen_tcp:send("[SERVER] Sorry to see you leave, see ya!"),
                gen_tcp:close();
            {ok, <<"PUB\r\n", Buffs/binary>>} -> 
                session({pub, Buffs}, Sock);
            {ok, _} ->
                gen_tcp:send("[ERROR] Invalid command you have provided."),
                session({command, <<>>}, Sock);
            {error, Reason} -> 
                io:format("[ERROR] Unable to receive data from remote ~p~n", [Reason]),
                gen_tcp:close()
    end;
session({pub, Buffs}, Sock) ->
    case gen_tcp:recv(Sock, 0) of
            {ok, <<"DONE\r\n">>} -> 
                session({command, <<>>}, Sock);
            {ok, Line} -> 
                session({pub, <<Buffs/binary, Line/binary>>}, Sock);
            {error, Reason} -> 
                io:format("[ERROR] Unable to receive data from remote ~p~n", [Reason]),
                gen_tcp:close()
    end.


% How will carshhash works as low level PoW concept?
% PUB\r\n
% text
% in
% here
% ...
% DONE <<< we are here now
% CHALLENGE <hash>

% READ <id>
% CLOSE <<< done
%
% Only Commands Are [PUB, READ, CLOSE]
%                     ^             ^
%                     done          done
