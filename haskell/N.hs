import System.FilePath
import Text.Regex
import Text.Regex.TDFA
import Data.Bool
import Data.List

mR = mkRegex
sR a b c = subRegex (mR a) c b
spR a = splitRegex (mR a)

type URI = String
type Graph = URI

data E = E URI Graph
e u = E u "_"

instance Show E where
    show (E u _)= "<" ++ u ++ ">"

-- constants
eBase = t "house"
eSep  = ".%/"
eB = "./"

firstMatch r s = case s =~ r :: (String,String,String,[String]) of
                   (_,_,_,[c]) -> c
                   (_,_,_,_)  -> ""                  
                   
base = eU takeBaseName

host (E u _) = sR "^www\\." "" (firstMatch "http://([^\\/]+)" u)

path = eU $ firstMatch "http://[^\\/]+(.*)"

dirname = eU takeDirectory

t = ( ++ "/")

uri :: E -> URI
uri (E u _) = u

-- liftURI
eU f (E u g) = E (f u) g

-- URI -> path
d e@(E u g) = eB ++ (gu e) ++ u

gu (E _ g) = uri $ u (E g g)

u :: E -> E
u e = as e eSep
-- cons URI
s :: E -> E -> E
s e = aE (u e)

-- triple URI
ou :: E -> E -> E -> E
ou r p = s (s r p)

-- uri++
a :: E -> URI -> E
a e s = eU (++ s) e
aE e (E u _) = a e u

-- uri/
tu = eU t

-- uri/++
as :: E -> URI -> E
as e = a (tu e)

-- _ _.. o -> o URI
ro (E u g) = E (up . last $ spR eSep u) g

up = sR "^([a-z]+:/)([^/])" "\\1/\\2"

-- GET path -> URI

doc = eU (head . spR "#")

dive :: String -> String
-- dive ['a'..'z'] = "ab/cd/efghijklmnopqrstuvwxyz"
dive s | length s > 3 = [s!!0,s!!1,'/',s!!2,s!!3,'/']++drop 4 s
       | otherwise = s

label :: URI -> String
label = gsub '_' ' ' . last . spR "[/#]" . sR "/$" ""

gsub :: Eq a => a -> a -> [a] -> [a]
gsub a b = map (\c -> case c == a of
                        True -> b
                        False -> c )

-- literal resources

li :: String -> E
li o | length o <=88 && not ('/' `elem` o) = e $ "u/" ++ liU o ++ "/" ++ o
     | o =~ "^[a-z]+://[a-zA-Z0-9_/]+$" :: Bool = e o
     | otherwise = liB o


liU o | o =~ "^[0-9]{4}[^0-9]" :: Bool = sR "[\\.:\\-T+]" "/" o
      | otherwise = (intersperse '/' $ take 5 o ) ++ drop 5 o

liB o = undefined

--ru p = 
