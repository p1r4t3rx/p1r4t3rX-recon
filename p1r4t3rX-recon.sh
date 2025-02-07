
#!/bin/bash
echo -e "\e[1;31]
█▀█ ▄█ █▀█ █░█ ▀█▀ █▀█ ▀▄▀
█▀▀ ░█ █▀▄ ▀▀█ ░█░ █▀▄ █░█\e[0m"
echo -e "\e[1;33m🏴‍☠️ P1r4t3rX Recon - Automated Recon Tool 🚀\e[0m"


# Read domain from user
echo "Enter the domain : "
read domain

# Set output directories
output_dir="$domain-output"
mkdir -p "$output_dir/amass"
mkdir -p "$output_dir/status_codes"

# Step 1: Run all subdomain finders in parallel
echo "[+] Running Subfinder, Assetfinder, & Katana..."
subfinder -d "$domain" -o "$output_dir/subdomains.txt" -t 200 -recursive -all &
assetfinder --subs-only "$domain" | anew "$output_dir/subdomains.txt" &
katana -u "$domain" -jc -d 10 -o "$output_dir/katana_subdomains.txt" &

echo "[+] Running Amass..."

amass enum -d "$domain" -active -brute  -timeout 500 -silent -o "$output_dir/amass/subdomains.txt" &

# Wait for subdomain processes to finish
wait

# Step 3: Merge & deduplicate subdomains
echo "[+] Merging & removing duplicate subdomains..."
sort -u "$output_dir/subdomains.txt" "$output_dir/katana_subdomains.txt" "$output_dir/amass/subdomains.txt" -o "$output_dir/subdoma>

# Step 4: Gather URLs using Gau & Katana
echo "[+] Running Gau & Katana for URLs..."
gau "$domain" --threads 500 --retries 5 --timeout 5 --config /dev/null | anew "$output_dir/urls.txt" &
katana -u "$domain" -jc -d 10 -o "$output_dir/katana_urls.txt" &

# Wait for URL gathering to finish
wait

# Step 5: Merge URLs
echo "[+] Merging & removing duplicate URLs..."
sort -u "$output_dir/urls.txt" "$output_dir/katana_urls.txt" -o "$output_dir/urls.txt"

# Step 6: Run Httpx for status codes (Super Fast)
echo "[+] Checking status codes with Httpx..."
httpx -silent -threads 500 -retries 2 -timeout 5 -status-code -no-color < "$output_dir/urls.txt" > "$output_dir/httpx_results.txt"

# Step 7: Categorize URLs by status code
echo "[+] Categorizing URLs by status codes..."
awk '{print > "'$output_dir'/status_codes/"$2".txt"}' "$output_dir/httpx_results.txt"

echo "[+] Completed! Results saved in: $output_dir"


