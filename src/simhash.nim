# simhash_nim
# Copyright zhoupeng
# Nim implementation of simhash algoritim

import bitops
import nre
import md5
import strutils,sequtils
import lc

const 
    defaultReg = r"[\w]+"
    defaultF = 64

type 
    Simhash* = object
        f*:int
        reg*:Regex
        value*:int64
        hashfunc*:proc (s: string): int

proc `$`*(self:Simhash):string =
    result = $(self.value)

proc `==`*(a,b:Simhash):bool =
    result = a.value == b.value

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

proc defaultHashFunc(a:string) :int =
    result = parseHexInt($a.toMD5)

proc tokenize(self:Simhash,content:string) : seq[string] {.noInit.} =
    result = lc[y | (y <- tokenize(self.reg,content)),string ]

iterator iterMasks(f:int):tuple[key:int,val:int] =
    for res in 0..<f:
        yield (key:res,val:1 shl res)

proc buildByFeatures*[T]( self:var Simhash, features:T):int =
    var 
        v = newSeq[int](self.f)
        h:int
        w:int
        t:int
    for f in features:
        h = self.hashfunc(f[0])
        w = f[1]
        for i,mask in iterMasks(self.f):
            t = if (h and mask) != 0 : w else : -w
            v[i] += t
    var ans = 0
    for i,mask in iterMasks(self.f):
        if v[i] > 0:
            result = (result or mask)

proc buildByText*(self:var Simhash, content:string):int =
    var 
        features = self.tokenize(content)
        r:seq[tuple[k:string,w:int]] = @[]
    var meet:string
    for x in features:
        if x != meet:
            let c = count(features,x)
            r.add( (k:x,w:c) )
            meet = x
    result = self.buildByFeatures(r)
        
proc fromText*(self:var Simhash, content:string) =
    self.value = self.buildByText(content)

proc fromFeatures*[T]( self:var Simhash, features:T) =
    self.value = self.buildByFeatures(features)
            
proc numDifferingBits*(a,b:SomeInteger):SomeInteger=
    result = popcount(a xor b)

proc distance*(self:Simhash,other:Simhash):int64 =
    result = numDifferingBits(self.value,other.value)

proc getFeature[T](features:T):seq[tuple[k:string,w:int]] =
    for x in features:
        result.add( (k:x,w:1) )

proc initSimhash*(value:string, f=defaultF, reg = defaultReg, hashfunc = defaultHashFunc ) : Simhash =
    result = Simhash(f:f,reg:re(reg),hashfunc:hashfunc)
    result.fromText(value)

proc initSimhash*(features:seq[tuple[k:string,w:int]] , f = defaultF, reg = defaultReg, hashfunc = defaultHashFunc ) : Simhash =
    result = Simhash(f:f,reg:re(reg),hashfunc:hashfunc)
    result.fromFeatures(features)

proc initSimhash*(features: openArray[tuple[k:string,w:int]], f = defaultF, reg = defaultReg, hashfunc = defaultHashFunc ) : Simhash =
    result = Simhash(f:f,reg:re(reg),hashfunc:hashfunc)
    result.fromFeatures(features)

proc initSimhash*(features:seq[string], f = defaultF, reg = defaultReg, hashfunc = defaultHashFunc ) : Simhash =
    result = Simhash(f:f,reg:re(reg),hashfunc:hashfunc)
    result.fromFeatures(getFeature(features))

proc initSimhash*(features:openArray[string], f = defaultF, reg = defaultReg, hashfunc = defaultHashFunc ) : Simhash =
    result = Simhash(f:f,reg:re(reg),hashfunc:hashfunc)
    result.fromFeatures(getFeature(features))
