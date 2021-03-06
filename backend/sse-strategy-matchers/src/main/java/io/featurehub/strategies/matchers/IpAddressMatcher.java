package io.featurehub.strategies.matchers;

import io.featurehub.sse.model.RolloutStrategyAttribute;

public class IpAddressMatcher implements StrategyMatcher {
  @Override
  public boolean match(String suppliedValue, RolloutStrategyAttribute attr) {
    try {
      switch (attr.getConditional()) {
        case EQUALS:
        case INCLUDES:
          return CIDRMatch.cidrMatch(attr.getValue().toString(), CIDRMatch.suppliedAddress(suppliedValue));
        case ENDS_WITH:
          break;
        case STARTS_WITH:
          break;
        case GREATER:
          break;
        case GREATER_EQUALS:
          break;
        case LESS:
          break;
        case LESS_EQUALS:
          break;
        case NOT_EQUALS:
        case EXCLUDES:
          return !CIDRMatch.cidrMatch(attr.getValue().toString(), CIDRMatch.suppliedAddress(suppliedValue));
        case REGEX:
          break;
      }
    } catch (Exception ignored) {}

    return false;
  }
}
