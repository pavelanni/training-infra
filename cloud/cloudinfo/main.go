package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"

	flag "github.com/spf13/pflag"
)

const (
	cloudInfoDir = "cloud_addresses"
	cloudInfoOut = "cloud_info.json"
	username     = "minio"
	domain       = "miniolabs.net"
)

type CloudInfo struct {
	Email   string  `json:"email"`
	Profile Profile `json:"profile"`
}

type Profile struct {
	Hostname   string `json:"hostname"`
	Username   string `json:"username"`
	IPAddress  string `json:"ip_address"`
	PrivateKey string `json:"private_key"`
}

type InputItem struct {
	Email string `json:"email"`
}

func readEmailsFromFile(filename string) ([]string, error) {
	data, err := os.ReadFile(filename)
	if err != nil {
		return nil, fmt.Errorf("error reading input file: %v", err)
	}

	var items []InputItem
	if err := json.Unmarshal(data, &items); err != nil {
		return nil, fmt.Errorf("error unmarshaling JSON: %v", err)
	}

	emails := make([]string, len(items))
	for i, item := range items {
		emails[i] = item.Email
	}

	return emails, nil
}

func main() {
	inputFile := flag.StringP("file", "f", "", "Input JSON file containing email addresses")
	flag.Parse()

	if *inputFile == "" {
		fmt.Println("Usage: go run main.go --file <input_file.json> or -f <input_file.json>")
		flag.PrintDefaults()
		return
	}

	emails, err := readEmailsFromFile(*inputFile)
	if err != nil {
		fmt.Printf("Error reading emails from file: %v\n", err)
		return
	}

	cloudInfoSlice := make([]CloudInfo, 0, len(emails))

	for i, email := range emails {
		number := fmt.Sprintf("%02d", i+1)
		ipFile := filepath.Join(cloudInfoDir, fmt.Sprintf("miniolab-%s-ip-address", number))
		keyFile := filepath.Join(cloudInfoDir, fmt.Sprintf("miniolab-%s-private-key", number))

		ipAddress, err := os.ReadFile(ipFile)
		if err != nil {
			fmt.Printf("Warning: IP address file not found for %s. Using 'EMPTY'.\n", email)
			ipAddress = []byte("EMPTY")
		}

		privateKey, err := os.ReadFile(keyFile)
		if err != nil {
			fmt.Printf("Warning: Private key file not found for %s. Using 'EMPTY'.\n", email)
			privateKey = []byte("EMPTY")
		}

		cloudInfo := CloudInfo{
			Email: email,
			Profile: Profile{
				Hostname:   fmt.Sprintf("%s.%s", fmt.Sprintf("miniolab-%s", number), domain),
				Username:   username,
				IPAddress:  string(ipAddress),
				PrivateKey: string(privateKey),
			},
		}

		cloudInfoSlice = append(cloudInfoSlice, cloudInfo)
	}

	jsonData, err := json.MarshalIndent(cloudInfoSlice, "", "  ")
	if err != nil {
		fmt.Printf("Error marshaling JSON: %v\n", err)
		return
	}
	err = os.WriteFile(cloudInfoOut, jsonData, 0644)
	if err != nil {
		fmt.Printf("Error writing JSON file: %v\n", err)
		return
	}

	fmt.Printf("JSON file %s has been created successfully.\n", cloudInfoOut)
}
