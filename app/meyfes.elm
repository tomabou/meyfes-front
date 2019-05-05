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
    { image : Maybe String
    , convertedImage : Maybe String
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( Model Nothing Nothing, Cmd.none )


type Msg
    = ImageRequested
    | ImageSelected File
    | ImageLoaded String
    | ImageConverted (Result Http.Error String)


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


imageDecoder : Decoder String
imageDecoder =
    field "image_url" string


view : Model -> Html Msg
view model =
    div []
        [ h2 [ class "header" ] [ text "image uploader" ]
        , viewImage model
        ]


viewImage : Model -> Html Msg
viewImage model =
    case model.image of
        Nothing ->
            button [ onClick ImageRequested ] [ text "Load Image" ]

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
