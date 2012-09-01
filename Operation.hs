module Operation where

import Control.Monad
import Data.Bits
import Data.Word

import Arch

data Operation = OP_BIT_OR | OP_BIT_AND | OP_ADD | OP_MUL
               | OP_RESERVED0 | OP_SHIFTL | OP_LT | OP_EQ
               | OP_GT | OP_BIT_ANDN | OP_BIT_XOR | OP_SUB
               | OP_BIT_XORN | OP_SHIFTR | OP_NEQ | OP_RESERVED1
  deriving Enum

extract :: Word32 -> Int -> Int -> Word32
extract word start len = (shiftR word start) .&. (shiftL 1 len - 1)

sex :: Word32 -> Word32
sex n = n .|. (0xfffff800 * ((shiftR n 11) .&. 1))

eval :: Word32 -> CPU ()
eval word = case mode of
  0 -> do res <- result; setReg z res
  1 -> do res <- result; m <- getMem res; setReg z m
  2 -> do res <- result; dst <- getReg z; setMem dst res
  _ -> do res <- result; src <- getReg z; setMem res src
  where swap = (== 1) $ extract word 30 2
        mode = fromIntegral $ extract word 28 2
        z = toEnum $ fromIntegral $ extract word 24 4
        x = getReg $ toEnum $ fromIntegral $ extract word 20 4
        y = getReg $ toEnum $ fromIntegral $ extract word 16 4
        f = liftM2 $ getOp $ toEnum $ fromIntegral $ extract word 12 4
        imm = return $ sex $ extract word 0 12
        addM = liftM2 (+)
        result = if swap then f x imm `addM` y else f x y `addM` imm

boolToReg :: Bool -> Word32
boolToReg False = 0x00000000
boolToReg True = 0xffffffff

-- TODO: Explain this
foo :: Word32 -> Word32
foo = xor 0x80000000

getOp :: Operation -> (Word32 -> Word32 -> Word32)
getOp OP_BIT_OR = \x y -> x .|. y
getOp OP_BIT_AND = \x y -> x .&. y
getOp OP_ADD = \x y -> x + y
getOp OP_MUL = \x y -> x * y
getOp OP_SHIFTL = \x y -> x * (2 ^ y)
getOp OP_LT = \x y -> boolToReg (foo x < foo y)
getOp OP_EQ = \x y -> boolToReg (x == y)
getOp OP_GT = \x y -> boolToReg (foo x > foo y)
getOp OP_BIT_ANDN = \x y -> x .&. (complement y)
getOp OP_BIT_XOR = \x y -> x `xor` y
getOp OP_SUB = \x y -> x - y
getOp OP_BIT_XORN = \x y -> x `xor` (complement y)
getOp OP_SHIFTR = \x y -> x `div` (2 ^ y)
getOp OP_NEQ = \x y -> boolToReg (x /= y)

