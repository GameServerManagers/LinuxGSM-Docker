#!/bin/bash

(
	cd "$(dirname "$0")"

	mapfile -t results_folder < <(find "." -maxdepth 1 -type d -iname "results*")

	mapfile -t servercodes < <(find ./${results_folder[0]}/ -type f -iname "*.log" | grep -Poe '(?<=.)[^./]+(?=.log)' | sort)
	for servercode in "${servercodes[@]}"; do
		successful=()
		failed=()

		for result_folder in "${results_folder[@]}"; do
			if [ -f "$result_folder/successful.$servercode.log" ]; then
				successful+=("$result_folder/successful.$servercode.log")
			elif [ -f "$result_folder/failed.$servercode.log" ]; then
				failed+=("$result_folder/failed.$servercode.log")
			fi
		done

		if [ "${#successful[@]}" -gt "0" ] && [ "${#failed[@]}" -gt "0" ]; then
			echo ""
			echo "$servercode flaky result"
			for result in "${successful[@]}" "${failed[@]}"; do
				echo "./test/${result//.\//}:10000"
			done
		elif [ "${#successful[@]}" -eq "0" ]; then
			echo ""
			echo "$servercode always failing"
			for result in "${successful[@]}" "${failed[@]}"; do
				echo "./test/${result//.\//}:10000"
			done
		fi
	done
)
