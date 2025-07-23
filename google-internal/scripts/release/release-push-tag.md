# Prompt for Pushing a Release Tag

This document guides the Gemini CLI to find the correct release commit on an existing branch and execute the `release-push-tag.sh` script from an up-to-date main branch.

## Gemini, please follow these instructions:

When a user asks to "push a release tag", you must follow this multi-step process precisely.

### Step 1: Gather Information and Prepare the Repository

1.  Ask the user for the **major.minor** version of the release (e.g., `1.133`).
2.  Ensure your local repository is up-to-date before proceeding.
    ```bash
    git checkout main
    git pull --rebase origin main
    ```

### Step 2: Find the Release Commit and Version

1.  Construct the release branch name from the user's input and check it out. This will put the repository in a detached HEAD state, which is expected for this discovery step.
    ```bash
    RELEASE_BRANCH="origin/github/release-$(echo <user-provided-major.minor>)"
    git checkout "${RELEASE_BRANCH}"
    ```
2.  From the checked-out branch, use `git log` to find the specific release commit. The command below will search the current history for the latest commit message starting with "Release" and the major.minor version, then output the commit hash and the full commit message.
    ```bash
    COMMIT_INFO=$(git log --grep="^Release <user-provided-major.minor>\." --pretty=format:'%H %s' -n 1)
    ```
3.  Parse the `COMMIT_INFO` string to extract the `GIT_COMMIT` (the first word) and the `VERSION` (the third word, which will be the full `major.minor.patch`).
4.  **Important:** Return to the main branch before executing the script to ensure a clean state and rebase to ensure that branches do not diverge.
    ```bash
    git checkout main
    git rebase origin
    ```


### Step 3: Perform a Dry Run

1.  Set the required environment variables:
    *   `VERSION`: The full `major.minor.patch` version extracted from the commit message.
    *   `GIT_COMMIT`: The commit hash extracted from the `git log` command.
    *   `VERSION_MAJOR_MINOR`: The `major.minor` version provided by the user.
    *   `REPO_PATH`: The absolute path to the repository, which you can get by running `pwd`.

2.  Execute the script in dry-run mode from the `dev/tasks` directory.
    ```bash
    cd dev/tasks
    export VERSION="<extracted-version>"
    export GIT_COMMIT="<extracted-commit-hash>"
    export VERSION_MAJOR_MINOR="<user-provided-major-minor>"
    export REPO_PATH=$(pwd)
    ../../google-internal/scripts/release/release-push-tag.sh
    ```

### Step 4: Analyze Dry Run Output

1.  Examine the `stdout` and `stderr` from the previous command.
2.  **You must verify the following:**
    *   `stderr` is empty.
    *   `stdout` does **not** contain the words "ERROR", "failed", or "Aborted".
    *   The "Preparing local repository" section shows the correct `GIT_COMMIT` and `VERSION`.
    *   The "The following command will be executed for a dry run" section shows a `go run` command with the correct branch name (`--branch release_MAJOR.MINOR`) and other parameters.
3.  If the output looks correct and free of errors, proceed to the final step. Otherwise, report the errors to the user and stop.

### Step 5: Execute the Final Push

1.  If the dry run analysis was successful, execute the `go run` command from the dry run output with the `--yes=true` flag.

    ```bash
    cd dev/tasks
    # Example command extracted from dry run output
    go run . --remote sso://cnrm/cnrm --branch release_1.133 --version-file version/VERSION --source /usr/local/google/home/${user}$/gitonborg/cnrm --push-options push-justification=b/382575614 -v=2 --yes=true
    ```
2.  Confirm to the user that the tag was pushed successfully.