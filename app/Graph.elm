module Graph exposing (Model, Msg, initial, subscriptions, update, view)

import Array exposing (..)
import Browser.Events
import Constant exposing (..)
import Html
import Html.Events
import Http
import Json.Decode exposing (Decoder, array, field, int, list, map, map3)
import Json.Encode
import Set
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Svg.Events exposing (onClick)
import Tuple exposing (first, second)


type alias Model =
    { vertex : Array (Array Bool)
    , edgeR : Set.Set ( Int, Int )
    , edgeC : Set.Set ( Int, Int )
    , maze : Array (Array Int)
    , routeRatio : Float
    , routeDistance : Int
    }


type alias GraphInfo =
    { vertex : Array (Array Bool)
    , edgeR : Set.Set ( Int, Int )
    , edgeC : Set.Set ( Int, Int )
    }


type Msg
    = ChangeNode Int Int
    | SubmitGraph
    | MazeCreated (Result Http.Error (Array (Array Int)))
    | AnimeFrame Float


intToPair : Int -> ( Int, Int )
intToPair x =
    ( x // 100, modBy 100 x )


decoder : Decoder GraphInfo
decoder =
    Json.Decode.map3 GraphInfo
        (field "vertex" (array (array (Json.Decode.map ((==) 1) int))))
        (field "edgeR" (Json.Decode.map Set.fromList (list (Json.Decode.map intToPair int))))
        (field "edgeC" (Json.Decode.map Set.fromList (list (Json.Decode.map intToPair int))))


mazeDecoder : Decoder (Array (Array Int))
mazeDecoder =
    field "mazelist" (array (array int))


initial : Int -> Int -> Model
initial x y =
    { vertex = Array.repeat x (Array.repeat y False)
    , edgeR = Set.empty
    , edgeC = Set.empty
    , maze = Array.empty
    , routeRatio = 0
    , routeDistance = 0
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChangeNode i j ->
            if hasVertex i j model then
                ( deleteVertex i j model, Cmd.none )

            else
                ( putVertex i j model, Cmd.none )

        SubmitGraph ->
            ( model
            , Http.post
                { url = urlPrefix ++ "/maze"
                , body =
                    Http.jsonBody
                        (Json.Encode.array
                            (Json.Encode.array
                                (Json.Encode.int
                                    << (\b ->
                                            if b then
                                                0

                                            else
                                                1
                                       )
                                )
                            )
                            model.vertex
                        )
                , expect = Http.expectJson MazeCreated mazeDecoder
                }
            )

        MazeCreated result ->
            case result of
                Ok arr ->
                    let
                        routesize =
                            foldl Basics.max 0 (Array.map (foldl Basics.max 0) arr) + 2
                    in
                    ( { model | maze = arr, routeDistance = routesize * 6 // 5 }, Cmd.none )

                Err err ->
                    ( model, Cmd.none )

        AnimeFrame time ->
            let
                newTime =
                    model.routeRatio + time / 5000

                newRatio =
                    newTime - toFloat (floor newTime)
            in
            ( { model | routeRatio = newRatio }, Cmd.none )


viewMaze : Model -> Html.Html Msg
viewMaze model =
    let
        ( i, j ) =
            getArrayArraySize model.maze
    in
    svg
        [ viewBox ("0 0 " ++ String.fromInt (i * 10) ++ " " ++ String.fromInt (j * 10)), class "svg_model" ]
        [ rect [ class "maze_background", x "0", y "0", width (String.fromInt (i * 10)), height (String.fromInt (j * 10)) ] []
        , viewMazeWall model
        ]


viewMazeWall : Model -> Svg Msg
viewMazeWall model =
    let
        threshold =
            floor (toFloat model.routeDistance * model.routeRatio)

        svgMsgArray =
            indexedMap (floorMaze threshold) model.maze
    in
    g [ class "maze" ]
        [ g [] (List.concat (toList (indexedMap (floorMaze threshold) model.maze)))
        , g [] (List.concat (toList (indexedMap (unreachMaze threshold) model.maze)))
        , g [] (List.concat (toList (indexedMap (reachMaze threshold) model.maze)))
        ]


floorMaze : Int -> Int -> Array Int -> List (Svg Msg)
floorMaze threshold xInd column =
    let
        func ( yInd, val ) =
            rect
                [ x (String.fromInt (xInd * 10 - 1))
                , y (String.fromInt (yInd * 10 - 1))
                , width "12"
                , height "12"
                , class "floor"
                ]
                []
    in
    toIndexedList column |> List.filter (second >> (==) 0) |> List.map func


reachMaze : Int -> Int -> Array Int -> List (Svg Msg)
reachMaze threshold xInd column =
    let
        func ( yInd, val ) =
            rect
                [ x (String.fromInt (xInd * 10 - 1))
                , y (String.fromInt (yInd * 10 - 1))
                , width "12"
                , height "12"
                , class "reach-floor"
                ]
                []
    in
    toIndexedList column |> List.filter (second >> (\i -> i >= 2 && i < threshold)) |> List.map func


unreachMaze : Int -> Int -> Array Int -> List (Svg Msg)
unreachMaze threshold xInd column =
    let
        func ( yInd, val ) =
            rect
                [ x (String.fromInt (xInd * 10 - 1))
                , y (String.fromInt (yInd * 10 - 1))
                , width "12"
                , height "12"
                , class "unreach-floor"
                ]
                []
    in
    toIndexedList column |> List.filter (second >> (\i -> i >= threshold)) |> List.map func


view : Model -> Html.Html Msg
view model =
    let
        ( xInd, yInd ) =
            getSize model
    in
    Html.div []
        [ svg
            [ viewBox ("0 0 " ++ String.fromInt (xInd * 10) ++ " " ++ String.fromInt (yInd * 10)), class "svg_model" ]
            [ viewEdge model
            , viewVertex model
            ]
        , Html.button [ Html.Events.onClick SubmitGraph ] [ Html.text "submit graph" ]
        , viewMaze model
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


getArrayArraySize : Array (Array a) -> ( Int, Int )
getArrayArraySize arr =
    let
        xInd =
            length arr

        yInd =
            case get 1 arr of
                Nothing ->
                    0

                Just column ->
                    length column
    in
    ( xInd, yInd )


getSize : Model -> ( Int, Int )
getSize model =
    getArrayArraySize model.vertex


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


indexToRecString : Int -> String
indexToRecString i =
    String.fromInt (i * 10 - 2)


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
            g []
                [ circle
                    [ cx (indexToString xInd)
                    , cy (indexToString yInd)
                    , r "3"
                    , class className
                    ]
                    []
                , rect
                    [ onClick (ChangeNode xInd yInd)
                    , x (indexToRecString xInd)
                    , y (indexToRecString yInd)
                    , width "10"
                    , height "10"
                    , class "hide"
                    ]
                    []
                ]
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


subscriptions : Model -> Sub Msg
subscriptions model =
    Browser.Events.onAnimationFrameDelta AnimeFrame
