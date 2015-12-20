
module Test.FileLock(main) where

import Development.Shake
import Control.Concurrent.Extra
import Control.Exception.Extra
import Control.Monad
import Data.Either.Extra
import System.Time.Extra
import Test.Type


main = shaken test $ \args obj ->
    action $ do
        putNormal "Starting sleep"
        liftIO $ sleep 5
        putNormal "Finished sleep"


test build obj = do
    -- check it fails exactly once
    time <- offsetTime
    lock <- newLock
    let out msg = do t <- time; withLock lock $ print (t, msg)
    out "before onceFork"
    a <- onceFork $ do out "a1"; build ["-VVV"]; out "a2"
    b <- onceFork $ do out "b1"; build ["-VVV"]; out "b2"
    out "after onceFork"
    a <- try_ a
    out "after try a"
    b <- try_ b
    out "after try b"
    when (length (filter isLeft [a,b]) /= 1) $
        error $ "Expected one success and one failure, got " ++ show [a,b]
    -- check it succeeds after the lock has been held
    build []
