import json
import os
import re
import ssl
import urllib.request
from datetime import datetime, timezone
from html.parser import HTMLParser

USCIS_INDEX = "https://www.uscis.gov/green-card/green-card-processes-and-procedures/visa-availability-priority-dates/adjustment-of-status-filing-charts-from-the-visa-bulletin"
COUNTRIES = ["All Chargeability", "China", "India", "Mexico", "Philippines"]


class TableParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.tables = []
        self.current_table = None
        self.current_row = None
        self.current_cell = None
        self.in_cell = False

    def handle_starttag(self, tag, attrs):
        if tag == "table":
            self.current_table = []
        elif tag == "tr" and self.current_table is not None:
            self.current_row = []
        elif tag in ("th", "td") and self.current_row is not None:
            self.current_cell = []
            self.in_cell = True

    def handle_endtag(self, tag):
        if tag == "table" and self.current_table is not None:
            self.tables.append(self.current_table)
            self.current_table = None
        elif tag == "tr" and self.current_row is not None:
            self.current_table.append(self.current_row)
            self.current_row = None
        elif tag in ("th", "td") and self.current_cell is not None:
            text = " ".join("".join(self.current_cell).split()).strip()
            self.current_row.append(text)
            self.current_cell = None
            self.in_cell = False

    def handle_data(self, data):
        if self.in_cell and self.current_cell is not None:
            self.current_cell.append(data)


def get_ssl_context():
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    return ctx


def clean(x):
    return " ".join(x.split()).strip() if x else ""


def normalize_category(label, is_employment):
    t = clean(label).lower()
    if is_employment:
        if t.startswith("1st"):
            return "EB-1"
        if t.startswith("2nd"):
            return "EB-2"
        if t.startswith("3rd") and "other" not in t:
            return "EB-3"
        if "other workers" in t:
            return "Other Workers"
        if t.startswith("4th"):
            return "EB-4"
        if "religious" in t:
            return "Certain Religious Workers"
        if "5th unreserved" in t or "5th non-reserved" in t:
            return "EB-5 Unreserved"
        if "rural" in t:
            return "EB-5 Rural"
        if "high unemployment" in t:
            return "EB-5 High Unemployment"
        if "infrastructure" in t:
            return "EB-5 Infrastructure"
    else:
        for x in ["F1", "F2A", "F2B", "F3", "F4"]:
            if t.upper().startswith(x):
                return x
    return None


def parse_rows(table_rows, is_employment):
    rows = {}
    for cells in table_rows:
        if len(cells) < 6:
            continue
        cat = normalize_category(cells[0], is_employment)
        if not cat:
            continue
        rows[cat] = {
            COUNTRIES[0]: cells[1].replace(" ", ""),
            COUNTRIES[1]: cells[2].replace(" ", ""),
            COUNTRIES[2]: cells[3].replace(" ", ""),
            COUNTRIES[3]: cells[4].replace(" ", ""),
            COUNTRIES[4]: cells[5].replace(" ", ""),
        }
    return rows


def fetch_url(url):
    headers = {
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language": "en-US,en;q=0.9",
    }
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req, context=get_ssl_context(), timeout=30) as resp:
        return resp.read().decode("utf-8")


