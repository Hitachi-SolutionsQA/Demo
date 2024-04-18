using HitachiQA;
using HitachiQA.Helpers;
using HitachiQA.Playwright;
using Microsoft.Extensions.Configuration;
using Microsoft.Playwright;
using Newtonsoft.Json.Linq;
using System;
using TechTalk.SpecFlow;

namespace Demo.StepDefinitions
{
    [Binding]
    public class CRMDemoStepDefinitions
    {
        public BasePage Page { get; init; }
        public IConfiguration Config { get; init; }
        public virtual IFrameLocator Frame => Page.PlaywrightPage.FrameLocator("//iframe[@title=\"IFRAME\"]");
        public SharedData Data;
        public CRMDemoStepDefinitions(BasePage basePage, SharedData data, IConfiguration config)
        {
            Page = basePage;
            Data = data;
            Config = config;
        }


        [Given(@"user landed in CRM")]
        public async Task GivenUserLandedInCRM()
        {
            await Page.PlaywrightPage.SetViewportSizeAsync(1600,1200);
           
            await Page.GotoAsync("https://hs.crm.dynamics.com/");
            await Page.PlaywrightPage.RouteAsync("**/cei_weeklyworkplans**", async req =>
            {
                var res = await req.FetchAsync();

                var body = await res.TextAsync();
                var json = JObject.Parse(body);
                foreach (JObject item in json["value"])
                {
                    if (item.ContainsKey("cei_hours") && item.Value<int>("cei_hours")==40)
                    {
                        item["cei_hours"] = 50;
                        item["cei_hours@OData.Community.Display.V1.FormattedValue"] = "50";
                    }
                }
                await req.FulfillAsync(new()
                {
                    Response = res,
                    Body = json.ToString(Newtonsoft.Json.Formatting.None),
                    
                });

            });


            await Page.PlaywrightPage.GetByPlaceholder("Email, phone, or Skype").TypeAsync(Config.GetVariable("dynamics.username"));
            await Page.Locator("xpath=//*[@value='Next']").ClickAsync();
            await Page.PlaywrightPage.GetByPlaceholder("Password").TypeAsync(Config.GetVariable("dynamics.password"));
            await Page.Locator("xpath=//*[@value='Sign in']").ClickAsync();
            if (!string.IsNullOrWhiteSpace(Config.GetVariable("mfa.secret", true)))
            {
                await Page.Locator("[data-value='PhoneAppOTP']").ClickAsync();
                var code = Functions.GenerateMFAOneTimeCode(Config.GetVariable("mfa.secret"));
                await Page.Locator("[name='otc']").TypeAsync(code);
                await Page.Locator("input[type='submit']").ClickAsync();
            }

            await Page.Locator("input[value='Yes']").ClickAsync();

           

            await Assertions.Expect(Page.Locator("xpath=//*[text()='Brand You Dashboar1d']").First).ToBeVisibleAsync(new() { Timeout=120000});
                       
        }
        [When(@"user types the following values into the project matrix")]
        public async Task WhenUserTypesTheFollowingValuesIntoTheProjectMatrix(Table table)
        {
            Data.SetValue("matrix", "table", table);
            foreach(var row in table.Rows)
            {
                var colI = row["colIndex"];
                var rowI = int.Parse(row["rowIndex"]);
                var value = row["value"];

                await Frame.Locator($"xpath=//*[contains(@class,'hsl-columnGroup-cei_weekdate hsl-columnGroup-{colI}')]//input").Nth(rowI).TypeAsync(value);
            }
            await Page.PlaywrightPage.Keyboard.PressAsync("Escape");

        }

        [Then(@"column total should display red if total greater than 40")]
        public async Task ThenColumnTotalShouldDisplayRedIfTotalGreaterThan()
        {
            var table = Data.GetValue<Table>("matrix", "table");
            foreach (var row in table.Rows)
            {
                var colI = row["colIndex"];
                var rowI = int.Parse(row["rowIndex"]);

                var columnTotalLocator = Frame.Locator($"xpath=//*[contains(@class,'hsl-colGroupFooter-{colI} hsl-columnGroup-cei_weekdate')]//*[text()]", null);
                var value = await columnTotalLocator.TextContentAsync();
                var classAtt = await columnTotalLocator.GetAttributeAsync("class");

                value.Should().NotBeNull();

                if (value != "" && int.Parse(value) > 40)
                {
                    classAtt.Should().Contain("text-danger");
                }
                else
                {
                    classAtt.Should().NotContain("text-danger");
                }
            }
        }


    }
}
