Feature: As Programmer
  I want to do mob programming
  So we can learn about the domain

  Background:
    Given the source code
    When I start mob
    When I connect to mob started
    
  Scenario: Drive a file
    When I drive a file
    Then I can see the drived file

  Scenario: The files I drive using absolute path
    always are relative to source code 
    When I drive a file using absolute path 
    Then I can see the drived file using absolute path

  Scenario: Handover on the drived file
    When I drive a file
    And I handover the file
    Then I can't see the drived file

  Scenario: Can't drive a drived file of other programmer
    Given a partner
    And the partner drive a file
    When I drive a file
    Then fails with message "other programmer it's driving the resource"

  Scenario: Only can handover my drives files
    Given a partner
    And the partner drive a file
    When I handover the file
    Then fails with message "programmer it's not driving the resource"

  Scenario: Only can drive file inside of project
    out of the source code
    When I try to drive a file out of project
    Then fails with message "not found file"

  Scenario: Can only drive little files
    When I drive a big file
    Then fails with message "overflow max size"
