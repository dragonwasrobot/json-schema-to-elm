# JSON schema to Elm

Generates Elm types and JSON decoders from JSON schema specifications.

## Installation

Download the archive `js2e-1.0.0.ez`.

Install with `mix archive.install js2e-1.0.0.ez`.

## Usage

See `mix help elm.gen` for usage instructions.

A proper description of which properties are mandatory are how the generator
works is still in progress, but feel free to take a look at the `examples`
folder which contains an example of a pair of JSON schemas and their
corresponding Elm output.

## Build

Run `mix archive.build` to create a new version of the `js2e` ez-archive.

Upgrading to a new version

Run `mix archive` to see installed archives.

Use `mix archive.uninstall` the previous version when use `mix archive.install`
to install the new version.
