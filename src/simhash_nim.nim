# simhash_nim
# Copyright zhoupeng
# Nim implementation of simhash algoritim

import bitops
import nre
import md5
import sugar
import strutils
import sequtils
import parseutils
import math

const 
    defaultReg = r"[\w]+"
    defaultF = 64

type 
    Simhash* = object
        f:int
        reg:Regex
        value:int64
        hashfunc:proc (s: string): array[0..15, uint8]

iterator slide(content:string, width=4) : string =
    let maxLen = max(content.len - width + 1, 1)
    for i in 0..<maxLen:
        let pos = i + width
        yield content[i..<pos]

iterator tokenize(reg:Regex, content:string) : string = 
    let lowers = content.toLowerAscii
    let tokens = lowers.findAll(reg).join("")
    for x in slide(tokens):
        yield x

proc tokenize(self:Simhash,content:string) : seq[string] {.noInit.} =
    result = lc[y | (y <- tokenize(self.reg,content)),string ]

iterator iterMasks(f:int):tuple[key:int,val:int] =
    for res in 0..<f:
        yield (key:res,val:1 shl res)

proc buildByFeatures[T]( self:var Simhash, features:T) =
    var 
        v = newSeq[int](self.f)
        h:MD5Digest
        w:int
        t:int
    for f in features:
        h = self.hashfunc(f[0])
        w = f[1]
        for i,mask in iterMasks(self.f):
            t = if (parseHexInt($h) and mask) != 0 : w else : -w
            v[i] += t
    var ans = 0
    for i,mask in iterMasks(self.f):
        if v[i] > 0:
            ans = (ans or mask)
    self.value = ans
    
proc buildByText(self:var Simhash, content:string) =
    var 
        features = self.tokenize(content)
        r:seq[tuple[k:string,w:int]] = @[]
    var meet:string
    for x in features:
        if x != meet:
            let c = count(features,x)
            r.add( (k:x,w:c) )
            meet = x
    self.buildByFeatures(r)
    
proc numDifferingBits*(a,b:SomeInteger):SomeInteger=
    result = popcount(a xor b)

proc distance(self:Simhash,other:Simhash):int64 =
    result = numDifferingBits(self.value,other.value)

proc getFeature[T](features:T):seq[tuple[k:string,w:int]] =
    for x in features:
        result.add( (k:x,w:1) )

proc initSimhash*(value:string, f=defaultF, reg = defaultReg, hashfunc = toMD5 ) : Simhash =
    result = Simhash(f:f,reg:re(reg),hashfunc:hashfunc)
    result.buildByText(value)

proc initSimhash*(features:seq[tuple[k:string,w:int]] , f = defaultF, reg = defaultReg, hashfunc = toMD5 ) : Simhash =
    result = Simhash(f:f,reg:re(reg),hashfunc:hashfunc)
    result.build_by_features(features)

proc initSimhash*(features: openArray[tuple[k:string,w:int]], f = defaultF, reg = defaultReg, hashfunc = toMD5 ) : Simhash =
    result = Simhash(f:f,reg:re(reg),hashfunc:hashfunc)
    result.build_by_features(features)

proc initSimhash*(features:seq[string], f = defaultF, reg = defaultReg, hashfunc = toMD5 ) : Simhash =
    result = Simhash(f:f,reg:re(reg),hashfunc:hashfunc)
    result.build_by_features(getFeature(features))

proc initSimhash*(features:openArray[string], f = defaultF, reg = defaultReg, hashfunc = toMD5 ) : Simhash =
    result = Simhash(f:f,reg:re(reg),hashfunc:hashfunc)
    result.build_by_features(getFeature(features))

when isMainModule:
    let a = 0xDEADBEEF;
    let b = 0xDEADBEAD;
    let expected = 2;
    assert numDifferingBits(a,b) == expected
    let sh3 = initSimhash(["aaa", "bbb"])
    assert sh3.value == 57087923692560392

    let sh4 = initSimhash([ ("aaa",1), ("bbb",1)])
    assert sh4.value == 57087923692560392

    let sh = initSimhash("How are you? I AM fine. Thanks. And you?")
    let sh2 = initSimhash("How old are you ? :-) i am fine. Thanks. And you?")
    assert sh.distance(sh2) > 0

    