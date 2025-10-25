#!/bin/bash
# Nexus - Startup script
set -euo pipefail

PROJECTS_DIR="/workspace/projects"
mkdir -p "$PROJECTS_DIR"

### ===========================
### PROJECTS CONFIGURATION
### ===========================
# Format: "name|repo|description"
PROJECTS=(
    "42_school|https://github.com/Alexis42/42_school|Exercices et projets de 42"
    "test_app|https://github.com/user/test|Application de test"
)

### ===========================
### UI UTILITIES
### ===========================
BOLD='\033[1m'
DIM='\033[2m'
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
RESET='\033[0m'

clear_screen() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${RESET}                     ${BOLD}🚀 NEXUS DEV ENVIRONMENT${RESET}                               ${CYAN}║${RESET}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════════════════╝${RESET}\n"
}

draw_table() {
    local width=76
    echo -e "${DIM}┌────┬─────────────────────────┬────────────────────────────────────────────┐${RESET}"
    echo -e "${DIM}│${RESET} ${BOLD}#${RESET}  ${DIM}│${RESET} ${BOLD}Project${RESET}                 ${DIM}│${RESET} ${BOLD}Description${RESET}                                ${DIM}${RESET}"
    echo -e "${DIM}├────┼─────────────────────────┼────────────────────────────────────────────┤${RESET}"
    
    for i in "${!PROJECTS[@]}"; do
        IFS="|" read -r name _ desc <<< "${PROJECTS[$i]}"
        printf "${DIM}│${RESET} ${GREEN}%-2s${RESET} ${DIM}│${RESET} %-23s ${DIM}│${RESET} ${DIM}%-43s${RESET} ${DIM}${RESET}\n" "$((i+1))" "$name" "$desc"
    done
    
    echo -e "${DIM}├────┴─────────────────────────┴────────────────────────────────────────────┤${RESET}"
    echo -e "${DIM}│${RESET} ${YELLOW}0${RESET}  ${DIM}│${RESET} Exit                                                              ${DIM}${RESET}"
    echo -e "${DIM}└────┴──────────────────────────────────────────────────────────────────────┘${RESET}"
}

show_status() {
    local status=$1
    local message=$2
    case $status in
        "success") echo -e "  ${GREEN}✓${RESET} $message" ;;
        "error")   echo -e "  ${RED}✗${RESET} $message" ;;
        "info")    echo -e "  ${CYAN}ℹ${RESET} $message" ;;
        "warn")    echo -e "  ${YELLOW}⚠${RESET} $message" ;;
    esac
}

loading_spinner() {
    local pid=$1
    local message=$2
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) %10 ))
        printf "\r  ${CYAN}${spin:$i:1}${RESET} $message..."
        sleep 0.1
    done
    printf "\r"
}

### ===========================
### PROJECT MANAGEMENT
### ===========================
clone_project() {
    local name=$1
    local repo=$2
    local path="$PROJECTS_DIR/$name"
    
    if [ -d "$path" ]; then
        return 0
    fi
    
    git clone "$repo" "$path" > /dev/null 2>&1 &
    local pid=$!
    loading_spinner $pid "Cloning $name"
    wait $pid
    
    if [ $? -eq 0 ]; then
        show_status "success" "Project cloned successfully"
        return 0
    else
        show_status "error" "Failed to clone project"
        return 1
    fi
}

launch_project() {
    local name=$1
    local path="$PROJECTS_DIR/$name"
    
    echo ""
    echo -e "${BOLD}Launching: ${CYAN}$name${RESET}"
    echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    
    # Check for run script
    if [ -f "$path/run.sh" ]; then
        cd "$path"
        bash run.sh
    elif [ -f "$path/Makefile" ]; then
        cd "$path"
        make
    else
        show_status "warn" "No run.sh or Makefile found"
        show_status "info" "Opening shell in project directory"
        cd "$path"
        bash
    fi
    
    echo ""
    echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    read -rp "Press Enter to return to menu..."
}

### ===========================
### MAIN LOOP
### ===========================
main() {
    while true; do
        clear_screen
        draw_table
        echo ""
        read -rp "  Select project: " choice
        
        # Validate input
        if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
            show_status "error" "Invalid input"
            sleep 1
            continue
        fi
        
        # Exit
        if [ "$choice" -eq 0 ]; then
            echo ""
            show_status "info" "Goodbye!"
            exit 0
        fi
        
        # Launch project
        if [ "$choice" -ge 1 ] && [ "$choice" -le "${#PROJECTS[@]}" ]; then
            INDEX=$((choice-1))
            IFS="|" read -r name repo desc <<< "${PROJECTS[$INDEX]}"
            
            echo ""
            if ! clone_project "$name" "$repo"; then
                sleep 2
                continue
            fi
            
            launch_project "$name"
        else
            show_status "error" "Invalid selection"
            sleep 1
        fi
    done
}

main
