{-# LANGUAGE TypeSynonymInstances #-}

module CSS where

import Control.Applicative
import Control.Monad (MonadPlus(..), ap)
import Text.ParserCombinators.Parsec hiding (many, optional, (<|>))
import qualified Text.Parsec.Token as P
import Text.Parsec.Language
import Text.ParserCombinators.Parsec.Language
import Data.List
import Data.Char ( digitToInt )

instance Applicative (GenParser s a) where
    pure  = return
    (<*>) = ap

lexer = P.makeTokenParser (emptyDef {
                             commentStart = "/*"
                           , commentEnd = "*/"})

brace      = P.braces lexer
semi       = P.semi lexer
symbol     = P.symbol lexer
lexeme     = P.lexeme lexer
commaSep   = P.commaSep lexer
hexadecimal= P.hexadecimal lexer
whiteSpace = P.whiteSpace lexer
trystring = try.string

data CSSsheet = CSSsheet [CSSstatement]
data CSSstatement = CSSruleset {selector :: CSSsel, rules :: [CSSrule] } 
                  | CSSimport CSSval
data CSSrule = CSSrule {key:: String, val :: [CSSval] }
data CSSval = CSSsize {len :: Double, unit :: CSSunit}
            | CSSurl String 
            | CSSkeyword String 
            | CSScolor {r :: Integer, g :: Integer, b :: Integer}
            | CSSstring String
data CSSsel = CSSsel [String]
data CSSunit = Cm | Em | Ex | In | Mm | Pc | Percent | Pt | Px | Un
             deriving (Read, Enum)

instance Show CSSunit where
    show (Em) = "em"
    show (Ex) = "ex"
    show (Px) = "px"
    show (In) = "in"
    show (Cm) = "cm"
    show (Mm) = "mm"
    show (Pt) = "pt"
    show (Pc) = "pc"
    show (Percent) = "%"
    show (Un)      = ""

instance Show CSSval where
    show (CSSsize l u) = (show l) ++ (show u)
    show (CSSurl u) = "url(" ++ u ++ ")"
    show (CSSkeyword s) = s
    show (CSSstring s) = s
    show (CSScolor r g b) = "rgb(" ++ (sintercalate "," [r,g,b]) ++ ")"

instance Show CSSstatement where
    show (CSSruleset s r) = (show s) ++ " {" ++ (sintercalate "; " r) ++ "}"
    show (CSSimport u) = "@import " ++ (show u) ++ ";"

instance Show CSSsel where
    show (CSSsel s) = spaceout s

instance Show CSSrule where
    show (CSSrule k v) = k ++ ": " ++ (spaceout $ map show v)

instance Show CSSsheet where
    show (CSSsheet r) = sintercalate "\n" r

sintercalate s v = intercalate s $ map show v
spaceout = intercalate " "

floatLiteral = do n <- lookAhead (char '.') *> pure 0 <|> decimal
                  fract <- option 0 fraction
                  return (fromInteger n + fract)

fraction        = do char '.'
                     digits <- option ['0'] (many1 digit)
                     return (foldr op 0.0 digits)
                where
                  op d f    = (f + fromIntegral (digitToInt d))/10.0
decimal         = number 10 digit

number base baseDigit
    = do digits <- many1 baseDigit
         let n = foldl (\x d -> base*x + toInteger (digitToInt d)) 0 digits
         seq n (return n)

parseCSSnum = ((try $ negate <$ char '-' <* lookAhead digit) <|> pure id) <*> floatLiteral

parseCSSsel = CSSsel <$> many (lexeme (many1 (noneOf "{ \n\r")))

brokenrule = many1 (noneOf ";}") >> pure [(CSSstring "")]

parseCSSrule = do i <- parseCSSid
                  v <- (char ':' *> whiteSpace *> many parseCSSval) <|> brokenrule
                  return $ CSSrule i v

parseCSSval = (parseCSSsize <|> parseCSSurl <|> parseCSScolor <|> parseCSSkeyword) <* whiteSpace

parseCSSsize = CSSsize <$> parseCSSnum <*> parseCSSunit

parseCSSunit = (char '%' *> pure Percent <|>
                trystring "em" *> pure Em <|>
                trystring "px" *> pure Px <|>
                trystring "ex" *> pure Ex <|>
                trystring "in" *> pure In <|>
                trystring "cm" *> pure Cm <|>
                trystring "mm" *> pure Mm <|>
                trystring "pt" *> pure Pt <|>
                trystring "pc" *> pure Pc <|>
                pure Un)

parseCSSurl = CSSurl <$> (trystring "url(" *> many (noneOf ")") <* char ')')

parseCSScolor = parseCSScolorHex <|> parseCSScolorRGB                

parseCSScolorHex = do char '#'; d <- many1 hexDigit
                      return $ hex (map (toInteger.digitToInt) d)
                 where
                   hex l | length l == 3 = hex3 l
                         | otherwise     = hex6 l
                   hex3 (r:g:b:[]) = hex6 [r,r,g,g,b,b]
                   hex6 (r:r':g:g':b:b':[]) = CSScolor (16*r+r') (16*g+g') (16*b+b')

parseCSScolorRGB = do trystring "rgb("
                      (r:g:b:[]) <- commaSep (lexeme decimal)
                      char ')'
                      return $ CSScolor r g b

parseCSSkeyword = CSSkeyword <$> many1 (noneOf " ;}")

parseCSSid :: Parser String
parseCSSid = many (alphaNum <|> char '-' <|> char '_')

parseCSSimport = CSSimport <$> (trystring "@import" *> whiteSpace *> parseCSSurl) <* manyTill anyChar semi

parseCSSruleset = CSSruleset <$> parseCSSsel <*> brace (sepEndBy parseCSSrule semi)

parseCSSstatement :: Parser CSSstatement
parseCSSstatement = parseCSSimport <|> parseCSSruleset
               
stylesheet :: Parser CSSsheet
stylesheet = CSSsheet <$> (whiteSpace *> many parseCSSstatement)
