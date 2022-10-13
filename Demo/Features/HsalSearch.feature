Feature: HsalSearch
	In order to find information about automation
	As a potential customer
	I want to search HSAL

@HSALSearch
Scenario: Navigate to HSAL and search for automation
  Given user landed on HSAL homepage
    When user opens Search modal
	And user types 'Automation' in searchbox
	And user clicks on Search button
   Then user should be presented with search results from HSAL
