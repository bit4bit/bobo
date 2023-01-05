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
    Then I connect to mob started

  Scenario: can't drive a file if content mismatch
    Given example source code as "example-mob"
    And example source code as "example-user"
    And In "example-user" file "example.rb" has content "puts 'bad'"
    And I inside "example-user"
    When I start mob
    Then I connect to mob started
    And I drive file "example.rb"
    Then drive fails with error message "can't drive file example.rb mismatch content"

  Scenario: drive a file
    Given example source code as "example-mob"
    And example source code as "example-user"
    And I inside "example-user"
    When I start mob
    Then I connect to mob started
    And I drive file "example.rb"
    Then drive ok
