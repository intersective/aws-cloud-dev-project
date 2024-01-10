#!/bin/bash

# Check if the number of entries is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <number_of_entries>"
    exit 1
fi

# Number of entries
NUM_ENTRIES=$1

# .htpasswd file path
HTPASSWD_FILE="zap-proxy/nginx/.htpasswd"

# Check if .htpasswd file already exists
if [ -f "$HTPASSWD_FILE" ]; then
    echo "$HTPASSWD_FILE exists. Overwrite? (y/n)"
    read answer
    if [ "$answer" != "${answer#[Yy]}" ]; then
        >$HTPASSWD_FILE # Empty the file
    else
        exit 1
    fi
fi

# Function to generate a random password
generate_password() {
    LC_ALL=C < /dev/urandom tr -dc 'A-Za-z0-9!@#$%^&*()-_=+[]{}|;:,.<>/?' | head -c10
}

# Generate entries
for (( i=1; i<=NUM_ENTRIES; i++ ))
do
    USERNAME="team-$i"
    PASSWORD=$(generate_password)
    htpasswd -bB $HTPASSWD_FILE $USERNAME $PASSWORD
    echo "Added $USERNAME with password $PASSWORD"

    echo ""$USERNAME":"$PASSWORD"" >> .accounts
done

echo "Generated $NUM_ENTRIES entries in $HTPASSWD_FILE"


