Feature: As Programmer
  Scenario: connect to active mob
    Given example source code as "example-mob"
    And example source code as "example-user"
    And I inside "example-user"
    When I start mob
    Then I connect to mob started

  Scenario: drive a file
    Given example source code as "example-mob"
    And example source code as "example-user"
    And I inside "example-user"
    When I start mob
    Then I connect to mob started
    And I drive file "example.rb"
    Then drive ok
