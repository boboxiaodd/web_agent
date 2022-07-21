%%%-------------------------------------------------------------------
%%% @author linhaibo
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 25. 八月 2018 下午11:32
%%%-------------------------------------------------------------------
-module(server_common).
-author("linhaibo").
%% API
-export([
    colorformat/2,
    to_list/1,
    to_integer/1,
    to_float/1,
    to_binary/1,
    get_timestamp/0,
    get_timestamp/1,
    md5_hex/1
]).

%%TOOL################################################################################################################

md5_hex(S) ->
    Md5_bin = erlang:md5(S),
    Md5_list = binary_to_list(Md5_bin),
    lists:flatten(list_to_hex(Md5_list)).
list_to_hex(L) -> lists:map(fun(X) -> int_to_hex(X) end, L).
int_to_hex(N) when N < 256 -> [hex(N div 16), hex(N rem 16)].
hex(N) when N < 10 -> $0 + N;
hex(N) when N >= 10, N < 16 -> $a + (N - 10).

to_list(A) when is_binary(A) -> binary_to_list(A);
to_list(A) when is_list(A) -> A;
to_list(A) when is_integer(A) -> integer_to_list(A);
to_list(A) when is_float(A) -> float_to_list(A, [{decimals, 2}]);
to_list(A) -> A.

to_integer(A) when is_binary(A) ->
    if
        A == <<"null">>; A == <<"">> ->
            0;
        true ->
            binary_to_integer(A)
    end;
to_integer(A) when is_list(A) -> list_to_integer(A);
to_integer(A) -> A.

to_binary(A) when is_integer(A) -> integer_to_binary(A);
to_binary(A) when is_list(A) -> list_to_binary(A);
to_binary(A) when is_float(A) -> float_to_binary(A);
to_binary(A) when is_atom(A) -> atom_to_binary(A,latin1);
to_binary(A) -> A.

to_float(A) when is_binary(A) -> binary_to_float(A);
to_float(A) -> A.



colorformat(F, Formater) ->
    [A, T, E] = apply(color, F, [Formater]),
    string:join([pid_to_list(self()), " ", binary_to_list(A), T, binary_to_list(E)], "").

get_timestamp() ->
    get_timestamp(second).

get_timestamp(Type) ->
    os:system_time(Type).
%%#############################################################################################################
