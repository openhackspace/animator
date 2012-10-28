{-# LANGUAGE
    NoMonomorphismRestriction,
    TypeFamilies,
    ForeignFunctionInterface,
    OverloadedStrings,
    BangPatterns,
    MagicHash,
    UnboxedTuples #-}

module Main where

import Animator.Prelude
import Animator.Internal.Prim
import Foreign.Ptr
import Haste.Prim(toPtr, fromPtr)
import GHC.Prim
import Data.Foldable 
import Prelude hiding (null)

{-

FFI quirks:
    All imported js functions take and return extra parameter:
        f(..., _) {
            return [1,_, ...]
        }
    FFI functions unwrap one level of pointers (this include JsString and Int).
    This does not apply to callbacks!

Representation:

    Haskell value               JS value
    -----                       ------
    False :: Bool               false
    123 :: Int                  [1,123]
    "foo" :: JsString           [1,"foo"]

    eval "function(){...}"      [1,function(){...}]
    eval "{...}"                [1,{...}]

    \x->x+x :: Int->Int         function
    (10,20)::(Int,Int)          [1,[1,10],[1,20]]


Polymorhism requirements:
    Assignment and referencing
        x.n = v
        x.n
    Calls
        f(x,y,z)
-}

main = testJQuery   

testPrim = do    
    logPrim $ (False::Bool)
    logPrim $ (123::Int)
    logPrim $ ("foo"::JsString)

    jf <- eval "(function(x){return x+x;})"
    logPrim $ jf

    jo <- eval "({foo:123,bar:function(x){return x}})"
    logPrim $ jo

    let hf = ((\x -> x + x) :: Int -> Int)
    logPrim $ hf

    let ho = (10::Int,20::Int)
    logPrim $ ho

testCall = do    
    g <- global                     
    o <- eval "([1,2,3,4])"
    foo <- get "foo" g :: IO JsObject
    alert <- get "alert" g :: IO JsObject
    console <- get "console" g :: IO JsObject
    logPrim $ foo
    res <- call1 foo console (o::JsObject)
    logPrim $ (res::JsObject)


testJQuery = do
    g <- global
    jq <- get "jQuery" g

    r1 <- call1 jq null ("#div1"::JsString)
    r1 %% "fadeIn" :: IO ()

    r2 <- call1 jq null ("#div2"::JsString)
    (r2 %%! "fadeIn") ("slow"::JsString) :: IO ()

    r3 <- call1 jq null ("#div3"::JsString)
    (r3 %%! "fadeIn") (5000::Double) :: IO ()


    -- object % "x" := 1
    --        % "y" := 2
    -- array [1,2,3] % "0" := 33