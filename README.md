# Cedar forbid vs permit

A quick, reproducible check that a Cedar `forbid` beats a conflicting `permit`. I
wanted to confirm this properly rather than take it on faith, so I ran it against
the Cedar engine through Amazon Verified Permissions.

The thing being checked: if one policy permits a request and another forbids the
same request, Cedar denies it. The forbid wins. That is what makes an explicit
forbid useful for hard restrictions (blocked roles, blackout windows, suspended
users) that need to hold no matter what other permits exist.

## What I ran

`verify_forbid_precedence.sh` spins up a throwaway policy store, adds a permit and
a matching forbid for the same principal/action/resource, and asks is-authorized
for a decision. Then it adds a permit for a different principal with no forbid, as
a control, and deletes the store at the end.

Results:

- permit plus a conflicting forbid, decision was DENY
- permit on its own, no forbid, decision was ALLOW

The second case matters: it shows the DENY in the first case is the forbid
actually overriding a real permit, not just Cedar defaulting to deny because
nothing matched.

I also threw the actual AgentCore policy shapes at it (`agentcore_policies.cedar`),
the ones with `AgentCore::OAuthUser`, `hasTag`/`getTag` and `context.input.amount`.
Both the permit and the forbid parse and are accepted. For `refund-agent` at an
amount of 15000, with a permit matching and the forbid matching, the decision came
back DENY and the determining policy was the forbid, no evaluation errors.

See `sample-output.txt` for the output.

## Running it yourself

    AWS_REGION=us-west-2 ./verify_forbid_precedence.sh

You need AWS credentials with Verified Permissions access. The script cleans up
the policy store it creates.

## A couple of notes

There are no account IDs in here. The ARN in `agentcore_policies.cedar` is a
placeholder.

I used Verified Permissions because it is an easy public way to drive the Cedar
engine. The forbid-over-permit rule is core Cedar, so it behaves the same wherever
Cedar runs, including AgentCore Policy.

## References

- Cedar, policy syntax (permit/forbid, when/unless): https://docs.cedarpolicy.com/policies/syntax-policy.html
- Cedar, how authorisation works (deny overrides, PARC): https://docs.cedarpolicy.com/auth/authorization.html
- AgentCore, understanding Cedar policies (deny by default, forbid): https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/policy-understanding-cedar.html
- Amazon Verified Permissions, what it is (the Cedar engine used here): https://docs.aws.amazon.com/verifiedpermissions/latest/userguide/what-is-avp.html
