using Demo.Pages;
using HitachiQA;
using HitachiQA.Playwright;
using Table = TechTalk.SpecFlow.Table;
using TechTalk.SpecFlow.Assist;

namespace Demo.StepDefinition
{
    [Binding]
    public sealed class HsalSearchSteps
    {
        public HsalHome HsalHome;
        public string searchCriteria;

        public HsalSearchSteps(HsalHome page)
        {
            HsalHome = page;
        }
        
        [Given(@"user landed on HSAL homepage")]
        public async Task GivenUserLandedOnHSALHomepage()
        {
            await HsalHome.navigate();
        }

        [Given(@"user clicks on '([^']*)' menu item")]
        public async Task GivenUserClicksOnMenuItem(string buttonName)
        {
            await HsalHome.GetMenuItemByName(buttonName).ClickAsync();
        }

        [Given(@"user clicks on '([^']*)' button")]
        public async Task GivenUserClicksOnButton(string buttonText)
        {
            await HsalHome.GetButtonByText(buttonText).ClickAsync();
        }


        [Given(@"user enters required info fields:")]
        public async Task GivenUserEntersRequiredInfoFields(Table table)
        {
            foreach (var row in table.Rows)
            {
                if (row.GetString("Field") == "Country")
                {
                    await HsalHome.GetDropdownOptionByLabel("Country").SelectOptionAsync($"{row.GetString("Value")}");
                }
                else
                {
                    await HsalHome.GetContactFormField($"{row.GetString("Field")}").FillAsync($"{row.GetString("Value")}");
                }
            }
        }

        [Given(@"user verifies tooltips are present for required fields ""([^""]*)""")]
        public async Task GivenUserVerifiesTooltipsArePresentForRequiredFields(string fieldNamesList)
        {
            string[] fields = fieldNamesList.Split(',');
            foreach (var field in fields)
            {
                var toolTipText = await HsalHome.GetFieldToolTip(field).TextContentAsync();
                toolTipText.Should().Be("This field is required.");
            }
            HsalHome.ScreenShot.Info();
        }


        [When(@"user opens Search modal")]
        public async Task WhenUserOpensSearchModal()
        {
            await HsalHome.OpenSearch.ClickAsync();
        }

        [When(@"user types '([^']*)' in searchbox")]
        public async Task WhenUserTypesInSearchbox(string searchCriteria)
        {
            await HsalHome.SearchInput.SetFieldValueAsync(searchCriteria);
            this.searchCriteria = searchCriteria;
        }

        [When(@"user clicks on Search button")]
        public async Task WhenUserClicksOnSearchButton()
        {
            await HsalHome.SearchButton.ClickAsync();
        }

        [Then(@"user should be presented with search results from HSAL")]
        public async Task ThenUserShouldBePresentedWithSearchResultsFromHSAL()
        {
            var result = await HsalHome.ResultSearchHeader.TextContentAsync();
            result.Should().Be($"Search results for: {this.searchCriteria}");
            Log.Info("This is an infomrmaitonal Message");
            HsalHome.ScreenShot.Info();
        }
    }
}
