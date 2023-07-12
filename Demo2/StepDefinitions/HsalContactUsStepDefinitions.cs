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
    public class HsalContactUsStepDefinitions
    {

        public HsalHome HsalHome;
        public HsalContactUs HsalContactUs;

        public HsalContactUsStepDefinitions(HsalHome home, HsalContactUs contacUs)
        {
            HsalHome = home;
            HsalContactUs = contacUs;
        }

        [Given(@"user landed on HSAL homepage")]
        public async Task GivenUserLandedOnHSALHomepage()
        {
            await this.HsalHome.navigate();
        }

        [When(@"user clicks on Contact Us button")]
        public async Task WhenUserClicksOnContactUsButton()
        {
            await this.HsalHome.ContactUsBtn.ClickAsync();
        }

        [When(@"user fill fields (.*)\, (.*)\, (.*) and (.*)")]
        public async Task WhenUserFillFieldsFirstNameLastNameCountryAndDescription(String FirstName, String LastName, String Country, String Description)
        {
            await this.HsalContactUs.FirstNameField.SetFieldValueAsync(FirstName);
            await this.HsalContactUs.LastNameField.SetFieldValueAsync(LastName);
            await this.HsalContactUs.CountrySelect.SelectOptionAsync(new[] { Country });
            await this.HsalContactUs.DescriptionField.SetFieldValueAsync(Description);
        }

        [When(@"user clicks on Submit button")]
        public async Task WhenUserClicksOnSubmitButton()
        {
            await this.HsalContactUs.SubmitBtn.ClickAsync();
        }

        [Then(@"user should be presented with an error message")]
        public async Task ThenUserShouldBePresentedWithAnErrorMessage()
        {
            await Assertions.Expect(HsalContactUs.ErrorMsg).ToContainTextAsync("This field is required.");
            this.HsalContactUs.ScreenShot.Take(Severity.INFO, "contact");

        }
    

    }
}
