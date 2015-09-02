-- This file is part of the Haskell debugger Hoed.
--
-- Copyright (c) Maarten Faddegon, 2015

module Debug.Hoed.Pure.Prop where
-- ( judge
-- , Property(..)
-- ) where

import Debug.Hoed.Pure.Observe(Trace(..),UID,Event(..),Change(..))
import Debug.Hoed.Pure.Render(CompStmt(..))
import Debug.Hoed.Pure.CompTree(Vertex(..))
import Debug.Hoed.Pure.EventForest(EventForest,mkEventForest,dfsChildren)

import Prelude hiding (Right)
import Data.Graph.Libgraph(Judgement(..))
import System.Directory(createDirectoryIfMissing)
import System.Process(system)
import System.Exit(ExitCode(..))

------------------------------------------------------------------------------------------------------------------------

data Property = Property {moduleName :: String, propertyName :: String, searchPath :: String}

sourceFile = ".Hoed/exe/Main.hs"
exeFile    = ".Hoed/exe/Main"
outFile    = ".Hoed/exe/Main.out"

------------------------------------------------------------------------------------------------------------------------

judge' :: ExitCode -> String -> Judgement -> Judgement
judge' (ExitFailure _) _   j = j
judge' ExitSuccess     out j
  | out == "False\n" = Wrong
  | out == "True\n"  = j
  | otherwise     = j

judge :: Trace -> Property -> Vertex -> IO Vertex
judge trc prop v = do
  createDirectoryIfMissing True ".Hoed/exe"
  putStrLn $ "Picked statement identifier = " ++ show i
  generateCode
  compile
  exit' <- compile
  putStrLn $ "Exitted with " ++ show exit'
  exit  <- case exit' of (ExitFailure n) -> return (ExitFailure n)
                         ExitSuccess     -> evaluate
  out  <- readFile outFile
  putStrLn $ "Exitted with " ++ show exit
  putStrLn $ "Output is " ++ show out
  return v{vertexJmt=judge' exit out (vertexJmt v)}

  where generateCode = writeFile sourceFile (generate prop trc i)
        compile      = system $ "ghc -o " ++ exeFile ++ " " ++ sourceFile
        evaluate     = system $ exeFile ++ " &> " ++ outFile
        i            = (stmtIdentifier . vertexStmt) v

------------------------------------------------------------------------------------------------------------------------

generate :: Property -> Trace -> UID -> String
generate prop trc i = generateHeading prop ++ generateMain prop trc i

generateHeading :: Property -> String
generateHeading prop =
  "-- This file is generated by the Haskell debugger Hoed\n"
  ++ "import " ++ moduleName prop ++ "\n"

generateMain :: Property -> Trace -> UID -> String
generateMain prop trc i =
  "main = print $ " ++ propertyName prop ++ " " ++ generateArgs trc i ++ "\n"

generateArgs :: Trace -> UID -> String
generateArgs trc i = case dfsChildren frt e of
  [_,ma,_,_]  -> generateExpr frt ma
  xs          -> error ("generateArgs: dfsChildren (" ++ show e ++ ") = " ++ show xs)

  where frt = (mkEventForest trc)
        e   = (reverse trc) !! (i-1)

generateExpr :: EventForest -> Maybe Event -> String
generateExpr _ Nothing    = __
generateExpr frt (Just e) = -- enable to add events as comments to generated code: "{- " ++ show e ++ " -}" ++
                            case change e of
  (Cons _ s) -> foldl (\acc c -> acc ++ " " ++ c) ("(" ++ s) cs ++ ") "
  Enter      -> ""
  _          -> "error \"cannot represent\""

  where cs = map (generateExpr frt) (dfsChildren frt e)

__ :: String
__ = "(error \"Request of value that was unevaluated in orignal program.\")"

------------------------------------------------------------------------------------------------------------------------
-- Some test data

p1 :: Property
p1 = Property "MyModule" "prop_never" "../Prop"
-- p1 = Property "MyModule" "prop_idemSimplify" "../Prop"

v1 :: Vertex
v1 = Vertex (CompStmt "bla" 1 "bla 3 = 4") Unassessed

t1, t2 :: IO ()
t1 = print $ generate p1 [] 1
t2 = do {judge [] p1 v1; return ()}
