Feature: As Programmer

  Background:
    Given fresh command

  Scenario: start a mob in source code
    Given example source code as "example"
    And I inside "example"
    When I start mob
    Then I can query mob ID

  Scenario: connect to active mob
    Given example source code as "example-mob"
    And example source code as "example-user"
    And I inside "example-user"
    When I start mob
    Then I can connect to mob started
