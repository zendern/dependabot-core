package main

import (
	"encoding/json"
	"fmt"
	"os"

	"github.com/hashicorp/hcl2/gohcl"
	"github.com/hashicorp/hcl2/hclparse"
)

type terraformModule struct {
	Name    string `hcl:"name,label" json:"name"`
	Source  string `hcl:"source" json:"source"`
	Version string `hcl:"version" json:"version"`
}

type terraformFile struct {
	Modules []terraformModule `hcl:"module,block" json:"module"`
}

func main() {
	parser := hclparse.NewParser()
	parsedFile, diags := parser.ParseHCLFile("tmp.tf")
	if diags.HasErrors() {
		fmt.Println(diags.Error())
		return
	}

	var tfFile terraformFile
	diags = gohcl.DecodeBody(parsedFile.Body, nil, &tfFile)
	if diags.HasErrors() {
		fmt.Println(diags.Error())
		return
	}

	jsonEnc := json.NewEncoder(os.Stdout)
	jsonEnc.Encode(tfFile)
}
