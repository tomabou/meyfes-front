module Main exposing (main)

import Array
import Browser
import Browser.Events
import Constant exposing (..)
import File exposing (File)
import File.Select as Select
import Graph
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode exposing (Decoder, field, string)
import Task


main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type State
    = NotYet
    | Processing
    | Done


type alias Model =
    { image : Maybe String
    , gridGraph : Graph.Model
    , converteState : State
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( Model Nothing (Graph.initial 30 20) NotYet, Cmd.none )


type Msg
    = ImageRequested
    | ImageSelected File
    | ImageLoaded String
    | ImageConverted (Result Http.Error Graph.GraphInfo)
    | GotGraphMsg Graph.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ImageRequested ->
            ( model, Select.file [ "image/jpeg" ] ImageSelected )

        ImageSelected file ->
            ( model
            , Cmd.batch
                [ Task.perform ImageLoaded
                    (File.toUrl file)
                , Http.post
                    { url = urlPrefix
                    , body = Http.multipartBody [ Http.filePart "image" file ]
                    , expect = Http.expectJson ImageConverted Graph.decoder
                    }
                ]
            )

        ImageLoaded url ->
            ( { model | image = Just url, converteState = Processing }, Cmd.none )

        ImageConverted res ->
            case res of
                Ok graph ->
                    let
                        oldGraph =
                            model.gridGraph

                        newGraph =
                            { oldGraph | vertex = graph.vertex, edgeR = graph.edgeR, edgeC = graph.edgeC }
                    in
                    ( { model | gridGraph = newGraph, converteState = Done }, Cmd.none )

                Err err ->
                    ( model, Cmd.none )

        GotGraphMsg graphMsg ->
            let
                ( graph, cmd ) =
                    Graph.update graphMsg model.gridGraph
            in
            ( { model | gridGraph = graph }, Cmd.map GotGraphMsg cmd )


imageDecoder : Decoder String
imageDecoder =
    field "image_url" (Json.Decode.map ((++) urlPrefix) string)


view : Model -> Html Msg
view model =
    div []
        [ viewHeader model
        , div [ class "wrapper", class "clearfix" ]
            [ main_ [ class "main" ]
                [ viewImage model
                , viewConverted model
                , Html.map GotGraphMsg (Graph.view model.gridGraph)
                ]
            , div [ class "sidemenu" ] []
            ]
        , footer [ class "footer" ] []
        ]


viewHeader : Model -> Html Msg
viewHeader model =
    header [ class "header" ]
        [ h1 [ class "logo", href urlPrefix ]
            [ text "image uploader"
            ]
        ]


viewImage : Model -> Html Msg
viewImage model =
    case model.image of
        Nothing ->
            div [] []

        Just url ->
            div []
                [ img [ src url, width 200 ] []
                ]


viewConverted : Model -> Html Msg
viewConverted model =
    let
        buttonName =
            "btn-flat-border"
    in
    case model.converteState of
        NotYet ->
            button
                [ onClick ImageRequested
                , class buttonName
                ]
                [ text "Load Image" ]

        Processing ->
            div []
                [ text "converting"
                , button
                    [ onClick ImageRequested
                    , class buttonName
                    ]
                    [ text "Reupload Image" ]
                ]

        Done ->
            div []
                [ text "finish!!"
                , button
                    [ onClick ImageRequested
                    , class buttonName
                    ]
                    [ text "Reupload Image" ]
                ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



--    Sub.map GotGraphMsg (Graph.subscriptions model.gridGraph)
