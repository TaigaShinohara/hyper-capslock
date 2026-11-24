#!/usr/bin/env python3
"""HyperCapsLock CLI — shares hypercapslock_core with any future front-end.
Usage: python3 cli/hypercapslock.py <command> [--json] [--dry-run] [--yes]
Exit codes: 0 ok / 1 input / 2 app failure / 3 permission / 4 not found."""
import argparse, json, sys, uuid
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))
import hypercapslock_core as core

def wrap(ok, data=None, error=None):
    if ok: return {"ok": True, "data": data, "meta": {"schema_version": core.SCHEMA_VERSION, "request_id": uuid.uuid4().hex[:12]}}
    return {"ok": False, "error": error}

def emit(args, payload, human):
    if getattr(args, "json", False): print(json.dumps(payload, ensure_ascii=False, indent=2))
    elif not payload.get("ok"): print(f"error: {payload['error']['message']}", file=sys.stderr)
    else: print(human)

def main(argv=None):
    p=argparse.ArgumentParser(prog="hypercapslock", description="HyperCapsLock — CapsLockをAI開発のコックピットにする (agent CLI)")
    sub=p.add_subparsers(dest="cmd", required=True)
    def common(sp):
        sp.add_argument("--json", action="store_true"); sp.add_argument("--dry-run", action="store_true")
        sp.add_argument("--yes", action="store_true"); sp.add_argument("--idempotency-key")
        sp.add_argument("--timeout", type=float)
    for name in ["status","history","doctor","verify","export"]:
        sp=sub.add_parser(name, help=f"{name} — see docs/AGENT_GUIDE.md"); common(sp)
    sub.choices["history"].add_argument("--limit", type=int, default=20)
    sub.choices["doctor"].add_argument("--platform", choices=["mac","windows"])
    sp=sub.add_parser("list", help="list bindings"); common(sp); sp.add_argument("--phase", choices=["core","starter","phase2","excluded"])
    sp=sub.add_parser("get", help="get one binding"); common(sp); sp.add_argument("id")
    for name in ["install","uninstall"]:
        sp=sub.add_parser(name, help=f"{name} platform config"); common(sp); sp.add_argument("--platform", required=True, choices=["mac","windows"])
    args=p.parse_args(argv)
    try:
        if args.cmd=="status": data=core.status(); human=f"hyper-capslock v{core.APP_VERSION} level L{core.AGENT_LEVEL} bindings={data['bindings_count']}"
        elif args.cmd=="list": data={"bindings":core.list_bindings(args.phase)}; human="\n".join(f"{b['id']}\t{b['key']}\t{b['label']}" for b in data["bindings"])
        elif args.cmd=="get": data=core.get_binding(args.id); human=f"{data['id']}: {data['key']} -> {data['label']}"
        elif args.cmd=="history": data={"history":core.history(args.limit)}; human="\n".join(f"{h['at']} {h['event']}" for h in data["history"]) or "(no history)"
        elif args.cmd=="doctor": data=core.doctor(args.platform); human=f"ready={data['ready']} issues={len(data['issues'])}"
        elif args.cmd=="verify":
            data=core.verify(); human=f"verify ok={data['ok']}"
            if not data["ok"]: emit(args, wrap(False, error={"code":"verify_failed","message":"verify failed","retryable":False,"details":data}), human); return 2
        elif args.cmd=="export": data=core.export(); human=f"files={len(data['files'])} bindings={len(data['bindings'])}"
        elif args.cmd=="install": data=core.install(args.platform, dry_run=args.dry_run, idempotency_key=args.idempotency_key); human=f"install {args.platform} dry_run={args.dry_run} actions={len(data['actions'])}"
        elif args.cmd=="uninstall":
            if not args.dry_run and not args.yes:
                emit(args, wrap(False, error={"code":"confirmation_required","message":"uninstall requires --yes (or --dry-run)","retryable":False}), ""); return 1
            data=core.uninstall(args.platform, dry_run=args.dry_run); human=f"uninstall {args.platform} dry_run={args.dry_run}"
        emit(args, wrap(True, data=data), human); return 0
    except core.CoreError as e:
        emit(args, wrap(False, error={"code":e.code,"message":e.message,"retryable":e.retryable}), ""); return e.exit_code
    except Exception as e:
        emit(args, wrap(False, error={"code":"internal","message":str(e),"retryable":False}), ""); return 2

if __name__=="__main__": sys.exit(main())
