# JSON schema to Elm

Generates Elm types and JSON decoders from JSON schema specifications.

## Installation

This project requires that you already have [elixir](http://elixir-lang.org/)
and its build tool `mix` installed, this can be done with `brew install elixir`
or similar.

- Clone this repository: `git clone git@github.com:dragonwasrobot/json-schema-to-elm.git`
- Compile the project: `MIX_ENV=prod mix deps.get && mix compile`
- Build an executable: `MIX_ENV=prod mix escript.build`
- An executable, `js2e`, has now been created in your current working directory.

For further help, look up the documentation on how
to [install escripts](https://hexdocs.pm/mix/Mix.Tasks.Escript.Install.html).

## Usage

See `./js2e` for usage instructions.

A proper description of which properties are mandatory are how the generator
works is still in progress, but feel free to take a look at the `examples`
folder which contains an example of a pair of JSON schemas and their
corresponding Elm output. Likewise, representations of each of the different
JSON schema types are described in the `lib/types` folder.
