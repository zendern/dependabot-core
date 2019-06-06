package parser

import (
	"github.com/hashicorp/hcl2/gohcl"
	"github.com/hashicorp/hcl2/hcl"
	"github.com/hashicorp/hcl2/hclparse"
)

// Args is the arguments specific to the dependency file parser
type Args struct {
	Filename string
}

// TerraformModule is a Terraform module declaration
type TerraformModule struct {
	Name    string `hcl:"name,label" json:"name"`
	Source  string `hcl:"source" json:"source"`
	Version string `hcl:"version" json:"version"`
}

type TerragruntBlock struct {
	Terraform []TerraformBlock `hcl:"terraform,block" json:"modules"`
}

// TerraformFile is a cut-down representation of a Terraform file that's
// returned by the parser
type TerraformFile struct {
	Modules    []TerraformModule `hcl:"module,block" json:"modules"`
	Terragrunt TerragruntBlock   `hcl:"terragrunt" json:"terragrunt"`
}

// ParseDependencyFile parses a terraform file, returning any module delcarations
func ParseDependencyFile(args *Args) (*TerraformFile, error) {
	parser := hclparse.NewParser()
	parsedFile, diags := parser.ParseHCLFile(args.Filename)
	if diags.HasErrors() {
		return nil, diags.Errs()[0]
	}

	schema, _ := gohcl.ImpliedBodySchema(TerraformFile{})
	bodyContent, _, diags := parsedFile.Body.PartialContent(schema)
	if diags.HasErrors() {
		return nil, diags.Errs()[0]
	}

	tfFile := TerraformFile{
		Modules: []TerraformModule{},
	}
	for _, modBlock := range bodyContent.Blocks.OfType("module") {
		if len(modBlock.Labels) < 1 {
			continue
		}

		mod := TerraformModule{Name: modBlock.Labels[0]}

		attrs, diags := modBlock.Body.JustAttributes()
		if diags.HasErrors() {
			return nil, diags.Errs()[0]
		}
		mod.Source = stringAttr(attrs, "source")
		mod.Version = stringAttr(attrs, "version")

		tfFile.Modules = append(tfFile.Modules, mod)
	}

	return &tfFile, nil
}

func stringAttr(attrs hcl.Attributes, key string) string {
	attr, ok := attrs[key]
	if !ok {
		return ""
	}

	val, diags := attr.Expr.Value(nil)
	if diags.HasErrors() {
		return ""
	}
	return val.AsString()
}
