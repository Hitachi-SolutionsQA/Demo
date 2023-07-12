Feature: HsalContactUs
	In order to find information about Hitachi Solutions
	As a potential customer
	I want to contact HSAL

@HsalContactUs
@DataSource:../Data/ContactUsData.csv
Scenario Outline: Navigate to HSAL and click Contact Us
  Given user landed on HSAL homepage
    When user clicks on Contact Us button
	And user fill fields <FirstName>, <LastName>, <Country> and <Description>
	And user clicks on Submit button
   Then user should be presented with an error message 

