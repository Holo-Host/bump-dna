#!/bin/sh
# Simple shell script for altering hashspace of self hosted DNAs
# type bump-dna for help
##

set -e

CONFIG_FILE="/var/lib/holochain-conductor/conductor-config.toml"
CONFIG_DIR="/var/lib/holochain-conductor"

hash_from_id(){
    awk -v my_id="$1" '
        /\[\[dnas\]\]/,/^$/ {
            gsub(/['"'"'"]/,"")
            if ($1 == "hash") hash=$3
            if ($1 == "id") id=$3
            if ($0 == "" && id == my_id) print hash
        }' $CONFIG_FILE
}

file_from_hash(){
    awk -v my_hash="$1" '
        /\[\[dnas\]\]/,/^$/ {
            gsub(/['"'"'"]/,"")
            if ($1 == "hash") hash=$3
            if ($1 == "file") file=$3
            if ($0 == "" && hash == my_hash) print file
        }' $CONFIG_FILE
}

if [ $# -eq 0 ]
    then
        echo "usage: bump-dna [-ih] [-u] "
        echo "  -i id of dna"
        echo "  -h hash of dna before bump (overwrites -i)"
        echo "  -u new uuid (optional, skipping will print current uuid)"
        exit 0
fi

while getopts i:h:u: OPTION
do
    case $OPTION in
        i)
            id=${OPTARG}
            hash_id=$( hash_from_id "$id" )
            optflag=1
            [[ -n $hash_id ]] || { echo "There is no dna with id $id" >&2;exit 1;}
            ;;
        h)  
            hash_h=${OPTARG}
            optflag=1
            ;;
        u)
            uuid=${OPTARG}
            ;;
        /?)
            echo "Invalid option: -$OPTARG"
            exit 1
    esac
done

# Error checks
[[ -f $CONFIG_FILE ]] || { echo "$CONFIG_FILE is not a file." >&2;exit 1;}
[[ -n $optflag ]] || { echo "Either -i or -h is required for identification of DNA" >&2;exit 1;}
hash=${hash_h:-${hash_id}} # -h overwrites -i
dna_path=$( file_from_hash "$hash")
[[ -n $dna_path ]] || { echo "There is no dna with hash $hash" >&2;exit 1;}
[[ -f $dna_path ]] || { echo "Failed to read from file $dna_path" >&2;exit 1;}

# If no uuid provided print current uuid
[[ -n $uuid ]] || { echo "Current uuid is "$( grep 'uuid' "$dna_path" | awk '{print $2}' | sed 's/,$//' | xargs );exit 0;}

tmp_path=$(mktemp -u)
cp "$dna_path" "$tmp_path"

# change uuid in a new file
sed -i "\|uuid|c\  \"uuid\": \"$uuid\"\," "$tmp_path"

# calculate new hash
cd "$(dirname "$tmp_path")"
new_hash=$(hc hash -p "$tmp_path" | sed -n 2p | awk '{print $3}')

# copy updated dna to dnas/
dna_dir=$CONFIG_DIR"/dnas"
new_path=$dna_dir"/$new_hash.dna.json"
[[ -d $dna_dir ]] || { echo "Creating dir $dna_dir"; mkdir $dna_dir;}
install -o holochain-conductor -g holochain-conductor -m 666 "$tmp_path" "$new_path"

# sed dnas.hash, dnas.file and instances.storage.path
sed -i "\|hash.*$hash|c\hash = \'$new_hash\'" $CONFIG_FILE
sed -i "\|file.*$dna_path|c\file = \'$new_path\'" $CONFIG_FILE
sed -i "\|path.*$hash|c\path = \'$CONFIG_DIR/$new_hash\'" $CONFIG_FILE

echo ""
echo "new_hash: $new_hash"
echo ""
echo "restarting holochain-conductor.service..."
systemctl restart holochain-conductor.service

exit 0
