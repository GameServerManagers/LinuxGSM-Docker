# Overview of testing

- All scripts supporting `-h or --help` for all options, here are only most important explained
- Some servers need [steam credentials](steam_test_credentials) don't commit them and don't share your logs if they are used!
- Wherever available `--version commit/tag/branch` can be:
    - empty to take recent lgsm master branch
    - a lgsm tag like `v22.1.0`
    - a commit id of official lgsm repository
    - a commit id of your _fork_
- `LGSM_GITHUBBRANCH / LGSM_GITHUBREPO / LGSM_GITHUBUSER` can be set with `--git-[branch,repo,user] "value"`
- Do you want to test a single servercode? E.g. to test a patch affecting just one server.
    - `./single.sh [--volume v] [--version commit/tag/branch] servercode`
- Do you want to test multiple or all servercodes? E.g. you refactoring code affecting multiple or all
    - `./multiple.sh [--version commit/tag/branch] [servercode1 servercode2 ...]`
        - if no servercode is provided every servercode is tested!
        - needs lots of cpu / ram / network / time, maybe you want to run it in background: 
            1. create a script `tmux.sh` with content:
            ```bash
            #!/bin/bash
            ./test/multiple.sh --version v22.1.0 --log-debug
            ```
            2. invoke it `tmux new -d -s lgsm-testing bash tmux.sh
            

## Examples:

### I just want to build this image, how?

- `./single.sh --build-only servercode`
- `./single.sh --build-only --version commit-id-from-fork servercode`

### I created a lgsm fork and want to test it

1. You have created a fork
2. You have commited and pushed your changes to your repository
3. If you didn't modify `linuxgsm.sh`:
    1. Lets say your repository is: `https://github.com/MyUser/LinuxGSM/`
    2. Append to the scripts: `--git-user "MyUser" --git-repo "LinuxGSM" --git-branch "mybranch"`
    4. You can skip the the values if the default is fine, e.g. if your fork repo is still LinuxGSM you dont need to provide it.
    3. Important: This will only work completely for a clean volume!
4. If you modified `linuxgsm.sh`:
    1. Get your commit id with `git log` e.g. `0dce0f0be3e2e881c592d726d0c11fc100a4a829`
    2. Appent to the scripts `--version 0dce0f0be3e2e881c592d726d0c11fc100a4a829`
    3. Did you modify your `linuxgsm.sh` to set LGSM_GITHUBBRANCH / LGSM_GITHUBREPO / LGSM_GITHUBUSER ?
        - If yes, you don't need to provide `--git-[user,repo,branch] "value"`
        - If no, check step 3
5. You are in the root of this repository
    - Do your changes affact just a single servercode? E.g. you provided a new one or you patched one, use the variant below.
        - `./single.sh --git-user "MyUser" --git-repo "LinuxGSM" --git-branch "mybranch" servercode`
        - `./single.sh --version 0dce0f0be3e2e881c592d726d0c11fc100a4a829 servercode`
        - `./single.sh --version 0dce0f0be3e2e881c592d726d0c11fc100a4a829 --git-user "MyUser" --git-repo "LinuxGSM" --git-branch "mybranch" servercode`
    - Do your changes affect all servercodes?
        - `./multiple.sh --git-user "MyUser" --git-repo "LinuxGSM" --git-branch "mybranch"`
        - `./multiple.sh --version 0dce0f0be3e2e881c592d726d0c11fc100a4a829`
        - `./multiple.sh --version 0dce0f0be3e2e881c592d726d0c11fc100a4a829 --git-user "MyUser" --git-repo "LinuxGSM" --git-branch "mybranch"`

#### My test was not successful, how to debug?

`./single.sh --version 0dce0f0be3e2e881c592d726d0c11fc100a4a829 --debug servercode`
1. Image will be build and entrypoint is overwritten to bash
2. Therefore entrypoint.sh is not executed and you are in the volume location
