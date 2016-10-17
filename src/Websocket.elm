effect module Websocket
    where { command = MyCmd, subscription = MySub }
    exposing
        ( connect
        , send
        , disconnect
        , listen
        , Url
        , Message
        , ErrorMessage
        )

{-| Websocket Client Effects Manager

The native driver is browser-based

# Commands
@docs connect, send, disconnect

# Subscriptions
@docs listen

# Types
@docs Url, Message, ErrorMessage

-}

import Dict exposing (Dict)
import Task exposing (Task)
import DebugF exposing (log, toStringF)
import Native.Websocket


-- API


type MyCmd msg
    = Connect (ConnectErrorTagger msg) (ConnectTagger msg) Url
    | Send (SendErrorTagger msg) (SendTagger msg) Url String
    | Disconnect (DisconnectErrorTagger msg) (DisconnectTagger msg) Url


type MySub msg
    = Listen (ListenErrorTagger msg) (MessageTagger msg) (ConnectionClosedTagger msg) Url



-- Types


{-| Native structure (opaque type)
-}
type Websocket
    = Websocket


{-| Websocket url type
-}
type alias Url =
    String


{-| Websocket message type
-}
type alias Message =
    String


{-| Websocket error message type
-}
type alias ErrorMessage =
    String



-- Taggers


type alias ConnectErrorTagger msg =
    ( Url, ErrorMessage ) -> msg


type alias ConnectTagger msg =
    Url -> msg


type alias SendErrorTagger msg =
    ( Url, Message, ErrorMessage ) -> msg


type alias SendTagger msg =
    ( Url, Message ) -> msg


type alias DisconnectErrorTagger msg =
    ( Url, ErrorMessage ) -> msg


type alias DisconnectTagger msg =
    Url -> msg


type alias ListenErrorTagger msg =
    ( Url, ErrorMessage ) -> msg


type alias MessageTagger msg =
    ( Url, Message ) -> msg


type alias ConnectionClosedTagger msg =
    Url -> msg



-- State


type alias ConnectionDict =
    Dict Url (Maybe Websocket)


type alias Listener msg =
    { messageTagger : MessageTagger msg
    , connectionClosedTagger : ConnectionClosedTagger msg
    }


type alias ListenerDict msg =
    Dict Url (Listener msg)


{-| Effects manager state
-}
type alias State msg =
    { connections : ConnectionDict
    , listeners : ListenerDict msg
    }



-- Operators


(?=) : Maybe a -> a -> a
(?=) =
    flip Maybe.withDefault


{-| lazy version of // operator
-}
(?!=) : Maybe a -> (() -> a) -> a
(?!=) maybe lazy =
    case maybe of
        Just x ->
            x

        Nothing ->
            lazy ()


(|?>) : Maybe a -> (a -> b) -> Maybe b
(|?>) =
    flip Maybe.map


(&>) : Task x a -> Task x b -> Task x b
(&>) t1 t2 =
    t1 `Task.andThen` \_ -> t2


(&>>) : Task x a -> (a -> Task x b) -> Task x b
(&>>) t1 f =
    t1 `Task.andThen` f



-- Init


init : Task Never (State msg)
init =
    Task.succeed
        { connections = Dict.empty
        , listeners = Dict.empty
        }



-- Cmds


cmdMap : (a -> b) -> MyCmd a -> MyCmd b
cmdMap f cmd =
    case cmd of
        Connect errorTagger tagger url ->
            Connect (f << errorTagger) (f << tagger) url

        Send errorTagger tagger url message ->
            Send (f << errorTagger) (f << tagger) url message

        Disconnect errorTagger tagger url ->
            Disconnect (f << errorTagger) (f << tagger) url


{-| Connect to a Websocket Server

    Usage:
        Websocket.connect ConnectError Connect "wss://echo.websocket.org"

    where:
        ConnectError and Connect are your application's messages to handle the different scenarios
-}
connect : ConnectErrorTagger msg -> ConnectTagger msg -> Url -> Cmd msg
connect errorTagger tagger url =
    command (Connect errorTagger tagger url)


{-| Send a message to the Websocket Server

    Usage:
        Websocket.send SendError Sent "wss://echo.websocket.org" "a string message"

    where:
        SendError and Sent are your application's messages to handle the different scenarios
-}
send : SendErrorTagger msg -> SendTagger msg -> Url -> String -> Cmd msg
send errorTagger tagger url message =
    command (Send errorTagger tagger url message)


