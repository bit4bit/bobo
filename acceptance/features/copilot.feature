Feature: As Copilot
  Scenario: copilot a mob
    Given example source code as "mycode"
    And example source code as "example-user"
    And In "example-user" file "example.rb" has content "mob"
    And In "mycode" file "example.rb" has content "user"
    And I inside "mycode"
    When I start mob
    Then I connect to mob started
    And connect partner "partner" in "example-user"
    And partner "partner" drive file "example.rb"
    And I wait 2 second
    Then In "mycode" file "example.rb" expects content "mob"
    Then In "example-user" file "example.rb" expects content "mob"
