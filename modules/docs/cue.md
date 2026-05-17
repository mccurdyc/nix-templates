# Cue

## Cue Directory Structure / Patterns

### Patterns
- `*_tool.cue` - **[Official]** special filename suffix that 
    - https://cuetorials.com/first-steps/scripting/
    - https://cuetorials.com/patterns/scripts-and-tasks/
- `*_schema.cue` - **[My pattern]** where object schemas --- and default values --- are defined. Nothing special or official with this suffix.
- `*_data.cue` - **[My pattern]** where data are defined. Nothing special or official with this suffix.
- `main.cue` - **[My pattern]** main entrypoint to a directory. Nothing special or official with this name.
- `transform.cue` - **[My pattern]** where transformation "functions" are defined. Nothing special or official with this filename.
    - https://cuetorials.com/patterns/functions/
        - Nothing special with the fields or `Transform` name.
        - It's not actually a "function" it's just value unions like anything else.

- `config/`
    - `cue.mod`
        - Cue module directory. You probably won't ever touch this.
        - `gen/` - **GENERATED** - These files were populated via the following

        ```bash
        cue get go github.com/fluxcd/helm-controller/api/...
        ```
    - `stages/`
        - Schema, scripts and global values set at this level
            - `build_tool.cue` - script-like "functions".
                - Any file ending in `_tool.cue`  can be used for scripting.
            - `k8s_schema.cue`
            - `k8s_data.cue`
                - **THE MAIN ENTRYPOINT** - Full Helm-values file
                    - "Pulls" / access values from stages and regions in the `for` loop.
            - `stage_schema.cue`
                - Schema for values that can be set at "lower" levels
            - `main.cue`
                - Global values
        - `stages/prd/`
            - `main.cue`
                - Production-specific values that span regions
            - `stages/prd/regions/<region>/`
                    - `main.cue`
                        - Region-specific entrypoint
## Debugging

### YAML fails to render

<a id="cue-yaml-failure"></a>

Cue is failing to render YAML. You are possibly missing "concrete" values somewhere.

To debug:

```bash
make cue/vet DIR="./stages/prd/regions"
# check the log for `string`, `int`, various types, etc. Anything that is NOT a concrete value.
```

Usually the `import` statements at the top are a good indication if there is a struct
that is causing it. For example, in the following, I would grep for `route` and `cluster`
to see which routes and/or cluster is causing the issue.

## More notes

- See [mccurdyc/cue-notes](https://github.com/mccurdyc/cue-notes/README.md)
