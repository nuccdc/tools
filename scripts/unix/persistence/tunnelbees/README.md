# Tunnelbees
Tunnelbees is a SSH honeypot that can securely let a client through given a shared secret. By default, the Tunnelbees server will open ports 1 through 4096 to a SSH honeypot. Through a zero-knowledge handshake demonstrating shared knowledge of a secret, a client and the Tunnelbees server can agree on a temporary, random port to open to proper SSH. This scheme is designed to be resistant to a powerful attacker that can observe, analyze, and replay packets, as well as scan ports. 

Tunnelbees uses Schnorr signatures for the interactive zero-knowledge scheme. Likewise, Tunnelbees relies on the discrete logarithm problem, so Shor's algorithm can efficiently crack this.

Nmap scan of Tunnelbees ports (312 is the zk exchange port):
```
$ nmap -p- -sV --open -v 127.0.0.1
...
283/tcp   open  ssh     OpenSSH 8d366a49a7e32601eaf9a568 (protocol 2.0)
284/tcp   open  ssh     OpenSSH c700e7ddb528c40081ce8421 (protocol 2.0)
285/tcp   open  ssh     OpenSSH f80a3791a6394d457a6b67bc (protocol 2.0)
286/tcp   open  ssh     OpenSSH 8c09f8fb7cf982e18ade6ea5 (protocol 2.0)
287/tcp   open  ssh     OpenSSH 25dbb3cdfd710ca402f55e31 (protocol 2.0)
288/tcp   open  ssh     OpenSSH a26f132b4fc7a04c1b1ff4b1 (protocol 2.0)
289/tcp   open  ssh     OpenSSH 23e36f26e19553b9dcc54bad (protocol 2.0)
290/tcp   open  ssh     OpenSSH 3acbaeb37ed35570a2a71513 (protocol 2.0)
291/tcp   open  ssh     OpenSSH 7c72bef4805caa09d85e0e54 (protocol 2.0)
292/tcp   open  ssh     OpenSSH 49e68bc22f927bfcbada5e7b (protocol 2.0)
293/tcp   open  ssh     OpenSSH 0b28c96f5e5b845564557bdb (protocol 2.0)
294/tcp   open  ssh     OpenSSH ee0e6bf06bc12a8f31fd6528 (protocol 2.0)
295/tcp   open  ssh     OpenSSH f789edfb2c4d9424c81d9779 (protocol 2.0)
296/tcp   open  ssh     OpenSSH dd6d71880e8f309929774f26 (protocol 2.0)
297/tcp   open  ssh     OpenSSH 7f293cea12025369d239f415 (protocol 2.0)
298/tcp   open  ssh     OpenSSH d2ef7d4e39d892dcfa6f80fc (protocol 2.0)
299/tcp   open  ssh     OpenSSH 2277c5a6ed4421b23dccc3b4 (protocol 2.0)
300/tcp   open  ssh     OpenSSH bbbc80c759701b22e89d9b26 (protocol 2.0)
301/tcp   open  ssh     OpenSSH a961cfd27d15aa372a51b8b2 (protocol 2.0)
302/tcp   open  ssh     OpenSSH c152982ede5f973343ac8bbb (protocol 2.0)
303/tcp   open  ssh     OpenSSH e8eb78b3797f1a8ad6d954a0 (protocol 2.0)
304/tcp   open  ssh     OpenSSH 892fa361bb71edaa84dee9cf (protocol 2.0)
305/tcp   open  ssh     OpenSSH 9b75b5e180b0f4cc9db0a26b (protocol 2.0)
306/tcp   open  ssh     OpenSSH dd473975daa83b6e5ca9f720 (protocol 2.0)
307/tcp   open  ssh     OpenSSH ae1203a288fa97e18a59aac0 (protocol 2.0)
308/tcp   open  ssh     OpenSSH 5d9fdc0b04f51a6fc34f338b (protocol 2.0)
309/tcp   open  ssh     OpenSSH dde07fbc465389f7a02647f6 (protocol 2.0)
310/tcp   open  ssh     OpenSSH 5d5bceaa466ef54eb01d3637 (protocol 2.0)
311/tcp   open  ssh     OpenSSH 1c4c9f8e28ae75610b314237 (protocol 2.0)
312/tcp   open  vslmp?
313/tcp   open  ssh     OpenSSH 6cf45e11db5cfcbfd9ab5a76 (protocol 2.0)
314/tcp   open  ssh     OpenSSH 9ae0773d4016cb84354b2a17 (protocol 2.0)
315/tcp   open  ssh     OpenSSH 6a945f0cdfc2d8d7d181483f (protocol 2.0)
316/tcp   open  ssh     OpenSSH 564d66871c4e384575fe08c2 (protocol 2.0)
317/tcp   open  ssh     OpenSSH 694b7b80342b905dc8a8c547 (protocol 2.0)
318/tcp   open  ssh     OpenSSH 71404e25cd8156d9e554c661 (protocol 2.0)
319/tcp   open  ssh     OpenSSH 534a23f0911efb9422af016b (protocol 2.0)
320/tcp   open  ssh     OpenSSH 71094eef35aca86f1f670312 (protocol 2.0)
321/tcp   open  ssh     OpenSSH b56c335548d77c1cfc058b7c (protocol 2.0)
322/tcp   open  ssh     OpenSSH aa6c5776e4fee5f015c52b35 (protocol 2.0)
...
```

