"""Shared core for HyperCapsLock. GUI-less: the CLI (and any future
front-end) must go through this module — no second implementation."""
import hashlib, json, os, shutil, uuid
from datetime import datetime, timezone
from pathlib import Path

SCHEMA_VERSION = 1
APP_VERSION = "0.2.0"
AGENT_LEVEL = 2

REPO_ROOT = Path(__file__).resolve().parent.parent
PLATFORM_FILES = {
    "mac": [("mac/karabiner/hyper-capslock.json",
             ".config/karabiner/assets/complex_modifications/hyper-capslock.json")],
    "windows": [("windows/kanata/hyper-capslock.kbd",
                 "hyper-capslock/kanata/hyper-capslock.kbd"),
                ("windows/autohotkey/HyperCapsLock.ahk",
                 "hyper-capslock/autohotkey/HyperCapsLock.ahk")],
}

class CoreError(Exception):
    def __init__(self, code, message, exit_code=2, retryable=False):
        super().__init__(message); self.code=code; self.message=message
        self.exit_code=exit_code; self.retryable=retryable

def state_home():
    return Path(os.environ.get("HYPERCAPSLOCK_HOME", str(Path.home())))

def _now():
    return datetime.now(timezone.utc).isoformat()

def _bindings():
    p = REPO_ROOT/"config"/"bindings.json"
    if not p.exists(): raise CoreError("config_missing","bindings.json not found",2)
    return json.loads(p.read_text(encoding="utf-8"))

def list_bindings(phase=None):
    items=_bindings()["bindings"]
    if phase: items=[b for b in items if b["phase"]==phase]
    return items

def get_binding(bid):
    for b in _bindings()["bindings"]:
        if b["id"]==bid: return b
    raise CoreError("not_found", f"binding not found: {bid}", exit_code=4)

def _sha(p): return hashlib.sha256(Path(p).read_bytes()).hexdigest()

def file_inventory():
    out=[]
    for plat, pairs in PLATFORM_FILES.items():
        for src,_ in pairs:
            p=REPO_ROOT/src
            out.append({"platform":plat,"path":src,"exists":p.exists(),
                        "sha256":_sha(p) if p.exists() else None})
    out.append({"platform":"shared","path":"config/bindings.json","exists":(REPO_ROOT/"config"/"bindings.json").exists(),
                "sha256":_sha(REPO_ROOT/"config"/"bindings.json") if (REPO_ROOT/"config"/"bindings.json").exists() else None})
    return out

def installed_state():
    home=state_home(); res={}
    for plat,pairs in PLATFORM_FILES.items():
        res[plat]=[{"target":dst,"installed":(home/dst).exists()} for _,dst in pairs]
    return res

def status():
    return {"app":"hyper-capslock","app_version":APP_VERSION,"schema_version":SCHEMA_VERSION,
            "agent_level":AGENT_LEVEL,"bindings_count":len(_bindings()["bindings"]),
            "files":file_inventory(),"installed":installed_state()}

def _history_path(): return state_home()/".hypercapslock"/"history.jsonl"

def record_history(event, detail):
    hp=_history_path(); hp.parent.mkdir(parents=True, exist_ok=True)
    rec={"at":_now(),"event":event,"detail":detail,"request_id":uuid.uuid4().hex[:12]}
    with hp.open("a",encoding="utf-8") as f: f.write(json.dumps(rec,ensure_ascii=False)+"\n")
    return rec

def history(limit=20):
    hp=_history_path()
    if not hp.exists(): return []
    lines=[json.loads(x) for x in hp.read_text(encoding="utf-8").splitlines() if x.strip()]
    return lines[-limit:]

def _idem_path(): return state_home()/".hypercapslock"/"idempotency.json"
def _idem_get(key):
    p=_idem_path()
    if not key or not p.exists(): return None
    try: return json.loads(p.read_text(encoding="utf-8")).get(key)
    except Exception: return None
