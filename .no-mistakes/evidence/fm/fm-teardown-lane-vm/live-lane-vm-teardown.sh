#!/usr/bin/env bash
# Live check: real fm-teardown.sh + real limactl against an isolated LIMA_HOME of
# real stopped Lima VMs. Usage: live-lane-vm-teardown.sh <defs.sh> <lima-home> <scenario: ship|scout|force>
DEFS=$1; export LIMA_HOME=$2; SCEN=$3
cd "$(dirname "$DEFS")"
. "$DEFS"
set -e
if [ "$SCEN" = force ]; then
  case_dir=$(make_case lane-vm-live-force); write_meta "$case_dir" no-mistakes ship
  wt_commit "$case_dir" "unlanded work"
  "$ROOT/bin/fm-lane-vm-record.sh" "$case_dir/state/task-x1.meta" pg-it
  "$ROOT/bin/fm-lane-vm-record.sh" "$case_dir/state/task-x1.meta" task-x1-api
  args=--force
else
  case_dir=$(lane_vm_case lane-vm-live-$SCEN "$SCEN"); args=
fi
rm -f "$case_dir/fakebin/limactl"   # use the real limactl
echo "== task meta lane_vms line"; grep '^lane_vms=' "$case_dir/state/task-x1.meta"
echo "== VMs before (LIMA_HOME=$LIMA_HOME)"; limactl list --format '{{.Name}} {{.Status}}'
set +e; run_teardown "$case_dir" $args > "$case_dir/stdout" 2> "$case_dir/stderr"; rc=$?; set -e
echo "== fm-teardown.sh task-x1 $args exit=$rc"; tail -3 "$case_dir/stdout"; grep -i -E 'lima|warning' "$case_dir/stderr" || true
echo "== VMs after"; limactl list --format '{{.Name}} {{.Status}}'
