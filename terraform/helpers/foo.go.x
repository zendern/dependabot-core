

type TerraformModule struct {
	Name    string `hcl:"name,label"`
	Source  string `hcl:"source"`
	Version string `hcl:"version"`
}

type TerraformFile struct {
	Modules []TerraformModule `hcl:"module,block"`
}

func main() {
	parser := hclparse.NewParser()
	file, diags := parser.ParseHCLFile("foo.tf")
	if diags.HasErrors() {
		fmt.Println(diags.Error())
		return
	}

	var val TerraformFile
	diags = gohcl.DecodeBody(file.Body, nil, &val)
	if diags.HasErrors() {
		fmt.Println(diags.Error())
		return
	}
	fmt.Println(val)
}

func main2() {
	fileBytes, err := ioutil.ReadFile("foo.tf")
	if err != nil {
		fmt.Println(err)
		return
	}

	f, diags := hclwrite.ParseConfig(fileBytes, "foo.tf", hcl.Pos{Line: 1, Column: 1})
	if diags.HasErrors() {
		fmt.Println(diags.Error())
		return
	}

	for _, block := range f.Body().Blocks() {
		for _, attr := range block.Body().Attributes() {
			for _, v := range attr.Expr().Variables() {
				fmt.Println(v)
			}
		}
	}
}
