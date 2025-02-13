module SubmitAPI.Config
  ( FeePolicy(..)
  , CollateralPolicy(..)
  , TxAssemblyConfig(..)
  , DefaultChangeAddress(..)
  , UnsafeEvalConfig(..)
  , unwrapChangeAddress
  ) where

import qualified Dhall         as D
import Dhall.Core (Expr(..), Chunks(..))
import           GHC.Generics

import           Ledger               (Address)
import qualified Cardano.Api          as C
import qualified Ledger.Tx.CardanoAPI as Interop
import           CardanoTx.Models     (ChangeAddress(..))
import Dhall (Natural)

data FeePolicy
  = Strict  -- Require existing TX inputs to cover fee entirely
  | Balance -- Allow adding new inputs to cover fee
  deriving Generic

instance D.FromDhall FeePolicy

data CollateralPolicy
  = Ignore -- Ignore collateral inputs
  | Cover  -- Allow adding new inputs to cover collateral
  deriving Generic

instance D.FromDhall CollateralPolicy

data TxAssemblyConfig = TxAssemblyConfig
  { feePolicy         :: FeePolicy
  , collateralPolicy  :: CollateralPolicy
  , deafultChangeAddr :: DefaultChangeAddress
  } deriving Generic

instance D.FromDhall TxAssemblyConfig

data UnsafeEvalConfig = UnsafeEvalConfig
  { unsafeTxFee :: Integer
  , exUnits     :: Natural
  , exMem       :: Natural
  } deriving Generic

instance D.FromDhall UnsafeEvalConfig

newtype DefaultChangeAddress = DefaultChangeAddress { getChangeAddr :: ChangeAddress }

unwrapChangeAddress :: DefaultChangeAddress -> Address
unwrapChangeAddress (DefaultChangeAddress (ChangeAddress addr)) = addr

instance D.FromDhall DefaultChangeAddress where
  autoWith _ = D.Decoder{..}
    where
      extract (TextLit (Chunks [] t)) =
        maybe (D.extractError "Invalid Shelly Address") (pure . DefaultChangeAddress . ChangeAddress) (do
          caddr <- C.deserialiseAddress (C.AsAddress C.AsShelleyAddr) t 
          either (const Nothing) pure (Interop.fromCardanoAddressInEra (C.shelleyAddressInEra caddr :: C.AddressInEra C.BabbageEra)))
      extract  expr = D.typeError expected expr

      expected = pure Text
