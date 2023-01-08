Feature: As Programmer
  Scenario: connect to active mob
    Given example source code as "mycode"
    And I inside "mycode"
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

  Scenario: drive a file it's always in the project
    Given example source code as "example-mob"
    And example source code as "example-user"
    And I inside "example-user"
    When I start mob
    Then I connect to mob started
    And I drive file "/example.rb"
    Then drive ok

  Scenario: release a drived file
    Given example source code as "example-mob"
    And example source code as "example-user"
    And I inside "example-user"
    When I start mob
    Then I connect to mob started
    And I drive file "example.rb"
    Then drive ok
    Then I release file "example.rb"
    Then ok

  Scenario: can't drive file of other programmer
    Given example source code as "example-mob"
    And example source code as "example-user"
    And I inside "example-user"
    When I start mob
    Then I connect to mob started
    And connect partner "partner" in "example-user"
    And partner "partner" drive file "example.rb"
    And I drive file "example.rb"
    Then fails with message "other programmer it's driving the resource"

  Scenario: can't release a drive of other programmer
    Given example source code as "mycode"
    And example source code as "example-user"
    And I inside "mycode"
    When I start mob
    Then I connect to mob started
    And connect partner "partner" in "example-user"
    And partner "partner" drive file "example.rb"
    And I release file "example.rb"
    Then fails with message "programmer it's not driving the resource"

  Scenario: can't drive a file out of project
    Given example source code as "example-mob"
    And example source code as "example-user"
    And I inside "example-user"
    When I start mob
    Then I connect to mob started
    And I drive file "../example-user/example.rb"
    Then fails with message "invalid path"

  Scenario: can't drive a file if overflow max file size
    Given example source code as "mycode"
    And I inside "mycode"
    When I start mob
    Then I connect to mob started with max-file-size 1 bytes
    And I drive file "example.rb"
    Then fails with message "overflow max size"
