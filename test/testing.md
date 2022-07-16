# Overview of testing

- all scripts supporting `-h or --help` for all options, here are only most important explained
- some servers need [steam credentials](steam_test_credentials) don't commit them and don't share your logs if they are used!
- Wherever available `--version commit/tag/branch` can be:
    - empty to take recent lgsm master branch
    - a lgsm tag like `v22.1.0`
    - a commit id of official lgsm repository
    - a commit id of your _fork_

- Do you want to test a single servercode? E.g. to test a patch affecting just one server.
    - `./single.sh [--volume v] [--version commit/tag/branch] servercode`
        - testing a single servercode, e.g. if current is working or for testing your lgsm fork
- Do you want to test multiple or all servercodes? E.g. you refactoring code affecting multiple or all
    - `./multiple.sh [--version commit/tag/branch] [servercode1 servercode2 ...]`
        - if no servercode is provided every servercode is tested!
        - needs lots of cpu / ram / network / time, maybe you want to run it in background: 
            1. create a script `tmux.sh` with content:
            ```bash
            #!/bin/bash
            ./test/multiple.sh --version v22.1.0 --log-debug
            ```
            2. invoke it `tmux new -d -s lgsm-testing bash tmux.sh // TODO: should work without extra script, maybe add option to scripts?
            

## Examples:

### I just want to build this image, how?

`./single.sh --build-only --latest servercode`

### I created a lgsm fork and want to test it

1. You have created a fork
2. You have commited and pushed your changes to your repository
3. Get your commit id with `git log` e.g. `0dce0f0be3e2e881c592d726d0c11fc100a4a829`
4. You are in the root of this repository
    - Do your changes affact just a single servercode? E.g. you provided a new one or you patched one
        - `./single.sh --version 0dce0f0be3e2e881c592d726d0c11fc100a4a829 servercode`
    - Do your changes affect all servercodes?
        - `./multiple.sh --version 0dce0f0be3e2e881c592d726d0c11fc100a4a829`

#### My test was not successful, how to debug?

`./single.sh --version 0dce0f0be3e2e881c592d726d0c11fc100a4a829 --debug servercode`
1. Image will be build and entrypoint is overwritten to bash
2. Therefore entrypoint.sh is not executed and you are in the volume location