Feature: HsalSearch
	In order to find information about automation
	As a potential customer
	I want to search HSAL

@HSALSearch
Scenario: Validate ContactUs Input ToolTip and search results
	Given user landed on HSAL homepage
	And user clicks on 'Contact us' menu item
	And user enters required info fields:
	| Field       | Value                |
	| First Name  | Tester               |
	| Last Name   | Automation           |
	| Country     | Curaçao              |
	| Description | test DescriptionTest |
	And user clicks on 'Submit' button
	And user verifies tooltips are present for required fields "Company Name,Company Email Address"
	When user opens Search modal
	And user types 'Irvine' in searchbox
	And user clicks on Search button
    Then user should be presented with search results from HSAL
