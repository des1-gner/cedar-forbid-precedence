#!/usr/bin/env bash
# Verify Cedar's forbid-overrides-permit semantic using Amazon Verified Permissions
# (the Cedar authorization engine). Creates a temporary policy store, adds a permit
# and a conflicting forbid for the same principal/action/resource, and runs
# is-authorized to show the result is DENY (forbid wins). Then a control case with a
# permit only shows ALLOW. The store is deleted at the end.
#
# No account IDs required; uses your own AWS credentials. Region defaults to us-west-2.
set -uo pipefail
R="${AWS_REGION:-us-west-2}"

PS=$(aws verifiedpermissions create-policy-store --validation-settings '{"mode":"OFF"}' --region "$R" \
     --query policyStoreId --output text)
echo "policy store: $PS"

aws verifiedpermissions create-policy --policy-store-id "$PS" --region "$R" \
  --definition '{"static":{"statement":"permit(principal == Agent::\"refund-agent\", action == Action::\"process\", resource == Gateway::\"refund\");"}}' >/dev/null
aws verifiedpermissions create-policy --policy-store-id "$PS" --region "$R" \
  --definition '{"static":{"statement":"forbid(principal == Agent::\"refund-agent\", action == Action::\"process\", resource == Gateway::\"refund\");"}}' >/dev/null

echo "--- permit + conflicting forbid (expect DENY) ---"
aws verifiedpermissions is-authorized --policy-store-id "$PS" --region "$R" \
  --principal '{"entityType":"Agent","entityId":"refund-agent"}' \
  --action '{"actionType":"Action","actionId":"process"}' \
  --resource '{"entityType":"Gateway","entityId":"refund"}' \
  --query decision --output text

aws verifiedpermissions create-policy --policy-store-id "$PS" --region "$R" \
  --definition '{"static":{"statement":"permit(principal == Agent::\"senior-agent\", action == Action::\"process\", resource == Gateway::\"refund\");"}}' >/dev/null

echo "--- permit only, no forbid (expect ALLOW) ---"
aws verifiedpermissions is-authorized --policy-store-id "$PS" --region "$R" \
  --principal '{"entityType":"Agent","entityId":"senior-agent"}' \
  --action '{"actionType":"Action","actionId":"process"}' \
  --resource '{"entityType":"Gateway","entityId":"refund"}' \
  --query decision --output text

aws verifiedpermissions delete-policy-store --policy-store-id "$PS" --region "$R" >/dev/null
echo "deleted policy store $PS"
