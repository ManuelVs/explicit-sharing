{-# LANGUAGE NoMonomorphismRestriction #-}

-- to compile, run:
-- ghc -fglasgow-exts -hide-package monads-fd -O2 --make last

-- $ time ./last 1000000 +RTS -H1000M -K20M
-- True
-- user	0m1.012s

import Control.Monad.Sharing.Lazy
import System ( getArgs )
import List

import Prelude hiding ( last )

main =
 do n <- liftM (read.head) getArgs
    mapM_ print . evalLazy . last . foldr cons nil . replicate n $ return True

last :: Sharing m => m (List m Bool) -> m Bool
last l = do x <- share freeBool
            l =:= append freeBoolList (cons x nil)
            x

instance MonadPlus m => Nondet m Bool
 where
  mapNondet _ = return

append :: Monad m => m (List m a) -> m (List m a) -> m (List m a)
append mxs ys = do xs <- mxs; appendLists xs ys

appendLists :: Monad m => List m a -> m (List m a) -> m (List m a)
appendLists Nil         ys = ys
appendLists (Cons x xs) ys = cons x (append xs ys)

freeBool :: MonadPlus m => m Bool
freeBool = return False `mplus` return True

freeBoolList :: MonadPlus m => m (List m Bool)
freeBoolList = nil `mplus` cons freeBool freeBoolList

(=:=) :: MonadPlus m => m (List m Bool) -> m (List m Bool) -> m ()
mxs =:= mys = do xs <- mxs; ys <- mys; eqBoolList xs ys

eqBoolList :: MonadPlus m => List m Bool -> List m Bool -> m ()
eqBoolList Nil         Nil         = return ()
eqBoolList (Cons x xs) (Cons y ys) = do True <- liftM2 (==) x y
                                        xs =:= ys
eqBoolList _           _           = mzero