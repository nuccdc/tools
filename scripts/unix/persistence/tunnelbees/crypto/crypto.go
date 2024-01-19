package crypto

import (
	"crypto/rand"
	"math/big"
	"crypto/sha256"
)

func HashWithSalt(secret, salt *big.Int) *big.Int {
	secretBytes := secret.Bytes()
	saltBytes := salt.Bytes()

	data := append(secretBytes, saltBytes...)
	hash := sha256.Sum256(data)
	result := new(big.Int).SetBytes(hash[:])

	return result
}

func RandomRange(min, max *big.Int) *big.Int {
	rangeInt := new(big.Int).Sub(max, min)
	n, _ := rand.Int(rand.Reader, rangeInt)
	return n.Add(n, min)
}
