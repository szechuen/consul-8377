#!/bin/sh

echo "Waiting for cluster to be ready..."
while [ $(curl -s http://127.0.0.1:8501/v1/status/leader) = '""' ]; do :; done
sleep 2
echo ""

echo "Creating health check..."
curl -w '\n' --request PUT --data @register.json http://127.0.0.1:8501/v1/catalog/register
sleep 2
echo ""

echo "Querying health check -- this should be consistent across servers..."
echo "server1: "; curl -w '\n' http://127.0.0.1:8501/v1/health/checks/service1?stale
echo "server2: "; curl -w '\n' http://127.0.0.1:8502/v1/health/checks/service1?stale
echo "server3: "; curl -w '\n' http://127.0.0.1:8503/v1/health/checks/service1?stale
echo ""

echo "Manually triggering snapshots with different indexes..."
echo "server3"; curl -s http://127.0.0.1:8503/v1/snapshot?stale > /dev/null
curl -s --request PUT --data 'bar1' http://127.0.0.1:8501/v1/kv/foo > /dev/null; sleep 2
echo "server2"; curl -s http://127.0.0.1:8502/v1/snapshot?stale > /dev/null
curl -s --request PUT --data 'bar2' http://127.0.0.1:8501/v1/kv/foo > /dev/null; sleep 2
echo "server1"; curl -s http://127.0.0.1:8501/v1/snapshot?stale > /dev/null
echo ""

echo "Leaving and restarting servers..."
echo "server3"; curl --request PUT http://127.0.0.1:8503/v1/agent/leave; sleep 10
echo "server2"; curl --request PUT http://127.0.0.1:8502/v1/agent/leave; sleep 10
echo "server1"; curl --request PUT http://127.0.0.1:8501/v1/agent/leave; sleep 10
echo ""

echo "Checking Raft stats after restarts..."
echo "server1: "; curl -s http://127.0.0.1:8501/v1/agent/self | jq -cM '.Stats.raft'
echo "server2: "; curl -s http://127.0.0.1:8502/v1/agent/self | jq -cM '.Stats.raft'
echo "server3: "; curl -s http://127.0.0.1:8503/v1/agent/self | jq -cM '.Stats.raft'
echo ""

echo "Querying health check -- this should now be INconsistent across servers..."
echo "server1: "; curl -w '\n' http://127.0.0.1:8501/v1/health/checks/service1?stale
echo "server2: "; curl -w '\n' http://127.0.0.1:8502/v1/health/checks/service1?stale
echo "server3: "; curl -w '\n' http://127.0.0.1:8503/v1/health/checks/service1?stale
echo ""

echo "Performing CAS check update..."
curl -s http://127.0.0.1:8501/v1/health/checks/service1?consistent | jq '.[0] | .Status = "critical" | [{"Check": {"Verb": "cas", "Check": .}}]' | curl -w '\n' --request PUT --data @- http://127.0.0.1:8501/v1/txn
sleep 2
echo ""

echo "Querying health check -- note that status is only updated on leader..."
echo "server1: "; curl -w '\n' http://127.0.0.1:8501/v1/health/checks/service1?stale
echo "server2: "; curl -w '\n' http://127.0.0.1:8502/v1/health/checks/service1?stale
echo "server3: "; curl -w '\n' http://127.0.0.1:8503/v1/health/checks/service1?stale
echo ""
