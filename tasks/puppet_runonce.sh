#!/bin/bash

[ "$PT_noop" = "true" ] && NOOP_FLAG="--noop" || unset NOOP_FLAG

# Wait for up to five minutes for an in-progress Puppet agent run to complete
# TODO: right now the check is just for lock file existence. Improve the check
#       to account for situations where the lockfile is stale.
echo -n "Check for and wait up to 5 minutes for in-progress run to complete"
lockfile=$(/opt/puppetlabs/bin/puppet config print agent_catalog_run_lockfile)
n=0
until [ $n -ge 300 ]
do
  [ ! -e "$lockfile" ] && break
  echo -n .
  n=$[$n+1]
  sleep 1
done
echo

# Notes:
#   - Do not run with color, as the color codes can make interpreting output when
#     passed through Bolt difficult.
#   - Without --detailed-exitcodes, the `puppet agent` command will return 0 even
#     if there are a resource failures. So, use --detailed-exitcodes.
/opt/puppetlabs/bin/puppet agent \
  --onetime \
  --verbose \
  --no-daemonize \
  --no-usecacheonfailure \
  --no-splay \
  --no-use_cached_catalog \
  --detailed-exitcodes \
  --color false \
  $NOOP_FLAG

# Only exit non-zero if an error occurred. Changes (detailed exit code 2) are
# not errors.
exitcode=$?
if [ $exitcode -eq 0 -o $exitcode -eq 2 ]; then
  exit 0
else
  exit $exitcode
fi
