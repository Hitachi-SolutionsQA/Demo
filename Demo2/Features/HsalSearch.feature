Feature: HsalSearch
	In order to search information about Hitachi Solutions
	As a potential customer
	I want to use HSAL search

@HsalSearch
@DataSource:../Data/SearchData.csv
Scenario Outline: Navigate to HSAL and Search for Keyword
  Given user landed on HSAL homepage
    When user clicks on Search button
	And user fill types <Keyword>
	And user search value
   Then user should be presented with the results of the search

