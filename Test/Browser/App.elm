module Test.App exposing (..)

import Platform
import String
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Websocket exposing (..)


type alias Model =
    { connected : Bool
    , input : String
    , messages : List String
    , url : String
    , listenError : Bool
    }


type Msg
    = Nop
    | ConnectError ( Url, ErrorMessage )
    | Connect Url
    | Input String
    | SendError ( Url, Message, ErrorMessage )
    | Sent ( Url, Message )
    | SendMessage
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
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


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
                { model | connected = True } ! []

        Input newInput ->
            { model | input = newInput } ! []

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

        SendMessage ->
            model ! [ Websocket.send SendError Sent model.url model.input ]

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


view : Model -> Html Msg
view model =
    let
        cannotSend =
            not model.connected || String.isEmpty model.input
    in
        div []
            [ input [ onInput Input, value model.input ] []
            , button [ onClick SendMessage, disabled <| cannotSend ] [ text "Send" ]
            , div [] (List.map viewMessage (List.reverse model.messages))
            ]


viewMessage : String -> Html msg
viewMessage msg =
    div [] [ text msg ]


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.listenError of
        False ->
            Websocket.listen ListenError Message ConnectionLost model.url

        True ->
            Sub.none
