using Demo.Pages;
using OpenQA.Selenium;
using TechTalk.SpecFlow;
using HitachiQA;

namespace Demo.StepDefinition
{
    [Binding]
    public sealed class HsalSearchSteps
    {
        // For additional details on SpecFlow step definitions see https://go.specflow.org/doc-stepdef

        public HsalHome HsalHome;
        public string searchCriteria;

        public HsalSearchSteps(HsalHome page)
        {
            this.HsalHome = page;
        }
        
        [Given(@"user landed on HSAL homepage")]
        public void GivenUserLandedOnHSALHomepage()
        {
            this.HsalHome.navigate();
        }

        [When(@"user opens Search modal")]
        public void WhenUserOpensSearchModal()
        {
            HsalHome.OpenSearch.Click();
        }

        [When(@"user types '([^']*)' in searchbox")]
        public void WhenUserTypesInSearchbox(string searchCriteria)
        {
            HsalHome.SearchInput.SetFieldValue(searchCriteria);
            this.searchCriteria = searchCriteria;
        }

        [When(@"user clicks on Search button")]
        public void WhenUserClicksOnSearchButton()
        {
            HsalHome.SearchButton.Click();
        }

        [Then(@"user should be presented with search results from HSAL")]
        public void ThenUserShouldBePresentedWithSearchResultsFromHSAL()
        {
            HsalHome.ResultSearchInput.assertTextFieldTextEquals(this.searchCriteria);

            Log.Info("This is an infomrmaitonal Message");
            HsalHome.ScreenShot.Info();
        }

    }
}