{-| Disconnect from a Websocket Server

    Usage:
        disconnect ErrorDisconnect SuccessDisconnect "wss://echo.websocket.org"

    where:
        ErrorDisconnect and SuccessDisconnect are your application's messages to handle the different scenarios
-}
disconnect : DisconnectErrorTagger msg -> DisconnectTagger msg -> Url -> Cmd msg
disconnect errorTagger tagger url =
    command (Disconnect errorTagger tagger url)



-- Subs


subMap : (a -> b) -> MySub a -> MySub b
subMap f sub =
    case sub of
        Listen errorTagger messageTagger connectionClosedTagger url ->
            Listen (f << errorTagger) (f << messageTagger) (f << connectionClosedTagger) url


{-| Listen for messages and events from a Websocket Server

    Usage:
        Websocket.listen ListenError Message ConnectionLost "wss://echo.websocket.org"

    where:
        ListenError is your application's message to handle an error in listening
        Message is your application's message to handle received messages
        ConnectionLost is your application's message to handle when the server closes it's connection
-}
listen : ListenErrorTagger msg -> MessageTagger msg -> ConnectionClosedTagger msg -> Url -> Sub msg
listen errorTagger messageTagger connectionClosedTagger url =
    subscription (Listen errorTagger messageTagger connectionClosedTagger url)



-- effect managers API


onEffects : Platform.Router msg (Msg msg) -> List (MyCmd msg) -> List (MySub msg) -> State msg -> Task Never (State msg)
onEffects router cmds newSubs state =
    let
        ( newSubsDict, subErrorTasks ) =
            List.foldl (addMySub router state) ( Dict.empty, [] ) newSubs

        oldListeners =
            Dict.diff state.listeners newSubsDict

        newListeners =
            Dict.diff newSubsDict state.listeners

        keepListeners =
            Dict.intersect state.listeners newSubsDict

        handleOneCmd state cmd tasks =
            let
                ( task, newState ) =
                    handleCmd router state cmd
            in
                ( task :: tasks, newState )

        ( tasks, cmdState ) =
            List.foldl (\cmd ( tasks, state ) -> handleOneCmd state cmd tasks) ( [], state ) cmds
    in
        Task.sequence (List.reverse <| tasks)
            &> Task.sequence (List.reverse <| subErrorTasks)
            &> Task.succeed { cmdState | listeners = Dict.union keepListeners newListeners }


addMySub : Platform.Router msg (Msg msg) -> State msg -> MySub msg -> ( ListenerDict msg, List (Task x ()) ) -> ( ListenerDict msg, List (Task x ()) )
addMySub router state sub ( dict, errorTasks ) =
    case sub of
        Listen errorTagger messageTagger connectionClosedTagger url ->
            let
                newSub =
                    { messageTagger = messageTagger
                    , connectionClosedTagger = connectionClosedTagger
                    }

                newErrorTasks =
                    Dict.get url dict
                        |?> (\_ -> Platform.sendToApp router (errorTagger ( url, "Listener already exists" )) :: errorTasks)
                        ?= errorTasks
            in
                ( Dict.insert url newSub dict, newErrorTasks )


settings0 : Platform.Router msg (Msg msg) -> (a -> Msg msg) -> Msg msg -> { onError : a -> Task msg (), onSuccess : Never -> Task x () }
settings0 router errorTagger tagger =
    { onError = \err -> Platform.sendToSelf router (errorTagger err)
    , onSuccess = \_ -> Platform.sendToSelf router tagger
    }


settings1 : Platform.Router msg (Msg msg) -> (a -> Msg msg) -> (b -> Msg msg) -> { onError : a -> Task Never (), onSuccess : b -> Task x () }
settings1 router errorTagger tagger =
    { onError = \err -> Platform.sendToSelf router (errorTagger err)
    , onSuccess = \result1 -> Platform.sendToSelf router (tagger result1)
    }


settings2 : Platform.Router msg (Msg msg) -> (a -> Msg msg) -> (b -> c -> Msg msg) -> { onError : a -> Task Never (), onSuccess : b -> c -> Task x () }
settings2 router errorTagger tagger =
    { onError = \err -> Platform.sendToSelf router (errorTagger err)
    , onSuccess = \result1 result2 -> Platform.sendToSelf router (tagger result1 result2)
    }


