%%%-------------------------------------------------------------------
%%% @author linhaibo
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. Mar 2019 3:59 PM
%%%-------------------------------------------------------------------
-module(mqtt_control).
-author("linhaibo").
%%-record(vmq_msg, {
%%    msg_ref,
%%    routing_key,
%%    payload,
%%    retain,
%%    dup = false,
%%    qos,
%%    mountpoint,
%%    persisted = false,
%%    sg_policy = prefer_local,
%%    properties = #{} :: map(),
%%    expiry_ts
%%}).

-record(vmq_msg, {
    msg_ref,%:: msg_ref() | 'undefined', % OTP-12719
    routing_key,%:: routing_key() | 'undefined',
    payload,%:: payload() | 'undefined',
    retain = false,%:: flag(),
    dup = false,%:: flag(),
    qos,%:: qos(),
    mountpoint,%:: mountpoint(),
    persisted = false,%:: flag(),
    sg_policy = prefer_local,%:: shared_sub_policy(),
    %% TODOv5: need to import the mqtt5 property typespec?
    properties = #{},%:: map(),
    expiry_ts             %:: undefined | msg_expiry_ts()
}).

-define(REGVIEW, vmq_reg_trie).
%%-define(MQTT_NODE, 'VerneMQ1@10.1.1.18').
%% API
-export([
    handle_sub/1,
    handle_unsub/1,
    handle_pub/1,
    handle_unsub_all/1
]).

handle_sub(#{<<"topics">> := Topics, <<"client_id">> := ClientId}) ->
    NewTopics = lists:map(fun(#{<<"topic">> := Topic, <<"qos">> := Qos}) ->
        {binary:split(Topic, <<"/">>, [global]), Qos}
                          end, Topics),
    SubscriberId = {"", ClientId},
    {ok,Node} = application:get_env(web_agent, mqtt_node),
    rpc:cast(Node, vmq_reg, subscribe, [true, SubscriberId, NewTopics]),
    #{ok => 1}.

handle_unsub(#{<<"topics">> := Topics, <<"client_id">> := ClientId}) ->
    NewTopics = lists:map(fun(#{<<"topic">> := Topic, <<"qos">> := _Qos}) ->
        binary:split(Topic, <<"/">>, [global])
                          end, Topics),
    SubscriberId = {"", ClientId},
    {ok, Node} = application:get_env(web_agent, mqtt_node),
    Res = rpc:call(Node, vmq_reg, unsubscribe, [true, SubscriberId, NewTopics]),
    lager:info("unsubscribe res:~p",[Res]),
    #{ok =>1}.

handle_unsub_all(#{<<"client_id">> := ClientId}) ->
    SubscriberId = {"", ClientId},
    {ok, Node } = application:get_env(web_agent, mqtt_node),
    rpc:cast(Node, vmq_reg, delete_subscriptions, [SubscriberId]),
    #{ok =>1}.

handle_pub(#{<<"topic">> := Topic, <<"payload">> := Payload}) ->
    NewTopic = binary:split(Topic, <<"/">>, [global]),
    {ok ,Node} = application:get_env(web_agent, mqtt_node),
    Res = rpc:call(Node, vmq_reg, publish, [true, ?REGVIEW, <<"c_10000000">>,
        #vmq_msg{
            msg_ref = uuid_server:get_uuid(),
            mountpoint = "",
            routing_key = NewTopic,
            payload = Payload,
            qos = 2}
    ]),
    lager:info("pub result:~p",[Res]),
    #{ok => 1}.


