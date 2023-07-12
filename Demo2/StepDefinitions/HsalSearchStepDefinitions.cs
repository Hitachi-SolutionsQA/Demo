using HitachiQA.Playwright;
using HitachiPWSample.Pages;
using System;
using TechTalk.SpecFlow;
using Microsoft.Playwright.MSTest;
using Microsoft.Playwright;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using HitachiQA;

namespace HitachiPWSample.StepDefinitions
{
    [Binding]
    public class HsalSearchStepsDefinitions
    {
        public HsalHome HsalHome;
        public HsalSearch HsalSearch;

        public HsalSearchStepsDefinitions(HsalHome home, HsalSearch search)
        {
            HsalHome = home;
            HsalSearch = search;
        }


        [When(@"user clicks on Search button")]
        public async Task WhenUserClicksOnSearchButton()
        {
            await this.HsalHome.SearchBtn.ClickAsync();
        }

        [When(@"user fill types (.*)")]
        public async Task WhenUserFillTypesKeyword(String Keyword)
        {
            await this.HsalHome.SearchInput.SetFieldValueAsync(Keyword);
        }

        [When(@"user search value")]
        public async Task WhenUserClicksEnter()
        {
            await this.HsalHome.SearchIcon.ClickAsync();
        }

        [Then(@"user should be presented with the results of the search")]
        public async Task ThenUserShouldBePresentedWithTheResultsOfTheSearch()
        {
            await Assertions.Expect(HsalSearch.ResultsNumber).ToContainTextAsync("Results 1 to 10 of 36");
            this.HsalSearch.ScreenShot.Take(Severity.INFO, "searh");
        }

    }

}
