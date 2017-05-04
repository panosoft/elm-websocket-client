port module Test.Node.App exposing (..)

import Platform
import Task
import Process
import Time exposing (Time)
import Websocket exposing (..)


port exitApp : Float -> Cmd msg


type alias Model =
    { connected : Bool
    , input : String
    , messages : List String
    , url : String
    , listenError : Bool
    }


type Msg
    = Nop
    | ConnectError ( Url, ( ConnectErrorCode, ErrorMessage ) )
    | Connect Url
    | SendError ( Url, Message, ErrorMessage )
    | Sent ( Url, Message )
    | SendMessage String
    | ListenError ( Url, ErrorMessage )
    | Message ( Url, Message )
    | ConnectionLost Url


initModel : Model
initModel =
    { connected = False
    , input = ""
    , messages = []
    , url = "ws://localhost:8080"
    , listenError = False
    }


init : ( Model, Cmd Msg )
init =
    let
        model =
            initModel
    in
        model ! [ Websocket.connect ConnectError Connect model.url ]


main : Program Never Model Msg
main =
    Platform.program
        { init = init
        , update = update
        , subscriptions = subscriptions
        }


delayUpdateMsg : Time -> Msg -> Cmd Msg
delayUpdateMsg delay msg =
    Task.perform (\_ -> msg) <| Process.sleep delay


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Nop ->
            model ! []

        ConnectError ( url, error ) ->
            let
                l =
                    Debug.log "ConnectError" ( url, error )
            in
                model ! []

        Connect url ->
            let
                l =
                    Debug.log "Connect" url
            in
                { model | connected = True } ! [ delayUpdateMsg 0 <| SendMessage "test" ]

        SendError ( url, message, error ) ->
            let
                l =
                    Debug.log "SendError" ( url, message, error )
            in
                model ! []

        Sent ( url, message ) ->
            let
                l =
                    Debug.log "Sent" ( url, message )
            in
                model ! []

        SendMessage message ->
            model ! [ Websocket.send SendError Sent model.url message ]

        ListenError ( url, error ) ->
            let
                l =
                    Debug.log "ListenError" ( url, error )
            in
                { model | listenError = True } ! []

        Message ( url, message ) ->
            let
                l =
                    Debug.log "Message" ( url, message )
            in
                model ! []

        ConnectionLost url ->
            let
                l =
                    Debug.log "ConnectionLost" url
            in
                { model | connected = False } ! []


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.listenError of
        False ->
            Websocket.listen ListenError Message ConnectionLost model.url

        True ->
            Sub.none