## Why Tunnelbees is better than port knocking
[Port knocking](https://wiki.archlinux.org/title/Port_knocking) is a method to externally open ports that, by default, are closed. Usually the "knocking" involves a series 
 of connection attempts on predefined ports. This is *security by obscurity* - generally bad security practice. A listening attacker could observe the port knocking sequence and gain access to the open port.

Tunnelbees nicely takes care of this problem. In exchange for a stronger initial assumption - shared knowledge of a secret - a client and a server can agree on a random port to open to a connection. A listening adversary would have to go through the discrete logarithm problem to gain consistent access to the server's open port.

# Usage
Generate a `key` file with `gen-key.go`:
```
$ go run gen-key.go -bits [int] -file [key.json]
```
I suggest using a key over 1024 bits to ensure solving the discrete logarithm problem is sufficiently hard.

To run the server:
```
$ go run tb-server.go -eport [HANDSHAKE_PORT] -username [USERNAME] -pass [PASSWORD] -key [filename.json]
```

To run the client to securely access the server:
```
$ go run tb-client.go -eport [HANDSHAKE_PORT] -username [USERNAME] -pass [PASSWORD] -key [KEY_PATH] -host [HOST]
```

# How it works (high-level)
- Both the client and the server have shared knowledge of a secret, `x`
- The client commits and sends a random variable `t`
- Based on `t`, the server sends a challenge `c` to the client
- The client responds to the challenge `c` with a proof `p`
- `p` is verified by the server
- Given `x`, `t`, the client and the server independently calculate `N = Hash(Salt(x,t)) % 4096`
- The server temporarily opens `N`, the client tries to SSH on port `N`
- Given the publicly displayed values, `t`, `N`, `c`, and `p`, an attacker would have to go through the discrete logarithm problem to obtain `x`

# Todo
- [x] make a "silent" ver that keeps no ports open by default
- [x] use randomly generated public key crypto for auth instead of user/password. can permute public key based on secret such that an attacker can't MITM insert their key.
- [ ] if i'm bored, develop a formal model for the handshake

# Misc
The name "tunnelbees" is inspired by the Roman historian Appian. In his account of the Third Mithridatic War, he writes:
> With another army Lucullus besieged Themiscyra, which is named after one of the Amazons and is situated on the river Thermodon. The besiegers of this place brought up towers, built mounds, and dug tunnels so large that great subterranean battles could be fought in them. The inhabitants cut openings into these tunnels from above and thrust bears and other wild animals and swarms of bees into them against the workers. 

Also ty [federico](https://github.com/cassanof) for the inspiration
