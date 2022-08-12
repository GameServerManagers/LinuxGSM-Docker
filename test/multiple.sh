#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

cd "$(dirname "$0")/.."

source "test/internal/api_various.sh"
source "test/steam_test_credentials"

ROOT_FOLDER="$(realpath "$(dirname "$0")/..")"

PARRALEL="$(lscpu -p | grep -Ev '^#' | sort -u -t, -k 2,4 | wc -l)"
IMAGE="$DEFAULT_DOCKER_REPOSITORY"
FLAKY="1"
LOG_DEBUG="false"
RERUN="false"
SUFFIX=""
VOLUMES="false"
VERSION="master"
LGSM_GITHUBUSER=""
LGSM_GITHUBREPO=""
LGSM_GITHUBBRANCH=""

GAMESERVER=()
while [ $# -ge 1 ]; do
    key="$1"
    shift

    case "$key" in
        -h|--help)
            echo "[help][multiple] testing every feature of specified server"
            echo "[help][multiple] full.sh [option] [server]"
            echo "[help][multiple] "
            echo "[help][multiple] options:"
            echo "[help][multiple] -c --cpus        x  run x servers in parralel, default x = physical cores"
			echo "[help][multiple] -d --log-debug      IMPORTANT: logs will leak your steam credentials!"
            echo "[help][multiple]    --image       x  set target image"
			echo "[help][multiple]    --flaky       x  test for flaky results x times, x should be greater as 1"
            echo "[help][multiple]    --rerun          check results and runs every gameserver which wasn't successful"
            echo "[help][multiple]    --git-branch  x  sets LGSM_GITHUBBRANCH"
            echo "[help][multiple]    --git-repo    x  sets LGSM_GITHUBREPO"
            echo "[help][multiple]    --git-user    x  sets LGSM_GITHUBUSER"
            echo "[help][multiple]    --suffix         suffix to add to every image"
            echo "[help][multiple]    --volumes        use volumes \"linuxgsm-SERVERCODE\""
            echo "[help][multiple] -v --version    x   use linuxgsm version x e.g. \"v21.4.1\""
            echo "[help][multiple] "
            echo "[help][multiple] "
            echo "[help][multiple] server:"
            echo "[help][multiple] *empty*         test every server"
            echo "[help][multiple] gmodserver ...  run only given servers"
            exit 0;;
        -c|--cpus)
            PARRALEL="$1"
            shift;;
		-d|--log-debug)
			LOG_DEBUG="true";;
        --image)
            IMAGE="$1"
            shift;;
		--flaky)
			FLAKY="$1"
			shift;;
        --rerun)
            RERUN="true";;
        --git-branch)
            LGSM_GITHUBBRANCH="$1"
			shift;;
        --git-repo)
            LGSM_GITHUBREPO="$1"
			shift;;
        --git-user)
            LGSM_GITHUBUSER="$1"
			shift;;
        --suffix)
            SUFFIX="$1"
            shift;;
        --volumes)
            VOLUMES="true";;
        -v|--version)
            VERSION="$1"
            shift;;
        *)
            if grep -qE '^-' <<< "$key"; then
                echo "[error][multiple] unknown option $key"
                exit 1
            else
                echo "[info][multiple] only testing servercode \"$key\""
            fi
            GAMESERVER+=("$key");;
    esac
