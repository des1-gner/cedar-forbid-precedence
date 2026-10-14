# Cedar: forbid overrides permit (verified)

A tiny, reproducible check of a core Cedar authorization semantic: **a `forbid`
policy always takes precedence over a conflicting `permit`**. This underpins how
Amazon Bedrock AgentCore Policy (and Cedar generally) enforces hard restrictions.

Verified live against the Cedar engine via Amazon Verified Permissions.

## The claim

> In Cedar, `forbid` policies always take precedence over `permit` policies.
> So an explicit `forbid` guarantees a restriction holds even if some other
> `permit` would otherwise allow the request.

## Result (see `sample-output.txt`)

| Scenario | Decision |
|---|---|
| `permit` + conflicting `forbid` (same principal/action/resource) | **DENY** (forbid wins) |
| `permit` only, no matching `forbid` | **ALLOW** |

The ALLOW control case shows the DENY is the forbid overriding a real permit, not
just a default-deny.

I also submitted the AgentCore-style policy shapes in `agentcore_policies.cedar`
(the `AgentCore::OAuthUser` principal, `hasTag`/`getTag`, `context.input.amount`
when-clauses). Both the permit and forbid parse and are accepted by the Cedar
engine, and for `refund-agent` at `amount=15000` the forbid is the determining
policy and the decision is DENY.

## Run it

```bash
AWS_REGION=us-west-2 ./verify_forbid_precedence.sh
```

Requires AWS credentials with Amazon Verified Permissions access. The script
creates a temporary policy store and deletes it at the end.

## Notes

- No account IDs are committed; the ARN in `agentcore_policies.cedar` uses an
  `<ACCOUNT_ID>` placeholder.
- Verified Permissions is used as a convenient, public way to exercise the Cedar
  engine; the forbid-overrides-permit rule is core Cedar behaviour and identical
  wherever Cedar is evaluated (including AgentCore Policy).

## References

- Cedar policy syntax: https://docs.cedarpolicy.com/policies/syntax-policy.html
- Understanding Cedar policies (AgentCore): https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/policy-understanding-cedar.html
