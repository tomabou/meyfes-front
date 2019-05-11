module Graph exposing (Model, Msg, initial, update, view)

import Array exposing (..)
import Html
import Set
import Svg exposing (..)
import Svg.Attributes exposing (..)


type alias Model =
    { vertex : Array (Array Bool)
    , edgeR : Set.Set ( Int, Int )
    , edgeC : Set.Set ( Int, Int )
    }


type Msg
    = ChangeNode Int Int


initial : Int -> Int -> Model
initial x y =
    { vertex = Array.repeat x (Array.repeat y False)
    , edgeR = Set.empty
    , edgeC = Set.empty
    }


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
        [ viewVertex graph
        ]


getSize : Model -> ( Int, Int )
getSize model =
    let
        xInd =
            length model.vertex

        yInd =
            case get 1 model.vertex of
                Nothing ->
                    0

                Just column ->
                    length column
    in
    ( xInd, yInd )


viewVertex : Model -> Svg Msg
viewVertex model =
    let
        svgMsgArray =
            indexedMap calcVertex model.vertex
    in
    g [ class "vertex" ] (List.concat (List.map toList (toList svgMsgArray)))


indexToString : Int -> String
indexToString i =
    String.fromInt (i * 10 + 3)


calcVertex : Int -> Array Bool -> Array (Svg Msg)
calcVertex xInd column =
    let
        func yInd status =
            let
                className =
                    if status then
                        "active"

                    else
                        "nonactive"
            in
            circle [ cx (indexToString xInd), cy (indexToString yInd), r "3", class className ] []
    in
    indexedMap func column


viewEdge : Model -> Svg Msg
viewEdge model =
    g [] [ calcEdgeC model.edgeC, calcEdgeR model.edgeR ]


calcEdgeC : Set.Set ( Int, Int ) -> Svg Msg
calcEdgeC set =
    let
        func ( i, j ) =
            line
                [ x1 (indexToString i)
                , y1 (indexToString j)
                , x2 (indexToString i)
                , y2 (indexToString (j + 1))
                ]
                []
    in
    g []
        (List.map func (Set.toList set))


calcEdgeR : Set.Set ( Int, Int ) -> Svg Msg
calcEdgeR set =
    let
        func ( i, j ) =
            line
                [ x1 (indexToString i)
                , y1 (indexToString j)
                , x2 (indexToString (i + 1))
                , y2 (indexToString j)
                ]
                []
    in
    g []
        (List.map func (Set.toList set))
