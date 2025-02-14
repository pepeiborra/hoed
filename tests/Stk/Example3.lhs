> {-# LANGUAGE TemplateHaskell, Rank2Types #-}
> import Debug.Hoed.Stk

> $(observedTypes "k" [])
> $(observedTypes "l" [])
> $(observedTypes "m" [])
> $(observedTypes "n" [])


> main = logO "hoed-tests-Stk-Example3.graph" $ print (k 1)

> k :: Int -> Int
> k  x = $(observeTempl "k") k' x
> k' x = {-# SCC "k" #-} k'' x
> k'' x = (l x) + (m $ x + 1)

> l :: Int -> Int
> l  x  = $(observeTempl "l") l' x
> l' x  = {-# SCC "l" #-} m x

> m :: Int -> Int
> m  x = $(observeTempl "m") m' x
> m' x = {-# SCC "m" #-} n x

> n :: Int -> Int
> n  x = $(observeTempl "n") n' x
> n' x = {-# SCC "n" #-} x
