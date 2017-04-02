# JSON schema to Elm

Generates Elm types, JSON decoders and JSON encoders from JSON schema
specifications.

## Installation

This project requires that you already have [elixir](http://elixir-lang.org/)
and its build tool `mix` installed, this can be done with `brew install elixir`
or similar.

- Clone this repository: `git clone git@github.com:dragonwasrobot/json-schema-to-elm.git`
- Build an executable: `MIX_ENV=prod mix build`
- An executable, `js2e`, has now been created in your current working directory.

## Usage

Run `./js2e` for usage instructions.

A proper description of which properties are mandatory are how the generator
works is still in progress, but feel free to take a look at the `examples`
folder which contains an example of a pair of JSON schemas and their
corresponding Elm output. Likewise, representations of each of the different
JSON schema types are described in the `lib/types` folder.