done
testAllServer="$([ "${#GAMESERVER[@]}" = "0" ] && echo true || echo false )"
if [ "$(whoami)" = "root" ]; then
    echo "[error][multiple] please dont execute me as root, iam invoking linuxgsm.sh directly and this will not work as root"
    exit 1
fi

for run in $(seq 1 "$FLAKY"); do
	# prepare results folder
	RESULTS="$ROOT_FOLDER/test/results"
	# for multiple runs move previous results folder
	if [ "$FLAKY" != "1" ] && [ "$run" -gt "1" ]; then
		rm -rf "$RESULTS.$((run-1))" > /dev/null 2>&1
		cp -rf "$RESULTS/" "$RESULTS.$((run-1))/"
	fi
	if [ "${#GAMESERVER[@]}" = "0" ]; then
		if "$RERUN"; then
			find "$RESULTS" -type f ! -name "successful.*" -exec rm -f "{}" \;
		else
			rm -rf "$RESULTS"
		fi
	else
		# rerun only remove specific log
		for servercode in "${GAMESERVER[@]}"; do
			rm -rf "${RESULTS:?}/"*".$servercode.log"
		done
	fi
	mkdir -p "$RESULTS"

	(
		if "$RERUN" || [ "$run" -gt "1" ]; then
			echo "[info][multiple] skipping building linuxgsm because rerun"
		else
			echo "[info][multiple] building linuxgsm base once"
			./test/internal/build.sh --version "$VERSION" --image "$IMAGE" --latest --suffix "$SUFFIX"
		fi

		subprocesses=()
		function handleInterrupt() {
			for pid in "${subprocesses[@]}"; do
				kill -s SIGINT "$pid" || true
			done
		}
		trap handleInterrupt SIGTERM SIGINT

		mapfile -d $'\n' -t servers < <(getServerCodeList "$VERSION")
		for server_code in "${servers[@]}"; do
			cd "$ROOT_FOLDER"

			# only start $PARRALEL amount of tests
			while [ "${#subprocesses[@]}" -ge "$PARRALEL" ]; do
				sleep 1s
				temp=()
				for pid in "${subprocesses[@]}"; do
					if ps -p "$pid" -o pid= > /dev/null 2>&1; then
						temp+=("$pid")
					fi
				done
				subprocesses=("${temp[@]}")
			done


			isServercodeInServerlist="$(grep -qF "$server_code" <<< "${GAMESERVER[@]}" && echo true || echo false )"
			serverDidntStartSuccessful="$([ ! -f "$RESULTS/successful.$server_code.log" ] && echo true || echo false )"
			testThisServercode="$( ("$testAllServer" || "$isServercodeInServerlist") && echo true || echo false )"
			rerunIsFine="$( ( ! "$RERUN" || "$serverDidntStartSuccessful" ) && echo true || echo false )"
			if "$testThisServercode" && "$rerunIsFine"; then
				echo "[info][multiple] testing: $server_code"
				(
					single=(./test/single.sh --logs --version "$VERSION" --image "$IMAGE" --skip-lgsm --suffix "$SUFFIX" --git-branch "$LGSM_GITHUBBRANCH" --git-repo "$LGSM_GITHUBREPO" --git-user "$LGSM_GITHUBUSER")
					if "$VOLUMES"; then
						single+=(--volume "linuxgsm-$server_code")
					fi
					if "$LOG_DEBUG"; then
						single+=(--log-debug)
					fi
					single+=("$server_code")

					echo "${single[@]}"
					is_successful="false"
					if "${single[@]}" > "$RESULTS/$server_code.log" 2>&1; then
						is_successful="true"
					fi
					
					# sanitize secrets in log like used steamuser / steampass
					if [ -n "$steam_test_password" ]; then
						sed -i "s/$(sed_sanitize "$steam_test_password")/SECRET_PASSWORD/g" "$RESULTS/$server_code.log" > /dev/null 2>&1 || true
					fi
					if [ -n "$steam_test_username" ]; then
						sed -i "s/$(sed_sanitize "$steam_test_username")/SECRET_USERNAME/g" "$RESULTS/$server_code.log" > /dev/null 2>&1 || true
					fi

					if "$is_successful"; then
						mv "$RESULTS/$server_code.log" "$RESULTS/successful.$server_code.log"
					else
						mv "$RESULTS/$server_code.log" "$RESULTS/failed.$server_code.log"
					fi
				) | tee /dev/tty > /dev/null 2>&1 &
				subprocesses+=("$!")
			fi
		done

		# await every job is done
		while [ "${#subprocesses[@]}" -gt "0" ]; do
			sleep 1s
			temp=()
			for pid in "${subprocesses[@]}"; do
				if ps -p "$pid" -o pid= > /dev/null 2>&1; then
					temp+=("$pid")
				fi
			done
			subprocesses=("${temp[@]}")
		done

		echo "[info][multiple] successful: $(find "$RESULTS/" -iname "successful.*" | wc -l)"
		echo "[info][multiple] failed: $(find "$RESULTS/" -iname "failed.*" | wc -l)"

		mapfile -t failed_credentials_missing < <(grep --include "*failed*" -rlF 'Change steamuser="username"' "$RESULTS" | sort | uniq || true)
		echo "[info][multiple] failed - unset steam credentials: $(grep -Po '(?<=failed.)[^.]*' <<< "${failed_credentials_missing[@]}" | tr '\n' ' ' || true)"
		# print filenames + very high line number to jump right at eof on click if IDE supports it
		printf '%s\n' "${failed_credentials_missing[@]/%/:100000}"

		mapfile -t failed_other < <(grep --include "*failed*" -rLF 'Change steamuser="username"' "$RESULTS" | sort | uniq || true)
		echo "[info][multiple] failed - other error: $(grep -Po '(?<=failed.)[^.]*' <<< "${failed_other[@]}" | tr '\n' ' ' || true)"
		printf '%s\n' "${failed_other[@]/%/:100000}"

		echo ""
		echo "[info][multiple] searching in log for command errors \"command not found\" please add this as minimal dependency!"
		grep -rnF 'command not found' "$RESULTS" || true

		echo ""
		echo "[info][multiple] searching in log for errors where health check got SIGKILL"
		grep -rnF '"ExitCode": 137' "$RESULTS" || true

		echo ""
		echo "[info][multiple] log contains message \"provide content log to LinuxGSM developers\""
		grep -rnF 'LinuxGSM developers' "$RESULTS" || true
	)
done

if [ "$FLAKY" != "1" ]; then
	(
		cd "$ROOT_FOLDER"
		./test/debug-utils/compare_multiple_result_folders.sh
	)
fi