def _idem_put(key, result):
    if not key: return
    p=_idem_path(); p.parent.mkdir(parents=True, exist_ok=True)
    data={}
    if p.exists():
        try: data=json.loads(p.read_text(encoding="utf-8"))
        except Exception: data={}
    data[key]=result; p.write_text(json.dumps(data,ensure_ascii=False),encoding="utf-8")

def install(platform, dry_run=False, idempotency_key=None):
    if platform not in PLATFORM_FILES:
        raise CoreError("invalid_input", f"unknown platform: {platform}", exit_code=1)
    prev=_idem_get(idempotency_key)
    if prev: return {**prev, "idempotent_replay": True}
    home=state_home(); actions=[]
    for src,dst in PLATFORM_FILES[platform]:
        sp=REPO_ROOT/src; tp=home/dst
        if not sp.exists(): raise CoreError("config_missing", f"source missing: {src}",2)
        actions.append({"source":src,"target":str(tp),"sha256":_sha(sp)})
        if not dry_run:
            tp.parent.mkdir(parents=True, exist_ok=True); shutil.copyfile(sp,tp)
    result={"platform":platform,"dry_run":dry_run,"actions":actions,"installed":not dry_run}
    if not dry_run:
        record_history("install",{"platform":platform,"targets":[a["target"] for a in actions]})
        _idem_put(idempotency_key,result)
    return result

def uninstall(platform, dry_run=False):
    if platform not in PLATFORM_FILES:
        raise CoreError("invalid_input", f"unknown platform: {platform}", exit_code=1)
    home=state_home(); removed=[]
    for _,dst in PLATFORM_FILES[platform]:
        tp=home/dst; removed.append({"target":str(tp),"exists":tp.exists()})
        if not dry_run and tp.exists(): tp.unlink()
    if not dry_run: record_history("uninstall",{"platform":platform})
    return {"platform":platform,"dry_run":dry_run,"targets":removed}

def verify():
    checks=[]
    try:
        b=_bindings(); ids=[x["id"] for x in b["bindings"]]
        checks.append({"name":"bindings-parse","ok":True})
        checks.append({"name":"binding-ids-unique","ok":len(ids)==len(set(ids))})
        checks.append({"name":"binding-ids-stable-prefix","ok":all(i.startswith("binding:") for i in ids)})
    except Exception as e:
        checks.append({"name":"bindings-parse","ok":False,"reason":str(e)})
    kp=REPO_ROOT/"mac"/"karabiner"/"hyper-capslock.json"
    try:
        json.loads(kp.read_text(encoding="utf-8")); checks.append({"name":"karabiner-json-valid","ok":True})
    except Exception as e:
        checks.append({"name":"karabiner-json-valid","ok":False,"reason":str(e)})
    for f in ["windows/kanata/hyper-capslock.kbd","windows/autohotkey/HyperCapsLock.ahk","docs/AGENT_GUIDE.md","docs/agent-manifest.json"]:
        checks.append({"name":f"exists:{f}","ok":(REPO_ROOT/f).exists()})
    ok=all(c["ok"] for c in checks)
    record_history("verify",{"ok":ok,"checks":len(checks)})
    return {"ok":ok,"checks":checks}

def doctor(platform=None):
    issues=[]
    for item in file_inventory():
        if not item["exists"]: issues.append({"code":"config_missing","target":item["path"],"fix":"restore the file from the repo"})
    plats=[platform] if platform else list(PLATFORM_FILES)
    for plat in plats:
        if plat not in PLATFORM_FILES: raise CoreError("invalid_input",f"unknown platform: {plat}",1)
        for entry in installed_state()[plat]:
            if not entry["installed"]:
                issues.append({"code":"not_installed","target":entry["target"],"fix":f"run: hypercapslock install --platform {plat} --dry-run, then without --dry-run"})
    issues.append({"code":"human_only","target":"os-permission-grant","fix":"human must approve Karabiner driver/input-monitoring or Windows UAC/driver dialogs (see AGENT_GUIDE)"})
    return {"platform":platform,"issues":issues,"ready":not any(i["code"]=="config_missing" for i in issues)}

def export():
    return {"files":file_inventory(),"bindings":list_bindings()}
