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
    , edgeR = Set.fromList [ ( 1, 3 ) ]
    , edgeC = Set.empty
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg graph =
    ( graph, Cmd.none )


view : Model -> Html.Html Msg
view model =
    let
        ( xInd, yInd ) =
            getSize model
    in
    svg
        [ viewBox ("0 0 " ++ String.fromInt (xInd * 10) ++ " " ++ String.fromInt (yInd * 10)), class "svg_model" ]
        [ viewVertex model
        , viewEdge model
        ]


hasVertex : Int -> Int -> Model -> Bool
hasVertex i j model =
    case get i model.vertex of
        Nothing ->
            False

        Just column ->
            case get j column of
                Nothing ->
                    False

                Just ans ->
                    ans


putVertex : Int -> Int -> Model -> Model
putVertex i j model =
    let
        vertex =
            case get i model.vertex of
                Nothing ->
                    model.vertex

                Just column ->
                    Array.set i (Array.set j True column) model.vertex

        edgeC =
            if hasVertex i (j + 1) model then
                Set.insert ( i, j ) model.edgeC

            else
                model.edgeC

        edgeC2 =
            if hasVertex i (j - 1) model then
                Set.insert ( i, j - 1 ) edgeC

            else
                edgeC

        edgeR =
            if hasVertex (i + 1) j model then
                Set.insert ( i, j ) model.edgeR

            else
                model.edgeR

        edgeR2 =
            if hasVertex (i - 1) j model then
                Set.insert ( i - 1, j ) edgeR

            else
                edgeR
    in
    { model | vertex = vertex, edgeC = edgeC2, edgeR = edgeR2 }


deleteVertex : Int -> Int -> Model -> Model
deleteVertex i j model =
    let
        vertex =
            case get i model.vertex of
                Nothing ->
                    model.vertex

                Just column ->
                    Array.set i (Array.set j False column) model.vertex

        edgeC =
            if hasVertex i (j + 1) model then
                Set.remove ( i, j ) model.edgeC

            else
                model.edgeC

        edgeC2 =
            if hasVertex i (j - 1) model then
                Set.remove ( i, j - 1 ) edgeC

            else
                edgeC

        edgeR =
            if hasVertex (i + 1) j model then
                Set.remove ( i, j ) model.edgeR

            else
                model.edgeR

        edgeR2 =
            if hasVertex (i - 1) j model then
                Set.remove ( i - 1, j ) edgeR

            else
                edgeR
    in
    { model | vertex = vertex, edgeC = edgeC2, edgeR = edgeR2 }


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
    g [ class "edge" ] [ calcEdgeC model.edgeC, calcEdgeR model.edgeR ]


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
