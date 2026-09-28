import json
import os
import re
from datetime import datetime, timezone
from bs4 import BeautifulSoup
from seleniumbase import SB

INDEX_URL = "https://travel.state.gov/content/travel/en/legal/visa-law0/visa-bulletin.html"
USCIS_URL = "https://www.uscis.gov/green-card/green-card-processes-and-procedures/visa-availability-priority-dates/adjustment-of-status-filing-charts-from-the-visa-bulletin"
COUNTRIES = ["All Chargeability", "China", "India", "Mexico", "Philippines"]


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


def parse_bulletin_html(html, url):
    soup = BeautifulSoup(html, "html.parser")
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


def main():
    print("Launching Undetected Chrome via SeleniumBase to bypass Cloudflare...")
    with SB(uc=True, test=False, headless=True) as sb:
        print(f"Navigating to {INDEX_URL}...")
        sb.uc_open_with_reconnect(INDEX_URL, reconnect_time=4)
        sb.sleep(3)

        index_html = sb.get_page_source()
        soup = BeautifulSoup(index_html, "html.parser")
        bulletin_links = []
        for a in soup.select("a[href]"):
            href = a["href"].strip()
            text = clean(a.get_text()).lower()
            if any(term in href.lower() for term in ["visa-bulletin-for-", "visa-bulletin/20"]) or ("bulletin for" in text and "visa" in text):
                if href.startswith("/"):
                    href = "https://travel.state.gov" + href
                if href not in bulletin_links:
                    bulletin_links.append(href)
                    print(f"Found bulletin link: {href} (text: {text})")

        if not bulletin_links:
            # Fallback scan
            for a in soup.select("a[href]"):
                href = a["href"].strip()
                if "bulletin" in href.lower() and "/202" in href:
                    if href.startswith("/"):
                        href = "https://travel.state.gov" + href
                    if href not in bulletin_links:
                        bulletin_links.append(href)

        if not bulletin_links:
            page_title = soup.title.string if soup.title else "unknown"
            raise RuntimeError(f"No Visa Bulletin links found on index page (page title: {page_title})")

        current_url = bulletin_links[0]
        prev_url = bulletin_links[1] if len(bulletin_links) > 1 else None
        print(f"Current Bulletin URL: {current_url}")
        print(f"Previous Bulletin URL: {prev_url}")

        print(f"Fetching current bulletin: {current_url}...")
        sb.uc_open_with_reconnect(current_url, reconnect_time=3)
        sb.sleep(2)
        current_html = sb.get_page_source()
        current_data = parse_bulletin_html(current_html, current_url)

        previous_tables = {}
        previous_month = None
        if prev_url:
            try:
                print(f"Fetching previous bulletin: {prev_url}...")
                sb.uc_open_with_reconnect(prev_url, reconnect_time=3)
                sb.sleep(2)
                prev_html = sb.get_page_source()
                prev_data = parse_bulletin_html(prev_html, prev_url)
                previous_tables = prev_data["tables"]
                previous_month = prev_data["month"]
            except Exception as e:
                print(f"Warning: could not parse previous bulletin: {e}")

        # Check USCIS determination
        chart_type = "Dates for Filing"
        note = "For all employment-based preference categories, you must use the Dates for Filing chart."
        try:
            print("Checking USCIS adjustment of status chart determination...")
            sb.open(USCIS_URL)
            sb.sleep(2)
            uscis_text = sb.get_page_source().lower()
            if "dates for filing" in uscis_text and "use the dates for filing" in uscis_text:
                chart_type = "Dates for Filing"
                note = "For all employment-based preference categories, you must use the Dates for Filing chart in the Department of State Visa Bulletin."
            elif "final action dates" in uscis_text and "use the final action dates" in uscis_text:
                chart_type = "Final Action Dates"
                note = "USCIS determined to use the Final Action Dates chart this month."
        except Exception as e:
            print(f"USCIS check notice: {e}")

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
