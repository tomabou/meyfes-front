module Main exposing (main)

import Array
import Browser
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


type alias Model =
    { image : Maybe String
    , convertedImage : Maybe String
    , gridGraph : Graph.Model
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( Model Nothing Nothing (Graph.initial 50 60), Cmd.none )


type Msg
    = ImageRequested
    | ImageSelected File
    | ImageLoaded String
    | ImageConverted (Result Http.Error String)
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
                    { url = "https://tomabou.com"
                    , body = Http.multipartBody [ Http.filePart "image" file ]
                    , expect = Http.expectJson ImageConverted imageDecoder
                    }
                ]
            )

        ImageLoaded url ->
            ( { model | image = Just url }, Cmd.none )

        ImageConverted res ->
            case res of
                Ok url ->
                    ( { model | convertedImage = Just url }, Cmd.none )

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
    field "image_url" string


view : Model -> Html Msg
view model =
    div []
        [ viewHeader model
        , div [ class "wrapper", class "clearfix" ]
            [ main_ [ class "main" ]
                [ viewImage model
                , Html.map GotGraphMsg (Graph.view model.gridGraph)
                ]
            , div [ class "sidemenu" ] []
            ]
        , footer [ class "footer" ] []
        ]


viewHeader : Model -> Html Msg
viewHeader model =
    header [ class "header" ]
        [ h1 [ class "logo", href "https://tomabou.com" ]
            [ text "image uploader"
            ]
        ]


viewImage : Model -> Html Msg
viewImage model =
    case model.image of
        Nothing ->
            button
                [ onClick ImageRequested
                , class "button1"
                ]
                [ text "Load Image" ]

        Just url ->
            div []
                [ img [ src url, width 200 ] []
                , viewConverted model
                ]


viewConverted : Model -> Html Msg
viewConverted model =
    case model.convertedImage of
        Nothing ->
            text "converting"

        Just url ->
            img [ src url, width 200 ] []


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
