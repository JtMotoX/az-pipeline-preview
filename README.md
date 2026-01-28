# Azure Pipeline Preview

A command-line tool to generate the final YAML configuration from an Azure Pipeline without running it.

## What it does

Queries Azure DevOps to preview what your pipeline will look like after all templates and variables are resolved, saving the output to a file.

## Installation

Clone the repository:

```sh
git clone <repository-url>
cd <repository-name>
```

Create a symlink to use the tool from anywhere:

```sh
ln -s "$(pwd)/az-pipeline-preview.sh" ~/.local/bin/az-pipeline-preview
```

Make sure `~/.local/bin` is in your PATH, or use another directory that is already in your PATH.

## Usage

```sh
az-pipeline-preview --project-name PROJECT --definition-id ID --branch BRANCH
```

### Example

```sh
az-pipeline-preview --project-name urw-workspace --definition-id 446 --branch fix/dockerfile-cmd
```

This saves the generated YAML to `/tmp/az-pipeline-preview.yml`

For all available options, run:

```sh
az-pipeline-preview --help
```

## Requirements

- Azure CLI (`az`) installed and authenticated
