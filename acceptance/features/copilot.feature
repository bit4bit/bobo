Feature: As Copilot
  Background:
    Given the source code
    When I start mob
    When I connect to mob started

  Scenario: copilot a mob
    Given a partner
    When the partner drive a file
    Then I expect same content of drived partner file

  Scenario: copilot only update changed files
    Given a partner
    When the partner drive a file
    Then I do not expect changes on the file
