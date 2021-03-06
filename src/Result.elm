module Result where
{-| A `Result` is the result of a computation that may fail. This is a great
way to manage errors in Elm.

# Type and Constructors
@docs Result

# Common Helpers
@docs map, andThen

# Formatting Errors
@docs toMaybe, fromMaybe formatError
-}

import Maybe ( Maybe(Just, Nothing) )


{-| A `Result` is either `Ok` meaning the computation succeeded, or it is an
`Err` meaning that there was some failure.
-}
type Result error value = Ok value | Err error


{-| Apply a function to a result. If the result is `Ok`, it will be converted.
If the result is an `Err`, the same error value will propegate through.

    map sqrt (Ok 4.0)          == Ok 2.0
    map sqrt (Err "bad input") == Err "bad input"
-}
map : (a -> b) -> Result e a -> Result e b
map f result =
    case result of
      Ok  v -> Ok (f v)
      Err e -> Err e


{-| Chain together a sequence of computations that may fail. It is helpful
to see its definition:

    andThen : Result e a -> (a -> Result e b) -> Result e b
    andThen result callback =
        case result of
          Ok value -> callback value
          Err msg -> Err msg

This means we only continue with the callback if things are going well. For
example, say you need to use (`toInt : String -> Result String Int`) to parse
a month and make sure it is between 1 and 12:

    toValidMonth : Int -> Result String Int
    toValidMonth month =
        if month >= 1 && month <= 12
            then Ok month
            else Err "months must be between 1 and 12"

    toMonth : String -> Result String Int
    toMonth rawString =
        toInt rawString `andThen` toValidMonth

    -- toMonth "4" == Ok 4
    -- toMonth "9" == Ok 9
    -- toMonth "a" == Err "cannot parse to an Int"
    -- toMonth "0" == Err "months must be between 1 and 12"

This allows us to come out of a chain of operations with quite a specific error
message. It is often best to create a custom type that explicitly represents
the exact ways your computation may fail. This way it is easy to handle in your
code.
-}
andThen : Result e a -> (a -> Result e b) -> Result e b
andThen result callback =
    case result of
      Ok value -> callback value
      Err msg -> Err msg


{-| Format the error value of a result. If the result is `Ok`, it stays exactly
the same, but if the result is an `Err` we will format the error. For example,
say the errors we get have too much information:

    parseInt : String -> Result ParseError Int

    type ParseError =
        { message : String
        , code : Int
        , position : (Int,Int)
        }

    formatError .message (parseInt "123") == Ok 123
    formatError .message (parseInt "abc") == Err "char 'a' is not a number"
-}
formatError : (error -> error') -> Result error a -> Result error' a
formatError f result =
    case result of
      Ok  v -> Ok v
      Err e -> Err (f e)


{-| Convert to a simpler `Maybe` if the actual error message is not needed or
you need to interact with some code that primarily uses maybes.

    parseInt : String -> Result ParseError Int

    maybeParseInt : String -> Maybe Int
    maybeParseInt string =
        toMaybe (parseInt string)
-}
toMaybe : Result e a -> Maybe a
toMaybe result =
    case result of
      Ok  v -> Just v
      Err _ -> Nothing


{-| Convert from a simple `Maybe` to interact with some code that primarily
uses `Results`.

    parseInt : String -> Maybe Int

    resultParseInt : String -> Result String Int
    resultParseInt string =
        fromMaybe ("error parsing string: " ++ show string) (parseInt string)
-}
fromMaybe : e -> Maybe a -> Result e a
fromMaybe err maybe =
    case maybe of
      Just v  -> Ok v
      Nothing -> Err err
