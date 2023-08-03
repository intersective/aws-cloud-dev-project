#!/bin/bash

# Get the PIDs of all processes in <defunct> state
defunct_pids=$(ps -aux | grep '<defunct>' | grep -v grep | awk '{print $2}')

# Loop through each PID and kill the process using kill -9
for pid in $defunct_pids; do
    echo "Killing process with PID: $pid"
    kill -9 $pid
done
