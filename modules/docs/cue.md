# Cue

## Useful Commands

- Print one object at a "deep" level with values set at every level above

    ```
    cue eval ./path/to/subdirectory/... -e envoy
    ```

- Print object at a SPECIFIC level

    ```
    cue eval ./path/to/subdirectory/main.cue -e envoy
    ```

- Check yaml against cue

    ```
    cue vet ranges.yaml check.cue
    ```

- Vet Cue (give it the deepest level. It wont traverse down itself)

    ```
    cue vet -c --strict ./path/to/subdirectory/...
    ```

- Format

    ```
    cue fmt ./...
    ```

- Render YAML

```
package main

import (
	"encoding/yaml"
	"tool/cli"
)

command: dump: {
	task: print: cli.Print & {
		text: yaml.Marshal(_rendered)
	}
}
```

```
cue cmd dump ./main/...
```

- YAML
	- https://github.com/cue-lang/cue/blob/v0.7.0/doc/tutorial/kubernetes/README.md
	- `cue import -f -R foo.yaml`

## Debugging
- `incomplete value string:` - you are missing a concrete value somewhere.
`yaml.Marshal` is EXTREMELY finicky. You will want to pull whatever out of
`yaml.Marshal()` into a thing that you can run via `cue eval`. Look for places
where you don't have concrete values. Those ALL need fixed.

## Getting Started

1. Define the interface you want users to use FIRST.
1. Define the input schema --- with constraints and defaults
    - Don't try to rely directly on the output schema for the input schema too
    - I ran into a lot of pain doing this
1. Define the output schema --- with contstraints and defaults. Use defaults generously --- you want (or need) to produce
1. Define transformation "functions" via [the function pattern](https://cuetorials.com/patterns/functions/)

- Mental model
	- Think merging multi-level (or layered) value maps (JSON objects) without overrides
	- "Objects" think "Go Structs"
	- Schemas can have constraints and default values
	- Packages are like Go package i.e., keep domains, etc. packaged
	- Types and values are one and the same (for loops, etc)
    - Order of evaluation does not matter
	- In global packages, set defaults, DON'T set concrete values (in most cases)
		- No such thing as "overwriting" at a deeper level
	- You take the type and constraints, but cant overwrite once a value becomes concrete
    - Types - https://cuetorials.com/overview/types-and-values/

- Project Structure
	- https://alpha.cuelang.org/docs/concept/modules-packages-instances/#instances
	- Within a module, all `.cue` files with the same package name are part of the same package.
	- A package is evaluated within the context of a certain directory.
	- Within this context, only the files belonging to that package in that directory and its ancestor directories within the module are combined.
	- We call that an _instance_ of a package.
		- "fully-compiled, concrete data-structure of the package in this 'instance'" when you reference this
	- _module root_: schema
		- all policy
	- _medial directories_: policy
		- some policy
	- _leaf directories_: data
		- all data

## Links / References

- Have the Cue playground open to test minimal examples out
    - https://cuelang.org/play
- Cue Stdlib -  https://pkg.go.dev/cuelang.org/go/pkg

### Understanding Fundamentals

- https://cuelang.org/docs/concepts/logic/
- https://alpha.cuelang.org/docs/howto/
- https://cuetorials.com/overview/foundations/

### Patterns

- Pattern matching / avoiding switch - https://cuetorials.com/overview/types-and-values/#pattern-matching-constraints

- Enums - https://cuelang.org/docs/tutorials/tour/types/disjunctions/

- Defining "global" package variable for re-use in the package - https://alpha.cuelang.org/docs/howto/use-the-built-in-function-or/

- Aliases - https://alpha.cuelang.org/docs/language-guide/templating/references/#aliases

- List comprehension / for-each - https://alpha.cuelang.org/docs/language-guide/templating/comprehensions/

- Applying constraint to many fields at once - https://alpha.cuelang.org/docs/language-guide/templating/constructing-maps/#pattern-constraints

## Examples

https://github.com/mccurdyc/playground/tree/main/cue
