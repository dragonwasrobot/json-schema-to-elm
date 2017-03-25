# JSON schema to Elm

Generates Elm types and JSON decoders from JSON schema specifications.

## Installation

This project requires that you already have [elixir](http://elixir-lang.org/)
and its build tool `mix` installed, this can be done with `brew install elixir`
or similar.

- Clone this repository: `git@github.com:dragonwasrobot/json-schema-to-elm.git`
- Build a mix archive: `mix archive.build`
- Install the archive: `mix archive.install js2e-1.0.0.ez`

## Usage

See `mix help elm.gen` for usage instructions.

A proper description of which properties are mandatory are how the generator
works is still in progress, but feel free to take a look at the `examples`
folder which contains an example of a pair of JSON schemas and their
corresponding Elm output. Likewise, representations of each of the different
JSON schema types are described in the `lib/types` folder.

## Build

Run `mix archive.build` to create a new version of the `js2e` ez-archive.

Upgrading to a new version

Run `mix archive` to see installed archives.

Use `mix archive.uninstall` the previous version when use `mix archive.install`
to install the new version.
