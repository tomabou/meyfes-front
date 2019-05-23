port module Graph exposing (GraphInfo, Model, Msg, decoder, initial, subscriptions, update, view)

import Array exposing (..)
import Browser.Events
import Constant exposing (..)
import Html
import Html.Attributes
import Html.Events
import Html.Lazy
import Http
import Json.Decode exposing (Decoder, array, field, int, list, map, map3)
import Json.Encode
import Set
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Svg.Events exposing (onClick)
import Svg.Lazy
import Tuple exposing (first, second)


port finalGridGraph : Json.Encode.Value -> Cmd msg


port createdMaze : (Json.Encode.Value -> msg) -> Sub msg


type alias Model =
    { vertex : Array (Array Bool)
    , edgeR : Set.Set ( Int, Int )
    , edgeC : Set.Set ( Int, Int )
    , maze : Array (Array Int)
    , routeRatio : Float
    , routeDistance : Int
    , showRoute : Bool
    , mazeConverted : Maybe Json.Decode.Error
    }


type alias GraphInfo =
    { vertex : Array (Array Bool)
    , edgeR : Set.Set ( Int, Int )
    , edgeC : Set.Set ( Int, Int )
    }


type Msg
    = ChangeNode Int Int
    | SubmitGraph
    | MazeCreated (Array (Array Int))
    | FailedCreateMaze Json.Decode.Error
    | AnimeFrame Float
    | ShowRoute


intToPair : Int -> ( Int, Int )
intToPair x =
    ( x // 1000, modBy 1000 x )


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
    , showRoute = False
    , mazeConverted = Nothing
    }


isEmptyMaze : Array (Array Bool) -> Bool
isEmptyMaze =
    Array.map (foldl (||) False) >> foldl (||) False >> not


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChangeNode i j ->
            if hasVertex i j model then
                ( deleteVertex i j model, Cmd.none )

            else
                ( putVertex i j model, Cmd.none )

        SubmitGraph ->
            let
                ( xSize, ySize ) =
                    getSize model

                mazeMatrix =
                    Json.Encode.array
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

                submitJson =
                    Json.Encode.object [ ( "x", Json.Encode.int xSize ), ( "y", Json.Encode.int ySize ), ( "maze", mazeMatrix ) ]
            in
            if isEmptyMaze model.vertex then
                ( model, Cmd.none )

            else
                ( model
                , finalGridGraph submitJson
                )

        MazeCreated arr ->
            let
                routesize =
                    foldl Basics.max 0 (Array.map (foldl Basics.max 0) arr) + 2
            in
            ( { model | maze = arr, routeDistance = routesize * 6 // 5, showRoute = False, routeRatio = 0 }, Cmd.none )

        FailedCreateMaze err ->
            ( { model | mazeConverted = Just err }, Cmd.none )

        AnimeFrame time ->
            let
                newTime =
                    model.routeRatio + time / 5000

                newRatio =
                    newTime - toFloat (floor newTime)
            in
            --            ( { model | routeRatio = newRatio }, Cmd.none )
            ( model, Cmd.none )

        ShowRoute ->
            ( { model | routeRatio = 1 - model.routeRatio, showRoute = not model.showRoute }, Cmd.none )


viewMaze : Model -> Html.Html Msg
viewMaze model =
    let
        ( i, j ) =
            getArrayArraySize model.maze

        threshold =
            floor (toFloat model.routeDistance * model.routeRatio) + 2
    in
    Html.div [ Html.Attributes.class "maze-svg" ]
        [ svg
            [ viewBox ("0 0 " ++ String.fromInt (i * 10) ++ " " ++ String.fromInt (j * 10)), class "svg_model" ]
            [ rect [ class "maze_background", x "0", y "0", width (String.fromInt (i * 10)), height (String.fromInt (j * 10)) ] []
            , Svg.Lazy.lazy2 viewMazeWall model.maze threshold
            ]
        ]


viewMazeWall : Array (Array Int) -> Int -> Svg Msg
viewMazeWall maze threshold =
    g [ class "maze" ]
        [ g [] (toList (indexedMap (Svg.Lazy.lazy2 floorMaze) maze))
        , g [] (toList (indexedMap (unreachMaze threshold) maze))
        , g [] (toList (indexedMap (reachMaze threshold) maze))
        ]


floorMaze : Int -> Array Int -> Svg Msg
floorMaze xInd column =
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
    toIndexedList column |> List.filter (second >> (==) 0) |> List.map func |> (\x -> g [] x)


reachMaze : Int -> Int -> Array Int -> Svg Msg
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
    toIndexedList column |> List.filter (second >> (\i -> i >= 2 && i < threshold)) |> List.map func |> (\x -> g [] x)


unreachMaze : Int -> Int -> Array Int -> Svg Msg
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
    toIndexedList column |> List.filter (second >> (\i -> i >= threshold)) |> List.map func |> (\x -> g [] x)


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
            , Html.Lazy.lazy viewVertex model.vertex
            ]
        , Html.button [ Html.Events.onClick SubmitGraph, Html.Attributes.class "btn-flat-border" ] [ Html.text "Submit Graph" ]
        , viewMaze model
        , Html.button [ Html.Events.onClick ShowRoute, Html.Attributes.class "btn-flat-border" ]
            [ Html.text
                (if model.showRoute then
                    "Hide Answer"

                 else
                    "Show Answer"
                )
            ]
        , case model.mazeConverted of
            Nothing ->
                Html.div [] []

            Just err ->
                text (Json.Decode.errorToString err)
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


viewVertex : Array (Array Bool) -> Svg Msg
viewVertex vertex =
    let
        svgMsgArray =
            indexedMap (Svg.Lazy.lazy2 calcVertex) vertex
    in
    g [ class "vertex" ] (toList svgMsgArray)


indexToString : Int -> String
indexToString i =
    String.fromInt (i * 10 + 3)


indexToRecString : Int -> String
indexToRecString i =
    String.fromInt (i * 10 - 2)


calcVertex : Int -> Array Bool -> Svg Msg
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
    g [] (toList (indexedMap (Svg.Lazy.lazy2 func) column))


viewEdge : Model -> Svg Msg
viewEdge model =
    g [ class "edge" ] [ Html.Lazy.lazy calcEdgeC model.edgeC, Html.Lazy.lazy calcEdgeR model.edgeR ]


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
    let
        func value =
            case Json.Decode.decodeValue mazeDecoder value of
                Ok maze ->
                    MazeCreated maze

                Err err ->
                    FailedCreateMaze err
    in
    createdMaze func
