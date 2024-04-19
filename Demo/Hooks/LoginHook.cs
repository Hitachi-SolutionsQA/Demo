using BoDi;
using HitachiQA;
using HitachiQA.Dynamics.FS.Pages;
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

            //Yes (stay signed in)
            if (Page.SubmitButton.GetAttribute("value") == "Sign in")
            {
                throw new Exception($"Sign In Failed, UI Message: {Page.Element("//*[@id='passwordError']").GetElementText()}");
            }
            Page.SubmitButton.Click();



        }
    }
}
