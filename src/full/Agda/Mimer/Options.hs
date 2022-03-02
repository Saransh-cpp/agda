module Agda.Mimer.Options where
import Agda.Interaction.BasicOps (parseExprIn)
import Agda.Auto.Options (parseTime)
import Agda.Syntax.Common (Nat)
import Agda.Syntax.Abstract.Name (QName)
import Agda.TypeChecking.Monad.Base (TCM)
import Agda.Interaction.Highlighting.Range (empty)
import Agda.Syntax.Common (InteractionId)
import Agda.Syntax.Position (Range)
import qualified Agda.Syntax.Abstract as A
import qualified Agda.Syntax.Abstract.Name as AN
import Agda.Utils.Maybe (catMaybes)
import Agda.Utils.Pretty (Pretty, pretty, text)

type MilliSeconds = Int

data HintMode = Unqualified | AllModules | Module | NoHints
  deriving (Eq, Show)

data Options = Options
  { optTimeout :: MilliSeconds
  , optHintMode :: HintMode
  , optExplicitHints :: [QName]
  } deriving Show

parseOptions :: InteractionId -> Range -> String -> TCM Options
parseOptions ii range argStr = do
  let tokens = readTokens $ words argStr
  -- TODO: Use 'parseName' instead?
  hintExprs <- sequence [parseExprIn ii range h | H h <- tokens]
  let hints = catMaybes $ map hintExprToQName hintExprs
  return Options
    { optTimeout = firstOr 1000 [parseTime t | T t <- tokens]
    -- TODO: Do arg properly
    , optHintMode = firstOr NoHints ([Module | M <- tokens] ++ [Unqualified | R <- tokens])
    , optExplicitHints = hints
    }

hintExprToQName :: A.Expr -> Maybe QName
hintExprToQName (A.ScopedExpr _ e) = hintExprToQName e
hintExprToQName (A.Def qname)      = Just $ qname
hintExprToQName (A.Proj _ qname)   = Just $ AN.headAmbQ qname
hintExprToQName (A.Con qname)      = Just $ AN.headAmbQ qname
hintExprToQName _ = Nothing

firstOr :: a -> [a] -> a
firstOr x [] = x
firstOr _ (x:_) = x


data Token = T String | M | R | C | L String | H String
  deriving (Eq, Show)

readTokens :: [String] -> [Token]
readTokens []              = []
readTokens ("-t" : t : ws) = T t        : readTokens ws
readTokens ("-l" : n : ws) = L n        : readTokens ws
readTokens ("-m"     : ws) = M          : readTokens ws
readTokens ("-c"     : ws) = C          : readTokens ws
readTokens ("-r"     : ws) = R          : readTokens ws
readTokens (h        : ws) = H h        : readTokens ws

instance Pretty HintMode where
  pretty = text . show

-- instance Pretty Options where
--   prettyht