handleCmd : Platform.Router msg (Msg msg) -> State msg -> MyCmd msg -> ( Task Never (), State msg )
handleCmd router state cmd =
    case cmd of
        Connect errorTagger tagger url ->
            let
                openCb url ws =
                    Platform.sendToSelf router <| SuccessConnect tagger url ws

                messageCb message =
                    Platform.sendToSelf router (Message url message)

                connectionClosedCb _ =
                    Platform.sendToSelf router <| ConnectionClosed url
            in
                (Dict.get url state.connections)
                    |?> (\_ -> ( Platform.sendToApp router (errorTagger ( url, "Connection already exists for specified url: " ++ (toString url) )), state ))
                    ?= ( Native.Websocket.connect (settings0 router (ErrorConnect errorTagger url) Nop) url openCb messageCb connectionClosedCb
                       , { state | connections = Dict.insert url Nothing state.connections }
                       )

        Send errorTagger tagger url message ->
            let
                error errMsg =
                    Platform.sendToApp router (errorTagger ( url, message, errMsg ))
            in
                ( (Dict.get url state.connections)
                    |?> (\maybeWs ->
                            maybeWs
                                |?> (\ws -> Native.Websocket.send (settings0 router (ErrorSend errorTagger url message) (SuccessSend tagger url message)) ws message)
                                ?= error ("Connection pending for specified url: " ++ (toString url))
                        )
                    ?= error ("Connection does not exists for specified url: " ++ (toString url))
                , state
                )

        Disconnect errorTagger tagger url ->
            ( Task.succeed (), state )


crashTask : a -> String -> Task Never a
crashTask x msg =
    let
        crash =
            Debug.crash msg
    in
        Task.succeed x


printableState : State msg -> State msg
printableState state =
    state


withConnection : State msg -> Url -> (Maybe Websocket -> Task Never (State msg)) -> Task Never (State msg)
withConnection state url f =
    Dict.get url state.connections
        |?> f
        ?!= (\_ -> (crashTask state <| "Connection for url '" ++ url ++ "' is not in state: " ++ (toStringF <| printableState state)))


updateConnection : Url -> Websocket -> State msg -> State msg
updateConnection url ws state =
    { state | connections = Dict.insert url (Just ws) state.connections }


removeConnection : Url -> State msg -> State msg
removeConnection url state =
    { state | connections = Dict.remove url state.connections }


type Msg msg
    = Nop
    | ErrorConnect (ConnectErrorTagger msg) Url ErrorMessage
    | SuccessConnect (ConnectTagger msg) Url Websocket
    | Message Url Message
    | ErrorSend (SendErrorTagger msg) Url Message ErrorMessage
    | SuccessSend (SendTagger msg) Url Message
    | ConnectionClosed Url


onSelfMsg : Platform.Router msg (Msg msg) -> Msg msg -> State msg -> Task Never (State msg)
onSelfMsg router selfMsg state =
    case selfMsg of
        Nop ->
            Task.succeed state

        ErrorConnect errorTagger url err ->
            (withConnection state url)
                (\connection ->
                    Platform.sendToApp router (errorTagger ( url, err ))
                        &> Task.succeed (removeConnection url state)
                )

        SuccessConnect tagger url ws ->
            (withConnection state url)
                (\connection ->
                    Platform.sendToApp router (tagger url)
                        &> Task.succeed (updateConnection url ws state)
                )

        Message url message ->
            (Dict.get url state.listeners)
                |?> (\listener -> Platform.sendToApp router (listener.messageTagger ( url, message )))
                ?= Task.succeed ()
                &> Task.succeed state

        ErrorSend errorTagger url message error ->
            Platform.sendToApp router (errorTagger ( url, message, error ))
                &> Task.succeed state

        SuccessSend tagger url message ->
            Platform.sendToApp router (tagger ( url, message ))
                &> Task.succeed state

        ConnectionClosed url ->
            (Dict.get url state.listeners)
                |?> (\listener -> Platform.sendToApp router (listener.connectionClosedTagger url))
                ?= Task.succeed ()
                &> Task.succeed state
