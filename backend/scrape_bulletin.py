import json
import os
import re
import sys
from datetime import datetime, timezone
from bs4 import BeautifulSoup
from curl_cffi import requests

INDEX_URL = "https://travel.state.gov/content/travel/en/legal/visa-law0/visa-bulletin.html"
USCIS_URL = "https://www.uscis.gov/green-card/green-card-processes-and-procedures/visa-availability-priority-dates/adjustment-of-status-filing-charts-from-the-visa-bulletin"
COUNTRIES = ["All Chargeability", "China", "India", "Mexico", "Philippines"]


def clean(x):
    return " ".join(x.split()).strip() if x else ""


def get_latest_bulletin_urls():
    """Finds current and previous bulletin URLs from the official index."""
    resp = requests.get(INDEX_URL, impersonate="chrome120", timeout=30)
    if resp.status_code != 200:
        raise RuntimeError(f"Failed to fetch index: HTTP {resp.status_code}")

    soup = BeautifulSoup(resp.text, "html.parser")
    bulletin_links = []
    for a in soup.select("a[href]"):
        href = a["href"]
        text = clean(a.get_text())
        if "visa-bulletin-for-" in href.lower() or "visa bulletin for" in text.lower():
            if href.startswith("/"):
                href = "https://travel.state.gov" + href
            if href not in bulletin_links:
                bulletin_links.append(href)

    if not bulletin_links:
        raise RuntimeError("No Visa Bulletin links found on index page")

    current_url = bulletin_links[0]
    prev_url = bulletin_links[1] if len(bulletin_links) > 1 else None
    return current_url, prev_url


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


def parse_table_rows(table, is_employment):
    rows = {}
    trs = table.select("tr")
    for tr in trs:
        cells = [clean(c.get_text()) for c in tr.select("th,td")]
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


def parse_bulletin_page(url):
    resp = requests.get(url, impersonate="chrome120", timeout=30)
    if resp.status_code != 200:
        raise RuntimeError(f"Failed to fetch bulletin at {url}: HTTP {resp.status_code}")

    soup = BeautifulSoup(resp.text, "html.parser")
    title = clean((soup.find("h1") or soup.find("title")).get_text())
    m = re.search(r"(?:For\s+)?([A-Z][a-z]+\s+20\d{2})", title)
    month = m.group(1) if m else title

    tables = soup.find_all("table")
    parsed = []
    for t in tables:
        text = clean(t.get_text()).lower()
        if "all chargeability" not in text or "india" not in text:
            continue
        is_emp = "employment" in text or any(k in text for k in ["1st", "2nd", "other workers"])
        rows = parse_table_rows(t, is_emp)
        if rows:
            parsed.append((is_emp, rows))

    fam = [r for is_emp, r in parsed if not is_emp]
    emp = [r for is_emp, r in parsed if is_emp]

    return {
        "month": month,
        "sourceUrl": url,
        "tables": {
            "family_final": fam[0] if len(fam) > 0 else {},
            "family_filing": fam[1] if len(fam) > 1 else {},
            "employment_final": emp[0] if len(emp) > 0 else {},
            "employment_filing": emp[1] if len(emp) > 1 else {},
        },
    }


def get_uscis_determination():
    """Extracts USCIS filing chart determination (Dates for Filing vs Final Action Dates)."""
    try:
        resp = requests.get(USCIS_URL, impersonate="chrome120", timeout=20)
        if resp.status_code == 200:
            text = resp.text.lower()
            if "dates for filing" in text and "use the dates for filing" in text:
                return "Dates for Filing", "For all employment-based categories, you must use the Dates for Filing chart."
            if "final action dates" in text and "use the final action dates" in text:
                return "Final Action Dates", "USCIS determined to use Final Action Dates for Adjustment of Status this month."
    except Exception as e:
        print(f"USCIS determination notice: {e}")
    return "Dates for Filing", "Check official USCIS Adjustment of Status filing chart."


def main():
    print("Fetching Department of State Visa Bulletin...")
    current_url, prev_url = get_latest_bulletin_urls()
    print(f"Current Bulletin URL: {current_url}")
    print(f"Previous Bulletin URL: {prev_url}")

    current_data = parse_bulletin_page(current_url)
    previous_tables = {}
    previous_month = None

    if prev_url:
        try:
            prev_data = parse_bulletin_page(prev_url)
            previous_tables = prev_data["tables"]
            previous_month = prev_data["month"]
        except Exception as e:
            print(f"Warning: could not parse previous bulletin: {e}")

    chart_type, note = get_uscis_determination()

    output = {
        "month": current_data["month"],
        "publishedAt": datetime.now(timezone.utc).isoformat(),
        "previousMonth": previous_month,
        "sourceUrl": current_url,
        "uscisFilingChart": chart_type,
        "uscisNote": note,
        "tables": current_data["tables"],
        "previousTables": previous_tables,
    }

    os.makedirs("data", exist_ok=True)
    out_path = os.path.join("data", "current.json")
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(output, f, indent=2)

    print(f"Successfully generated {out_path} for {current_data['month']}!")


if __name__ == "__main__":
    main()
