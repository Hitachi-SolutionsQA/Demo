using BoDi;
using HitachiQA;
using HitachiQA.Dynamics.FS.Pages;
using HitachiQA.Helpers;
using HitachiQA.Hooks;
using HitachiQA.Hooks.Browsers;
using Microsoft.Extensions.Configuration;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Demo.Hooks
{
    [Binding]
    public class LoginHook
    {
        ObjectContainer objectContainer;
        ScenarioInfo scenarioInfo;

        public LoginHook(ObjectContainer oc, ScenarioInfo ScenarioInfo)
        {
            this.objectContainer = oc;
            scenarioInfo = ScenarioInfo;
        }

        [BeforeScenario(Order = 3)]
        public void WhenUserSignsIn(IConfiguration Config)
        {
            if (!objectContainer.Resolve<BrowserIndicator>().IsBrowserFeature || !scenarioInfo.Tags.Contains("login"))
            {
                return;
            }
            
            Dyn_LoginPage Page = objectContainer.Resolve<Dyn_LoginPage>();
            Page.UsernameTextField.setText(Config.GetVariable("dynamics.username"));

            //Next button
            Page.SubmitButton.Click();

            Page.PasswordTextField.setText(Config.GetVariable("dynamics.password"));

            //Sign in button
            Page.SubmitButton.Click();

            Thread.Sleep(1000);

            Page.ScreenShot.Take(Severity.INFO);
            var progressBar = Page.Element("//*[@class='row progress-container']");
            progressBar.assertElementIsVisible(5,true);
            progressBar.assertElementNotPresent();
            if(!Page.SubmitButton.assertElementIsVisible(wait_Seconds: 1, optional: true))
            {
                var mfaSecret = Config.GetVariable("mfa.secret", true);
                if(!string.IsNullOrWhiteSpace(mfaSecret) && mfaSecret.ToLower() !="tbd")
                {
                    if(Page.Element("//*[text()='Approve sign in request']").assertElementIsVisible(wait_Seconds:1,optional:true))
                    {
                        Page.Element("//*[@id='signInAnotherWay']").Click();
                    }

                    var phoneAppOTPButton = Page.Element("//*[@data-value='PhoneAppOTP']");
                    phoneAppOTPButton.Click();
                    var code = Functions.GenerateMFAOneTimeCode(Config.GetVariable("mfa.secret"));
                    Page.Element("//*[@name='otc']").SetFieldValue(code);
                    Page.SubmitButton.Click();
                }


            }

            //Yes (stay signed in)
            if (Page.SubmitButton.GetAttribute("value") == "Sign in")
            {
                throw new Exception($"Sign In Failed, UI Message: {Page.Element("//*[@id='passwordError']").GetElementText()}");
            }
            Page.SubmitButton.Click();



        }
    }
}
