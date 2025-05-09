#!/bin/bash

# Directories
roms="/userdata/roms/heroic"
images="/userdata/roms/heroic/images"
icons="/userdata/system/.config/heroic/icons"
logs_dir="/userdata/system/.config/heroic/GamesConfig"
json_dir="/userdata/system/.config/heroic/GamesConfig"
extra="/userdata/system/add-ons/heroic/extra"
list="$extra/gamelist.txt"
check="$extra/check.txt"
all="$extra/all.txt"
GAMELIST_PATH="$roms/gamelist.xml"
processed_list="$extra/processed_games.txt"

# Prepare directories
mkdir -p "$images" "$extra" 2>/dev/null
touch "$processed_list"
rm -rf "$check" "$all"

# Clean up invalid entries in the processed list
temp_processed_list="$extra/temp_processed_games.txt"
touch "$temp_processed_list"

while read -r processed_gid; do
  if [[ -f "$roms/$processed_gid.txt" ]]; then
    echo "$processed_gid" >> "$temp_processed_list"
  else
    echo "Removing invalid entry: $processed_gid from processed list."
  fi
done < "$processed_list"

# Replace the old processed list with the valid one
mv "$temp_processed_list" "$processed_list"

# Generate list of game IDs from icons
ls "$icons" | cut -d "." -f1 > "$list"

nrgames=$(wc -l < "$list")

# Process each game ID
if [[ -e "$list" && $nrgames -gt 0 ]]; then
  for gid in $(cat "$list"); do
    # Skip games already processed
    if grep -q "^$gid$" "$processed_list"; then
      continue
    fi

    # Get the icon
    icon=$(ls "$icons" | grep "^$gid" | head -n1)

    # Copy icon to images directory
    if [[ -n "$icon" ]]; then
      cp "$icons/$icon" "$images/$icon" 2>/dev/null
    fi

    # Extract game name from logs or JSON
    game_name=""
    for log_file in "$logs_dir/$gid"*.log; do
      if [[ -f "$log_file" ]]; then
        extracted_name=$(grep -oP '(?<=Preparing download for ")[^"]+' "$log_file" | head -n1)
        if [[ -z "$extracted_name" ]]; then
          extracted_name=$(grep -oP '(?<=Launching ")[^"]+' "$log_file" | head -n1)
        fi
        if [[ -n "$extracted_name" ]]; then
          game_name="$extracted_name"
          break
        fi
      fi
    done

    if [[ -z "$game_name" ]]; then
      json_file="$json_dir/$gid.json"
      if [[ -f "$json_file" ]]; then
        extracted_name=$(grep -oP '(?<=winePrefix": "/userdata/system/Games/Heroic/Prefixes/default/)[^"]+' "$json_file" | head -n1)
        if [[ -n "$extracted_name" ]]; then
          game_name="$extracted_name"
        fi
      fi
    fi

    # Fallback to game ID if no name is found
    if [[ -z "$game_name" ]]; then
      game_name="$gid"
      echo "Warning: Could not extract game name for ID $gid."
    fi

    # Sanitize game name
    sanitized_name=$(echo "$game_name" | tr ' ' '_')

    # Rename icon to sanitized name
    if [[ -n "$icon" ]]; then
      ext="${icon##*.}"
      mv "$images/$icon" "$images/$sanitized_name.$ext" 2>/dev/null
    fi

    # Check and clean outdated files
    find "$roms" -maxdepth 1 -type f -not -name '*.txt' -exec basename {} \; > "$all"
    dos2unix "$all" 2>/dev/null
    for thisrom in $(cat "$all"); do
      romcheck=$(cat "$roms/$thisrom" 2>/dev/null)
      if [[ -z "$romcheck" || ! -e "$icons/$romcheck.png" ]]; then
        rm -f "$roms/$thisrom" "$images/$romcheck.png" "$images/$romcheck.jpg"
      fi
    done

    # Create .txt file for the game if not exists
    if [[ ! -f "$roms/$sanitized_name.txt" ]]; then
      echo "$gid" > "$roms/$sanitized_name.txt"
      echo "$gid" >> "$check"
    fi

    # Add game to processed list
    echo "$gid" >> "$processed_list"
  done
fi

# Create or initialize gamelist.xml
if [[ ! -f "$GAMELIST_PATH" ]]; then
  echo '<?xml version="1.0" encoding="UTF-8"?><gameList></gameList>' > "$GAMELIST_PATH"
fi

# Update gamelist.xml with new entries
for TXT_FILE in "$roms"/*.txt; do
  if [[ -f "$TXT_FILE" ]]; then
    FILE_NAME="$(basename "$TXT_FILE" .txt)"
    MATCHING_IMAGE="$images/$FILE_NAME.jpg"

    if [[ -f "$MATCHING_IMAGE" ]]; then
      xmlstarlet ed -L \
        -s "/gameList" -t elem -n "game" -v "" \
        -s "/gameList/game[last()]" -t elem -n "path" -v "./$(basename "$TXT_FILE")" \
        -s "/gameList/game[last()]" -t elem -n "name" -v "${FILE_NAME//_/ }" \
        -s "/gameList/game[last()]" -t elem -n "image" -v "./images/$(basename "$MATCHING_IMAGE")" \
        -s "/gameList/game[last()]" -t elem -n "rating" -v "0" \
        -s "/gameList/game[last()]" -t elem -n "releasedate" -v "19700101T010000" \
        -s "/gameList/game[last()]" -t elem -n "lang" -v "en" \
        "$GAMELIST_PATH"
    fi
  fi
done

# Cleanup temporary files
rm -rf "$check" "$all" "$list"