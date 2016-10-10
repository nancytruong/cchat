-module(server).
-export([handle/2, initial_state/1]).
-include_lib("./defs.hrl").

%% inititial_state/2 and handle/2 are used togetger with the genserver module,
%% explained in the lecture about Generic server.

% Produce initial state
initial_state(ServerName) ->
    #server_st{serverName = ServerName, channels = [], clientNames = []}.

initial_cState(ChatroomName, ServerName, ClientName) ->
  #chatroom_st{name = ChatroomName, clients = [ClientName], serverName = ServerName}.

%% ---------------------------------------------------------------------------

%% handle/2 handles requests from clients

%% All requests are processed by handle/2 receiving the request data (and the
%% current state), performing the needed actions, and returning a tuple
%% {reply, Reply, NewState}, where Reply is the reply to be sent to the client
%% and NewState is the new state of the server.

handle(St, Request) ->
  % io:fwrite("Request ~p~n", [Request]),
  case Request of
    {connect, ClientName} ->
      case lists:any(fun(e) -> e == ClientName end, St#server_st.clientNames) of
        true ->
          Response = user_already_connected,
          NewSt = St;
        false ->
          io:fwrite("clientName = " ++ ClientName ++ "~n"),
          NewSt = St#server_st{clientNames = St#server_st.clientNames ++ [ClientName]},
          Response = "connected"
      end;

    {disconnect, ClientName} ->
      Response = "disconnected",
      NewSt = St#server_st{clientNames = lists:delete(ClientName, clientNames)};
    {join, Channel, ClientName} ->
      ChannelAtom = list_to_atom(Channel),
      case lists:any(fun(e) -> e == Channel end, St#server_st.channels) of
        true -> % it does exist
          % call genserver:request with the channel name to add the client to client list
          Response = genserver:request(ChannelAtom, {addClient, ChannelAtom, ClientName}),
          NewSt = St;
        false -> % it does NOT exist yet
          genserver:start(ChannelAtom, initial_cState(ChannelAtom, St#server_st.serverName, ClientName), fun handle_chat/2),
          NewSt = St#server_st{channels = St#server_st.channels ++ [ChannelAtom]},
          Response = "joined"
      end;
    {leave, Channel} ->
      Response = "left",
      NewSt = St;
    {msg_from_GUI, Channel, Msg} ->
      Response = "Connected to shire",
      NewSt = St;
    {nick, Nick} ->
      Response = "Changed nickname",
      NewSt = St
    end,
    {reply, Response, NewSt}.

handle_chat(St, Request) ->
  case Request of
    {addClient, ChannelAtom, ClientName} ->
      case lists:any(fun(e) -> e == ClientName end, St#chatroom_st.clients) of
        true ->
          NewSt = St,
          Response = "already joined";
        false ->
          NewSt = St#chatroom_st{clients = St#chatroom_st.clients ++ [ClientName]},
          Response = "successfully joined"
      end
  end,
  {reply, Response, NewSt}.
