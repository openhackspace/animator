
{-# LANGUAGE DisambiguateRecordFields, TypeFamilies, MagicHash,
    StandaloneDeriving, DeriveFunctor, DeriveFoldable, GeneralizedNewtypeDeriving,
    TypeSynonymInstances, FlexibleInstances, ForeignFunctionInterface #-}

-------------------------------------------------------------------------------------
-- | 
-- This module provides a basic interface to the JavaScript host environment.
-------------------------------------------------------------------------------------

-- TODO Remove TypeSynonymInstances, FlexibleInstances?
--      Required for String instance of JsProp, can we rethink this?

module Animator.Internal.Prim (

        -- ** Strings
        JsString,
        toJsString,
        fromJsString,

        -- ** Objects
        JsObject,
        -- JsArray,
        new,
        create,
        global,
        JsName,
        JsProp(..),

        -- ** JSON
        JSON,

        -- ** Utility
        windowAlert,
        windowConsoleLog,
        windowDocumentWrite,
  ) where

import Data.Int
import Data.Word
import Data.String (IsString(..))
import qualified Haste.Prim as H
import qualified Haste.JSON as HJ




-- | An unboxed JavaScript string.
newtype JsString = JsString { getJsString :: H.JSString }
    deriving (Eq, Ord, Show, IsString)
-- Applicative
-- Monad
-- Functor
-- Semigroup
-- Monoid
-- Foldable

-- | Convert a Haskell string to a JavaScript string.
toJsString :: String -> JsString  
toJsString = JsString . H.toJSStr 

-- | Convert a JavaScript string to a Haskell string.
fromJsString :: JsString -> String
fromJsString = H.fromJSStr . getJsString

-- | An unboxed JavaScript object.
newtype JsObject = JsObject { getJsObject :: H.JSAny }

-- -- | An unboxed JavaScript array.
-- newtype JsArray  = JsArray { getJsArray :: H.JSAny }


-- | Creates a new JavaScript object. 
--
-- Equivalent to:
--
-- > {}
new :: IO JsObject
new = new# >>= (return . JsObject)

-- | Creates a new JavaScript object using the given object as prototype.
--
-- Equivalent to:
--
-- > Object.create(x)
create :: JsObject -> IO JsObject
create x = undefined
                                      
-- | Returns the JavaScript global object.
global :: IO JsObject
global = global# >>= (return . JsObject)












type JsName = String

-- | 
-- Class of types that can be properties of a 'JsObject'.
-- 
-- The methods of this class perform no dynamic checks, so retrieving a value of
-- the wrong type (for example, reading an 'Int' from a field containing a string)
-- results in undefined behaviour.
class JsProp a where
    -- | @get n o@ fetches the value named @n@ from object @o@.
    -- 
    --   Equivalent to:
    --
    -- > o.n    
    get :: JsName -> JsObject -> IO a

    -- | @set n o x@ assigns the property @n@ to @x@ in object @o@.
    --   
    --   Equivalent to:
    --
    -- > o.n = x
    set :: JsName -> JsObject -> a -> IO ()

    -- | @update n o f@ updates the value named @n@ in object @o@ by applying the function f.
    --   
    --   Equivalent to:
    --
    -- > x.n = f(x.n)
    update :: JsName -> JsObject -> (a -> a) -> IO ()
    update n o f = get n o >>= set n o . f

instance JsProp String where
    get name obj = getString# (H.toJSStr name) (getJsObject obj) >>= (return . H.fromJSStr)
    set name obj value = setString# (H.toJSStr name) (getJsObject obj) (H.toJSStr value)

instance JsProp Int where
    get name obj = getInt# (H.toJSStr name) (getJsObject obj) >>= return
    set name obj value = setInt# (H.toJSStr name) (getJsObject obj) value

instance JsProp Word where
    get name obj = getWord# (H.toJSStr name) (getJsObject obj) >>= return
    set name obj value = setWord# (H.toJSStr name) (getJsObject obj) value

instance JsProp Int32 where
    get name obj = getInt32# (H.toJSStr name) (getJsObject obj) >>= return
    set name obj value = setInt32# (H.toJSStr name) (getJsObject obj) value

instance JsProp Word32 where
    get name obj = getWord32# (H.toJSStr name) (getJsObject obj) >>= return
    set name obj value = setWord32# (H.toJSStr name) (getJsObject obj) value

instance JsProp Float where
    get name obj = getFloat# (H.toJSStr name) (getJsObject obj) >>= return
    set name obj value = setFloat# (H.toJSStr name) (getJsObject obj) value

instance JsProp Double where
    get name obj = getDouble# (H.toJSStr name) (getJsObject obj) >>= return
    set name obj value = setDouble# (H.toJSStr name) (getJsObject obj) value

instance JsProp JsObject where
    get name obj = getObj# (H.toJSStr name) (getJsObject obj) >>= (return . JsObject)
    set name obj value = setObj# (H.toJSStr name) (getJsObject obj) (getJsObject value)






foreign import ccall "animator_write" documentWrite#    :: H.JSString -> IO ()
foreign import ccall "animator_log"   consoleLog#       :: H.JSString -> IO ()
foreign import ccall "animator_alert" alert#            :: H.JSString -> IO ()

-- | Like @window.alert@ in JavaScript, i.e. displays a modal window with the given text.
windowAlert :: String -> IO ()
windowAlert str  = alert# (H.toJSStr $ str)

-- | Like @window.console.log@ in JavaScript, i.e. posts a line to the web console.
windowConsoleLog :: String -> IO ()
windowConsoleLog str = consoleLog# (H.toJSStr $ str)

-- | Like @window.document.write@ in JavaScript, i.e. appends the given content at the end of the `body` element.
windowDocumentWrite :: String -> IO ()
windowDocumentWrite str = documentWrite# (H.toJSStr $ "<code>" ++ str ++ "</code><br/>")


newtype JSON = JSON { getJSON :: HJ.JSON }






foreign import ccall "aPrimObj"    new#       :: IO H.JSAny
foreign import ccall "aPrimGlobal" global#    :: IO H.JSAny

foreign import ccall "aPrimGet"    getInt#    :: H.JSString -> H.JSAny -> IO Int
foreign import ccall "aPrimGet"    getWord#   :: H.JSString -> H.JSAny -> IO Word
foreign import ccall "aPrimGet"    getInt32#  :: H.JSString -> H.JSAny -> IO Int32
foreign import ccall "aPrimGet"    getWord32# :: H.JSString -> H.JSAny -> IO Word32
foreign import ccall "aPrimGet"    getFloat#  :: H.JSString -> H.JSAny -> IO Float
foreign import ccall "aPrimGet"    getDouble# :: H.JSString -> H.JSAny -> IO Double
foreign import ccall "aPrimGet"    getString# :: H.JSString -> H.JSAny -> IO H.JSString
foreign import ccall "aPrimGet"    getObj#    :: H.JSString -> H.JSAny -> IO H.JSAny

foreign import ccall "aPrimSet"    setInt#    :: H.JSString -> H.JSAny -> Int -> IO ()
foreign import ccall "aPrimGet"    setWord#   :: H.JSString -> H.JSAny -> Word -> IO ()
foreign import ccall "aPrimGet"    setInt32#  :: H.JSString -> H.JSAny -> Int32 -> IO ()
foreign import ccall "aPrimGet"    setWord32# :: H.JSString -> H.JSAny -> Word32 -> IO ()
foreign import ccall "aPrimGet"    setFloat#  :: H.JSString -> H.JSAny -> Float -> IO ()
foreign import ccall "aPrimGet"    setDouble# :: H.JSString -> H.JSAny -> Double -> IO ()
foreign import ccall "aPrimSet"    setString# :: H.JSString -> H.JSAny -> H.JSString -> IO ()
foreign import ccall "aPrimSet"    setObj#    :: H.JSString -> H.JSAny -> H.JSAny -> IO ()
