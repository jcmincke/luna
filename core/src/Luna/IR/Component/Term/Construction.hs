{-# LANGUAGE TypeInType           #-}
{-# LANGUAGE UndecidableInstances #-}

module Luna.IR.Component.Term.Construction where

import Prologue

import qualified Data.Tag                         as Tag
import qualified Foreign.Storable.Deriving        as Storable
import qualified Foreign.Storable1.Deriving       as Storable1
import qualified Luna.IR.Component.Link           as Link
import qualified Luna.IR.Component.Link.TH        as Link
import qualified Luna.IR.Component.Term.Class     as Term
import qualified Luna.IR.Component.Term.Discovery as Discovery
import qualified Luna.IR.Component.Term.Layer     as Layer
import qualified Luna.IR.Term.Format              as Format
import qualified OCI.IR.Component                 as Component
import qualified OCI.IR.Layer                     as Layer
import qualified OCI.IR.Layout                    as Layout

import Luna.IR.Component.Term.Class (Term, Terms)
import Luna.IR.Component.Term.Layer (Model)
import OCI.IR.Component             (Component)



------------------------------
-- === Top construction === --
------------------------------

-- === DefaultType === --

class DefaultType m where
    defaultType :: m (Term ())


-- === Contexts === --

type UntypedCreator t m =
    ( Component.Creator Terms   m
    , Layer.Writer  Terms Model m
    , Layer.IsCons1 Model (Term.TagToCons t)
    , Layer.IsUnwrapped Term.Uni
    )

type Creator tag m =
    ( UntypedCreator tag m
    , Link.Creator m
    , Layer.Writer Terms Layer.Type m
    , DefaultType m
    )


-- TODO[WD]: Rename, its used as Req term construction when tag is known
type CreatorX m =
    ( Link.Creator m
    , Layer.Writer Terms Layer.Type m
    , DefaultType m
    , Component.Creator Terms   m
    , Layer.Writer  Terms Model m
    )


-- === Construction === --

type LayoutModelCheck tag layout = Layout.Get Model layout ~ tag

uncheckedUntypedNewM :: UntypedCreator tag m
    => (Term any -> m (Term.TagToCons tag layout)) -> m (Term any)
uncheckedUntypedNewM !cons = do
    ir <- Component.new1 @(Component Terms)
    let !ir' = Layout.unsafeRelayout ir
    !term <- cons ir'
    Layer.write @Model ir $! Layer.cons1 @Model term
    pure ir'
{-# INLINE uncheckedUntypedNewM #-}

untypedNewM :: ( UntypedCreator tag m, LayoutModelCheck tag layout)
     => (Term layout -> m (Term.TagToCons tag layout)) -> m (Term layout)
untypedNewM = uncheckedUntypedNewM ; {-# INLINE untypedNewM #-}

uncheckedUntypedNew :: UntypedCreator tag m
                    => Term.TagToCons tag layout -> m (Term any)
uncheckedUntypedNew = uncheckedUntypedNewM . const . pure ; {-# INLINE uncheckedUntypedNew #-}

untypedNew :: (UntypedCreator tag m, Layout.AssertEQ Model layout tag)
    => Term.TagToCons tag layout -> m (Term layout)
untypedNew = uncheckedUntypedNew ; {-# INLINE untypedNew #-}

uncheckedNewM :: Creator tag m
              => (Term any -> m (Term.TagToCons tag layout)) -> m (Term any)
uncheckedNewM !cons = uncheckedUntypedNewM $ \self -> do
    typeTerm <- defaultType
    typeLink <- Link.new typeTerm self
    Layer.write @Layer.Type self (Layout.unsafeRelayout typeLink)
    cons self
{-# INLINE uncheckedNewM #-}

newM :: (Creator tag m, LayoutModelCheck tag layout)
     => (Term layout -> m (Term.TagToCons tag layout)) -> m (Term layout)
newM = uncheckedNewM ; {-# INLINE newM #-}

uncheckedNew :: Creator tag m => Term.TagToCons tag layout -> m (Term any)
uncheckedNew = uncheckedNewM . const . pure ; {-# INLINE uncheckedNew #-}
