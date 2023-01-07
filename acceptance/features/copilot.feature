Feature: As Copilot
  Scenario: copilot a mob
    Given example source code as "mycode"
    And example source code as "driver"
    And In "driver" file "example.rb" has content "mob"
    And In "mycode" file "example.rb" has content "user"
    And I inside "mycode"
    When I start mob
    Then I connect to mob started
    And connect partner "partner" in "driver"
    And partner "partner" drive file "example.rb"
    And I wait 2 second
    Then In "mycode" file "example.rb" expects content "mob"
    Then In "driver" file "example.rb" expects content "mob"


  Scenario: copilot only update changed files
    Given example source code as "mycode"
    And example source code as "driver"
    And In "driver" file "example.rb" has content "mob"
    And In "mycode" file "example.rb" has content "user"
    And I inside "mycode"
    When I start mob
    Then I connect to mob started
    And connect partner "partner" in "driver"
    And partner "partner" drive file "example.rb"
    And I wait 2 second
    Then In "mycode" file "example.rb" expects content "mob"
    Then I wait 3 seconds and in "mycode" file "example.rb" is the same