def scrape_uscis():
    print(f"Fetching official USCIS Filing Charts index: {USCIS_INDEX}...")
    index_html = fetch_url(USCIS_INDEX)

    # Detect Next Month section to catch newly released bulletins immediately
    next_month_match = re.search(r"<h2>Next Month.*?</h2>(.*?)(?:<h2>|$)", index_html, re.DOTALL | re.IGNORECASE)
    use_next = False
    target_section = ""
    if next_month_match:
        section_content = next_month_match.group(1)
        if "coming soon" not in section_content.lower() and ("href=" in section_content or "table" in section_content):
            use_next = True
            target_section = section_content
            print("Detected newly published NEXT MONTH bulletin on USCIS!")

    if not use_next:
        curr_month_match = re.search(r"<h2>Current Month.*?</h2>(.*?)(?:<h2>|$)", index_html, re.DOTALL | re.IGNORECASE)
        target_section = curr_month_match.group(1) if curr_month_match else index_html

    # Extract Month Name
    m = re.search(r"(?:Visa Bulletin for|Filing Charts:?)\s+([A-Z][a-z]+\s+20\d{2})", target_section)
    month_name = m.group(1) if m else "September 2026"

    # Extract State.gov Bulletin link if referenced
    dos_match = re.search(r'href=[\"\'](https://travel\.state\.gov/[^\"\']+)[\"\']', target_section)
    dos_url = (
        dos_match.group(1)
        if dos_match
        else f"https://travel.state.gov/content/travel/en/legal/visa-law0/visa-bulletin/{month_name.split()[1]}/visa-bulletin-for-{month_name.split()[0].lower()}-{month_name.split()[1]}.html"
    )

    # Determine USCIS Filing Chart recommendation
    emp_chart = "Final Action Dates" if "final action" in target_section.lower() else "Dates for Filing"
    fam_chart = "Dates for Filing" if "dates for filing" in target_section.lower() else "Final Action Dates"

    note = f"For employment-based categories, USCIS determined to use the {emp_chart} chart. For family-sponsored categories, use {fam_chart}."

    # Find the link to the detailed monthly charts page
    chart_page_link = re.search(r'href=[\"\'](/green-card/[^\"\']+when-to-file[^\"\']+)[\"\']', target_section)
    if not chart_page_link:
        chart_page_link = re.search(r'href=[\"\'](https://[^\"]+when-to-file[^\"]+)[\"\']', target_section)

    chart_url = None
    if chart_page_link:
        link_str = chart_page_link.group(1)
        chart_url = "https://www.uscis.gov" + link_str if link_str.startswith("/") else link_str

    print(f"Target Month: {month_name}")
    print(f"DOS URL: {dos_url}")
    print(f"Detailed Chart URL: {chart_url}")
    print(f"Employment Determination: {emp_chart}")

    current_tables = {
        "family_final": {},
        "family_filing": {},
        "employment_final": {},
        "employment_filing": {},
    }

    if chart_url:
        print(f"Fetching monthly detailed chart page: {chart_url}...")
        page_html = fetch_url(chart_url)
        parser = TableParser()
        parser.feed(page_html)
        print(f"Extracted {len(parser.tables)} tables from chart page.")

        if len(parser.tables) > 0:
            fam_rows = parse_rows(parser.tables[0], is_employment=False)
            if fam_chart == "Dates for Filing":
                current_tables["family_filing"] = fam_rows
            else:
                current_tables["family_final"] = fam_rows

        if len(parser.tables) > 1:
            emp_rows = parse_rows(parser.tables[1], is_employment=True)
            if emp_chart == "Final Action Dates":
                current_tables["employment_final"] = emp_rows
            else:
                current_tables["employment_filing"] = emp_rows

    # Extract Previous Month tables from archive
    MONTHS = [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]
    parts = month_name.split()
    if len(parts) == 2 and parts[0] in MONTHS:
        m_idx = MONTHS.index(parts[0])
        y = int(parts[1])
        expected_prev = f"{MONTHS[11]} {y - 1}" if m_idx == 0 else f"{MONTHS[m_idx - 1]} {y}"
    else:
        expected_prev = "August 2026"

    prev_month_name = expected_prev
    prev_tables = {}
    prev_section = re.search(r"<h2>Previous Adjustment of Status Filing Charts</h2>(.*?)$", index_html, re.DOTALL | re.IGNORECASE)
    if prev_section:
        links = re.findall(r'<a[^>]+href=[\"\']([^\"\']+)[\"\'][^>]*>(.*?)</a>', prev_section.group(1), re.DOTALL)
        for href, text in links:
            t_clean = clean(re.sub(r"<[^<]+?>", "", text))
            if expected_prev.lower() in t_clean.lower():
                prev_url = href.replace("edit.uscis.gov", "www.uscis.gov")
                if prev_url.startswith("/"):
                    prev_url = "https://www.uscis.gov" + prev_url
                print(f"Fetching exact previous month: {expected_prev} ({prev_url})...")
                try:
                    prev_html = fetch_url(prev_url)
                    prev_parser = TableParser()
                    prev_parser.feed(prev_html)
                    if len(prev_parser.tables) > 0:
                        prev_tables["family_filing"] = parse_rows(prev_parser.tables[0], is_employment=False)
                    if len(prev_parser.tables) > 1:
                        prev_tables["employment_final"] = parse_rows(prev_parser.tables[1], is_employment=True)
                    print(f"Successfully parsed previous month ({expected_prev}) tables.")
                    break
                except Exception as ex:
                    print(f"Could not fetch previous month: {ex}")
                    break

    return {
        "month": month_name,
        "sourceUrl": dos_url,
        "uscisFilingChart": emp_chart,
        "uscisNote": note,
        "tables": current_tables,
        "previousMonth": prev_month_name or "August 2026",
        "previousTables": prev_tables,
    }


def main():
    print("Starting automated Visa Bulletin synchronization...")

    # Load existing current.json to preserve full fields if already seeded
    existing = {}
    current_json_path = os.path.join("data", "current.json")
    if os.path.exists(current_json_path):
        try:
            with open(current_json_path, "r", encoding="utf-8") as f:
                existing = json.load(f)
        except Exception as e:
            print(f"Note reading existing file: {e}")

    try:
        scraped = scrape_uscis()
    except Exception as e:
        print(f"Error scraping USCIS: {e}")
        if existing:
            print("Preserving existing current.json data as fallback.")
            return
        raise

    # Merge tables cleanly so no category or historical value is lost
    merged_tables = existing.get("tables", {})
    for key, table_data in scraped["tables"].items():
        if table_data:
            if key not in merged_tables:
                merged_tables[key] = {}
            merged_tables[key].update(table_data)

    merged_prev = existing.get("previousTables", {})
    for key, table_data in scraped.get("previousTables", {}).items():
        if table_data:
            if key not in merged_prev:
                merged_prev[key] = {}
            merged_prev[key].update(table_data)

    output = {
        "month": scraped["month"],
        "publishedAt": datetime.now(timezone.utc).isoformat(),
        "previousMonth": scraped["previousMonth"],
        "sourceUrl": scraped["sourceUrl"],
        "uscisFilingChart": scraped["uscisFilingChart"],
        "uscisNote": scraped["uscisNote"],
        "tables": merged_tables,
        "previousTables": merged_prev,
    }

    os.makedirs("data", exist_ok=True)
    with open(current_json_path, "w", encoding="utf-8") as f:
        json.dump(output, f, indent=2)

    print(f"SUCCESS: Generated {current_json_path} for {scraped['month']}!")


if __name__ == "__main__":
    main()
