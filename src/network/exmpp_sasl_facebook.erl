%% The contents of this file are subject to the Erlang Public License,
%% Version 1.1, (the "License"); you may not use this file except in
%% compliance with the License. You should have received a copy of the
%% Erlang Public License along with this software. If not, it can be
%% retrieved online at http://www.erlang.org/.
%%
%% Software distributed under the License is distributed on an "AS IS"
%% basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
%% the License for the specific language governing rights and limitations
%% under the License.

-module(exmpp_sasl_facebook).

-export([
	 mech_client_new/2,
	 mech_step/2]).


%% @type mechstate() = {state, Step, AccessToken, AppId}
%%     Step = 1 | 2
%%     AccessToken = string()
%%     AppId = string()

-record(state, {step, access_token, app_id}).

mech_client_new(AccessToken, AppId) ->
    {ok, #state{step = 1,
                access_token = AccessToken,
                app_id = AppId
		}}.

%% @spec (State, ClientIn) -> Ok | Continue | Error
%%     State = mechstate()
%%     ClientIn = string()
%%     Ok = {ok, Props}
%%         Props = [Prop]
%%         Prop = {nonce, Nonce} | {method, Method}
%%         Nonce = string()
%%         Method = string()
%%     Continue = {continue, ServerOut, New_State}
%%         ServerOut = string()
%%         New_State = mechstate()
%%     Error = {error, Reason} | {error, Reason}
%%         Reason = term()

mech_step(#state{step = 1, access_token = AccessToken, app_id = AppId} = State, ServerOut) ->
    case parse(ServerOut) of
        bad ->
            {error, 'bad-protocol'};
        KeyVals ->
            Nonce = proplists:get_value("nonce", KeyVals),
            Method = proplists:get_value("method", KeyVals),
            CallId = integer_to_list(element(2, now())),
            {continue,
             string:join(["method=" ++ Method,
                          "api_key=" ++ AppId,
                          "access_token=" ++ AccessToken,
                          "call_id=" ++ CallId,
                          "v=1.0",
                          "nonce=" ++ Nonce], "&"),
             State#state{step = 2}}
    end;
mech_step(#state{step = 2}, ServerOut) ->
    io:format("sout: ~p~n", [ServerOut]),
    {ok, []};
mech_step(_A, _B) ->
    {error, 'bad-protocol'}.

%% @spec (S) -> [{Key, Value}] | bad
%%     S = string()
%%     Key = string()
%%     Value = string()

parse(S) ->
    try
        [list_to_tuple(string:tokens(Pair, "=")) || Pair <- string:tokens(S, "&")]
    catch
        _Class:_Error -> bad
    end.
