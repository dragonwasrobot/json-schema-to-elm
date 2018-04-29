# Contributing

If you have found a bug, think I have misinterpreted the JSON schema spec
somewhere, or have a proposal for a new feature, feel free to open an issue so
we can discuss a proper solution.

## Reporting bugs

When reporting a bug, please include:

- A short description of the bug,
- JSON schema example that triggers the bug,
- expected Elm output, and the
- actual Elm output.

## Pull requests

Please do not create pull requests before an issue has been created and a
solution has been discussed and agreed upon.

When making a pull request ensure that:

1. It solves one specific problem, and that problem has already been documented
   and discussed as an issue,
2. the PR solves the problem as agreed upon in the issue,
3. if it is a new feature, ensure that there is proper code coverage of the new
   feature, and
4. the PR contains no compiler warnings or dialyzer warnings (and preferably no
   credo warnings).

## Development

The project is written in [Elixir](http://elixir-lang.org/) - as I found it to
be a more suitable tool for the job than Elm - and uses the `mix` tool for
building.

#### Compiling

Install dependencies

    mix deps.get

Compile project

    mix compile

and you are good to go.

#### Tests

Run the standard mix task

    mix test

for test coverage run

    mix coveralls.html

#### Static analysis

Run dialyzer

    mix dialyzer

Run credo

    mix credo
