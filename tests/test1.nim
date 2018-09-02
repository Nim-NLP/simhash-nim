import simhash

when isMainModule:
    let a = 0xDEADBEEF;
    let b = 0xDEADBEAD;
    let expected = 2;
    assert numDifferingBits(a,b) == expected
    
    let sh3 = initSimhash(["aaa", "bbb"])
    let sh4 = initSimhash([ ("aaa",1), ("bbb",1)])
    
    assert sh4.value == sh3.value
    assert $sh4 == "57087923692560392"

    let sh = initSimhash("How are you? I AM fine. Thanks. And you?")
    let sh2 = initSimhash("How old are you ? :-) i am fine. Thanks. And you?")
    assert sh.distance(sh2) > 0