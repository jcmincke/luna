module Luna.Package.Utilities where

import Prologue



-------------------------------
-- === Utility Functions === --
-------------------------------

-- === API === --

-- from package `extra` with BSD3 licence, slightly altered
partitionM :: Monad m => (a -> m Bool) -> [a] -> m ([a],[a])
partitionM _ [] = pure ([],[])
partitionM f (x:xs) = do
    res <- f x
    (as, bs) <- partitionM f xs
    pure ([x | res] <> as, [x | not res] <> bs)

