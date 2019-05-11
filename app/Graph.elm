module Graph exposing (Model, Msg, initial, update, view)

import Array exposing (..)
import Html
import Svg exposing (..)
import Svg.Attributes exposing (..)


type alias Model =
    Array (Array Bool)


type Msg
    = ChangeNode Int Int


initial : Int -> Int -> Model
initial x y =
    Array.repeat x (Array.repeat y False)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg graph =
    ( graph, Cmd.none )


view : Model -> Html.Html Msg
view graph =
    svg
        [ width "120", height "120", viewBox "0 0 120 120" ]
        [ rect [ x "10", y "10", width "100", height "100", rx "15", ry "15" ] [] ]
