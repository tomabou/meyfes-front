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
    let
        ( xInd, yInd ) =
            getSize graph
    in
    svg
        [ viewBox ("0 0 " ++ String.fromInt (xInd * 10) ++ " " ++ String.fromInt (yInd * 10)), class "svg_graph" ]
        [ rect [ x "10", y "10", width "100", height "100", rx "15", ry "15" ] [] ]


getSize : Model -> ( Int, Int )
getSize graph =
    let
        xInd =
            length graph

        yInd =
            case get 1 graph of
                Nothing ->
                    0

                Just column ->
                    length column
    in
    ( xInd, yInd )


viewVertex : Model -> List (Svg Msg)
viewVertex model =
    let
        svgMsgArray =
            indexedMap calcVertex model
    in
    List.concat (List.map toList (toList svgMsgArray))


calcVertex : Int -> Array Bool -> Array (Svg Msg)
calcVertex xInd column =
    let
        func yInd status =
            let
                className =
                    if status then
                        "true_vertex"

                    else
                        "false_vertex"
            in
            circle [ cx (String.fromInt (xInd * 10)), cy (String.fromInt (yInd * 10)), r "3", class className ] []
    in
    indexedMap func column
