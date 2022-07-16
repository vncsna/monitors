#!/usr/bin/bash
set -euo pipefail

wd=$HOME/collab/monitors
inpath=$wd/sample_input.json
oupath=$wd/sample_output.json

function extract() {
    swaymsg --type get_tree | jq > $inpath
}

function transform() {
    cat $inpath | \
    jq --compact-output --raw-output '
        .name as $setup_name |
        .rect.x as $setup_x |
        .rect.y as $setup_y |
        .rect.width as $setup_width |
        .rect.height as $setup_height |
        (.nodes[] | select(.percent != null)) |
        .name as $monitor_name |
        .rect.x as $monitor_x |
        .rect.y as $monitor_y |
        .rect.width as $monitor_width |
        .rect.height as $monitor_height |
        .nodes[] |
        .name as $window_name |
        .rect.x as $window_x |
        .rect.y as $window_y |
        .rect.width as $window_width |
        .rect.height as $window_height |
        .nodes[] |
        .name as $app_name |
        .app_id as $app_id |
        .rect.x as $app_x |
        .rect.y as $app_y |
        .rect.width as $app_width |
        .rect.height as $app_height |
        [(now | strflocaltime("%s") | tonumber),
        $setup_x, $setup_y, $setup_width, $setup_height,
        $monitor_name, $monitor_x, $monitor_y, $monitor_width, $monitor_height,
        $window_name, $window_x, $window_y, $window_width, $window_height,
        $app_name, $app_id, $app_x, $app_y, $app_width, $app_height]' | \
    jq --slurp '{values:[.[]]}' > $oupath
}

function load() {
    access_token=$($wd/auth.sh)
    
    range="A1:T1000"
    spreadsheet_id="1V-dTsqi2YDj32kJ_QGnswbJTNXLTZrHb-4Wwe0SP_Uk"
    
    curl\
    --json @$oupath\
    --header "Authorization: Bearer $access_token"\
    --url "https://sheets.googleapis.com/v4/spreadsheets/$spreadsheet_id/values/$range:append?valueInputOption=RAW"
}

extract && transform && load
