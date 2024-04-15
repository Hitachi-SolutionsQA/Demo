Feature: HsalSearch
	In order to find information about automation
	As a potential customer
	I want to search HSAL

@HSALSearch
Scenario: Validate ContactUs Input ToolTip and search results
	Given user landed on HSAL homepage
	* user clicks on 'Contact us' button
	And user enters required info fields:
	| Field                      | Value                |
	| First Name                 | Tester               |
	| Last Name                  | Automation           |
	| Company Name               | Testers Inc.         |
	| E-mail                     | test132@test.co      |
	| Country					 | Curaçao              |
	| What can we help you with? | test DescriptionTest |
	* user clicks on 'Submit' button
	When user verifies "Thank You!" header 
	And user opens Search modal
	* user types 'Irvine' in searchbox
	* user clicks on Search button
    Then user should be presented with search results from HSAL
