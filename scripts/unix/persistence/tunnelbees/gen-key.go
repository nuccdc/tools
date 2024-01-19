package main

import (
	"crypto/rand"
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"math/big"
	"tunnelbees/crypto"
)

// Define your data structure
type BigIntValues struct {
	P string `json:"p"`
	G string `json:"g"`
	X string `json:"x"`
}

func main() {
	filename := flag.String("file", "key.json", "Output filename for the JSON data")
	bits := flag.Int("bits", 2048, "Number of bits for the prime generation")

	flag.Usage = func() {
		fmt.Fprintf(flag.CommandLine.Output(), "Usage of gen-key.go \n")
		fmt.Println("Generates a JSON file with random BigInt values for use in the Tunnelbees handshake.")
		flag.PrintDefaults()
	}

	flag.Parse()

	if flag.Lookup("help") != nil || flag.Lookup("h") != nil {
		flag.Usage()
		return
	}

	// Generate values for p, g, x
	p, _ := rand.Prime(rand.Reader, *bits)
	g := crypto.RandomRange(big.NewInt(2), new(big.Int).Sub(p, big.NewInt(1)))
	x := crypto.RandomRange(big.NewInt(2), new(big.Int).Sub(p, big.NewInt(2)))

	// Create the struct
	values := BigIntValues{
		P: p.String(),
		G: g.String(),
		X: x.String(),
	}

	// Marshal to JSON
	jsonData, err := json.MarshalIndent(values, "", "  ")
	if err != nil {
		fmt.Println("Error marshalling JSON:", err)
		return
	}

	err = ioutil.WriteFile(*filename, jsonData, 0644)
	if err != nil {
		fmt.Println("Error writing to file:", err)
		return
	}
}
