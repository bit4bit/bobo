Feature: As Programmer

  Background:
    Given fresh command

  Scenario: start a mob in source code
    Given example source code as "example"
    And I inside "example"
    When I start mob
    Then I can query mob ID
    Then I stop mob
