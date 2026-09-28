import json, os, re
from datetime import datetime, timezone
import requests
from bs4 import BeautifulSoup
import azure.functions as func
from azure.storage.blob import BlobServiceClient, ContentSettings

app = func.FunctionApp()
INDEX = "https://travel.state.gov/content/travel/en/legal/visa-law0/visa-bulletin.html"
UA = {"User-Agent": "VisaBulletinLite/1.0 (+unofficial bulletin notifier)"}
COUNTRIES = ["All Chargeability", "China", "India", "Mexico", "Philippines"]


def latest_link():
    s = BeautifulSoup(requests.get(INDEX, headers=UA, timeout=20).text, "html.parser")
    # Anchor discovery to the "Current Visa Bulletin" region so archived links cannot win.
    current = s.find(lambda tag: tag.name in ["h1","h2","h3","h4","div","span"] and "current visa bulletin" in clean(tag.get_text(" ", strip=True)).lower())
    anchor = current.find_next("a", href=True) if current else None
    if not anchor or "visa-bulletin-for-" not in anchor.get("href", ""):
        anchor = next((a for a in s.select("a[href]") if "/visa-bulletin/20" in a.get("href","") and "visa-bulletin-for-" in a.get("href","")), None)
    if not anchor: raise RuntimeError("Could not locate current bulletin link")
    href=anchor.get("href")
    if href.startswith("/"): href="https://travel.state.gov"+href
    return href


def clean(x): return " ".join(x.split()).strip()

def normalize_category(label, employment):
    t=clean(label).lower()
    if employment:
        if t.startswith("1st"): return "EB-1"
        if t.startswith("2nd"): return "EB-2"
        if t.startswith("3rd"): return "EB-3"
        if "other workers" in t: return "Other Workers"
        if t.startswith("4th"): return "EB-4"
        if "religious" in t: return "Certain Religious Workers"
        if "5th unreserved" in t: return "EB-5 Unreserved"
        if "rural" in t: return "EB-5 Rural"
        if "high unemployment" in t: return "EB-5 High Unemployment"
        if "infrastructure" in t: return "EB-5 Infrastructure"
    else:
        for x in ["F1","F2A","F2B","F3","F4"]:
            if t.upper().startswith(x): return x
    return None


def table_rows(table, employment):
    rows={}
    trs=table.select("tr")
    for tr in trs[1:]:
        cells=[clean(c.get_text(" ", strip=True)) for c in tr.select("th,td")]
        if len(cells)<6: continue
        cat=normalize_category(cells[0], employment)
        if not cat: continue
        rows[cat]={COUNTRIES[i]: cells[i+1].replace(" ","") for i in range(5)}
    return rows


def parse_bulletin(url):
    html=requests.get(url,headers=UA,timeout=20).text
    s=BeautifulSoup(html,"html.parser")
    title=clean((s.find("h1") or s.find("title")).get_text(" ",strip=True))
    m=re.search(r"(?:For\s+)?([A-Z][a-z]+\s+20\d{2})", title)
    month=m.group(1) if m else title
    tables=s.find_all("table")
    parsed=[]
    for t in tables:
        text=clean(t.get_text(" ",strip=True)).lower()
        if "all chargeability" not in text or "india" not in text: continue
        employment=("employment" in text or any(k in text for k in ["1st","2nd","other workers"]))
        rows=table_rows(t,employment)
        if rows: parsed.append((employment,rows))
    # Expected sequence: family final, family filing, employment final, employment filing.
    fam=[r for e,r in parsed if not e]; emp=[r for e,r in parsed if e]
    if len(fam)<2 or len(emp)<2: raise RuntimeError(f"Unexpected bulletin table shape: family={len(fam)} employment={len(emp)}")
    return {"month":month,"publishedAt":datetime.now(timezone.utc).isoformat(),"sourceUrl":url,"tables":{"family_final":fam[0],"family_filing":fam[1],"employment_final":emp[0],"employment_filing":emp[1]}}


def blob_client():
    conn=os.environ["AzureWebJobsStorage"]
    svc=BlobServiceClient.from_connection_string(conn)
    container=svc.get_container_client("public")
    try: container.create_container(public_access="blob")
    except Exception: pass
    return container.get_blob_client("current.json")


def load_existing(blob):
    try: return json.loads(blob.download_blob().readall())
    except Exception: return None


def send_push(month):
    # Optional Firebase Admin credentials as JSON in FIREBASE_SERVICE_ACCOUNT_JSON.
    raw=os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON")
    if not raw: return
    import firebase_admin
    from firebase_admin import credentials, messaging
    if not firebase_admin._apps:
        firebase_admin.initialize_app(credentials.Certificate(json.loads(raw)))
    messaging.send(messaging.Message(notification=messaging.Notification(title=f"{month} Visa Bulletin published",body="See what changed across visa categories."),topic="visa-bulletin",data={"type":"new_bulletin"}))


def run_check():
    url=latest_link(); fresh=parse_bulletin(url); blob=blob_client(); old=load_existing(blob)
    if old and old.get("month")==fresh.get("month"): return {"changed":False,"month":fresh["month"]}
    fresh["previousMonth"] = old.get("month") if old else None
    fresh["previousTables"] = old.get("tables",{}) if old else {}
    blob.upload_blob(json.dumps(fresh,indent=2),overwrite=True,content_settings=ContentSettings(content_type="application/json",cache_control="public, max-age=300"))
    send_push(fresh["month"])
    return {"changed":True,"month":fresh["month"]}

@app.timer_trigger(schedule="0 0 14 * * *", arg_name="timer", run_on_startup=False, use_monitor=True)
def daily_check(timer: func.TimerRequest):
    run_check()

@app.route(route="check", methods=["POST"], auth_level=func.AuthLevel.FUNCTION)
def manual_check(req: func.HttpRequest):
    try: return func.HttpResponse(json.dumps(run_check()),mimetype="application/json")
    except Exception as e: return func.HttpResponse(json.dumps({"error":str(e)}),status_code=500,mimetype="application/json")
