// The exact Cedar policy shapes used by AgentCore Policy (NL2Cedar output),
// as taught in the training. Both parse and are accepted by the Cedar engine.
// <ACCOUNT_ID> is a placeholder.

// PERMIT: allow refund-agent to process refunds under $500
permit(
  principal is AgentCore::OAuthUser,
  action == AgentCore::Action::"RefundTool___process_refund",
  resource == AgentCore::Gateway::"arn:aws:bedrock-agentcore:us-west-2:<ACCOUNT_ID>:gateway/refund-gateway"
)
when {
  principal.hasTag("username") &&
  principal.getTag("username") == "refund-agent" &&
  context.input.amount < 500
};

// FORBID: deny refund-agent from processing refunds over $10,000.
// forbid always takes precedence over any matching permit.
forbid(
  principal is AgentCore::OAuthUser,
  action == AgentCore::Action::"RefundTool___process_refund",
  resource == AgentCore::Gateway::"arn:aws:bedrock-agentcore:us-west-2:<ACCOUNT_ID>:gateway/refund-gateway"
)
when {
  principal.hasTag("username") &&
  principal.getTag("username") == "refund-agent" &&
  context.input.amount > 10000
};
