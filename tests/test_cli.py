import json, os, subprocess, sys, tempfile, unittest
from pathlib import Path
ROOT = Path(__file__).resolve().parent.parent
CLI = [sys.executable, str(ROOT/"cli"/"hypercapslock.py")]

def run(args, home):
    env = dict(os.environ, HYPERCAPSLOCK_HOME=str(home))
    r = subprocess.run(CLI+args, capture_output=True, text=True, env=env)
    return r

class TestCLI(unittest.TestCase):
    def setUp(self): self.home = Path(tempfile.mkdtemp())
    def test_status(self):
        r = run(["status","--json"], self.home); d=json.loads(r.stdout)
        self.assertEqual(r.returncode,0); self.assertTrue(d["ok"]); self.assertEqual(d["data"]["bindings_count"],22)
    def test_list_get(self):
        r=run(["list","--phase","starter","--json"], self.home); d=json.loads(r.stdout)
        self.assertTrue(all(b["phase"]=="starter" for b in d["data"]["bindings"]))
        r=run(["get","binding:hyper-c","--json"], self.home); self.assertEqual(json.loads(r.stdout)["data"]["key"],"Hyper+C")
        r=run(["get","binding:nope","--json"], self.home); self.assertEqual(r.returncode,4)
    def test_install_dryrun_idempotent_uninstall(self):
        r=run(["install","--platform","mac","--dry-run","--json"], self.home); self.assertTrue(json.loads(r.stdout)["data"]["dry_run"])
        self.assertFalse((self.home/".config").exists())
        run(["install","--platform","mac","--idempotency-key","k1","--json"], self.home)
        target=self.home/".config"/"karabiner"/"assets"/"complex_modifications"/"hyper-capslock.json"; self.assertTrue(target.exists())
        r=run(["install","--platform","mac","--idempotency-key","k1","--json"], self.home)
        self.assertTrue(json.loads(r.stdout)["data"].get("idempotent_replay"))
        r=run(["uninstall","--platform","mac","--json"], self.home); self.assertEqual(r.returncode,1)
        r=run(["uninstall","--platform","mac","--yes","--json"], self.home); self.assertEqual(r.returncode,0); self.assertFalse(target.exists())
    def test_verify_doctor_history(self):
        r=run(["verify","--json"], self.home); self.assertTrue(json.loads(r.stdout)["data"]["ok"])
        r=run(["doctor","--json"], self.home); self.assertEqual(r.returncode,0)
        r=run(["history","--json"], self.home); self.assertTrue(json.loads(r.stdout)["ok"])
    def test_help(self):
        r=run(["--help"], self.home); self.assertEqual(r.returncode,0); self.assertIn("hypercapslock", r.stdout)

if __name__=="__main__": unittest.main()
