using BoDi;
using HitachiQA.Playwright;
using Microsoft.Playwright;

namespace HitachiPWSample.Pages
{

    public class HsalContactUs : BasePage
    {
        public HsalContactUs(ObjectContainer OC) : base(OC) 
        {
        }
        public string URL_PATH = "/contact-us/";
        public ILocator FirstNameField => Locator("#input_5_1");
        public ILocator LastNameField => Locator("#input_5_3");
        public ILocator CountrySelect => Locator("#input_5_8");
        public ILocator DescriptionField => Locator("#input_5_12");
        public ILocator SubmitBtn => Locator("#gform_submit_button_5");
        public ILocator ErrorMsg => Locator("#validation_message_5_5");
    }
}
