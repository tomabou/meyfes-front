module Main exposing (main)

import Browser
import File exposing (File)
import File.Select as Select
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
    { image : Maybe String }


init : () -> ( Model, Cmd Msg )
init _ =
    ( Model Nothing, Cmd.none )


type Msg
    = ImageRequested
    | ImageSelected File
    | ImageLoaded String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ImageRequested ->
            ( model, Select.file [ "image/jpeg" ] ImageSelected )

        ImageSelected file ->
            ( model, Task.perform ImageLoaded (File.toUrl file) )

        ImageLoaded url ->
            ( { model | image = Just url }, Cmd.none )


view : Model -> Html Msg
view model =
    div []
        [ h2 [] [ text "image uploader" ]
        , viewImage model
        ]


viewImage : Model -> Html Msg
viewImage model =
    case model.image of
        Nothing ->
            button [ onClick ImageRequested ] [ text "Load Image" ]

        Just url ->
            div []
                [ text "Your image"
                , img [ src url ] []
                ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
